@IsTest
private class CityList_MobileAPI_Test {

    @IsTest
    static void test_getPicklistValues() {
        RestRequest  req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CityList';
        req.httpMethod = 'GET';
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        CityList_MobileAPI.getPicklistValues();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200');
        String body = res.responseBody.toString();
        System.assert(body.contains('"status":true'), 'Response should have status true');
        System.assert(body.contains('"data"'), 'Response should have data');
    }
}