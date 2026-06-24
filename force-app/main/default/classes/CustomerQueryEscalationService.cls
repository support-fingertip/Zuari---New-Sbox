/**
 * Single source of truth for Customer_Query__c escalation state transitions.
 * Used by CustomerQueryEscalationBatch (auto path) and the escalation panel LWC
 * (manual path from TL / HOD / CFO).
 */
public without sharing class CustomerQueryEscalationService {

    private static final String DEFAULT_COMPANY_NAME = 'Zuari Infraworld India Ltd.';
    private static final Integer EXECUTIVE_SLA_DAYS = 7;
    private static final String LEVEL_EXECUTIVE = 'Executive';

    // ─── Trigger path ────────────────────────────────────────────────────────

    public static void initializeOnInsert(List<Customer_Query__c> newList) {
        Date seedDate = Date.today().addDays(EXECUTIVE_SLA_DAYS);
        for (Customer_Query__c cq : newList) {
            if (String.isBlank(cq.Escalation_Level__c)) {
                cq.Escalation_Level__c = LEVEL_EXECUTIVE;
            }
            if (cq.Next_Escalation_Date__c == null) {
                cq.Next_Escalation_Date__c = seedDate;
            }
        }
    }

    // ─── Batch path (bulk) ───────────────────────────────────────────────────

    public static void escalate(Set<Id> queryIds, String toLevel, String reason) {
        if (queryIds == null || queryIds.isEmpty() || String.isBlank(toLevel)) {
            return;
        }

        Query_Escalation_Config__mdt cfg = getConfig(toLevel);
        if (cfg == null) {
            System.debug(LoggingLevel.WARN, 'No Query_Escalation_Config__mdt for level: ' + toLevel);
            return;
        }

        User recipient = findActiveUserByProfile(cfg.Profile_Name__c);
        if (recipient == null) {
            System.debug(LoggingLevel.WARN, 'No active user on profile: ' + cfg.Profile_Name__c);
            return;
        }

        List<Customer_Query__c> queries = [
            SELECT Id, Name, OwnerId, Subject__c, Description__c, Priority__c,
                   Query_Status__c, CreatedDate, Escalation_Level__c,
                   Next_Escalation_Date__c, Escalation_History__c,
                   Customer_Master__r.Customer_Name__c, Customer_Master__r.Email__c,
                   Booking__r.Plot__r.Project__r.Name
            FROM Customer_Query__c
            WHERE Id IN :queryIds
        ];
        if (queries.isEmpty()) {
            return;
        }

        Datetime now = Datetime.now();
        Date newNextDate = Date.today().addDays(Integer.valueOf(cfg.SLA_Days__c));

        String actorName = UserInfo.getName();
        for (Customer_Query__c cq : queries) {
            cq.OwnerId = recipient.Id;
            cq.Escalation_Level__c = toLevel;
            cq.Last_Escalated_On__c = now;
            cq.Next_Escalation_Date__c = newNextDate;
            cq.Escalation_History__c = appendHistory(
                cq.Escalation_History__c, now, toLevel, actorName, reason
            );
        }

        update queries;

        sendEscalationEmails(queries, recipient, cfg, toLevel);
        sendCustomNotifications(queries, recipient.Id, cfg.Custom_Notification__c, toLevel);
    }

    // ─── Manual path (LWC) ───────────────────────────────────────────────────

    @AuraEnabled
    public static void escalateManual(Id queryId, String toLevel, String reason) {
        if (queryId == null || String.isBlank(toLevel)) {
            throw new AuraHandledException('Missing query or escalation level.');
        }
        try {
            escalate(new Set<Id>{ queryId }, toLevel, String.isBlank(reason) ? 'Manual escalation' : reason);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void reassignManual(Id queryId, Id newOwnerId, String reason) {
        if (queryId == null || newOwnerId == null) {
            throw new AuraHandledException('Missing query or new owner.');
        }
        if (String.isBlank(reason)) {
            throw new AuraHandledException('Reassignment reason is required.');
        }
        try {
            reassign(queryId, newOwnerId, reason);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getCrmExecutives() {
        return [
            SELECT Id, Name
            FROM User
            WHERE IsActive = true
            AND Profile.Name = 'CRM Executive'
            ORDER BY Name
        ];
    }

    public static void reassign(Id queryId, Id newOwnerId, String reason) {
        Customer_Query__c cq = [
            SELECT Id, Name, OwnerId, Escalation_Level__c, Escalation_History__c,
                   Next_Escalation_Date__c
            FROM Customer_Query__c
            WHERE Id = :queryId
            LIMIT 1
        ];

        Datetime now = Datetime.now();
        cq.OwnerId = newOwnerId;
        cq.Escalation_Level__c = LEVEL_EXECUTIVE;
        cq.Reassignment_Reason__c = reason.length() > 255 ? reason.substring(0, 255) : reason;
        cq.Next_Escalation_Date__c = Date.today().addDays(EXECUTIVE_SLA_DAYS);
        cq.Last_Escalated_On__c = now;
        cq.Escalation_History__c = appendHistory(
            cq.Escalation_History__c, now, 'Reassigned → ' + LEVEL_EXECUTIVE, UserInfo.getName(), reason
        );
        update cq;
        // Owner-change email + bell notification to the new owner are handled
        // by the existing CustomerQueryTriggerHandler.afterUpdate path.
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────
@TestVisible
private static Query_Escalation_Config__mdt testConfig;
    
   private static Query_Escalation_Config__mdt getConfig(String level) {


    if(Test.isRunningTest() && testConfig != null){
        return testConfig;
    }

    List<Query_Escalation_Config__mdt> rows = [
        SELECT DeveloperName,
               Level__c,
               Profile_Name__c,
               SLA_Days__c,
               Custom_Notification__c
        FROM Query_Escalation_Config__mdt
        WHERE Level__c = :level
        LIMIT 1
    ];

    return rows.isEmpty() ? null : rows[0];
}
    @TestVisible
private static User findActiveUserByProfile(String profileName) {
        List<User> users = [
            SELECT Id, Name, Email
            FROM User
            WHERE Profile.Name = :profileName
              AND IsActive = true
            ORDER BY LastLoginDate DESC NULLS LAST, Id ASC
            LIMIT 1
        ];
        return users.isEmpty() ? null : users[0];
    }
@TestVisible
private static String appendHistory(String existing, Datetime ts, String level, String actor, String reason) {
        String entry = ts.format('yyyy-MM-dd HH:mm') + ' | → ' + level
            + ' | ' + (String.isBlank(actor) ? 'System' : actor)
            + ' | ' + (String.isBlank(reason) ? '-' : reason);
        if (String.isBlank(existing)) {
            return entry;
        }
        String combined = existing + '\n' + entry;
        return combined.length() > 32000 ? combined.substring(combined.length() - 32000) : combined;
    }
    
    public static void sendEscalationEmails(
        List<Customer_Query__c> queries, User recipient,
        Query_Escalation_Config__mdt cfg, String level
    ) {
        if (String.isBlank(recipient.Email)) {
            return;
        }
        Map<String, Id> orgWideMap = getOrgWideEmailMap();
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Customer_Query__c cq : queries) {
            String companyName = cq.Booking__r != null && cq.Booking__r.Plot__r != null
                && cq.Booking__r.Plot__r.Project__r != null
                && String.isNotBlank(cq.Booking__r.Plot__r.Project__r.Name)
                ? cq.Booking__r.Plot__r.Project__r.Name : DEFAULT_COMPANY_NAME;

            String subjectLine = String.isNotBlank(cq.Subject__c) ? cq.Subject__c : '(no subject)';
            String priority = String.isNotBlank(cq.Priority__c) ? cq.Priority__c : 'Not set';
            String status = String.isNotBlank(cq.Query_Status__c) ? cq.Query_Status__c : 'Not set';
            String recordLink = orgUrl + '/' + cq.Id;

            String body = '<p>Hi ' + recipient.Name + ',</p>'
                + '<p>Customer Query <strong>' + cq.Name + '</strong> has been escalated to <strong>' + level + '</strong>.</p>'
                + '<ul>'
                + '<li><strong>Subject:</strong> ' + subjectLine + '</li>'
                + '<li><strong>Priority:</strong> ' + priority + '</li>'
                + '<li><strong>Status:</strong> ' + status + '</li>'
                + '<li><strong>Raised On:</strong> ' + cq.CreatedDate.format() + '</li>'
                + '</ul>'
                + '<p><a href="' + recordLink + '">Open the record</a></p>'
                + '<br/>'
                + '<p>Regards,<br/>' + companyName + '</p>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { recipient.Email });
            mail.setSubject('Customer Query Escalated to ' + level + ': ' + cq.Name);
            mail.setHtmlBody(body);
            mail.setSaveAsActivity(false);
            if (!orgWideMap.isEmpty()) {
                mail.setOrgWideEmailAddressId(orgWideMap.values()[0]);
            }
            emails.add(mail);
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    public static void sendCustomNotifications(
        List<Customer_Query__c> queries, Id recipientUserId,
        String notificationDeveloperName, String level
    ) {
        if (String.isBlank(notificationDeveloperName)) {
            return;
        }
        Set<String> recipients = new Set<String>{ String.valueOf(recipientUserId) };
        for (Customer_Query__c cq : queries) {
            NotificationController.sendCustomNotification(
                recipients,
                'Customer Query Escalated to ' + level + ': ' + cq.Name,
                String.isNotBlank(cq.Subject__c) ? cq.Subject__c : cq.Name,
                cq.Id,
                notificationDeveloperName
            );
        }
    }

    public static Map<String, Id> getOrgWideEmailMap() {
        Map<String, Id> orgWideMap = new Map<String, Id>();
        for (OrgWideEmailAddress ow : [SELECT Id, Address FROM OrgWideEmailAddress]) {
            orgWideMap.put(ow.Address.toLowerCase(), ow.Id);
        }
        return orgWideMap;
    }
}