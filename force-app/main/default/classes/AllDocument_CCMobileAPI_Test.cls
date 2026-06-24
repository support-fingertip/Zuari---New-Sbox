@isTest
public class AllDocument_CCMobileAPI_Test {

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
    static void attachFileToBooking(Id bookingId) {
    // Insert ContentVersion — Salesforce auto-creates ContentDocument
    ContentVersion cv = new ContentVersion(
        Title = 'TestDocument',
        PathOnClient = 'TestDocument.pdf',
        VersionData = Blob.valueOf('Test file content'),
        IsMajorVersion = true
    );
    insert cv;

    // Query back the auto-created ContentDocumentId
    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    // Link the document to the booking
    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = cv.ContentDocumentId,
        LinkedEntityId = bookingId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;
}
    @isTest
    static void testSuccess() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","documentName":"","pageSize":0}');
        Test.startTest();
        AllDocument_CCMobileAPI.getAllDocuments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":"","bookingId":"","pageSize":0}');
        Test.startTest();
        AllDocument_CCMobileAPI.getAllDocuments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingBookingId() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","bookingId":"","pageSize":0}');
        Test.startTest();
        AllDocument_CCMobileAPI.getAllDocuments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","bookingId":"BK001","pageSize":0}');
        Test.startTest();
        AllDocument_CCMobileAPI.getAllDocuments();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @isTest
static void testSuccessWithDocuments() {
    Customer_Master__c c = getCust();
    Booking__c b = getBooking();
    attachFileToBooking(b.Id);

    setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","documentName":"","pageSize":0}');
    Test.startTest();
    AllDocument_CCMobileAPI.getAllDocuments();
    Test.stopTest();
    System.assertEquals(200, RestContext.response.statusCode);

    // Verify response contains document data
    String respBody = RestContext.response.responseBody.toString();
    AllDocument_CCMobileAPI.AllDocumentResponse resp =
        (AllDocument_CCMobileAPI.AllDocumentResponse) JSON.deserialize(respBody, AllDocument_CCMobileAPI.AllDocumentResponse.class);
    System.assertEquals(true, resp.status);
    System.assertEquals(1, resp.data.size());
}
@isTest
static void testDocumentNameFilter() {
    Customer_Master__c c = getCust();
    Booking__c b = getBooking();
    attachFileToBooking(b.Id);

    setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","documentName":"NonExistentDoc","pageSize":0}');
    Test.startTest();
    
    AllDocument_CCMobileAPI.getAllDocuments();
    Test.stopTest();
    System.assertEquals(200, RestContext.response.statusCode);
}
@isTest
static void testDateRangeFilter() {
    Customer_Master__c c = getCust();
    Booking__c b = getBooking();
    attachFileToBooking(b.Id);

    String fromDate = Datetime.now().addDays(-1).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    String toDate = Datetime.now().addDays(1).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","documentName":"","fromDate":"' + fromDate + '","toDate":"' + toDate + '","pageSize":0}');
    Test.startTest();
    AllDocument_CCMobileAPI.getAllDocuments();
    Test.stopTest();
    System.assertEquals(200, RestContext.response.statusCode);
}
@isTest
static void testFromDateGreaterThanToDate() {
    Customer_Master__c c = getCust();
    Booking__c b = getBooking();

    String fromDate = Datetime.now().addDays(1).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    String toDate = Datetime.now().addDays(-1).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","documentName":"","fromDate":"' + fromDate + '","toDate":"' + toDate + '","pageSize":0}');
    Test.startTest();
    AllDocument_CCMobileAPI.getAllDocuments();
    Test.stopTest();
    System.assertEquals(200, RestContext.response.statusCode);
}
@isTest
static void testBookingNotFoundForCustomer() {
    Customer_Master__c c = getCust();
    setupPost('{"userId":"' + c.Name + '","bookingId":"INVALID_BK","pageSize":0}');
    Test.startTest();
    AllDocument_CCMobileAPI.getAllDocuments();
    Test.stopTest();
    System.assertEquals(200, RestContext.response.statusCode);
}
@isTest
static void testPagination() {
    Customer_Master__c c = getCust();
    Booking__c b = getBooking();
    // Attach 2 files
    attachFileToBooking(b.Id);
    attachFileToBooking(b.Id);

    setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","documentName":"","pageSize":1}');
    Test.startTest();
    AllDocument_CCMobileAPI.getAllDocuments();
    Test.stopTest();
    System.assertEquals(200, RestContext.response.statusCode);
}
}