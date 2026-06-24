public class DocumentandEmailController {
    
    public class BookingDataWrapper {
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public String customerNames;
    }
    
    @AuraEnabled
    public static BookingDataWrapper getBookingDetails(Id recordId) {
        
        Booking__c booking = [SELECT Id,First_Applicant_Name__c,S__c,Agreement_Execution_Date__c, Plot__r.Name,Funding_Type__c,Plot__r.Phase_Detail__c,
                              Agreement_Expected_Date__c,Project1__r.Name,Owner_Phone__c,Agreement_Executed_Date__c,Possession_Date__c,Total_received_Amount__c,Agreement_Execution_Amount1__c
                              /*(SELECT Salutation__c, Name FROM Co_Applicant__r)*/
                              FROM Booking__c WHERE Id = :recordId LIMIT 1];
        
        String customerNames = (String.isEmpty(booking.S__c) ? '' : booking.S__c) + ' ' +
            (String.isEmpty(booking.First_Applicant_Name__c) ? '' : booking.First_Applicant_Name__c);
        
        
        /* 
String customerNames = (String.isEmpty(booking.S__c) ? '' : booking.S__c) + ' ' + 
(String.isEmpty(booking.First_Applicant_Name__c) ? '' : booking.First_Applicant_Name__c);


if (booking.Co_Applicant__r != null && !booking.Co_Applicant__r.isEmpty()) {
for (Co_Applicant__c coApplicant : booking.Co_Applicant__r) {

String salutation = (String.isEmpty(coApplicant.Salutation__c) ? '' : coApplicant.Salutation__c);
String name = (String.isEmpty(coApplicant.Name) ? '' : coApplicant.Name);

customerNames += ' & ' + salutation + ' ' + name;
}
}
*/
        BookingDataWrapper wrapper = new BookingDataWrapper();
        wrapper.booking = booking;
        wrapper.customerNames =  customerNames;
        return wrapper;
    }
    
    @AuraEnabled
    public static String sendEmailGenerateReceipt(Id receiptId) {
        System.debug('Called From Trigger');
        String returnMessage;
        try {
            // Retrieve the Receipt record
            Receipt__c receipt = [SELECT Id, Booking__c, CreatedBy.Email FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
            System.debug(receipt);
            if (receipt == null || receipt.Booking__c == null) {
                return 'Receipt or associated Booking record not found.';
            }
            
            // Retrieve the related Booking record
            Booking__c booking = [SELECT Id, Email__c,First_Applicant_Name__c,Email1__c,Owner.Email
                                  FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
            System.debug(booking);
            
            if (booking != null && !String.isBlank(booking.Email__c)) {
                List<String> lstCCEmail = new List<String>();
                
                // Retrieve co-applicants associated with the Booking
                List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
                
                PageReference receiptPage;
                receiptPage = Page.Receipt;
                // Generate the PDF for the receipt
                receiptPage.getParameters().put('id', receiptId);
                Blob pdfBlob = !Test.isRunningTest() ? receiptPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email__c);
                System.debug(booking.Email__c);
                // Include Co-Applicant emails
                for (Co_Applicant__c ca : coApps) {
                    if (ca.Email__c != null) {
                        sendTo.add(ca.Email__c);
                    }
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (!lstCCEmail.isEmpty()) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Receipt for Your Payment');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached receipt for your payment.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Receipt.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                
                //email.setSaveAsActivity(true);
                //email.setWhatId(receipt.Id);
                
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
     @future(callout = true)
    public static void sendEmailGenerateReceiptfromTrigger(Id receiptId) {
        System.debug('Called From Trigger');
        String returnMessage;
        try {
            // Retrieve the Receipt record
            Receipt__c receipt = [SELECT Id, Booking__c, CreatedBy.Email FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
            System.debug(receipt);
            if (receipt == null || receipt.Booking__c == null) {
               return;
            }
            
            // Retrieve the related Booking record
            Booking__c booking = [SELECT Id, Email__c,First_Applicant_Name__c,Email1__c,Owner.Email
                                  FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
            System.debug(booking);
            
            if (booking != null && !String.isBlank(booking.Email__c)) {
                List<String> lstCCEmail = new List<String>();
                
                // Retrieve co-applicants associated with the Booking
                List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
                
                PageReference receiptPage;
                receiptPage = Page.Receipt;
                // Generate the PDF for the receipt
                receiptPage.getParameters().put('id', receiptId);
                Blob pdfBlob = !Test.isRunningTest() ? receiptPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email__c);
                System.debug(booking.Email__c);
                // Include Co-Applicant emails
                for (Co_Applicant__c ca : coApps) {
                    if (ca.Email__c != null) {
                        sendTo.add(ca.Email__c);
                    }
                }
                
                // Include CC addresses
                lstCCEmail.add(booking.Owner.Email);
                if (!lstCCEmail.isEmpty()) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Receipt for Your Payment');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached receipt for your payment.<br/><br/>Thank you.');
                
                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Receipt.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                
                //email.setSaveAsActivity(true);
                //email.setWhatId(receipt.Id);
                
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

                ContentVersion receiptFile = new ContentVersion();
                receiptFile.Title = 'Receipt';
                receiptFile.PathOnClient = 'Receipt.pdf';
                receiptFile.VersionData = pdfBlob;
                receiptFile.FirstPublishLocationId = receipt.Id;
                insert receiptFile;
                
               // returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        //return returnMessage;
    }
  
    
    @AuraEnabled
    public static String sendEmailGenerateSA(Id recId, String emailContent) {
        system.debug('emailContent: ' + emailContent);
        String returnMessage = 'Unknown error';
        set<string> conDocId = new set<string>();
        list<Messaging.EmailFileAttachment> attachments =  new list<Messaging.EmailFileAttachment>(); 
        try {
            // Retrieve the Booking record
            Booking__c booking = [ SELECT Id, Project__c, Email__c,Plot__c,plot__r.Name,Agreement_Execution_Date__c,Project1__r.Name, First_Applicant_Name__c, CRM_Manager__c, CRM_Manager__r.Email
                                  FROM Booking__c  WHERE Id = :recId   LIMIT 1 ];
            if (booking.Email__c == null) {
                return 'Email address not specified in the Booking record.';
            }
            
            PageReference vfPage = Page.SaleAgreement;
            vfPage.getParameters().put('id', recId);
            
            vfPage.setRedirect(true);
            Blob pdfBlob = Test.isRunningTest() 
                ? Blob.valueOf('testblob') 
                : vfPage.getContentAsPDF();
            
            // Prepare the email
            Set<String> sendTo = new Set<String>();
            sendTo.add(booking.Email__c);
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>(sendTo));
            
            email.setSubject('Sale Agreement for Plot/Unit No. ' + booking.plot__r.Name + ' at Zuari ' + booking.Project1__r.Name);
            email.setHtmlBody(emailContent);
            email.setSaveAsActivity(true);
            email.setWhatId(booking.Id);
            
            //CC to veegaland customercare 
            List<String> lstCCEmail = new List<String>();
            //lstCCEmail.add('');
            
            email.setCcAddresses(lstCCEmail);
            
            // Add PDF as attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Sale Agreement.pdf');
            attachment.setBody(pdfBlob);
            attachment.setContentType('application/pdf');
            attachments.add(attachment);
            
            // Add unt type foorbplan as attachment
            /* if(cdList.size() >0){
for(ContentDocumentLink c : cdList){
conDocId.add(c.ContentDocumentId);
}

list<ContentVersion> cvList = [ SELECT Id, Title, VersionData, FileExtension  FROM ContentVersion   WHERE ContentDocumentId in :conDocId and IsLatest = true ORDER BY CreatedDate DESC ];
system.debug(cvList);
for(ContentVersion cv : cvList){

if(cv.Title.contains('Plumbing Plan') || cv.Title.contains('Electrical Plan') || cv.Title.contains('Parking Plan') ||  cv.Title.contains('Floor Plan') || cv.Title.contains('Selected Parking Slots')){
system.debug(cv);
Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
efa.setFileName(cv.Title + '.' + cv.FileExtension);
efa.setBody(cv.VersionData); // This is the actual file blob
String contentType = 'application/octet-stream';
if(cv.FileExtension != null){
switch on cv.FileExtension.toLowerCase(){
when 'pdf'       { contentType = 'application/pdf'; }
when 'doc'       { contentType = 'application/msword'; }
when 'docx'      { contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'; }
when 'xls'       { contentType = 'application/vnd.ms-excel'; }
when 'xlsx'      { contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'; }
when 'png'       { contentType = 'image/png'; }
when 'jpg','jpeg'{ contentType = 'image/jpeg'; }
when 'txt'       { contentType = 'text/plain'; }
when else        { contentType = 'application/octet-stream'; }
}
}
efa.setContentType(contentType);
attachments.add(efa);
}
}


}*/
            email.setFileAttachments( attachments );
            
            // Send email
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email });
            
            returnMessage = 'Email sent successfully';
            
        } catch (Exception e) {
            system.debug('Error sending email: ' + e.getMessage());
            //ExceptionHandler.addLog(e,emailContent,'GenerateDocumnetController',recId);  /*Add Exception to error log*/
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        
        return returnMessage;
    }
    
    @InvocableMethod
    public static void sendEmailGenerateDemand(List<Id> recIds) {
        try {
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            // Fetch the Demand_Raised__c records for the given recIds
            List<Demand_Raised__c> demandRecords = [
                SELECT Id, Demand_Email_Content__c,CreatedBy.Email, Booking__r.Email__c, Demand_Name__c,Project__c,
                Booking__r.Owner.Email,Booking__r.Total__c, booking__r.CRM_Manager__r.Email,booking__r.Project1__r.Name,booking__r.CRM_Head_Manager_Email__c,
                (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks WHERE LinkedEntityId IN :recIds)
                FROM Demand_Raised__c 
                WHERE Id IN :recIds
            ];
            
            if (demandRecords.isEmpty()) {
                return;
            }
            
            
            for (Demand_Raised__c demand : demandRecords) {
                // Convert comma-separated string of content IDs to Set<Id>
                List<String> contentDocumentIds = new List<String>();
                /*if (!String.isBlank(demand.Demand_Content_Ids__c)) {
contentDocumentIds.addAll(demand.Demand_Content_Ids__c.split(','));
}*/
                
                //Boolean isCompletedOC = demand.Payment_schedule__r.Post_OC_Completion__c;
                List<String> lstCCEmail = new List<String>();
                Booking__c booking = demand.Booking__r;
                
                if (booking != null && !String.isBlank(booking.Email__c)) {
                    // Generate the PDF for the Agreement Amount Request
                    PageReference vfPage = Page.Demand_Note_Send;          
                    vfPage.getParameters().put('id', demand.Id);
                    Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                    
                    // Prepare email details
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    sendTo.add(booking.Email__c);
                    lstCCEmail.add(booking.Owner.Email);
                    if (booking.CRM_Head_Manager_Email__c != null) {
                        lstCCEmail.add(booking.CRM_Head_Manager_Email__c);
                    }
                                        
                    email.setToAddresses(sendTo);
                    email.setSubject('Demand Note for Completion of '+demand.Demand_Name__c +' In '+demand.Booking__r.Project1__r.name);
                    email.setHtmlBody(demand.Demand_Email_Content__c);
                    
                    // Retrieve Content Versions for attachments
                    List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                    if (!contentDocumentIds.isEmpty()) {
                        List<ContentVersion> contentVersions = [
                            SELECT Title, FileExtension, VersionData 
                            FROM ContentVersion 
                            WHERE ContentDocumentId IN :contentDocumentIds
                        ];
                        
                        for (ContentVersion cv : contentVersions) {
                            Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                            contentAttach.setFileName(cv.Title + '.' + cv.FileExtension);
                            contentAttach.setBody(cv.VersionData);
                            emailAttachments.add(contentAttach);
                        }
                    }
                    
                    // Attach the Demand PDF
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName('Demand.pdf');
                    attachment.setBody(pdfBlob);
                    emailAttachments.add(attachment);
                    
                    if (!emailAttachments.isEmpty()) {
                        email.setFileAttachments(emailAttachments);
                    }
                    if(!Test.isRunningTest()){
                        String CreatedEmail = demand.CreatedBy.Email;
                        list<OrgWideEmailAddress> orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :CreatedEmail LIMIT 1];
                        if (orgWideEmail.size() > 0) {
                            email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                        }
                    }
                    email.setSaveAsActivity(true);
                    email.setWhatId(demand.Id);
                    // Send the email
                    emails.add(email);
                } 
                if (!emails.isEmpty()) {
                    Messaging.sendEmail(emails);
                }
            }
        } catch (Exception e) {
            // ExceptionHandler.addLog(e,string.valueof(recIds),'DocumentandEmailController','');  /*Add Exception to error log*/
            System.debug('Exception occurred: ' + e.getMessage());
            throw e;
        }
    }
    
    public static List<String> validateEmails(List<String> emailAddresses) {
        List<String> validEmails = new List<String>();
        for (String email : emailAddresses) {
            if (email != null && Pattern.matches('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$', email)) {
                validEmails.add(email);
            }
        }
        return validEmails;
    }
    @AuraEnabled
    public static Booking__c getBookingRecordViaReciept(Id recordId) {
        Receipt__c receipt = [SELECT Id, Booking__c FROM Receipt__c WHERE id = :recordId LIMIT 1];
        Booking__c booking = [SELECT Id,Project1__r.Name, Total_received_Amount__c,First_Applicant_Name__c
                              FROM Booking__c 
                              WHERE Id = :receipt.Booking__c 
                              LIMIT 1];
        //if (booking.Agreement_Cost__c <= booking.Total_received_Amount__c) {
        //system.debug(booking.Name);
        return booking;
        //} else {
        //return null;
        //}
    }
    
    @AuraEnabled
    public static String sendAgreementRequestMail(Id recId,String emailContent) {
        system.debug('emailContent'+emailContent);
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        String returnMessage;
        try {
            // Retrieve the Booking record
            List<Booking__c> bookings = [SELECT Id, Project__c, Email__c, Applicant_Name__c,Plot__r.Name, Project1__r.Name
                                         FROM Booking__c WHERE Id = :recId LIMIT 1];
            List<String> lstCCEmail = new List<String>();
            
            // Retrieve co-applicants associated with the Booking
            //List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            //List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (!bookings.isEmpty()) {
                Booking__c booking = bookings[0];
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                if (booking.Email__c != null) {
                    sendTo.add(booking.Email__c);
                }
                
                email.setToAddresses(sendTo);
                String emailSubject;
                if (booking.Project1__r != null && booking.Project1__r.Name == 'Zuari Gangothri Tribhuja') {
                    emailSubject = 'Requisition for Flat Registration – Unit No. ' + booking.Plot__r.Name + ' | Zuari Gangothri Tribhuja';
                } else {
                    emailSubject = 'Agreement Execution Confirmation for ' + booking.Plot__r.Name + '-' + booking.Project1__r.Name;
                }
                email.setSubject(emailSubject);
                email.setHtmlBody(emailContent);
                
                //CC to veegaland customercare 
                //List<String> lstCCEmail1 = new List<String>();
                //lstCCEmail.add('customercare@veegaland.in');
                
                //email.setCcAddresses(lstCCEmail1);
                
                
                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                emailsToSend.add(email);
                // Send the email
                
                if (!emailsToSend.isEmpty()) {
                    Messaging.sendEmail(emailsToSend);
                }
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            //ExceptionHandler.addLog(e,emailContent,'GenerateDocumnetController',recId);  /*Add Exception to error log*/
            returnMessage = 'Error sending email: ' + e.getMessage();
            system.debug('returnMessage'+e);
        }
        return returnMessage;
    }
      @AuraEnabled
    public static String sendHandoverEmail(Id bookingId) {

        System.debug('Handover Email Triggered for Booking: ' + bookingId);
        String result;

        try {
            // Fetch Booking + Owner Email
            Booking__c booking = [
                SELECT Id, Email__c, First_Applicant_Name__c, Email1__c,
                       Owner.Email
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            if (booking == null || String.isBlank(booking.Email__c)) {
                return 'Customer Email missing on Booking.';
            }

            // Fetch Co-Applicants
            List<Co_Applicant__c> coApps = [
                SELECT Id, Email__c, Name, Booking__c
                FROM Co_Applicant__c
                WHERE Booking__c = :booking.Id
            ];

            // ===== 1. Generate PDF from VF Page =====
            PageReference pdfPage = Page.Key_Handover_Letter;
            pdfPage.getParameters().put('id', bookingId);

            Blob pdfBlob = !Test.isRunningTest()
                ? pdfPage.getContentAsPDF()
                : Blob.valueOf('testblob');

            // ===== 2. Prepare Email =====
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            // TO Addresses
            List<String> sendTo = new List<String>();
            sendTo.add(booking.Email__c);

            // Co-applicants
            for (Co_Applicant__c ca : coApps) {
                if (!String.isBlank(ca.Email__c)) {
                    sendTo.add(ca.Email__c);
                }
            }

            // CC Addresses
            List<String> ccList = new List<String>();
            if (!String.isBlank(booking.Owner.Email)) {
                ccList.add(booking.Owner.Email);
            }

            email.setToAddresses(sendTo);
            if (!ccList.isEmpty()) {
                email.setCcAddresses(ccList);
            }

            // Fetch project name for dynamic email content
            Booking__c bookingWithProject = [SELECT Project1__r.Name, Project1__r.Project_Address__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            String handoverProjectName = bookingWithProject.Project1__r.Name != null ? bookingWithProject.Project1__r.Name : 'Zuari Project';
            String handoverProjectAddress = bookingWithProject.Project1__r.Project_Address__c != null ? bookingWithProject.Project1__r.Project_Address__c : '';

            email.setSubject('Key Handover Confirmation – ' + handoverProjectName);

            // ===== 3. Email Body (HTML) =====
            String body = ''
            + '<p>Dear ' + booking.First_Applicant_Name__c + ',</p>'
            + '<p>We are delighted to inform you that the keys for your unit at '
            + '<strong>' + handoverProjectName + '</strong>, located at ' + handoverProjectAddress
            + ', have been handed over to you.</p>'

            + '<p>Please find the attached letter for your reference.</p>'

            + '<p>Kindly acknowledge receipt by signing the attached document, confirming that '
            + 'you have inspected all the keys and verified their working condition prior to the handover.</p>'

            + '<p>Thank you for choosing <strong>Zuari Infraworld India Limited</strong>. '
            + 'We look forward to serving you.</p>'

            + '<br/>'
            + '<p>Best regards,<br/>'
            + 'CRM Representative<br/>'
            + 'Zuari Infraworld India Limited</p>';

            email.setHtmlBody(body);

            // ===== 4. Attach PDF =====
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Handover-' + booking.Id + '.pdf');
            attachment.setBody(pdfBlob);
            email.setFileAttachments(
                new Messaging.EmailFileAttachment[] { attachment }
            );

            // ===== 5. Send Email =====
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
		
            result = 'Handover email sent successfully.';
        }
        catch (Exception e) {
            System.debug('Error Sending Handover Email: ' + e.getMessage());
            result = 'Error: ' + e.getMessage();
        }

        return result;
    }
}