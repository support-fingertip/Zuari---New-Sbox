public class InspectionReminderBatch implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Today's date
        Date today = Date.today();
        
        // Fetch all Inspection__c records meeting your conditions
        String query = 'SELECT Id, Name, Customer_Email__c ' +
            'FROM Inspection__c ' +
            'WHERE Status__c != \'Completed\' ' +
            'AND (Expected_Completed_Date__c = :today ' +
            '  OR Extended_Completed_Date__c = :today)' +
            'AND Customer_Email__c != null';
        System.debug(query);
        List<Inspection__c> lst = Database.query(query);
        
        System.debug(lst);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Inspection__c> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        System.debug(scope);
        for (Inspection__c insp : scope) {
            system.debug(insp);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
            
            if (!String.isBlank(insp.Customer_Email__c)) {
                toAddresses.add(insp.Customer_Email__c);
            }
          
            if (toAddresses.isEmpty()) {
                String defaultEmail = Test.isRunningTest() ? 'test@example.com' : 'support@zuari.com'; 
                toAddresses.add(defaultEmail);
                System.debug('No email addresses found for demand ' + insp.Name + '. Using default email: ' + defaultEmail);
            }
            
            email.setToAddresses(toAddresses);
            email.setSubject('Inspection Reminder');
            email.setPlainTextBody(
                'Dear Customer,\n\n' +
                'This is a gentle reminder that your inspection for the property is scheduled for completion today.\n' +
                'Inspection Name: ' + insp.Name + '\n\n' +
                'Thank you.'
            );
            
            emails.add(email);
        }
        
        if (!emails.isEmpty()) {
            
            Messaging.SendEmailResult[] results= Messaging.sendEmail(emails);
            System.debug(results);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // Optional: send summary email or log
    }
}