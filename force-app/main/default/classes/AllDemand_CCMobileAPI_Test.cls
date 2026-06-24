@isTest
public class AllDemand_CCMobileAPI_Test {

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

        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c = booking.Id, Amount_Demanded__c = 50000,
            Demand_Status__c = 'Demand Raised', Payment_schedule__c = ps.Id,
            Demanded_Date__c = Date.today()
        );
        insert demand;
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
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","demandStatusId":"","pageSize":0,"raiseFromDate":null,"raiseToDate":null,"dueFromDate":null,"dueToDate":null}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testWithStatusFilter() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","demandStatusId":"Demand Raised","pageSize":0,"raiseFromDate":null,"raiseToDate":null,"dueFromDate":null,"dueToDate":null}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testWithRaiseDateFilter() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","demandStatusId":"","pageSize":0,"raiseFromDate":"2025-01-01T00:00:00Z","raiseToDate":"2027-12-31T23:59:59Z","dueFromDate":null,"dueToDate":null}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testWithDueDateFilter() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","demandStatusId":"","pageSize":0,"raiseFromDate":null,"raiseToDate":null,"dueFromDate":"2025-01-01T00:00:00Z","dueToDate":"2027-12-31T23:59:59Z"}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidRaiseDateRange() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","demandStatusId":"","pageSize":0,"raiseFromDate":"2027-12-31T00:00:00Z","raiseToDate":"2025-01-01T00:00:00Z","dueFromDate":null,"dueToDate":null}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidDueDateRange() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","demandStatusId":"","pageSize":0,"raiseFromDate":null,"raiseToDate":null,"dueFromDate":"2027-12-31T00:00:00Z","dueToDate":"2025-01-01T00:00:00Z"}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testEmptyDates() {
        Customer_Master__c c = getCust();
        Booking__c b = getBooking();
        setupPost('{"userId":"' + c.Name + '","bookingId":"' + b.Name + '","demandStatusId":"","pageSize":0,"raiseFromDate":"","raiseToDate":"","dueFromDate":"","dueToDate":""}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":"","bookingId":"","pageSize":0,"raiseFromDate":null,"raiseToDate":null,"dueFromDate":null,"dueToDate":null}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingBookingId() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","bookingId":"","pageSize":0,"raiseFromDate":null,"raiseToDate":null,"dueFromDate":null,"dueToDate":null}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","bookingId":"BK001","pageSize":0,"raiseFromDate":null,"raiseToDate":null,"dueFromDate":null,"dueToDate":null}');
        Test.startTest();
        AllDemand_CCMobileAPI.getAllDemands();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}