public without sharing class CustomerQueryTriggerHandler {

    private static final String DEFAULT_COMPANY_NAME = 'Zuari Infraworld India Ltd.';

    public static void afterInsert(List<Customer_Query__c> newList) {
        notifyOwnerOnInsert(newList);
System.debug('inside the class');
        Set<Id> queryIds = new Set<Id>();
        for (Customer_Query__c cq : newList) {
            if (cq.Query_Status__c == 'New' && cq.Customer_Master__c != null) {
                queryIds.add(cq.Id);
            }
        }
        if (queryIds.isEmpty()) {
            return;
        }

        List<Customer_Query__c> queries = [
            SELECT Id, Name, Customer_Master__r.Customer_Name__c, Customer_Master__r.Email__c,
                   Booking__r.Plot__r.Project__r.Name
            FROM Customer_Query__c
            WHERE Id IN :queryIds
        ];
System.debug('inside the class'+ queries);
        Map<String, Id> orgWideMap = getOrgWideEmailMap();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
System.debug(orgWideMap);
        for (Customer_Query__c cq : queries) {
            String customerEmail = cq.Customer_Master__r.Email__c;
            if (String.isBlank(customerEmail)) {
                continue;
            }

            String customerName = String.isNotBlank(cq.Customer_Master__r.Customer_Name__c)
                ? cq.Customer_Master__r.Customer_Name__c : 'Customer';
            String companyName = String.isNotBlank(cq.Booking__r?.Plot__r?.Project__r?.Name)
                ? cq.Booking__r.Plot__r.Project__r.Name : DEFAULT_COMPANY_NAME;
            String queryName = cq.Name;

            String subject = 'Query Received - Thank You for Contacting ' + companyName;
            String body = '<p>Dear ' + customerName + ',</p>'
                + '<p>Thank you for reaching out to ' + companyName + '. We have received your query and our support team is reviewing it. You can expect a response within 7 working days.</p>'
                + '<p>Your query reference number is <strong>' + queryName + '</strong>. Please use this number for any follow-up communication.</p>'
                + '<br/>'
                + '<p>Best regards,<br/>' + companyName + ' Support Team</p>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { customerEmail });
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setSaveAsActivity(false);
            setOrgWideEmail(mail, orgWideMap);
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            System.debug('send mail');
            Messaging.sendEmail(emails);
            System.debug('Emails Sent Successfully: ' + emails.size());
        }
    }

    public static void afterUpdate(List<Customer_Query__c> newList, Map<Id, Customer_Query__c> oldMap) {
        notifyOwnerOnChange(newList, oldMap);

        Set<Id> closedQueryIds = new Set<Id>();
        for (Customer_Query__c cq : newList) {
            Customer_Query__c oldCq = oldMap.get(cq.Id);
            if (cq.Query_Status__c == 'Closed' && oldCq.Query_Status__c != 'Closed' && cq.Customer_Master__c != null) {
                closedQueryIds.add(cq.Id);
            }
        }
        if (closedQueryIds.isEmpty()) {
            return;
        }

        List<Customer_Query__c> queries = [
            SELECT Id, Name, Customer_Master__r.Customer_Name__c, Customer_Master__r.Email__c,
                   Booking__r.Plot__r.Project__r.Name
            FROM Customer_Query__c
            WHERE Id IN :closedQueryIds
        ];

        Map<String, Id> orgWideMap = getOrgWideEmailMap();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Customer_Query__c cq : queries) {
            String customerEmail = cq.Customer_Master__r.Email__c;
            if (String.isBlank(customerEmail)) {
                continue;
            }

            String customerName = String.isNotBlank(cq.Customer_Master__r.Customer_Name__c)
                ? cq.Customer_Master__r.Customer_Name__c : 'Customer';
            String companyName = String.isNotBlank(cq.Booking__r?.Plot__r?.Project__r?.Name)
                ? cq.Booking__r.Plot__r.Project__r.Name : DEFAULT_COMPANY_NAME;
            String queryName = cq.Name;

            String subject = 'Your Query ' + queryName + ' has Been Closed';
            String body = '<p>Dear ' + customerName + ',</p>'
                + '<p>We\'re writing to let you know that your Query <strong>' + queryName + '</strong> has been successfully resolved and closed.</p>'
                + '<p>If you believe your issue has not been fully addressed, do contact our support team within 7 days.</p>'
                + '<p>Thank you for reaching out to ' + companyName + '. We appreciate your time and trust in us.</p>'
                + '<br/>'
                + '<p>Best regards,<br/>' + companyName + ' Support Team</p>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { customerEmail });
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setSaveAsActivity(false);
            setOrgWideEmail(mail, orgWideMap);
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    public static void notifyOwnerOnInsert(List<Customer_Query__c> newList) {
        Set<Id> queryIds = new Set<Id>();
        for (Customer_Query__c cq : newList) {
            if (cq.OwnerId != null && String.valueOf(cq.OwnerId).startsWith('005')) {
                queryIds.add(cq.Id);
            }
        }
        if (!queryIds.isEmpty()) {
            notifyOwners(queryIds, true);
        }
    }

    public static void notifyOwnerOnChange(List<Customer_Query__c> newList, Map<Id, Customer_Query__c> oldMap) {
        Set<Id> queryIds = new Set<Id>();
        for (Customer_Query__c cq : newList) {
            Customer_Query__c oldCq = oldMap.get(cq.Id);
            if (cq.OwnerId != null
                && cq.OwnerId != oldCq.OwnerId
                && String.valueOf(cq.OwnerId).startsWith('005')) {
                queryIds.add(cq.Id);
            }
        }
        if (!queryIds.isEmpty()) {
            notifyOwners(queryIds, false);
        }
    }

    private static void notifyOwners(Set<Id> queryIds, Boolean isNew) {
        List<Customer_Query__c> queries = [
            SELECT Id, Name, Subject__c, Description__c, Priority__c, Query_Status__c,
                   OwnerId, Owner.Email, Owner.Name
            FROM Customer_Query__c
            WHERE Id IN :queryIds
        ];

        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        Map<String, Id> orgWideMap = getOrgWideEmailMap();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Set<String> recipientIds = new Set<String>();
        List<Customer_Query__c> notifiableQueries = new List<Customer_Query__c>();

        for (Customer_Query__c cq : queries) {
            if (!String.valueOf(cq.OwnerId).startsWith('005')) {
                continue;
            }
            recipientIds.add(String.valueOf(cq.OwnerId));
            notifiableQueries.add(cq);

            String ownerEmail = cq.Owner.Email;
            if (String.isBlank(ownerEmail)) {
                continue;
            }

            String ownerName = String.isNotBlank(cq.Owner.Name) ? cq.Owner.Name : 'Team';
            String subjectLine = String.isNotBlank(cq.Subject__c) ? cq.Subject__c : '(no subject)';
            String priority = String.isNotBlank(cq.Priority__c) ? cq.Priority__c : 'Not set';
            String status = String.isNotBlank(cq.Query_Status__c) ? cq.Query_Status__c : 'Not set';
            String descSnippet = String.isBlank(cq.Description__c)
                ? ''
                : (cq.Description__c.length() > 300 ? cq.Description__c.substring(0, 300) + '…' : cq.Description__c);
            String recordLink = orgUrl + '/' + cq.Id;

            String emailSubject = isNew
                ? 'New Customer Query Assigned: ' + cq.Name
                : 'Customer Query Ownership Transferred: ' + cq.Name;

            String heading = isNew
                ? 'A new Customer Query has been assigned to you.'
                : 'Ownership of a Customer Query has been transferred to you.';

            String body = '<p>Hi ' + ownerName + ',</p>'
                + '<p>' + heading + '</p>'
                + '<ul>'
                + '<li><strong>Record:</strong> ' + cq.Name + '</li>'
                + '<li><strong>Subject:</strong> ' + subjectLine + '</li>'
                + '<li><strong>Priority:</strong> ' + priority + '</li>'
                + '<li><strong>Status:</strong> ' + status + '</li>'
                + (String.isBlank(descSnippet) ? '' : '<li><strong>Description:</strong> ' + descSnippet + '</li>')
                + '</ul>'
                + '<p><a href="' + recordLink + '">Open the record</a></p>'
                + '<br/>'
                + '<p>Regards,<br/>' + DEFAULT_COMPANY_NAME + '</p>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { ownerEmail });
            mail.setSubject(emailSubject);
            mail.setHtmlBody(body);
            mail.setSaveAsActivity(false);
            setOrgWideEmail(mail, orgWideMap);
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }

        if (!recipientIds.isEmpty() && !notifiableQueries.isEmpty()) {
            for (Customer_Query__c cq : notifiableQueries) {
                String title = isNew
                    ? 'New Customer Query Assigned: ' + cq.Name
                    : 'Customer Query Ownership Transferred: ' + cq.Name;
                String body = String.isNotBlank(cq.Subject__c) ? cq.Subject__c : cq.Name;
                NotificationController.sendCustomNotification(
                    new Set<String>{ String.valueOf(cq.OwnerId) },
                    title,
                    body,
                    cq.Id,
                    'Customer_Query_Owner_Notification'
                );
            }
        }
    }

    private static Map<String, Id> getOrgWideEmailMap() {
        Map<String, Id> orgWideMap = new Map<String, Id>();
        for (OrgWideEmailAddress ow : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'communication@crm.zuariproperties.com' limit 1]) {
            orgWideMap.put(ow.Address.toLowerCase(), ow.Id);
        }
        return orgWideMap;
    }

    private static void setOrgWideEmail(Messaging.SingleEmailMessage mail, Map<String, Id> orgWideMap) {
        if (!orgWideMap.isEmpty()) {
            mail.setOrgWideEmailAddressId(orgWideMap.values()[0]);
        }
    }
}