@IsTest
private class SendEmailToCustomerTPAClassTest {

    @IsTest
    static void testSendEmailToCustomerTPA() {

        // ----------- USER (OWNER) -----------
        User u = new User(
            FirstName = 'Test',
            LastName = 'Owner',
            Email = 'owner@test.com',
            Alias = 'tst',
            Username = 'owner123@test.com',
            CommunityNickname = 'owner123',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id
        );
        insert u;

       

        // ----------- LEAD -----------
        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'testcompany',
            Phone = '111111111'
        );
        insert ld;

        // ----------- QUOTE -----------
        Quote__c qc = new Quote__c(
            Quote_status__c = 'Converted',
            Block__c = ' ',
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100
        );
        insert qc;

        // ----------- PROJECT -----------
        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c = true
        );
        insert pjt;

        // ----------- PLOT -----------
        Plot__c ut = new Plot__c(
            Name = 'Test plot',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        // ----------- MASTER PAYMENT SCHEDULE -----------
        Master_payment_schedule__c mps = new Master_payment_schedule__c(
            Name = 'test',
            Project__c = pjt.Id,
            Payment_Percent__c = 20,
            Status__c = 'Completed'
        );
        insert mps;

        // ----------- BOOKING (YOUR VERSION) -----------
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            Email__c = 'test@gmail.com',
            OwnerId = u.Id
        );
        insert book;

        // ----------- PAYMENT SCHEDULE (MATCHES CONTROLLER SOQL) -----------
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Payment_percent__c = 100,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c = true,
            Quote__c = qc.Id,
            Booking__c = book.Id,
            S_No__c = 1
        );
        insert ps;

        // ----------- RECEIPT -----------
        Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c = book.Id
        );
        insert testReceipt;

        // ----------- RECEIPT LINE ITEM -----------
        Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c = 'Additional Charges',
            Amount__c = 100,
            Received_Amount__c = 100,
            Booking__c = book.Id
        );
        insert testLineItem;

        // ----------- CO-APPLICANT -----------
        Co_Applicant__c coApp = new Co_Applicant__c(
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
        insert coApp;

        // ----------- PDF ATTACHMENT SIMULATION -----------

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        Test.startTest();

        SendEmailToCustomerTPAClass.sendEmailToCustomerTPA(book.Id);

        Test.stopTest();

        // ----------- ASSERT EMAIL WAS SENT -----------
       
      
    }
}