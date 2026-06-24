@isTest
private class ZGTstatementOfAccountsControllerTest {

    private static Booking__c createTestData() {
        Lead ld = new Lead(LastName = 'Test', Company = 'testcompany', Phone = '111111111');
        insert ld;

        Quote__c qc = new Quote__c(
            Quote_status__c = 'Converted',
            Block__c = ' ',
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100
        );
        insert qc;

        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c = true
        );
        insert pjt;

        Plot__c ut = new Plot__c(
            Name = 'Test plot',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        Master_payment_schedule__c mps = new Master_payment_schedule__c(
            Project__c = pjt.Id,
            Name = 'test',
            Payment_Percent__c = 20,
            Status__c = 'Completed'
        );
        insert mps;

        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            Project1__c = pjt.Id,
            Email__c = 'test@gmail.com',
            First_Applicant_Name__c = 'John Doe',
            Mobile__c = '9999999999',
            Booking_Date__c = Date.today()
        );
        insert book;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Payment_percent__c = 100,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c = true,
            Quote__c = qc.Id,
            Booking__c = book.Id,
            S_No__c = 1
        );
        insert ps;

        Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c = book.Id,
            Receipt_Date__c = Date.today(),
            Bank_Name__c = 'HDFC Bank',
            Check_Transaction_Nmber__c = 'TXN001'
        );
        insert testReceipt;

        Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c = 'Additional Charges',
            Amount__c = 100,
            Received_Amount__c = 100,
            Booking__c = book.Id,
            Bank_Name__c = 'HDFC Bank'
        );
        insert testLineItem;

        Co_Applicant__c testCoApplicant = new Co_Applicant__c(
            Name = 'Test Co-Applicant',
            Email__c = 'coapplicant@example.com',
            Booking__c = book.Id,
            PAN_Number__c = 'ABCDE1234F',
            Passport_Number__c = 'A1234567',
            Date_of_Birth__c = System.today() - 7300,
            Nationality__c = 'NRI',
            Occupation__c = 'Employee',
            Son_Daughter_Wife_of__c = 'Test Parent',
            Salutation__c = 'Mrs.',
            Primary_Phone__c = '8888888888'
        );
        insert testCoApplicant;

        return book;
    }

    @isTest
    static void testControllerWithAllData() {
        Booking__c book = createTestData();

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(book);
        ZGTstatementOfAccountsController controller = new ZGTstatementOfAccountsController(stdController);
        Test.stopTest();

       
    }

    @isTest
    static void testControllerWithoutOptionalData() {
        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c = true
        );
        insert pjt;

        Plot__c ut = new Plot__c(
            Name = 'Test plot 2',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Plot__c = ut.Id,
            Project1__c = pjt.Id,
            Email__c = 'solo@gmail.com',
            First_Applicant_Name__c = 'Solo Applicant',
            Mobile__c = '7777777777'
        );
        insert book;

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(book);
        ZGTstatementOfAccountsController controller = new ZGTstatementOfAccountsController(stdController);
        Test.stopTest();


    }
}