@isTest
public class CreateCustomerQuery_CCMobileAPI_Test {

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

        // Customer without booking
        Customer_Master__c customerNoBooking = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9999999999',
            Email__c = 'nobooking@test.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'No Booking Customer'
        );
        insert customerNoBooking;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Allocated_Project__c = 'Zuari Garden City'
        );
        insert testLead;

        Project__c proj = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Project_Address__c = 'Address'
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Plot-001',
            Status__c = 'Available',
            Project__c = proj.Id,
            BHK_Type__c = '2BHK',
            Carpet_Area__c = 1000
        );
        insert plot;

        Quote__c quote = new Quote__c(
            SLead__c = testLead.Id,
            Unit__c = plot.Id,
            Project__c = 'Zuari Garden City',
            Quote_date__c = Date.today()
        );
        insert quote;

        Booking__c booking = new Booking__c(
            Quote__c = quote.Id,
            SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City',
            Project1__c = proj.Id,
            Plot__c = plot.Id,
            Stage__c = 'Booked',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Customer_Master__c = customer.Id,
            Approval_status__c = 'Pending'
        );
        insert booking;
    }

    private static void setupRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        req.httpMethod = 'POST';

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static Customer_Master__c getCustomer() {
        return [
            SELECT Id, Name
            FROM Customer_Master__c
            WHERE Customer_Name__c = 'Test Customer'
            LIMIT 1
        ];
    }

    private static Booking__c getBooking() {
        return [
            SELECT Id,
                   Plot__c,
                   Plot__r.Name,
                   Plot__r.Project__r.Project_Id__c
            FROM Booking__c
            LIMIT 1
        ];
    }

    @isTest
    static void testSuccess() {

        Customer_Master__c c = getCustomer();
        Booking__c b = getBooking();

        String body =
        '{"userId":"' + c.Name +
        '","projectId":"' + b.Plot__r.Project__r.Project_Id__c +
        '","unitNumberId":"' + b.Plot__r.Name +
        '","subject":"Test Subject"' +
        ',"queryTypeId":"CRM Query"' +
        ',"subTypeId":"General"' +
        ',"description":"Test Description"}';

        setupRequest(body);

        Test.startTest();
        CreateCustomerQuery_CCMobileAPI.createCustomerQuery();
        Test.stopTest();

    }

    @isTest
    static void testSuccessWithoutUnit() {

        Customer_Master__c c = getCustomer();
        Booking__c b = getBooking();

        String body =
        '{"userId":"' + c.Name +
        '","projectId":"' + b.Plot__r.Project__r.Project_Id__c +
        '","unitNumberId":""' +
        ',"subject":"Test"' +
        ',"queryTypeId":"Other"' +
        ',"subTypeId":"Sub"' +
        ',"description":"Description"' +
        ',"otherQueryDescription":"Other Query"}';

        setupRequest(body);

        Test.startTest();
        CreateCustomerQuery_CCMobileAPI.createCustomerQuery();
        Test.stopTest();

    }

    @isTest
    static void testMissingUserId() {

        setupRequest(
            '{"userId":"","projectId":"","unitNumberId":""}'
        );

        Test.startTest();
        CreateCustomerQuery_CCMobileAPI.createCustomerQuery();
        Test.stopTest();
    }

    @isTest
    static void testCustomerNotFound() {

        setupRequest(
            '{"userId":"INVALID","projectId":"P1"}'
        );

        Test.startTest();
        CreateCustomerQuery_CCMobileAPI.createCustomerQuery();
        Test.stopTest();
    }

    @isTest
    static void testNoBookingFound() {

        Customer_Master__c c = [
            SELECT Id, Name
            FROM Customer_Master__c
            WHERE Customer_Name__c = 'No Booking Customer'
            LIMIT 1
        ];

        setupRequest(
            '{"userId":"' + c.Name +
            '","projectId":"PRJ001"}'
        );

        Test.startTest();
        CreateCustomerQuery_CCMobileAPI.createCustomerQuery();
        Test.stopTest();
    }

    @isTest
    static void testProjectMismatch() {

        Customer_Master__c c = getCustomer();

        setupRequest(
            '{"userId":"' + c.Name +
            '","projectId":"INVALID_PROJECT"}'
        );

        Test.startTest();
        CreateCustomerQuery_CCMobileAPI.createCustomerQuery();
        Test.stopTest();
    }

    @isTest
    static void testDuplicateQuery() {

        Customer_Master__c c = getCustomer();
        Booking__c b = getBooking();

        insert new Customer_Query__c(
            Customer_Master__c = c.Id,
            Booking__c = b.Id,
            Query_Type__c = 'Other Query',
            Query_Sub_Type__c = 'Booking Form',
            Query_Status__c = 'New',
            Lapse_Email_Sent__c = false
        );

        String body =
        '{"userId":"' + c.Name +
        '","projectId":"' + b.Plot__r.Project__r.Project_Id__c +
        '","unitNumberId":"' + b.Plot__r.Name +
        '","queryTypeId":"CRM Query"' +
        ',"subTypeId":"General"}';

        setupRequest(body);

        Test.startTest();
        CreateCustomerQuery_CCMobileAPI.createCustomerQuery();
        Test.stopTest();
    }
}