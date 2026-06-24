@isTest
public class MyBookedUnit_CCMobileAPI_Test {

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

    @isTest
    static void testSuccess() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","pageSize":0}');
        Test.startTest();
        MyBookedUnit_CCMobileAPI.getMyBookedUnits();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":"","pageSize":0}');
        Test.startTest();
        MyBookedUnit_CCMobileAPI.getMyBookedUnits();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","pageSize":0}');
        Test.startTest();
        MyBookedUnit_CCMobileAPI.getMyBookedUnits();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}