@isTest
public class VerifyOTP_CCMobileAPI_Test {

    @testSetup
    static void setupData() {
        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9876543210',
            Email__c = 'test@example.com',
            Password__c = 'Test@123',
            OTP_Number__c = 123456,
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

    @isTest
    static void testSuccess() {
        setupPost('{"mobileNumber":"9876543210","otp":"123456"}');
        Test.startTest();
        VerifyOTP_CCMobileAPI.verifyOTP();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidOTP() {
        setupPost('{"mobileNumber":"9876543210","otp":"999999"}');
        Test.startTest();
        VerifyOTP_CCMobileAPI.verifyOTP();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingFields() {
        setupPost('{"mobileNumber":"","otp":""}');
        Test.startTest();
        VerifyOTP_CCMobileAPI.verifyOTP();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"mobileNumber":"0000000000","otp":"123456"}');
        Test.startTest();
        VerifyOTP_CCMobileAPI.verifyOTP();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}