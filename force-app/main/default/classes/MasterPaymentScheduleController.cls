public class MasterPaymentScheduleController {
    @AuraEnabled
    public static void CompletetionOfMPS(List<Id> mpsIds) {
        if(mpsIds.isEmpty()) return;

        List<Master_Payment_Schedule__c> milestones = [
            SELECT Id, Name, Completed_Date__c, S_No__c, Payment_Percent__c, Project__c, Project__r.Name
            FROM Master_Payment_Schedule__c
            WHERE Id IN :mpsIds
        ];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for(Master_Payment_Schedule__c milestone : milestones){
            // Collect recipient emails
            set<String> recipients = new set<String>();
            /*if(milestone.Project__r.CRM_Executive__r.Email != null) 
                recipients.add(milestone.Project__r.CRM_Executive__r.Email);
            if(milestone.Project__r.CRM_Team_Lead__r.Email != null)
                recipients.add(milestone.Project__r.CRM_Team_Lead__r.Email);*/
            recipients.add('SampleCRMTeamLead@sample.com');
            recipients.add('SampleCRMExcecutive@sample.com');

            if(recipients.isEmpty()) continue;

            // Build email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>(recipients));
            email.setSubject('Milestone Completed: ' + milestone.Name + ' for Project ' + milestone.Project__r.Name);
            
            String body = 'Dear Team,\n\n' +
                'We are pleased to inform you that the milestone "' + milestone.Name + '" (Milestone No. ' + milestone.S_No__c + 
                ') for the project "' + milestone.Project__r.Name + '" has been completed successfully on ' + 
                (milestone.Completed_Date__c != null ? milestone.Completed_Date__c.format() : 'Not Provided') + 
                '. The payment associated with this milestone is ' + milestone.Payment_Percent__c + '%.\n\n' +
                'Kindly update your records accordingly and proceed with any follow-up actions required.\n\n' +
                'Best regards,\n' +
                'Zuari Infraworld India Ltd.';

            email.setPlainTextBody(body);

            emailsToSend.add(email);
        }

        // Send all emails
        if(!emailsToSend.isEmpty()){
            Messaging.sendEmail(emailsToSend);
        }
    }
}