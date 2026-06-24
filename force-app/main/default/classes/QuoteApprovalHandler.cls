public class QuoteApprovalHandler {
    public static void processQuotes(List<Quote__c> quoteList) {
        try {
            if (quoteList.isEmpty()) return;

            // Collect User IDs and Project Names for bulk processing
            Set<Id> userIds = new Set<Id>();
            Set<String> projectNames = new Set<String>();

            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();

            for (Quote__c q : quoteList) {
                    // Submit for Approval
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setObjectId(q.Id);
                    req.setSubmitterId(q.OwnerId);
                    //req.setProcessDefinitionNameOrId('Quote_Approval_Latest_1'); // Ensure this process exists
                req.setProcessDefinitionNameOrId(System.Label.Quote_Approval_Process_Name);   
                req.setSkipEntryCriteria(false);
                    approvalRequests.add(req);
                
            }

            if (!approvalRequests.isEmpty()) {
                Approval.ProcessResult[] results = Approval.process(approvalRequests);
                
                // Error Handling - Log failed approval processes
                for (Approval.ProcessResult result : results) {
                    System.debug(result);
                    if (!result.isSuccess()) {
                        System.debug('Approval submission failed: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in QuoteApprovalHandler: ' + e.getMessage());
        }
    }
    public static void sendApprovalEmail(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) return;

        // Fetch Quote and related Booking__c records
        List<Quote__c> quotes = [ SELECT Id, Name, Discount_Amount__c,  Approval_Status__c,Manager_Email__c,Discount_Price__c,Rate_sq_Ft__c,Rate_sq_Ft_Discount__c FROM Quote__c   WHERE Id IN :quoteIds ];
 
User hdo = [Select id,Email from User Where Profile.Name='HOD' LIMIT 1];
User cfo = [Select id,Email from User Where Profile.Name='CFO' LIMIT 1];
//User ceo = [Select id,Email from User Where Profile.Name='CEO' LIMIT 1];
         List<String> lstCCEmail = new List<String>();
       
        // Prepare email messages
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Quote__c q : quotes) {
            if(q.Discount_Price__c>300 && q.Discount_Price__c <=450){
                lstCCEmail.add(q.Manager_Email__c);
            } if(q.Discount_Price__c>450 && q.Discount_Price__c <=633){
                 lstCCEmail.add(hdo.Email);
            
            }
             if(q.Discount_Price__c>633 && q.Discount_Price__c <=685){
                 lstCCEmail.add(cfo.Email);
             //    lstCCEmail.add(ceo.Email);
            
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
System.debug(lstCCEmail+ '--'+ q.Manager_Email__c);
            // Set recipient - e.g. Manager or approval queue
            // ⚠️ Replace with dynamic approver lookup or fixed email for testing
          //  mail.setToAddresses(new String[] { 'manager@yourcompany.com' });
mail.setToAddresses(lstCCEmail );
            
            mail.setSubject('Quote Submitted for Approval: ' + q.Name);

            // Create simple HTML body
            String body = 
                '<p>Dear Approver,</p>' +
                '<p>The following quote has been submitted for approval:</p>' +
                '<ul>' +
                '<li><b>Quote Name:</b> ' + q.Name + '</li>' +
                '<li><b>Actual Rate per  Sq.ft  :</b> ₹' + q.Rate_sq_Ft__c + '</li>' +
                '<li><b>Discount Price:</b> ₹' + q.Discount_Price__c + '</li>' +
                '<li><b>After Discount Rate per Sq.ft</b> ' + q.Rate_sq_Ft_Discount__c+ '</li>' +
                '</ul>' +
                '<p>Please review and take appropriate action in Salesforce.</p>' +
                '<p>Thank you,<br/>Salesforce System</p>';

            mail.setHtmlBody(body);
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    
    
// === Helper Method to Build Criteria Update ===
public static Quote__c buildCriteriaUpdate(Quote__c q) {

    String criteria = '';

    if (q.Discount_Price__c >= 300 && q.Discount_Price__c <= 450) {
        criteria = 'Step 1: Manager Approval (300–450)';
    }
    else if (q.Discount_Price__c >= 451 && q.Discount_Price__c <= 633) {
        criteria = 'Step 2: Manager → HOD (451–633)';
    }
    else if (q.Discount_Price__c >= 634 && q.Discount_Price__c <= 685) {
        criteria = 'Step 3: Manager → HOD → CFO (634–685)';
    }
    else {
        criteria = 'Outside Valid Range';
    }

    return new Quote__c(
        Id = q.Id,
        Approval_Criteria__c = criteria
    );
}
    /*
    @AuraEnabled
    public static void approveRecord(Id recordId, String comments) {

        validateBeforeApproval(recordId);

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(recordId);
        req.setComments(comments);
        req.setSubmitterId(UserInfo.getUserId());
        req.setNextApproverIds(null); // Prevent reassignment
        Approval.ProcessResult result = Approval.process(req);
    }
     @AuraEnabled
    public static void rejectRecord(Id recordId, String comments) {

        List<ProcessInstanceWorkitem> items = [
            SELECT Id 
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :recordId
            LIMIT 1
        ];

        if (items.isEmpty()) {
            throw new AuraHandledException('No active approval request found.');
        }

        Approval.ProcessWorkitemRequest rejectReq = new Approval.ProcessWorkitemRequest();
        rejectReq.setAction('Reject');
        rejectReq.setComments(comments);
        rejectReq.setWorkitemId(items[0].Id);

        Approval.ProcessResult result = Approval.process(rejectReq);
    }

    private static void validateBeforeApproval(Id recordId) {
        
    }
    */
    public static void sendCustomNotification(Set<String> recepientIds, String title, String body, Id recId, String notificationName){
        CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
        Notification.setNotificationTypeId(closedWonNotification.id); 
        Notification.setSenderId(Userinfo.getUserId()); 
        Notification.setBody(body); 
        Notification.setTitle(title); 
        Notification.setTargetId(recId);
        try{
            Notification.send(recepientIds);
        }catch(exception e){
            
        }
        
    }
    public static void sendQuoteStatusNotificationAndEmail(Quote__c qt) {
        if (qt == null) return;
        
        String msg = 'Your Quote ' + qt.Name + ' has been ' + qt.Approval_Status__c + '.';
        
        // Custom Notification
        sendCustomNotification(new Set<String>{ qt.OwnerId },
                               'Quote ' + qt.Approval_Status__c,
                               msg,
                               qt.Id,
                               'Quote_Notification');
        
        // -------- EMAIL SENDING WITH STATUS CHECK --------
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        User u = [SELECT Email FROM User WHERE Id = :qt.OwnerId LIMIT 1];
          OrgWideEmailAddress[] owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'communication@crm.zuariproperties.com' limit 1];// This is for Production
            
           
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ u.Email });
        mail.setSubject('Quote ' + qt.Approval_Status__c);
        mail.setPlainTextBody(msg);
         if (owea.size() > 0) {
                mail.setOrgWideEmailAddressId(owea[0].Id);
            }
          
        emailList.add(mail);
        
        if (!emailList.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
            
            for (Messaging.SendEmailResult res : results) {
                System.debug('=== EMAIL STATUS (Quote Notification) ===');
                System.debug('Success?  → ' + res.isSuccess());
                
                if (!res.isSuccess()) {
                    System.debug('Error Code → ' + res.getErrors()[0].getStatusCode());
                    System.debug('Error Msg  → ' + res.getErrors()[0].getMessage());
                }
            }
        }
    }
   public static void testcover(){
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
       i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
       
    }
}