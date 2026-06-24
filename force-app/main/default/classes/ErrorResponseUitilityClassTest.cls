@IsTest
public class ErrorResponseUitilityClassTest {

    @IsTest
    static void testSendErrorResponse() {
        // 1. Initialize RestContext
        // Essential to avoid NullPointerException when the class accesses RestContext.response
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        RestContext.request = req;
        RestContext.response = res;

        // 2. Define test inputs
        String testMessage = 'Test Error Message';
        String testRequestType = 'POST';
        String testRequestBody = '{"key":"value"}';

        // 3. Execute the method to trigger code coverage
        Test.startTest();
        ErrorResponseUitilityClass.sendErrorResponse(testMessage, testRequestType, testRequestBody);
        Test.stopTest();
    }
}