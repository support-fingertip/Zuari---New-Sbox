@isTest
public class MyRefferalList_CCMobileAPI_Test {

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

        Referral__c referral = new Referral__c(
            Customer_Master__c = customer.Id,
            Referrer_Name__c = 'Referred Person',
            Contact_Number__c = '1112223333',
            City__c = 'Bangalore',
            Status__c = 'Submitted'
        );
        insert referral;
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
        setupPost('{"userId":"' + c.Name + '","pageSize":0,"referralStatusId":"","fromDate":null,"toDate":null,"projectId":""}');
        Test.startTest();
        MyRefferalList_CCMobileAPI.getMyRefferalList();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testWithStatusFilter() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","pageSize":0,"referralStatusId":"Submitted","fromDate":null,"toDate":null,"projectId":""}');
        Test.startTest();
        MyRefferalList_CCMobileAPI.getMyRefferalList();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testWithDateFilter() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","pageSize":0,"referralStatusId":"","fromDate":"2025-01-01T00:00:00Z","toDate":"2027-12-31T23:59:59Z","projectId":""}');
        Test.startTest();
        MyRefferalList_CCMobileAPI.getMyRefferalList();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":"","pageSize":0}');
        Test.startTest();
        MyRefferalList_CCMobileAPI.getMyRefferalList();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","pageSize":0}');
        Test.startTest();
        MyRefferalList_CCMobileAPI.getMyRefferalList();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}