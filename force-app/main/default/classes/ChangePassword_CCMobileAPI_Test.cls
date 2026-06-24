@isTest
public class ChangePassword_CCMobileAPI_Test {

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
        setupPost('{"userId":"' + c.Name + '","oldPassword":"Test@123","newPassword":"NewPass@456"}');
        Test.startTest();
        ChangePassword_CCMobileAPI.changePassword();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testWrongOldPassword() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","oldPassword":"WrongPass","newPassword":"NewPass@456"}');
        Test.startTest();
        ChangePassword_CCMobileAPI.changePassword();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingFields() {
        setupPost('{"userId":"","oldPassword":"","newPassword":""}');
        Test.startTest();
        ChangePassword_CCMobileAPI.changePassword();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","oldPassword":"pass","newPassword":"new"}');
        Test.startTest();
        ChangePassword_CCMobileAPI.changePassword();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}