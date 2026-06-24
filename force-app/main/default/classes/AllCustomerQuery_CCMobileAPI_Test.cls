@isTest
public class AllCustomerQuery_CCMobileAPI_Test {

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

        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Subject__c = 'Test Query Subject',
            Description__c = 'Test query description',
            Query_Type__c = 'CRM Query',
            Query_Status__c = 'New',
            Priority__c = 'High',
            Project__c = 'Zuari Garden City'
        );
        insert cq;
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
        setupPost('{"userId":"' + c.Name + '","pageSize":0,"projectId":"","search":"","ticketStatusId":"","ticketTypeId":""}');
        Test.startTest();
        AllCustomerQuery_CCMobileAPI.getAllCustomerQueries();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testWithFilters() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","pageSize":0,"projectId":"","search":"Test","ticketStatusId":"New","ticketTypeId":"CRM Query"}');
        Test.startTest();
        AllCustomerQuery_CCMobileAPI.getAllCustomerQueries();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":"","pageSize":0}');
        Test.startTest();
        AllCustomerQuery_CCMobileAPI.getAllCustomerQueries();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","pageSize":0}');
        Test.startTest();
        AllCustomerQuery_CCMobileAPI.getAllCustomerQueries();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}