@isTest
public class LoginAPI_CCMobileAPI_Test {

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

        Logged_in_Device__c device = new Logged_in_Device__c(
            Customer_Master__c = customer.Id,
            Device_Id__c = 'existing-device-001',
            Status__c = 'Active'
        );
        insert device;
    }

    static void setupPost(String body) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @isTest
    static void testLoginSuccess() {
        setupPost('{"mobileNumber":"9876543210","password":"Test@123","deviceId":"new-device-002"}');
        Test.startTest();
        LoginAPI_CCMobileAPI.checkLogin();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testLoginExistingDevice() {
        setupPost('{"mobileNumber":"9876543210","password":"Test@123","deviceId":"existing-device-001"}');
        Test.startTest();
        LoginAPI_CCMobileAPI.checkLogin();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testLoginInvalidPassword() {
        setupPost('{"mobileNumber":"9876543210","password":"WrongPass","deviceId":"dev-001"}');
        Test.startTest();
        LoginAPI_CCMobileAPI.checkLogin();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testLoginMissingCredentials() {
        setupPost('{"mobileNumber":"","password":"","deviceId":""}');
        Test.startTest();
        LoginAPI_CCMobileAPI.checkLogin();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testLoginCustomerNotFound() {
        setupPost('{"mobileNumber":"0000000000","password":"pass","deviceId":"dev"}');
        Test.startTest();
        LoginAPI_CCMobileAPI.checkLogin();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}