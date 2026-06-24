public without sharing class RaiseDemandEmailController {
    
    @AuraEnabled
    public static Boolean checkDemandedRaised(Id bookingId) {
        try {
            if(bookingId == null) {
                throw new AuraHandledException('Booking ID is required');
            }
            
            // Query the latest completed Payment_Schedule__c record based on S_No__c
            List<Payment_Schedule__c> schedules = [
                SELECT Id, Is_Demanded__c
                FROM Payment_Schedule__c
                WHERE Booking__c = :bookingId AND Status__c = 'Completed'
                ORDER BY S_No__c DESC
                LIMIT 1
            ];
            
            // Check if the Is_Demanded__c flag is true for the last completed payment schedule
            if (!schedules.isEmpty() && schedules[0].Is_Demanded__c) {
                return false;
            } else {
                return true;
            }
        } catch (Exception e) {
            System.debug('Error in checkDemandedRaised: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error checking demand status: ' + e.getMessage());
        }
    } 
    
    @AuraEnabled
    public static String sendEmailWithAttachment(Id recId, String typeOfDemand) {
        System.debug('=== Starting sendEmailWithAttachment ===');
        System.debug('recId: ' + recId);
        System.debug('typeOfDemand: ' + typeOfDemand);
        
        String returnmessage;
        Booking__c booking;
        
        try {
            // Validate inputs
            if(recId == null) {
                throw new AuraHandledException('Record ID is required');
            }
            
            if(String.isBlank(typeOfDemand)) {
                throw new AuraHandledException('Type of Demand is required');
            }
            
            // Query booking record
            System.debug('Querying booking record...');
            if(typeOfDemand == 'Flat'){
                List<Booking__c> bookings = [
                    SELECT Id, Email__c, Email1__c, Funding_Type__c, Bank_Email__c, 
                           First_Applicant_Name__c, Demand_Raised__c, Owner.Email, 
                           CRM_Manager__c, CRM_Manager__r.Email 
                    FROM Booking__c 
                    WHERE Id = :recId 
                    LIMIT 1
                ];
                
                if(bookings.isEmpty()) {
                    throw new AuraHandledException('Booking record not found');
                }
                booking = bookings[0];
            }
            else if(typeOfDemand == 'AD'){
                List<Additional_Charges__c> adcs = [
                    SELECT Id, Booking__c 
                    FROM Additional_Charges__c 
                    WHERE Id = :recId
                    LIMIT 1
                ];
                
                if(adcs.isEmpty()) {
                    throw new AuraHandledException('Additional Charges record not found');
                }
                
                List<Booking__c> bookings = [
                    SELECT Id, Email__c, Email1__c, Funding_Type__c, 
                           First_Applicant_Name__c, Demand_Raised__c, Owner.Email, 
                           CRM_Manager__c, CRM_Manager__r.Email 
                    FROM Booking__c 
                    WHERE Id = :adcs[0].Booking__c 
                    LIMIT 1
                ];
                
                if(bookings.isEmpty()) {
                    throw new AuraHandledException('Related Booking record not found');
                }
                booking = bookings[0];
            } else {
                throw new AuraHandledException('Invalid Type of Demand: ' + typeOfDemand);
            }
            
            System.debug('Booking found: ' + booking);
            
            // Validate booking email
            if (String.isBlank(booking.Email__c)) {
                throw new AuraHandledException('Email address not specified in the Booking record.');
            }
            
            List<String> lstCCEmail = new List<String>();
            List<String> sendTo = new List<String>();
            
            // Build recipient list
            sendTo.add(booking.Email__c);
            System.debug('Primary email added: ' + booking.Email__c);
            
            if(!String.isBlank(booking.Email1__c)){
                sendTo.add(booking.Email1__c);
                System.debug('Secondary email added: ' + booking.Email1__c);
            }
            
            // Add bank email for Loan funding type
            if(typeOfDemand == 'Flat' && 
               booking.Funding_Type__c == 'Loan' && 
               !String.isBlank(booking.Bank_Email__c)){
                sendTo.add(booking.Bank_Email__c);
                System.debug('Bank email added: ' + booking.Bank_Email__c);
            }
            
            // Build CC list
            if(!String.isBlank(booking.Owner.Email)){
                lstCCEmail.add(booking.Owner.Email);
            }
            
            if(booking.CRM_Manager__c != null && 
               !String.isBlank(booking.CRM_Manager__r.Email)){
                lstCCEmail.add(booking.CRM_Manager__r.Email);
            }
            
            System.debug('To Addresses: ' + sendTo);
            System.debug('CC Addresses: ' + lstCCEmail);
            
            // Generate PDF ONLY if not in test context
            Blob pdfBlob;
            System.debug('Generating PDF...');
            
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Unit Test PDF Content');
                System.debug('Test mode - using dummy PDF');
            } else {
                try {
                    PageReference pdfPage = Page.Demand_letterAdditional;
                    pdfPage.getParameters().put('id', recId);
                    
                    // Use getContentAsPDF() - the standard method
                    pdfBlob = pdfPage.getContentAsPDF();
                    
                    if(pdfBlob == null) {
                        throw new AuraHandledException('PDF generation returned null');
                    }
                    
                    System.debug('PDF generated successfully. Size: ' + pdfBlob.size());
                    
                } catch (Exception pdfEx) {
                    System.debug('PDF Error Type: ' + pdfEx.getTypeName());
                    System.debug('PDF Error Message: ' + pdfEx.getMessage());
                    System.debug('PDF Error Line: ' + pdfEx.getLineNumber());
                    System.debug('PDF Stack Trace: ' + pdfEx.getStackTraceString());
                    throw new AuraHandledException('Failed to generate PDF: ' + pdfEx.getMessage());
                }
            }
            
            // Create email
            System.debug('Creating email message...');
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Set Org-Wide Email Address if available
            if(!String.isBlank(booking.Owner.Email)) {
                List<OrgWideEmailAddress> owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'communication@crm.zuariproperties.com'];
        
                
                if (!owea.isEmpty()) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                    System.debug('Org-wide email set: ' + owea[0].Address);
                }
            }
            
            // Set email recipients
            email.setToAddresses(sendTo);
            
            if(!lstCCEmail.isEmpty()){
                email.setCcAddresses(lstCCEmail);
            }
            
            // Set email content
            String customerName = String.isBlank(booking.First_Applicant_Name__c) ? 
                                  'Valued Customer' : 
                                  booking.First_Applicant_Name__c;
            
            String emailBody = 'Dear ' + customerName + ',<br/><br/>' +
                              'Please find the attached Demand Letter.<br/><br/>' +
                              'We are pleased to inform you that your booking has been confirmed. ' +
                              'Attached is the Demand Letter for your reference.<br/><br/>' +
                              'If you have any questions or need further assistance, please do not hesitate to contact us.<br/><br/>' +
                              'Best regards,<br/>' +
                              'Zuari CRM Team';
            
            email.setSubject('Demand Letter');
            email.setHtmlBody(emailBody);
            email.setSaveAsActivity(false); // Prevent activity creation issues
            
            // Attach PDF
            System.debug('Attaching PDF...');
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('DemandLetter.pdf'); 
            attachment.setBody(pdfBlob);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            // Send email
            System.debug('Sending email...');
            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new Messaging.SingleEmailMessage[] { email }, 
                false
            );
            
            // Check results
            if (results != null && results.size() > 0 && results[0].isSuccess()) {
                System.debug('Email sent successfully');
                
                // Update booking if Flat demand
                if(typeOfDemand == 'Flat'){
                    booking.Demand_Raised__c = true;
                    update booking;
                    System.debug('Booking updated');
                }
                
                returnmessage = 'Demand raise email sent Successfully';
            } else {
                String errorMsg = 'Email failed to send: ';
                if(results != null && results.size() > 0) {
                    for(Messaging.SendEmailError error : results[0].getErrors()) {
                        errorMsg += error.getMessage() + '; ';
                    }
                }
                System.debug('Email Send Error: ' + errorMsg);
                throw new AuraHandledException(errorMsg);
            }
            
        } catch (AuraHandledException ahe) {
            // Re-throw AuraHandledException as-is
            System.debug('AuraHandledException: ' + ahe.getMessage());
            throw ahe;
        } catch (QueryException qe) {
            System.debug('Query Error: ' + qe.getMessage());
            System.debug('Query Stack Trace: ' + qe.getStackTraceString());
            throw new AuraHandledException('Database error: ' + qe.getMessage());
        } catch (DmlException de) {
            System.debug('DML Error: ' + de.getMessage());
            System.debug('DML Stack Trace: ' + de.getStackTraceString());
            throw new AuraHandledException('Update error: ' + de.getMessage());
        } catch (Exception e) {
            System.debug('Unexpected Error Type: ' + e.getTypeName());
            System.debug('Error Message: ' + e.getMessage());
            System.debug('Error Line: ' + e.getLineNumber());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error: ' + e.getMessage() + ' (Line: ' + e.getLineNumber() + ')');
        }
        
        System.debug('=== Completed sendEmailWithAttachment ===');
        return returnmessage;
    }
    
    @AuraEnabled
    public static void updatePaymentSchedules(String recordId){
        System.debug('=== Starting updatePaymentSchedules ===');
        System.debug('recordId: ' + recordId);
        
        try {
            if(String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required');
            }
            
            Id recId = (Id) recordId;
            
            List<Booking__c> books = [SELECT Id, Name FROM Booking__c WHERE Id = :recId LIMIT 1];
            if(books.isEmpty()) {
                throw new AuraHandledException('Booking record not found');
            }
            
            List<Payment_Schedule__c> payList = [
                SELECT Id, S_No__c, Name, Pending_Amount__c, Payment_Due_Date__c, 
                       Received_Amount1__c, Is_Demanded__c, Payment_percent__c, AmountB__c,
                       Master_Payment_Schedule__r.Completed_date__c, Booking__c
                FROM Payment_Schedule__c
                WHERE Master_Payment_Schedule__r.Status__c = 'Completed' 
                AND Pending_Amount__c != 0
                AND Booking__c = :recId
            ];
            
            System.debug('Found ' + payList.size() + ' payment schedules to update');
            
            List<Payment_Schedule__c> toUpdate = new List<Payment_Schedule__c>();
            for(Payment_Schedule__c p : payList){
                p.Is_Demanded__c = true;
                if(p.Payment_Due_Date__c == null){
                    p.Payment_Due_Date__c = System.today() + 15;
                }
                toUpdate.add(p);
            }
            
            if(!toUpdate.isEmpty()){
                update toUpdate;
                System.debug('Updated ' + toUpdate.size() + ' payment schedules');
            }
            
            System.debug('=== Completed updatePaymentSchedules ===');
        } catch (Exception e) {
            System.debug('Error Type: ' + e.getTypeName());
            System.debug('Error in updatePaymentSchedules: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error updating payment schedules: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String RaiseDemand(List<Id> bookingIds, Map<Id,String> emailContents, Map<Id,List<String>> contentIds) {
        try {
            return DemandRaisedSave.RaiseDemand(bookingIds, emailContents, contentIds);
        } catch (Exception e) {
            System.debug('Error in RaiseDemand: ' + e.getMessage());
            throw new AuraHandledException('Error raising demand: ' + e.getMessage());
        }
    }
    
}