public without sharing class SendEmailToCustomerTPAClass {
    @AuraEnabled
    public static void sendEmailToCustomerTPA(Id bookingId) {
        // Query Booking record and related info
        Booking__c booking = [
            SELECT Id, Name, Plot__r.Name, Email1__c, Email__c, Slead__r.Email, 
                   First_Applicant_Name__c, Project__c, Unit_No__c, Owner.Email 
            FROM Booking__c WHERE Id = :bookingId LIMIT 1
        ];
        
        // Query Co-Applicants related to Booking
        List<Co_Applicant__c> coApplicants = [
            SELECT Id, Name, Email__c, Booking__c 
            FROM Co_Applicant__c WHERE Booking__c = :booking.Id
        ];
        
        // Query OrgWideEmailAddress matching Owner's email
        List<OrgWideEmailAddress> orgWideEmails = [
            SELECT Id, Address, DisplayName 
            FROM OrgWideEmailAddress WHERE Address = 'communication@crm.zuariproperties.com' limit 1];
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        List<String> ccEmails = new List<String>();
        List<String> toEmails = new List<String>();
        
        // Set OrgWideEmailAddress if found
        if (!orgWideEmails.isEmpty()) {
            email.setOrgWideEmailAddressId(orgWideEmails[0].Id);
            ccEmails.add(orgWideEmails[0].Address);
        }
        
        // Prepare PDF attachment of Tripartite Agreement
        PageReference pdfPage = Page.TRIPARTITE_AGREEMENT;
        pdfPage.getParameters().put('id', booking.Id);
        
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContent();
        }
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Tripartite_Agreement.pdf');
        attachment.setBody(pdfBlob);
        attachments.add(attachment);
        
        // Add Booking email to TO list
        if (booking.Email__c != null) {
            toEmails.add(booking.Email__c);
        }
        
        // Add emails of Co-Applicants to TO list
        for (Co_Applicant__c ca : coApplicants) {
            if (ca.Email__c != null) {
                toEmails.add(ca.Email__c);
            }
        }
        
        // Email subject and body
        email.setSubject('Tripartite Agreement - Zuari Project');
        email.setToAddresses(toEmails);
        email.setCcAddresses(ccEmails);
        
        String emailBody = 'Dear Sir/Madam,<br/><br/>' +
                           'Please find attached the Tripartite Agreement for your booking.<br/><br/>' +
                           'Property Details:<br/>' +
                           'Unit No: ' + booking.Unit_No__c + '<br/>' +
                           'Project: ' + booking.Project__c + '<br/>' +
                           'First Applicant: ' + booking.First_Applicant_Name__c + '<br/><br/>' +
                           'Thank you for choosing Zuari.<br/><br/>' +
                           'Best regards,<br/>Zuari Infra Team';
        email.setHtmlBody(emailBody);
        
        // Attach PDF
        email.setFileAttachments(attachments);
        
        // Send email if TO addresses exist
        if (!toEmails.isEmpty()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            System.debug('Email sent successfully to: ' + toEmails);
        } else {
            System.debug('No recipient email addresses found for booking Id: ' + bookingId);
        }
    }
}