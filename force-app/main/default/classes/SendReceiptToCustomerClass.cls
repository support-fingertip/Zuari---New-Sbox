public without sharing class SendReceiptToCustomerClass {

    @AuraEnabled
    public static String sendReceiptToCustomer(Id BookingId) {
        System.debug(BookingId);

        Booking__c bookingRecord = [
            SELECT Id, Name, Plot__r.Name, Email1__c, Email__c, Slead__r.Email, First_Applicant_Name__c,
                   Project__c, Unit_No__c, Owner.Email, Project1__r.Name
            FROM Booking__c
            WHERE Id = :BookingId
            LIMIT 1
        ];
        System.debug(bookingRecord);

        List<Co_Applicant__c> coApplicants = [
            SELECT Id, Name, Email__c, Booking__c
            FROM Co_Applicant__c
            WHERE Booking__c = :bookingRecord.Id
        ];

        List<OrgWideEmailAddress> orgWideEmails = [
            SELECT Id, Address, DisplayName 
            FROM OrgWideEmailAddress WHERE Address = 'communication@crm.zuariproperties.com' limit 1];
        

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        List<String> ccEmails = new List<String>();
        List<String> toEmails = new List<String>();

        // Set Org Wide Email if exists
        if (!orgWideEmails.isEmpty()) {
            email.setOrgWideEmailAddressId(orgWideEmails[0].Id);
            ccEmails.add(orgWideEmails[0].Address);
        }

        // Determine which VF page to use based on Project1__r.Name
        PageReference receiptPage;
        if (bookingRecord.Project1__r.Name == 'Zuari Gangothri Tribhuja') {
            receiptPage = Page.ZGT_statement_Of_Accounts;
        } else {
            receiptPage = Page.Customer_Statement;
        }
        receiptPage.getParameters().put('id', bookingRecord.Id);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Unit.Test');
        } else {
            pdfBlob = receiptPage.getContent();
        }

        Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
        pdfAttachment.setFileName('Consolidated Receipt.pdf');
        pdfAttachment.setBody(pdfBlob);
        attachments.add(pdfAttachment);

        // Recipients in To
        if (bookingRecord.Email__c != null) {
            toEmails.add(bookingRecord.Email__c);
        }

        for (Co_Applicant__c coApp : coApplicants) {
            if (coApp.Email__c != null) {
                toEmails.add(coApp.Email__c);
            }
        }

        email.setToAddresses(toEmails);
        email.setCcAddresses(ccEmails);
        email.setSubject('Zuari Consolidated Receipt');

        // Compose HTML Body
        String body = ''
            + 'Dear Sir/Madam,<br/><br/>'
            + 'We are pleased to acknowledge the receipt of your payment for the property as detailed below:<br/><br/>'
            + '<b>Property Details:</b><br/>'
            + '<b>Unit No:</b> ' + bookingRecord.Unit_No__c + '<br/>'
            + '<b>Project Name:</b> ' + bookingRecord.Project__c + '<br/>'
            + '<b>First Applicant Name:</b> ' + bookingRecord.First_Applicant_Name__c + '<br/>';

        if (!coApplicants.isEmpty()) {
            body += '<b>Co-Applicant(s):</b> ';
            for (Co_Applicant__c coApp : coApplicants) {
                body += coApp.Name + ', ';
            }
            body = body.substring(0, body.length() - 2) + '<br/>';
        }

        body += ''
            + '<b>Flat Number:</b> ' + bookingRecord.Unit_No__c + '<br/><br/>'
            + 'Thank you for your timely payment and continued trust in us. Please find the consolidated receipt attached for your reference.<br/><br/>'
            + 'Should you have any queries, feel free to contact us anytime.<br/><br/>'
            + 'Thank you once again for choosing Zuari!<br/><br/>';

        email.setHtmlBody(body);
        email.setFileAttachments(attachments);

        if (!toEmails.isEmpty()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            return 'Email sent successfully';
        } else {
            return 'No recipient email addresses found';
        }
    }

}