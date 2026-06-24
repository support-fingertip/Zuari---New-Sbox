@isTest
public class WelcomeMailControllerTest {

    @testSetup
    static void setupTestData() {
      

        // Lead
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Company = 'testcompany';
        ld.Phone = '111111111';
        insert ld;
        
        // Quote
        Quote__c qc = new Quote__c();
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        qc.Payment_Type__c = 'Standard';
        qc.Sale_Area__c = 2567;
        qc.Built_up_area__c = 4567;
        qc.Rate_per_sqft__c = 7100;
        insert qc;
       
        // Project
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c = true;
        insert pjt;
        
        // Plot
        Plot__c ut = new Plot__c();
        ut.Name = 'Test plot';
        ut.Status__c = 'Available';
        ut.Project__c = pjt.Id;
        insert ut;

        // Master Payment Schedule
        Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.Id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c = 'Completed';
        insert mps;

        // Booking
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.Email__c = 'test@gmail.com';
        insert book;

        // Payment Schedule that the controller queries:
        // WHERE Booking__c = :leadRecord.Id AND S_No__c = 1
        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Payment_percent__c = 100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = true;
        ps.Quote__c = qc.Id;
        ps.Booking__c = book.Id;  // critical for SOQL match
        ps.S_No__c = 1;           // critical for SOQL match
        insert ps;

        // Receipt
        Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c = book.Id
        );
        insert testReceipt;

        // Receipt Line Item
        Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c = 'Additional Charges',
            Amount__c = 100,
            Received_Amount__c = 100,
            Booking__c = book.Id
        );
        insert testLineItem;

        // Co Applicant
        Co_Applicant__c testCoApplicant = new Co_Applicant__c(
            Name = 'Test Co-Applicant',
            Email__c = 'coapplicant@example.com',
            Booking__c = book.Id,
            PAN_Number__c = 'ABCDE1234F',
            Passport_Number__c = 'A1234567',
            Date_of_Birth__c = System.today() - 7300,
            Nationality__c = 'NRI',
            Occupation__c = 'Employee',
            Son_Daughter_Wife_of__c = 'fhsgd'
        );
        insert testCoApplicant;

        // Dummy EmailMessage (not strictly needed, but keeping as in original)
        EmailMessage email = new EmailMessage();
        email.Subject = 'Test';
        email.ToAddress = 'tejaswini@fingertipplus.com';
        email.CcAddress = 'tejaswini@fingertipplus.com';
        insert email;

        // ContentVersion used as attachment
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testContentVersion;

        // Refresh to get ContentDocumentId
        testContentVersion = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :testContentVersion.Id
        ];

        // Link document to Booking
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = book.Id,
            ContentDocumentId = testContentVersion.ContentDocumentId,
            ShareType = 'V'
        );
        insert testContentDocumentLink;
    }

    @isTest
    static void testGetRecordData() {
        // Get the test Booking__c record
        Booking__c testBooking = [
            SELECT Id 
            FROM Booking__c 
            WHERE Email__c = 'test@gmail.com'
            LIMIT 1
        ];

        Test.startTest();
        Booking__c result = WelcomeMailController.getRecordData(testBooking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Booking record should be returned.');
        System.assertEquals(testBooking.Id, result.Id, 'Should return the same booking.');
    }

    @isTest
    static void testSendWelcomeEmail() {
        // Get the test Booking__c record
        Booking__c testBooking = [
            SELECT Id 
            FROM Booking__c 
            WHERE Email__c = 'test@gmail.com'
            LIMIT 1
        ];

        // Get the ContentDocumentId
        ContentVersion testContentVersion = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            LIMIT 1
        ];

        Test.startTest();
        // Call the sendWelcomeEmail method
        WelcomeMailController.sendWelcomeEmail(
            testBooking.Id,
            'Test Email Content',
            new List<String>{ 'recipient@example.com' },
            new List<String>{ testContentVersion.ContentDocumentId }
        );

        // Call Unit Readiness email method as well
        WelcomeMailController.sendUnitRedinessMail(
            testBooking.Id,
            'Test Email Content',
            new List<String>{ 'recipient@example.com' },
            new List<String>{ testContentVersion.ContentDocumentId }
        );
        Test.stopTest();

        // Verify that the Welcome_Mail_Sent_Time__c field is updated
        Booking__c updatedBooking = [
            SELECT Id, Welcome_Mail_Sent_Time__c 
            FROM Booking__c 
            WHERE Id = :testBooking.Id
        ];
        System.assertNotEquals(
            null, 
            updatedBooking.Welcome_Mail_Sent_Time__c,
            'Welcome_Mail_Sent_Time__c should be set after sending welcome email.'
        );
    }

    @isTest
    static void testSendWelcomeEmailWithoutAttachments() {
        // Get the test Booking__c record
        Booking__c testBooking = [
            SELECT Id 
            FROM Booking__c 
            WHERE Email__c = 'test@gmail.com'
            LIMIT 1
        ];

        Test.startTest();
        // Call the sendWelcomeEmail method without contentIds (no file attachments from ContentDocument)
        WelcomeMailController.sendWelcomeEmail(
            testBooking.Id,
            'Test Email Content',
            new List<String>{ 'recipient@example.com' },
            new List<String>()
        );
        Test.stopTest();

        // Verify that the Welcome_Mail_Sent_Time__c field is updated
        Booking__c updatedBooking = [
            SELECT Id, Welcome_Mail_Sent_Time__c 
            FROM Booking__c 
            WHERE Id = :testBooking.Id
        ];
        System.assertNotEquals(
            null,
            updatedBooking.Welcome_Mail_Sent_Time__c,
            'Welcome_Mail_Sent_Time__c should still be set even without content attachments.'
        );
    }
}