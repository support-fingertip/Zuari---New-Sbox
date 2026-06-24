trigger ApexLogTrigger on Apex_Log__c (after insert) {
    
    if(Trigger.IsInsert && Trigger.IsAfter){
        
          List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
  List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE '%communication@crm.zuariproperties.com%' LIMIT 1];
             
        for(Apex_Log__c log : Trigger.New){
            if (!String.isBlank(log.Error_Message__c)) {
                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                if (!oweaList.isEmpty()) {
                   mail.setOrgWideEmailAddressId(oweaList[0].Id);
                }
       
                // To Address
                mail.setToAddresses(new String[] { 'praveen@fingertipplus.com' });
                mail.setSubject('Apex Log - Error');
                 String body = 'Hello Praveen,' +
                              '\n\nAn Apex Log has been generated with an error.' +
                              '\n\nLog Name: ' + log.Name +
                              '\nRequest: ' + log.Request__c +
                              '\nError Message: ' + log.Error_Message__c +
                              '\n\nRegards,' +
                              '\nSalesforce System';
                
                mail.setPlainTextBody(body);
                
                emails.add(mail);
                
               
            }
        }
         if (!emails.isEmpty()) {
          //  Messaging.sendEmail(emails);
        }
    }

}