@isTest
public class GetProjectListAPITest {
    
    @isTest static void testGetPicklistValues() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GETPROJECTLIST/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        Test.startTest();
        GetProjectListAPI.getPicklistValues();
        Test.stopTest();
    }

}