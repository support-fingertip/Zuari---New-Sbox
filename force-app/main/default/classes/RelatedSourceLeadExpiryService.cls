/**
 * @description Service class that enforces the AMC lead-expiry policy on
 * Channel Partner Related_Source__c records.
 *
 * ------------------------------------------------------------
 *  BUSINESS RULES (configurable via Custom Labels):
 * ------------------------------------------------------------
 *  Scenario 1 - "Enquiry to Site Visit" - default 30 days
 *      If a CP related source does NOT have a COMPLETED Site Visit
 *      within 30 days of:
 *          - Last_Re_Opened_Date__c  (when the lead is reopened)
 *          - CreatedDate              (otherwise)
 *      then the lead is expired.
 *
 *      Note: A Site Visit that was Scheduled and later Cancelled is
 *      treated the same as no Site Visit, because we only count
 *      Site_Visit__c records with Status__c = 'Completed'.
 *
 *  Scenario 2 - "Site Visit to Booking" - default 45 days
 *      If a CP related source has a COMPLETED Site Visit but NO Booking
 *      within 45 days of the latest of:
 *          - Last completed Site_Visit__c.CreatedDate (or SV date)
 *          - Last_Re_Opened_Date__c (if the lead was reopened after SV)
 *      then the lead is expired.
 *
 *  When a lead expires the service:
 *      1. Changes OwnerId   ->  Direct Team Sales Head user
 *         (configured via Custom Label "Direct_Sales_Head_Username")
 *      2. Sets Lead_Expired__c   = true   (prevents re-processing on next run)
 *      3. Sets Expiry_Remarks__c          (reason + scenario + anchor date)
 *      4. Appends an audit line to Last_Note__c
 *      5. Creates a Call_Comments__c record (audit trail)
 *      6. Sends an email to the new owner (Sales head)
 *
 *  SCOPE:  Only Related_Source__c records where Channel_Partner1__c != null
 *          (i.e. leads sourced through a Channel Partner). Direct leads are
 *          out of scope per AMC requirement.
 *
 *  Author : Auto-generated for AMC Lead Expiry requirement
 *  Date   : 14-05-2026
 */
public without sharing class RelatedSourceLeadExpiryService {

    // ----- Tunable thresholds (override via Custom Labels if you want) -----
    // Public so Batch_RelatedSourceLeadExpiry can read the same values.
    public static Integer SCENARIO_1_DAYS = 30;
    public static Integer SCENARIO_2_DAYS = 45;

    // Booked status on Related_Source__c.Lead_status1__c - excluded from expiry.
    // Expiry itself is tracked via the dedicated Lead_Expired__c checkbox
    // (instead of overloading the Lead_status1__c picklist).
  //  public static final String STATUS_BOOKED  = 'Booked';
    
    public static final Set<String> EXCLUDED_STATUSES = new Set<String>{
    'Booked',
    'Request for Rejection',
    'Rejected',
    'Unqualified',
    'Closed Lost'
};

    public static final String NOTE_PREFIX_S1 = 'Lead Expired (Scenario 1): No Site Visit completed within ';
    public static final String NOTE_PREFIX_S2 = 'Lead Expired (Scenario 2): Site Visit not converted to Booking within ';

    /**
     * @description Entry point - invoked by the scheduler.
     *
     *              Fires Batch_RelatedSourceLeadExpiry so that processing
     *              happens in 50-record chunks. This is required because
     *              the RelatedSourceTrigger / RelatedSourceHandler chain
     *              has a SOQL query inside a per-record loop in
     *              sendCustomNotification(...) - updating 100+ records in
     *              a single transaction blows the 100-SOQL governor limit.
     *
     *              Batch chunks each run in their own transaction with a
     *              fresh SOQL budget, so we stay safely under the cap.
     *
     *              The original single-transaction implementation
     *              (collectScenario1Candidates / collectScenario2Candidates
     *              / applyExpiry) is retained below as a quick-revert
     *              fallback - it is not called.
     *
     *              @AuraEnabled so the QA tester LWC (leadExpiryTester)
     *              can fire it from a button. NOT cacheable - it has a
     *              side effect (kicks off the batch).
     *
     * @return AsyncApexJob Id of the kicked-off batch run
     */
    @AuraEnabled
    public static Id processExpiries() {
        return Database.executeBatch(new Batch_RelatedSourceLeadExpiry(), 50);
    }

    // ------------------------------------------------------------
    //  SCENARIO 1 : Enquiry -> Site Visit  (30 days)
    // ------------------------------------------------------------
    /**
     * Finds CP related sources older than 30 days (from re-opened date OR
     * created date) that have NO completed Site Visit.
     *
     * NOTE on cancelled SVs:  We only look at Site_Visit__c records with
     * Status__c = 'Completed'. Scheduled or Cancelled SVs are ignored, so
     * a lead whose SV got cancelled will fall into this scenario and expire
     * (which is exactly what the business asked for).
     */
    @TestVisible
    private static void collectScenario1Candidates(Map<Id, ExpiryResult> toExpire) {

        DateTime cutoff = System.now().addDays(-SCENARIO_1_DAYS);

        // Pull active CP related sources where the relevant anchor date is older than the cutoff.
        // We compute "anchor" in Apex because SOQL can't COALESCE on DateTime cleanly.
        List<Related_Source__c> candidates = [
            SELECT Id, Name, OwnerId, Owner.Email,
                   Channel_Partner1__c, Channel_Partner1__r.Name,
                   CreatedDate, Last_Re_Opened_Date__c,
                   Lead_status1__c, Last_Note__c, SLead__c,
                   Lead_Expired__c, Expiry_Remarks__c,
                   Extension_Days__c,
                   Is_Site_Visit_Created__c
            FROM   Related_Source__c
            WHERE  Channel_Partner1__c != null
            AND    Lead_Expired__c = false
            AND    Lead_status1__c NOT IN :EXCLUDED_STATUSES
            AND    (Last_Re_Opened_Date__c <= :cutoff
                    OR (Last_Re_Opened_Date__c = null AND CreatedDate <= :cutoff))
            LIMIT  10000
        ];

        if (candidates.isEmpty()) return;

        // Find which of these actually have a Completed Site Visit (those we exclude)
        Set<Id> rsIds = new Map<Id, Related_Source__c>(candidates).keySet();
        Set<Id> rsWithCompletedSV = new Set<Id>();

        for (AggregateResult ar : [
            SELECT Related_Source__c rsId
            FROM   Site_Visit__c
            WHERE  Related_Source__c IN :rsIds
            AND    Status__c = 'Completed'
            GROUP BY Related_Source__c
        ]) {
            rsWithCompletedSV.add((Id) ar.get('rsId'));
        }

        for (Related_Source__c rs : candidates) {
            if (rsWithCompletedSV.contains(rs.Id)) continue;          // SV done -> skip Scenario 1
            if (toExpire.containsKey(rs.Id)) continue;                 // Already queued

            DateTime anchor = (rs.Last_Re_Opened_Date__c != null)
                              ? rs.Last_Re_Opened_Date__c
                              : rs.CreatedDate;

            Integer extDays = (rs.Extension_Days__c == null) ? 0 : rs.Extension_Days__c.intValue();
            if (anchor > System.now().addDays(-(SCENARIO_1_DAYS + extDays))) continue;

            String reason = NOTE_PREFIX_S1 + (SCENARIO_1_DAYS + extDays) +
                            ' days from ' +
                            (rs.Last_Re_Opened_Date__c != null ? 're-opened date' : 'enquiry date') +
                            ' (' + anchor.format('dd-MM-yyyy', 'Asia/Kolkata') + ').';

            toExpire.put(rs.Id, new ExpiryResult(rs, reason, 'Scenario 1'));
        }
    }

    // ------------------------------------------------------------
    //  SCENARIO 2 : Site Visit -> Booking  (45 days)
    // ------------------------------------------------------------
    /**
     * Finds CP related sources that DO have a completed Site Visit but no
     * Booking, where 45 days have passed since the later of:
     *   - the last completed SV date
     *   - Last_Re_Opened_Date__c (if reopened after the SV)
     */
    @TestVisible
    private static void collectScenario2Candidates(Map<Id, ExpiryResult> toExpire) {

        DateTime cutoff = System.now().addDays(-SCENARIO_2_DAYS);

        // Step 1: pull every CP related source that's still open and has had a completed SV.
        // We can't filter by "has Booking" in a single SOQL, so we filter in Apex.
        List<Related_Source__c> openCpRecords = [
            SELECT Id, Name, OwnerId, Owner.Email,
                   Channel_Partner1__c, Channel_Partner1__r.Name,
                   CreatedDate, Last_Re_Opened_Date__c,
                   Lead_status1__c, Last_Note__c, SLead__c,
                   Lead_Expired__c, Expiry_Remarks__c,
                   Extension_Days__c,
                   (SELECT Id, CreatedDate FROM Site_Visit__r
                    WHERE Status__c = 'Completed'
                    ORDER BY CreatedDate DESC LIMIT 1),
                   (SELECT Id FROM Bookings__r LIMIT 1)
            FROM   Related_Source__c
            WHERE  Channel_Partner1__c != null
            AND    Lead_Expired__c = false
            AND    Lead_status1__c NOT IN :EXCLUDED_STATUSES
            LIMIT  10000
        ];
        // NOTE: child relationship names (Site_Visit__r, Bookings__r) may differ in your org.
        //       Adjust to match the actual Child Relationship Name on the lookups.

        for (Related_Source__c rs : openCpRecords) {
            if (toExpire.containsKey(rs.Id)) continue;                 // Already queued by Scenario 1

            // Must have at least one completed SV to be in Scenario 2
            List<Site_Visit__c> svList = rs.Site_Visit__r;
            if (svList == null || svList.isEmpty()) continue;

            // Skip if a booking already exists - lead converted
            if (rs.Bookings__r != null && !rs.Bookings__r.isEmpty()) continue;

            DateTime lastSv = svList[0].CreatedDate;
            DateTime anchor = lastSv;
            if (rs.Last_Re_Opened_Date__c != null && rs.Last_Re_Opened_Date__c > anchor) {
                anchor = rs.Last_Re_Opened_Date__c;
            }

            Integer extDays = (rs.Extension_Days__c == null) ? 0 : rs.Extension_Days__c.intValue();
            if (anchor > System.now().addDays(-(SCENARIO_2_DAYS + extDays))) continue;

            String reason = NOTE_PREFIX_S2 + (SCENARIO_2_DAYS + extDays) +
                            ' days from ' +
                            (anchor == rs.Last_Re_Opened_Date__c ? 're-opened date' : 'site visit completion date') +
                            ' (' + anchor.format('dd-MM-yyyy', 'Asia/Kolkata') + ').';

            toExpire.put(rs.Id, new ExpiryResult(rs, reason, 'Scenario 2'));
        }
    }

    // ------------------------------------------------------------
    //  APPLY EXPIRY: owner change, note, comment, email
    // ------------------------------------------------------------
    @TestVisible
    private static void applyExpiry(Map<Id, ExpiryResult> toExpire, Id directSalesHeadId) {

        User salesHead = [
            SELECT Id, Name, Email
            FROM   User
            WHERE  Id = :directSalesHeadId
            LIMIT  1
        ];

        List<Related_Source__c>   rsUpdates   = new List<Related_Source__c>();
        List<Call_Comments__c>    comments    = new List<Call_Comments__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        String timestamp = System.now().format('dd-MM-yy HH:mm a', 'Asia/Kolkata');

        for (ExpiryResult er : toExpire.values()) {
            Related_Source__c rs = er.record;

            // Append to Last_Note__c (preserve history) - keeps human-readable trail
            String existingNote = (rs.Last_Note__c == null) ? '' : rs.Last_Note__c;
            String newLine      = '\nLead Expiry [' + timestamp + ']: ' + er.reason +
                                  ' Owner changed to ' + salesHead.Name + '.';

            // Expiry_Remarks__c is the dedicated reason field
            String remarks = '[' + timestamp + '] ' + er.scenarioLabel + ' - ' + er.reason +
                             ' | Previous owner: ' + rs.OwnerId +
                             ' | New owner: ' + salesHead.Name;

            rsUpdates.add(new Related_Source__c(
                Id                 = rs.Id,
                OwnerId            = directSalesHeadId,
                Lead_Expired__c    = true,
                Expiry_Remarks__c  = remarks,
                Last_Note__c       = existingNote + newLine
            ));

            // 2) Audit comment on Call_Comments__c
            comments.add(new Call_Comments__c(
                Comments__c        = er.reason,
                Related_Source__c  = rs.Id,
                Lead__c            = rs.SLead__c,
                Created_User__c    = UserInfo.getUserId(),
                Created_Date__c    = System.now(),
                User_Profile__c    = 'System (Lead Expiry Scheduler)'
            ));

            // 3) Email the new owner
            emails.add(buildEmail(rs, salesHead, er.scenarioLabel, er.reason));
        }

        // -------- DML (partial success so a single bad row doesn't fail the batch) --------
        if (!rsUpdates.isEmpty()) {
            for (Database.SaveResult sr : Database.update(rsUpdates, false)) {
                if (!sr.isSuccess()) {
                    for (Database.Error e : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'RS update failed [' + sr.getId() + ']: ' + e.getMessage());
                    }
                }
            }
        }

        if (!comments.isEmpty()) {
            Database.insert(comments, false);
        }

        // Skip email in tests to avoid governor noise
        if (!emails.isEmpty() && !Test.isRunningTest()) {
            try {
                Messaging.sendEmail(emails, false);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Expiry email send failed: ' + ex.getMessage());
            }
        }
    }

    // ------------------------------------------------------------
    //  Email builder - public so Batch_RelatedSourceLeadExpiry can reuse it.
    // ------------------------------------------------------------
   
    public static Messaging.SingleEmailMessage buildEmail(
        Related_Source__c rs, User salesHead, String scenarioLabel, String reason
    ) {
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE '%communication@crm.zuariproperties.com%' LIMIT 1];
       
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ salesHead.Email });
        mail.setSaveAsActivity(false);
        mail.setSubject('[Lead Expiry] ' + scenarioLabel + ' - ' + rs.Name);
		 if (!owea.IsEmpty()) mail.setOrgWideEmailAddressId(owea[0].id);
           
        String body =
            'Hello ' + salesHead.Name + ',\n\n' +
            'A Channel-Partner-sourced lead has expired per AMC policy and ' +
            'has been transferred to you.\n\n' +
            'Related Source : ' + rs.Name + '\n' +
            'Record Id      : ' + rs.Id + '\n' +
            'Channel Partner: ' + (rs.Channel_Partner1__r != null ? rs.Channel_Partner1__r.Name : '-') + '\n' +
            'Reason         : ' + reason + '\n\n' +
            'Please review and take next action.\n\n' +
            '-- Lead Expiry Scheduler';

        mail.setPlainTextBody(body);
        return mail;
    }

    // ------------------------------------------------------------
    //  Direct Sales Head resolution
    //  Looks up the User by Username stored in a Custom Label.
    //  If the label is missing or the user can't be found, returns null.
    // ------------------------------------------------------------
    // Public so Batch_RelatedSourceLeadExpiry can resolve once per run.
    public static Id resolveDirectSalesHeadId() {
        String username;
        try {
            username = System.Label.Direct_Sales_Head_Username;
        } catch (Exception ex) {
            // Label not present - org admin must create it
            return null;
        }
        if (String.isBlank(username)) return null;

        List<User> matches = [
            SELECT Id FROM User
            WHERE (Username = :username OR Alias = :username OR Email = :username)
            AND   IsActive = true
            LIMIT 1
        ];
        return matches.isEmpty() ? null : matches[0].Id;
    }

    // ------------------------------------------------------------
    //  Inner DTO 
    // ------------------------------------------------------------
    @TestVisible
    private class ExpiryResult {
        Related_Source__c record;
        String            reason;
        String            scenarioLabel;
        ExpiryResult(Related_Source__c r, String why, String label) {
            this.record        = r;
            this.reason        = why;
            this.scenarioLabel = label;
        }
    }
}