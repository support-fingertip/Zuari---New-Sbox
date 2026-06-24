/**
 * Nightly batch that drives the Customer_Query__c escalation matrix:
 *   Day 0-7  : Executive
 *   Day 7+   : auto-escalate to TL
 *   Day 14+  : auto-escalate to CFO (skipping HOD if not manually escalated)
 *   Day 21+  : auto-escalate to CEO
 *   Day 60+  : auto-close
 *
 * Picks up any record whose Next_Escalation_Date__c is <= today and has not
 * been closed. All state mutations are delegated to CustomerQueryEscalationService.
 */
public class CustomerQueryEscalationBatch implements Database.Batchable<sObject> {

    private static final String DEFAULT_COMPANY_NAME = 'Zuari Infraworld India Ltd.';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();
        return Database.getQueryLocator([
            SELECT Id, Name, CreatedDate, OwnerId, Query_Status__c,
                   Escalation_Level__c, Next_Escalation_Date__c,
                   Escalation_History__c
            FROM Customer_Query__c
            WHERE Query_Status__c != 'Closed'
              AND Next_Escalation_Date__c != null
              AND Next_Escalation_Date__c <= :today
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Customer_Query__c> scope) {
        Date today = Date.today();
        Map<String, Set<Id>> moves = new Map<String, Set<Id>>();
        Set<Id> toClose = new Set<Id>();

        for (Customer_Query__c cq : scope) {
            Integer ageDays = cq.CreatedDate.date().daysBetween(today);

            if (ageDays >= 60) {
                toClose.add(cq.Id);
                continue;
            }

            String nextLevel = resolveNextLevel(cq.Escalation_Level__c, ageDays);
            if (nextLevel == null) {
                continue;
            }
            if (!moves.containsKey(nextLevel)) {
                moves.put(nextLevel, new Set<Id>());
            }
            moves.get(nextLevel).add(cq.Id);
        }

        for (String level : moves.keySet()) {
            CustomerQueryEscalationService.escalate(
                moves.get(level), level, 'Auto-escalated by scheduler'
            );
        }
        if (!toClose.isEmpty()) {
            autoClose(toClose);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('CustomerQueryEscalationBatch completed');
    }

    /**
     * Level resolver. Age thresholds (days from CreatedDate) take precedence.
     * For records still at Executive but whose age is 14+ we skip TL and jump
     * straight to CFO, matching BRD requirement (iv).
     */
    @TestVisible
    private static String resolveNextLevel(String current, Integer ageDays) {
        if (ageDays >= 21 && current != 'CEO') return 'CEO';
        if (ageDays >= 14 && current != 'CFO' && current != 'CEO') return 'CFO';
        if (ageDays >= 7  && current == 'Executive') return 'TL';
        if (current == 'TL')  return 'HOD';
        if (current == 'HOD') return 'CFO';
        return null;
    }

    private void autoClose(Set<Id> queryIds) {
        List<Customer_Query__c> queries = [
            SELECT Id, Name, OwnerId, Query_Status__c, Escalation_History__c,
                   Customer_Master__r.Customer_Name__c, Customer_Master__r.Email__c,
                   Booking__r.Plot__r.Project__r.Name,
                   Booking__r.CRM_Head__r.Phone
            FROM Customer_Query__c
            WHERE Id IN :queryIds
        ];

        Datetime now = Datetime.now();
        String actor = UserInfo.getName();
        for (Customer_Query__c cq : queries) {
            cq.Query_Status__c = 'Closed';
            cq.Auto_Closed__c = true;
            cq.Next_Escalation_Date__c = null;
            cq.Escalation_History__c = appendHistory(
                cq.Escalation_History__c, now, '→ Auto-Closed (60 days)', actor, null
            );
        }
        update queries;

        sendCustomerLapseEmails(queries);
    }

    private static String appendHistory(String existing, Datetime ts, String level, String actor, String reason) {
        String entry = ts.format('yyyy-MM-dd HH:mm') + ' | ' + level
            + ' | ' + (String.isBlank(actor) ? 'System' : actor)
            + ' | ' + (String.isBlank(reason) ? '-' : reason);
        if (String.isBlank(existing)) {
            return entry;
        }
        String combined = existing + '\n' + entry;
        return combined.length() > 32000 ? combined.substring(combined.length() - 32000) : combined;
    }

    private void sendCustomerLapseEmails(List<Customer_Query__c> queries) {
        Map<String, Id> orgWideMap = new Map<String, Id>();
        for (OrgWideEmailAddress ow : [SELECT Id, Address FROM OrgWideEmailAddress]) {
            orgWideMap.put(ow.Address.toLowerCase(), ow.Id);
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Customer_Query__c cq : queries) {
            if (cq.Customer_Master__c == null || String.isBlank(cq.Customer_Master__r.Email__c)) {
                continue;
            }
            String customerEmail = cq.Customer_Master__r.Email__c;
            String customerName = String.isNotBlank(cq.Customer_Master__r.Customer_Name__c)
                ? cq.Customer_Master__r.Customer_Name__c : 'Customer';
            String companyName = cq.Booking__r != null && cq.Booking__r.Plot__r != null
                && cq.Booking__r.Plot__r.Project__r != null
                && String.isNotBlank(cq.Booking__r.Plot__r.Project__r.Name)
                ? cq.Booking__r.Plot__r.Project__r.Name : DEFAULT_COMPANY_NAME;
            String crmHodPhone = cq.Booking__r != null && cq.Booking__r.CRM_Head__r != null
                && String.isNotBlank(cq.Booking__r.CRM_Head__r.Phone)
                ? cq.Booking__r.CRM_Head__r.Phone : 'our support team';

            String subject = 'Update on Your Open Ticket ' + cq.Name + ' - Query Time Lapse';
            String body = '<p>Dear ' + customerName + ',</p>'
                + '<p>We wanted to inform you that your support ticket <strong>' + cq.Name + '</strong> has exceeded maximum ticket time of 60 days and has been automatically closed. If the issue is still unresolved, please reach out and we will reopen and prioritise it.</p>'
                + '<p>If you wish to call us please contact <strong>' + crmHodPhone + '</strong>.</p>'
                + '<br/>'
                + '<p>Best regards,<br/>' + companyName + '</p>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { customerEmail });
            mail.setSubject(subject);
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
}