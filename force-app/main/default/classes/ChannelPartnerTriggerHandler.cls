public without sharing class ChannelPartnerTriggerHandler {

    private static final Id APPROVAL_SUBMITTER_ID = Id.valueOf(System.Label.CP_Approval_Submitter_User_Id);
    private static final String APPROVAL_PROCESS_NAME = System.Label.CP_Approval_Process_Name;
    private static final String NOTIFICATION_TYPE_NAME = System.Label.CP_Approval_Notification_Type;

    public static void onAfterInsert(List<Channel_Partner__c> newList) {
        Set<Id> submittedIds = submitForApproval(newList);
        if (!submittedIds.isEmpty()) {
            notifyActualApprovers(submittedIds);
        }
       CPEmailNotificationService.sendDocumentsPending(newList);
    }

    public static void onAfterUpdate(List<Channel_Partner__c> newList,
                                     Map<Id, Channel_Partner__c> oldMap) {
        CPEmailNotificationService.sendDocumentsSubmitted(newList, oldMap);
        CPEmailNotificationService.sendTrainingScheduled(newList, oldMap);
        CPEmailNotificationService.sendTrainingCompleted(newList, oldMap);
        CPEmailNotificationService.sendActivationCompleted(newList, oldMap);
    }


    private static Set<Id> submitForApproval(List<Channel_Partner__c> newList) {
        Set<Id> submittedIds = new Set<Id>();
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();

        for (Channel_Partner__c cp : newList) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(cp.Id);
            req.setSubmitterId(APPROVAL_SUBMITTER_ID);
            req.setComments('Auto-submitted via CP Registration Form.');
            req.setProcessDefinitionNameOrId(APPROVAL_PROCESS_NAME);
            requests.add(req);
        }

        if (requests.isEmpty()) return submittedIds;

        try {
            List<Approval.ProcessResult> results = Approval.process(requests, false);
            for (Integer i = 0; i < results.size(); i++) {
                Approval.ProcessResult r = results[i];
                if (r.isSuccess()) {
                    submittedIds.add(newList[i].Id);
                } else {
                    System.debug(LoggingLevel.ERROR, 'CP approval submission failed for ' + newList[i].Id + ': ' + r.getErrors());
                }
            }
        } catch (Exception e) {
            // Never break the insert when the approval process is misconfigured.
            System.debug(LoggingLevel.ERROR, 'CP approval submission threw: ' + e.getMessage());
        }
        return submittedIds;
    }

    private static void notifyActualApprovers(Set<Id> targetIds) {
        Map<Id, Set<String>> targetToRecipients = new Map<Id, Set<String>>();
        for (ProcessInstanceWorkitem wi : [
            SELECT Id, ActorId, ProcessInstance.TargetObjectId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId IN :targetIds
        ]) {
            Id target = (Id) wi.ProcessInstance.TargetObjectId;
            if (!targetToRecipients.containsKey(target)) {
                targetToRecipients.put(target, new Set<String>());
            }
            if (wi.ActorId != null) {
                targetToRecipients.get(target).add(String.valueOf(wi.ActorId));
            }
        }
        if (targetToRecipients.isEmpty()) return;

        Map<Id, Channel_Partner__c> nameById = new Map<Id, Channel_Partner__c>(
            [SELECT Id, Name FROM Channel_Partner__c WHERE Id IN :targetToRecipients.keySet()]
        );

        for (Id target : targetToRecipients.keySet()) {
            Set<String> recipientIds = targetToRecipients.get(target);
            if (recipientIds.isEmpty()) continue;

            Channel_Partner__c cp = nameById.get(target);
            String cpName = cp != null && cp.Name != null ? cp.Name : 'A Channel Partner';
            String title = 'Channel Partner pending approval';
            String body = cpName + ' has been submitted for your approval.';

            try {
                RelatedSourceHandler.sendCustomNotification(recipientIds, title, body, target, NOTIFICATION_TYPE_NAME );
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'CP approver bell notification failed for ' + target + ': ' + e.getMessage());
            }
        }
    }

     public static void onApprovalSetPasswordAndNotify(
        List<Channel_Partner__c> newList,
        Map<Id, Channel_Partner__c> oldMap
    ) {
        List<Channel_Partner__c> toUpdate = new List<Channel_Partner__c>();
        Map<Id, String> cpIdToPassword = new Map<Id, String>();

        for (Channel_Partner__c cp : newList) {
            Channel_Partner__c oldCp = oldMap.get(cp.Id);
            if (cp.Approval_Status__c == 'Approved' && cp.Active__c  && (cp.Approval_Status__c != oldCp.Approval_Status__c || cp.Active__c != oldCp.Active__c) ) {
               // String password = SimplePasswordGenerator.generatePassword();
                String password = 'Welcome@123';
                
                cpIdToPassword.put(cp.Id, password);
                toUpdate.add(new Channel_Partner__c(Id = cp.Id, Password__c = password));
            }
        }

        if (toUpdate.isEmpty()) return;

        update toUpdate;

        List<Channel_Partner__c> approvedCPs = [
            SELECT Id, Name, Email__c, Mobile_Number__c
            FROM Channel_Partner__c
            WHERE Id IN :cpIdToPassword.keySet()
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE '%communication@crm.zuariproperties.com%' LIMIT 1];
      //  List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address ='pattusudaru@gmail.com' LIMIT 1];
        
          
        
        Id oweaId = oweaList.isEmpty() ? null : oweaList[0].Id;

        for (Channel_Partner__c cp : approvedCPs) {
            if (String.isBlank(cp.Email__c)) continue;

            String password = cpIdToPassword.get(cp.Id);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ cp.Email__c });
            mail.setSubject('Your Channel Partner Account Has Been Approved');

         /*   String body = 'Dear ' + cp.Name + ',\n\n';
            body += 'Congratulations! Your Channel Partner account has been approved.\n\n';
            body += 'Your login credentials are as below:\n';
            body += 'Mobile Number: ' + cp.Mobile_Number__c + '\n';
            body += 'Password: ' + password + '\n\n';
            body += 'Please login and change your password at first login.\n\n';
            body += 'Regards,\nSupport Team';

            mail.setPlainTextBody(body);*/
            String htmlBody = ''
+ 'Dear ' + cp.Name + ',<br/><br/>'
+ 'Congratulations! Your Channel Partner account has been approved.<br/><br/>'

+ '<b>Your login credentials are as below:</b><br/>'
+ 'Mobile Number: ' + cp.Mobile_Number__c + '<br/>'
+ 'Password: ' + password + '<br/><br/>'

+ '<b>Install the Zuari Connect App:</b><br/><br/>'

+ '<a href="https://apps.apple.com/in/app/zuari-connect/id6761705226">'
+ 'Download for iOS</a><br/><br/>'

+ '<a href="https://play.google.com/store/apps/details?id=com.zuariconnect.app">'
+ 'Download for Android</a><br/><br/>'

+ 'Please login and change your password at first login.<br/><br/>'

+ 'Regards,<br/>'
+ 'Support Team';

mail.setHtmlBody(htmlBody);
            
            if (oweaId != null) {
                mail.setOrgWideEmailAddressId(oweaId);
            }
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
          List<Messaging.SendEmailResult> results=  Messaging.sendEmail(emails);
            System.debug(results[0]);
        }
    }
}