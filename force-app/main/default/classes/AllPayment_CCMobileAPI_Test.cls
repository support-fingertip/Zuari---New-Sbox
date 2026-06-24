@isTest
public class AllPayment_CCMobileAPI_Test {

    @testSetup
    static void setupData() {
        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9876543210',
            Email__c = 'test@example.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'Test Customer'
        );
        insert customer;

        Lead testLead = new Lead(
            FirstName = 'Test', LastName = 'Lead', Company = 'Test Co',
            Allocated_Project__c = 'Zuari Garden City'
        );
        insert testLead;

        Project__c proj = new Project__c(
            Name = 'Zuari Garden City', Project__c = 'Zuari Garden City',
            Project_Address__c = '123 Test Street'
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Plot-001', Status__c = 'Available',
            Project__c = proj.Id, BHK_Type__c = '2BHK', Carpet_Area__c = 1000
        );
        insert plot;

        Quote__c quote = new Quote__c(
            SLead__c = testLead.Id, Unit__c = plot.Id,
            Project__c = 'Zuari Garden City', Quote_date__c = Date.today()
        );
        insert quote;

        Booking__c booking = new Booking__c(
            Quote__c = quote.Id, SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City', Project1__c = proj.Id,
            Plot__c = plot.Id, Stage__c = 'Booked',
            Booking_Date__c = Date.today(), Booking_Amount__c = 50000,
            Customer_Master__c = customer.Id,
            Approval_status__c = 'Pending'
        );
        insert booking;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Name = 'Test Payment Schedule',
            Quote__c = quote.Id, S_No__c = 1,
            Amount__c = 100000, Booking__c = booking.Id, Status__c = 'Scheduled'
        );
        insert ps;

        Receipt__c receipt = new Receipt__c(
            Booking__c = booking.Id, Receipt_Date__c = Date.today()
        );
        insert receipt;

        Receipt_Line_Item__c rli = new Receipt_Line_Item__c(
            Booking__c = booking.Id, Receipt__c = receipt.Id,
            Amount__c = 25000, Mode_of_Payment__c = 'UPI',
            Cheque_no_Transaction_Number__c = 'TXN001',
            Payment_schedule__c = ps.Id
        );
        insert rli;
    }

    static void setupPost(String body) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    static Customer_Master__c getCust() {
        return [SELECT Id, Name FROM Customer_Master__c LIMIT 1];
    }

    static Booking__c getBooking() {
        return [SELECT Id, Name FROM Booking__c LIMIT 1];
    }

    @isTest
    static void testSuccess() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","paymentStatusId":"","pageSize":0}');
        Test.startTest();
        AllPayment_CCMobileAPI.getAllPayments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testWithDateFilter() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","paymentStatusId":"","pageSize":0,"fromDate":"2025-01-01T00:00:00Z","toDate":"2027-12-31T23:59:59Z"}');
        Test.startTest();
        AllPayment_CCMobileAPI.getAllPayments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":"","bookingId":"","pageSize":0}');
        Test.startTest();
        AllPayment_CCMobileAPI.getAllPayments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingBookingId() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","bookingId":"","pageSize":0}');
        Test.startTest();
        AllPayment_CCMobileAPI.getAllPayments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","bookingId":"BK001","pageSize":0}');
        Test.startTest();
        AllPayment_CCMobileAPI.getAllPayments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @isTest
static void testReceiptFileDownloadUrl() {

    Receipt__c receipt =
        [SELECT Id FROM Receipt__c LIMIT 1];

    ContentVersion cv = new ContentVersion(
        Title = 'Receipt_File',
        PathOnClient = 'Receipt_File.pdf',
        VersionData = Blob.valueOf('Test Data')
    );
    insert cv;

    cv = [
        SELECT Id, ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
    ];

    insert new ContentDocumentLink(
        LinkedEntityId = receipt.Id,
        ContentDocumentId = cv.ContentDocumentId,
        ShareType = 'V'
    );

    Customer_Master__c c = getCust();
    Booking__c b = getBooking();

    setupPost(
        '{"userId":"' + c.Name +
        '","bookingId":"' + b.Name +
        '","pageSize":0}'
    );

    Test.startTest();
    AllPayment_CCMobileAPI.getAllPayments();
    Test.stopTest();

    System.assertEquals(
        200,
        RestContext.response.statusCode
    );
}
}