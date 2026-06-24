public class DemandRaisedHelper {
    public static void updatePaymentScheduleFields(List<Id> demandIds) {
        if (demandIds == null || demandIds.isEmpty()) return;
        
        // Query Demand_Raised__c with related Payment_Schedule__c
        List<Demand_Raised__c> demands = [SELECT Id, Payment_Schedule__c,Booking__c FROM Demand_Raised__c WHERE Id IN :demandIds ];
        
        Set<Id> paymentScheduleIds = new Set<Id>();
        Set<Id> bookingIds = new Set<Id>();
        for (Demand_Raised__c d : demands) {
            if (d.Payment_Schedule__c != null) {
                paymentScheduleIds.add(d.Payment_Schedule__c);
            }
            if(d.Booking__c != null){
                bookingIds.add(d.Booking__c);
            }
        }
        
        if (paymentScheduleIds.isEmpty()) return;
        
        List<Payment_Schedule__c> schedulesToUpdate = [ SELECT Id, Is_Demanded__c, Demanded_Date__c, Payment_Due_Date__c,status__c FROM Payment_Schedule__c WHERE Id IN :paymentScheduleIds];
        
        Date today = Date.today();
        for (Payment_Schedule__c ps : schedulesToUpdate) {
            ps.status__c='Completed';
            ps.Is_Demanded__c = true;
            ps.Demanded_Date__c = today;
            ps.Payment_Due_Date__c = today.addDays(15);
        }
        
        update schedulesToUpdate;
        // For Updating the Current Demanded amount in Booking
         if (bookingIds.isEmpty()) return;
          Map<Id, Decimal> latestDemandAmountMap = new Map<Id, Decimal>();
         for (Demand_Raised__c d : [ SELECT Id, Booking__c, Current_Demand_amount__c, CreatedDate  FROM Demand_Raised__c  WHERE Booking__c IN :bookingIds  ORDER BY CreatedDate DESC  ]) {
            if (!latestDemandAmountMap.containsKey(d.Booking__c)) {
                latestDemandAmountMap.put(d.Booking__c, d.Current_Demand_amount__c);
            }
        }
        List<Booking__c> bookingUpdates = new List<Booking__c>();
        for (Id bId : latestDemandAmountMap.keySet()) {
            Booking__c b = new Booking__c(
                Id = bId,
                Demand_Raised__c = true,
                Demanded_Amount__c = latestDemandAmountMap.get(bId)
            );
            bookingUpdates.add(b);
        }

        if (!bookingUpdates.isEmpty()) {
            update bookingUpdates;}
            }
    
    public static void sendDemandEmailToCustomer(List<Id> demandIds) {
        if (demandIds == null || demandIds.isEmpty()) return;
        
        List<Demand_Raised__c> demands = [  SELECT Id, Name, Demand_Email_Content__c, Booking__r.Email__c,Booking__r.CRM_Head_Manager_Email__c  FROM Demand_Raised__c WHERE Id IN :demandIds];
        
     /*   Set<Id> allContentVersionIds = new Set<Id>();
        for (Demand_Raised__c demand : demands) {
            if (!String.isBlank(demand.Demand_Content_Ids__c)) {
                List<String> ids = demand.Demand_Content_Ids__c.split(',');
                for (String idStr : ids) {
                    allContentVersionIds.add((Id)idStr.trim()); // Trim to avoid whitespace issues
                }
            }
        }*/
        
        // Single query for all content versions
      /*  Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>(
            [SELECT Id, Title, VersionData FROM ContentVersion WHERE Id IN :allContentVersionIds]
        );*/
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<ContentVersion> cvs = new List<ContentVersion>();
        for (Demand_Raised__c demand : demands) {
            if (String.isBlank(demand.Booking__r.Email__c)) continue;
            
            //Boolean isCompletedOC = demand.Payment_schedule__r.Post_OC_Completion__c;
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
            
            // Add customer email if not empty
            if (!String.isBlank(demand.Booking__r.Email__c)) {
                toAddresses.add(demand.Booking__r.Email__c);
            }
            
            // Add manager email if not empty
            if (!String.isBlank(demand.Booking__r.CRM_Head_Manager_Email__c)) {
                toAddresses.add(demand.Booking__r.CRM_Head_Manager_Email__c);
            }
            
            // If both emails are null/empty, add a default email address
            if (toAddresses.isEmpty()) {
                // You can use a custom label, custom setting, or hardcoded value
                String defaultEmail = Test.isRunningTest() 
                    ? 'test@example.com' 
                    : 'support@zuari.com'; // Change to your default email
                
                toAddresses.add(defaultEmail);
                
            }

			email.setToAddresses(toAddresses);
            
            //email.setToAddresses(new String[] { demand.Booking__r.Email__c,demand.Booking__r.CRM_Head_Manager_Email__c });
            email.setSubject('Demand Note Raised - ' + demand.Name);
            email.setHtmlBody(demand.Demand_Email_Content__c);
            
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            
            // VF Page PDF Attachment
            PageReference pdfPage = Page.Demand_Note_Send;
           //// if(isCompletedOC == true){
                
//}else{
            /////   pdfPage  = Page.Demand_Note_send;
//}
           
            pdfPage.getParameters().put('id', demand.Id);
            Blob pdfBlob;
            if (!Test.isRunningTest()) {
                try {
                    pdfBlob = pdfPage.getContent(); 
                } catch (Exception e) {
                    pdfBlob = Blob.valueOf('Test PDF content'); 
                }
            }
            else{
                pdfBlob = Blob.valueOf('Test PDF content'); 
            }
            
            // Blob pdfBlob = pdfPage.getContent();
            
            
            Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
            pdfAttachment.setFileName('Demand_Note.pdf');
            pdfAttachment.setBody(pdfBlob);
            pdfAttachment.setContentType('application/pdf');
            attachments.add(pdfAttachment);
            
            // 1. Save PDF as a File (ContentVersion)
            ContentVersion dcv = new ContentVersion();
            dcv.Title = 'Demand Note-' + demand.Name;
            dcv.PathOnClient = 'Demand Note-' + demand.Name + '.pdf';
            dcv.VersionData = pdfBlob;
            dcv.FirstPublishLocationId = demand.Id; 
            cvs.add(dcv);
            /*
            // Additional content attachments
            if (!String.isBlank(demand.Demand_Content_Ids__c)) {
                List<String> contentIds = demand.Demand_Content_Ids__c.split(',');
                for (String idStr : contentIds) {
                    Id contentId = Id.valueOf(idStr.trim());
                    if (contentVersionMap.containsKey(contentId)) {
                        ContentVersion cv = contentVersionMap.get(contentId);
                        Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
                        file.setFileName(cv.Title);
                        file.setBody(cv.VersionData);
                        attachments.add(file);
                    }
                }
            }*/
            
            email.setFileAttachments(attachments);
            email.setSaveAsActivity(true);
            email.setWhatId(demand.Booking__c);
            emailsToSend.add(email);
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
        if (!cvs.isEmpty()) {
            insert cvs;
        }
    }
    @Future(callout=true)
     public static void sendDemandEmailLogic(List<Id> demandIds) {
        if (demandIds == null || demandIds.isEmpty()) return;

        List<Demand_Raised__c> demands = [
            SELECT Id, Name, Demand_Email_Content__c,
                   Booking__r.Email__c,
                   Booking__r.CRM_Head_Manager_Email__c,
                   Booking__c
            FROM Demand_Raised__c
            WHERE Id IN :demandIds
        ];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<ContentVersion> cvs = new List<ContentVersion>();

        for (Demand_Raised__c demand : demands) {

            if (String.isBlank(demand.Booking__r.Email__c)) continue;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
            
            if (!String.isBlank(demand.Booking__r.Email__c)) {
                toAddresses.add(demand.Booking__r.Email__c);
            }
            
            if (!String.isBlank(demand.Booking__r.CRM_Head_Manager_Email__c)) {
                toAddresses.add(demand.Booking__r.CRM_Head_Manager_Email__c);
            }
            
            if (toAddresses.isEmpty()) {
                String defaultEmail = Test.isRunningTest() ? 'test@example.com' : 'support@zuari.com'; 
                toAddresses.add(defaultEmail);
                System.debug('No email addresses found for demand ' + demand.Name + '. Using default email: ' + defaultEmail);
            }
            
            email.setToAddresses(toAddresses);
            email.setSubject('Demand Note Raised - ' + demand.Name);
            email.setHtmlBody(demand.Demand_Email_Content__c);

            // ===== PDF Generation =====
            PageReference pdfPage = Page.Demand_Note_Send;
            pdfPage.getParameters().put('id', demand.Id);

            Blob pdfBlob;
            try {
                pdfBlob = pdfPage.getContent();
            } catch (Exception e) {
                pdfBlob = Blob.valueOf('PDF generation failed');
            }

            Messaging.EmailFileAttachment pdfAttachment =
                new Messaging.EmailFileAttachment();
            pdfAttachment.setFileName('Demand_Note.pdf');
            pdfAttachment.setBody(pdfBlob);
            pdfAttachment.setContentType('application/pdf');

            email.setFileAttachments(
                new List<Messaging.EmailFileAttachment>{ pdfAttachment }
            );

            email.setSaveAsActivity(true);
            email.setWhatId(demand.Booking__c);
            emailsToSend.add(email);

            // ===== Save PDF as File =====
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Demand Note - ' + demand.Name;
            cv.PathOnClient = 'Demand Note - ' + demand.Name + '.pdf';
            cv.VersionData = pdfBlob;
            cv.FirstPublishLocationId = demand.Id;
            cvs.add(cv);
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
        if (!cvs.isEmpty()) {
            insert cvs;
        }
    }
}