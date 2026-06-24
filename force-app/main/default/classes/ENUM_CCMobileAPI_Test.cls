@isTest
public class ENUM_CCMobileAPI_Test {

    @isTest
    static void testSuccess() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestContext.response = new RestResponse();
        Test.startTest();
        ENUM_CCMobileAPI.getPicklistValues();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}