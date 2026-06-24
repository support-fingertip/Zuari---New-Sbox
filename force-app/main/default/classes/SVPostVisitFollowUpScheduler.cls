/**
 * Use Case #3: Post Site Visit Follow-up Reminder.
 * Runs daily and alerts the CP Manager when a completed Site Visit has had no
 * Follow_up__c created within 24 hours of its SV_Completed_Date_Time__c.
 *
 * Schedule (one-time, anonymous Apex):
 *   System.schedule('SV Follow-up Reminder Daily', '0 0 10 * * ?', new SVPostVisitFollowUpScheduler());
 */
public without sharing class SVPostVisitFollowUpScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        run();
    }

    @TestVisible
    private static void run() {
        Datetime upper = Datetime.now().addHours(-24);
        Datetime lower = upper.addHours(-1); // 1-hour scan window each day

        List<Site_Visit__c> svs = [
            SELECT Id, Name, Channel_Partner1__c, Related_Source__c, SLead__c, SV_Completed_Date_Time__c
            FROM Site_Visit__c
            WHERE Status__c = 'Completed'
              AND Source_Type__c = 'Channel partner'
              AND SV_Completed_Date_Time__c >= :lower
              AND SV_Completed_Date_Time__c <= :upper
              AND Channel_Partner1__c != NULL
        ];

        if (svs.isEmpty()) return;

        Set<Id> rsIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> cpIds = new Set<Id>();
        for (Site_Visit__c sv : svs) {
            if (sv.Related_Source__c != null) rsIds.add(sv.Related_Source__c);
            if (sv.SLead__c != null) leadIds.add(sv.SLead__c);
            if (String.isNotBlank(sv.Channel_Partner1__c)) {
                try { cpIds.add((Id) sv.Channel_Partner1__c); } catch (Exception e) {}
            }
        }

        // Collect lead/source IDs that already have a follow-up after the SV completion window
        Set<Id> rsWithFollowUp = new Set<Id>();
        Set<Id> leadWithFollowUp = new Set<Id>();
        if (!rsIds.isEmpty() || !leadIds.isEmpty()) {
            for (Follow_up__c fu : [
                SELECT Id, Related_Source__c, SLead__c, CreatedDate
                FROM Follow_up__c
                WHERE CreatedDate >= :lower
                  AND (Related_Source__c IN :rsIds OR SLead__c IN :leadIds)
            ]) {
                if (fu.Related_Source__c != null) rsWithFollowUp.add(fu.Related_Source__c);
                if (fu.SLead__c != null) leadWithFollowUp.add(fu.SLead__c);
            }
        }

        Map<Id, Channel_Partner__c> cpMap = new Map<Id, Channel_Partner__c>();
        if (!cpIds.isEmpty()) {
            cpMap = new Map<Id, Channel_Partner__c>([
                SELECT Id, Source_Manager__c,Sourcing_RM__c FROM Channel_Partner__c WHERE Id IN :cpIds
            ]);
        }

        Id followUpTypeId = SiteVisitTriggerHandler.getCustomNotificationTypeId('SV_Followup_Reminder');

        Set<Id> allRecipients = new Set<Id>();
        Map<Id, Set<Id>> svToRecipients = new Map<Id, Set<Id>>();
        List<Site_Visit__c> svsToNotify = new List<Site_Visit__c>();

        for (Site_Visit__c sv : svs) {
            Boolean hasFollowUp =
                (sv.Related_Source__c != null && rsWithFollowUp.contains(sv.Related_Source__c))
                || (sv.SLead__c != null && leadWithFollowUp.contains(sv.SLead__c));
            if (hasFollowUp) continue;

            Id cpId = null;
            try { cpId = (Id) sv.Channel_Partner1__c; } catch (Exception e) {}
            Channel_Partner__c cp = (cpId != null) ? cpMap.get(cpId) : null;
            if (cp == null || cp.Sourcing_RM__c == null) continue;

            Set<Id> recipients = new Set<Id>{ cp.Sourcing_RM__c };
            svToRecipients.put(sv.Id, recipients);
            svsToNotify.add(sv);
            allRecipients.addAll(recipients);
        }

        if (svsToNotify.isEmpty()) return;

        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Email FROM User WHERE Id IN :allRecipients AND IsActive = true
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Site_Visit__c sv : svsToNotify) {
            Set<Id> recipients = svToRecipients.get(sv.Id);
            SiteVisitTriggerHandler.sendBell(followUpTypeId, sv, recipients, 'FollowUp', sv.Name);
            SiteVisitTriggerHandler.buildEmails(emails, sv, sv.Name, recipients, userMap, 'FollowUp');
        }

        if (!emails.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(emails, false);
        }
    }
}