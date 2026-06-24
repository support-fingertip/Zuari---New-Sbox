@IsTest
private class ENUM_MobileAPI_Test {

    @IsTest
    static void test_getPicklistValues_FullCoverage() {
        // 1. Initialize the RestContext for a GET request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/ENUMAPI/';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response = res;

        // 2. Execute the method to cover the main logic and Schema describes
        Test.startTest();
        ENUM_MobileAPI.getPicklistValues();
        Test.stopTest();
    }

}