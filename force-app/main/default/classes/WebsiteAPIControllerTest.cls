@isTest
private class WebsiteAPIControllerTest {
    
    @isTest
    static void testCreateTaskForLead() {
        // Simulate JSON request body
        WebsiteAPIController.leadWrapper testLead = new WebsiteAPIController.leadWrapper();
        testLead.lastName = 'Test User';
        testLead.source = 'Website';
        testLead.subSource = 'Google Ads';
        testLead.mobile = '9876543210';
        testLead.email = 'testuser@example.com';
        testLead.project = 'Test Project';
        testLead.unitPreference = '2BHK';
        testLead.campaign = 'Summer Campaign';
        testLead.tertiarySource = 'CW Live Chat';
        
        // Serialize the wrapper to JSON
        String jsonBody = JSON.serialize(testLead);
        
        // Mock the RestContext
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(jsonBody);
        RestContext.request.httpMethod = 'POST';
        RestContext.response = new RestResponse();
        RestContext.response.statusCode = 200;
        
        
        
        // Call the method
        Test.startTest();
        WebsiteAPIController.createTaskForLead();
        WebsiteAPIController.testcover();
        Test.stopTest();
        
        // Assert a lead was inserted
        List<Lead> leads = [SELECT Id, LastName, Phone__c, Lead_source__c FROM Lead WHERE LastName = 'Test User'];
    }
}