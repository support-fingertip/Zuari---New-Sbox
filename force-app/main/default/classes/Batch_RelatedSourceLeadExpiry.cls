/**
 * @description Batch implementation of the AMC lead-expiry policy on
 * Channel Partner Related_Source__c records.
 *
 * Why a batch?
 *   When the same logic ran as a single-transaction service
 *   (RelatedSourceLeadExpiryService.processExpiries old impl) it blew
 *   the 100-SOQL governor limit because the RelatedSourceTrigger ->
 *   RelatedSourceHandler.sendCustomNotification chain runs a query
 *   per owner-changed record. Processing in 50-record chunks gives
 *   each chunk its own fresh SOQL budget and keeps us safely under
 *   the cap.
 *
 * Scope size       : 50  (driven by scheduler / on-demand call)
 * Concurrency      : Stateful counters accumulate across chunks for
 *                    the finish-email summary.
 * Re-entrancy safe : locator filters Lead_Expired__c = false so a
 *                    record cannot be processed twice across runs.
 *
 * Modeled after Batch_CountSiteVisitPerRelatedSource for pattern
 * consistency with the rest of this org.
 */
global without sharing class Batch_RelatedSourceLeadExpiry
    implements Database.Batchable<sObject>, Database.Stateful {

    // -------- Stateful counters (accumulate across chunks) --------
    global Integer scenario1Count   = 0;
    global Integer scenario2Count   = 0;
    global Integer totalProcessed   = 0;
    global Integer totalFailed      = 0;
    global List<String> errorMessages = new List<String>();

    // -------- Per-run caches (lazy-resolved on first execute) --------
    private static Id   cachedDirectSalesHeadId;
    private static User cachedSalesHead;

    // ============================================================
    //  START - prefilter at the record level. The 30-day cutoff
    //  catches both scenarios: Scenario 2 requires a 45-day-old SV
    //  which implies the record itself is at least that old.
    // ============================================================
    global Database.QueryLocator start(Database.BatchableContext bc) {

        // Conservative prefilter: catches Scenario 1 candidates by raw age.
        // Scenario 2 implies the record is at least 30 days old too, so this
        // covers both. Extension_Days__c is applied precisely in execute()
        // per record.
        DateTime cutoff30 = System.now().addDays(-RelatedSourceLeadExpiryService.SCENARIO_1_DAYS);

        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId, Owner.Name, Owner.Email,
                   Channel_Partner1__c, Channel_Partner1__r.Name,
                   CreatedDate, Last_Re_Opened_Date__c,
                   Lead_status1__c, Last_Note__c, SLead__c,
                   Lead_Expired__c, Expiry_Remarks__c,
                   Expiry_Days__c, Extension_Days__c
            FROM   Related_Source__c
            WHERE  Channel_Partner1__c != null AND Allocated_Project__c = 'Zuari Gangothri Tribhuja'
            AND    Lead_Expired__c = false
            AND    Lead_status1__c NOT IN :RelatedSourceLeadExpiryService.EXCLUDED_STATUSES
            AND    (Last_Re_Opened_Date__c <= :cutoff30
                    OR (Last_Re_Opened_Date__c = null AND CreatedDate <= :cutoff30))
        ]);
    }

    // ============================================================
    //  EXECUTE - one chunk
    // ============================================================
    global void execute(Database.BatchableContext bc, List<Related_Source__c> scope) {

        // ---- Resolve & cache Sales Head once per JVM container ----
        if (cachedDirectSalesHeadId == null) {
            cachedDirectSalesHeadId = RelatedSourceLeadExpiryService.resolveDirectSalesHeadId();
            if (cachedDirectSalesHeadId == null) {
                errorMessages.add('Direct Sales Head user not found - chunk skipped. ' +
                                  'Check Custom Label "Direct_Sales_Head_Username".');
                return;
            }
            cachedSalesHead = [
                SELECT Id, Name, Email FROM User
                WHERE  Id = :cachedDirectSalesHeadId LIMIT 1
            ];
        }

        Set<Id> rsIds = new Map<Id, Related_Source__c>(scope).keySet();

        // ---- Per-chunk lookups (2 SOQL queries, fully bulk) ----
        Map<Id, DateTime> latestCompletedSvByRs = new Map<Id, DateTime>();
        for (AggregateResult ar : [
            SELECT Related_Source__c rsId, MAX(CreatedDate) lastSv
            FROM   Site_Visit__c
            WHERE  Related_Source__c IN :rsIds
            AND    Status__c = 'Completed'
            GROUP BY Related_Source__c
        ]) {
            latestCompletedSvByRs.put((Id) ar.get('rsId'), (DateTime) ar.get('lastSv'));
        }

        Set<Id> rsWithBooking = new Set<Id>();
        for (AggregateResult ar : [
            SELECT Related_Source__c rsId
            FROM   Booking__c
            WHERE  Related_Source__c IN :rsIds
            GROUP BY Related_Source__c
        ]) {
            rsWithBooking.add((Id) ar.get('rsId'));
        }

        // ---- Evaluate scenarios per record ----
        // Per-record cutoffs add Extension_Days__c so an approved RM->TL
        // extension defers expiry. Scenario labels preserved per business request.
        String timestamp  = System.now().format('dd-MM-yy HH:mm a', 'Asia/Kolkata');

        List<Related_Source__c>            rsUpdates         = new List<Related_Source__c>();
        List<String>                       scenarioForUpdate = new List<String>();
        List<Call_Comments__c>             comments          = new List<Call_Comments__c>();
        List<Messaging.SingleEmailMessage> emails            = new List<Messaging.SingleEmailMessage>();

        for (Related_Source__c rs : scope) {
            String   scenarioLabel = null;
            String   reason        = null;
            DateTime anchorUsed    = null;
            Boolean  hasCompletedSv = latestCompletedSvByRs.containsKey(rs.Id);

            Integer extDays = (rs.Extension_Days__c == null) ? 0 : rs.Extension_Days__c.intValue();
            DateTime cutoff30 = System.now().addDays(-(RelatedSourceLeadExpiryService.SCENARIO_1_DAYS + extDays));
            DateTime cutoff45 = System.now().addDays(-(RelatedSourceLeadExpiryService.SCENARIO_2_DAYS + extDays));

            // SCENARIO 1: no completed SV, anchor (reopen-or-created) old enough
            if (!hasCompletedSv) {
                DateTime anchorS1 = (rs.Last_Re_Opened_Date__c != null)
                                    ? rs.Last_Re_Opened_Date__c
                                    : rs.CreatedDate;
                if (anchorS1 <= cutoff30) {
                    scenarioLabel = 'Scenario 1';
                    anchorUsed    = anchorS1;
                    reason = RelatedSourceLeadExpiryService.NOTE_PREFIX_S1
                           + (RelatedSourceLeadExpiryService.SCENARIO_1_DAYS + extDays)
                           + ' days from '
                           + (rs.Last_Re_Opened_Date__c != null ? 're-opened date' : 'enquiry date')
                           + ' (' + anchorUsed.format('dd-MM-yyyy', 'Asia/Kolkata') + ').';
                }
            }
            // SCENARIO 2: completed SV exists, no booking, anchor (later of SV-date / reopen-date) old enough
            else if (!rsWithBooking.contains(rs.Id)) {
                DateTime anchorS2 = latestCompletedSvByRs.get(rs.Id);
                Boolean  fromReopen = false;
                if (rs.Last_Re_Opened_Date__c != null && rs.Last_Re_Opened_Date__c > anchorS2) {
                    anchorS2   = rs.Last_Re_Opened_Date__c;
                    fromReopen = true;
                }
                if (anchorS2 <= cutoff45) {
                    scenarioLabel = 'Scenario 2';
                    anchorUsed    = anchorS2;
                    reason = RelatedSourceLeadExpiryService.NOTE_PREFIX_S2
                           + (RelatedSourceLeadExpiryService.SCENARIO_2_DAYS + extDays)
                           + ' days from '
                           + (fromReopen ? 're-opened date' : 'site visit completion date')
                           + ' (' + anchorUsed.format('dd-MM-yyyy', 'Asia/Kolkata') + ').';
                }
            }

            if (scenarioLabel == null) continue;

            // Build the payload
            String existingNote = (rs.Last_Note__c == null) ? '' : rs.Last_Note__c;
            String newLine = '\nLead Expiry [' + timestamp + ']: ' + reason +
                             ' Owner changed to ' + cachedSalesHead.Name + '.';
            String previousOwnerName = (rs.Owner != null && rs.Owner.Name != null)
                                       ? rs.Owner.Name
                                       : String.valueOf(rs.OwnerId);   // queue or null fallback
            String remarks = '[' + timestamp + '] ' + scenarioLabel + ' - ' + reason +
                             ' | Previous owner: ' + previousOwnerName +
                             ' | New owner: ' + cachedSalesHead.Name;

            rsUpdates.add(new Related_Source__c(
                Id                = rs.Id,
                OwnerId           = cachedDirectSalesHeadId,
                Lead_Expired__c   = true,
                Expiry_Remarks__c = remarks,
                Last_Note__c      = existingNote + newLine
            ));
            scenarioForUpdate.add(scenarioLabel);

            comments.add(new Call_Comments__c(
                Comments__c       = reason,
                Related_Source__c = rs.Id,
                Lead__c           = rs.SLead__c,
                Created_User__c   = UserInfo.getUserId(),
                Created_Date__c   = System.now(),
                User_Profile__c   = 'System (Lead Expiry Batch)'
            ));

            emails.add(RelatedSourceLeadExpiryService.buildEmail(rs, cachedSalesHead, scenarioLabel, reason));
        }

        // ---- DML with partial success ----
        if (!rsUpdates.isEmpty()) {
            Database.SaveResult[] results = Database.update(rsUpdates, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    totalProcessed++;
                    if (scenarioForUpdate[i] == 'Scenario 1') scenario1Count++;
                    else                                       scenario2Count++;
                } else {
                    totalFailed++;
                    for (Database.Error e : results[i].getErrors()) {
                        errorMessages.add('RS ' + rsUpdates[i].Id +
                                          ' [' + scenarioForUpdate[i] + '] | ' +
                                          e.getStatusCode() + ' | ' + e.getMessage());
                    }
                }
            }
        }

        if (!comments.isEmpty()) {
            Database.insert(comments, false);
        }

        if (!emails.isEmpty() && !Test.isRunningTest()) {
            try {
                Messaging.sendEmail(emails, false);
            } catch (Exception ex) {
                errorMessages.add('Email send chunk failed: ' + ex.getMessage());
            }
        }
    }

    // ============================================================
    //  FINISH - summary email to job creator
    // ============================================================
    global void finish(Database.BatchableContext bc) {

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                   TotalJobItems, CreatedBy.Email
            FROM   AsyncApexJob
            WHERE  Id = :bc.getJobId()
        ];

        String summary = 'Batch_RelatedSourceLeadExpiry Completed.\n\n' +
            'Status              : ' + job.Status + '\n' +
            'Total Batches       : ' + job.TotalJobItems + '\n' +
            'Batches Processed   : ' + job.JobItemsProcessed + '\n' +
            'Batch-Level Errors  : ' + job.NumberOfErrors + '\n\n' +
            'Records Expired     : ' + totalProcessed + '\n' +
            '  Scenario 1 (30 d) : ' + scenario1Count + '\n' +
            '  Scenario 2 (45 d) : ' + scenario2Count + '\n' +
            'Records Failed      : ' + totalFailed + '\n';

        if (!errorMessages.isEmpty()) {
            summary += '\nError Details:\n';
            for (String e : errorMessages) summary += '- ' + e + '\n';
        }

        System.debug(summary);

        if (!Test.isRunningTest()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{ job.CreatedBy.Email });
            mail.setSaveAsActivity(false);
            mail.setSubject('Batch Job Complete: Related Source Lead Expiry');
            mail.setPlainTextBody(summary);
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'Finish email send failed: ' + e.getMessage());
            }
        }
    }
}