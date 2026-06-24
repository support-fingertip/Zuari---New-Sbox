public class InspectionEsclationBatch implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Today's date
        Date today = Date.today();
        
        // Fetch all Inspection__c records meeting your conditions
        String query = 'SELECT Id, Name, Customer_Email__c ' +
            'FROM Inspection__c ' +
            'WHERE Status__c != \'Completed\' ' +
            'AND Escalation_Date__c = :today ';
        System.debug(query);
        List<Inspection__c> lst = Database.query(query);
        
        System.debug(lst);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Inspection__c> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        User cfo = [Select id,Email from User Where Profile.Name='CFO' AND IsActive = True LIMIT 1];
        
        for (Inspection__c insp : scope) {
            system.debug(insp);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{cfo.Email});
            email.setSubject('Inspection Reminder');
            email.setPlainTextBody(
                'Dear Sir,\n\n' +
                'This is a gentle reminder that inspection '+ insp.Name +'not yet completed by the user.\n' +
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