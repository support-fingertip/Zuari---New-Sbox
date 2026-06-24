@isTest
public class ProjectList_CCMobileAPI_Test {

    @testSetup
    static void setupData() {
        Project__c proj = new Project__c(
            Name = 'Zuari Garden City', Project__c = 'Zuari Garden City',
            Project_Address__c = '123 Test Street'
        );
        insert proj;
    }

    @isTest
    static void testSuccess() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        RestContext.response = new RestResponse();
        Test.startTest();
        ProjectList_CCMobileAPI.getPicklistValues();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}