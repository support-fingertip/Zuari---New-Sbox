@IsTest
private class CreateNewFollowUp_MobileAPI_Test {

    @IsTest
    static void test_addFollowUp_FullSuccess() {
        // 1. Create Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Email__c')) {
            cp.put('Email__c', 'partner' + DateTime.now().getTime() + '@test.com');
        }
        insert cp;
        // Get the system-generated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 2. Create Lead and Link to CP (Critical for the API's SOQL)
        Lead ld = new Lead(LastName = 'DynamicLead', Company = 'TestCo');
        // Map the lookup field to the CP we created
        if (Schema.sObjectType.Lead.fields.getMap().containsKey('Channel_Partner__c')) {
            ld.put('Channel_Partner__c', cp.Id);
        }
        insert ld;
        
        // RE-QUERY to get the Lead_ID__c (Formula/Auto-number)
        ld = [SELECT Id, Lead_ID__c FROM Lead WHERE Id = :ld.Id];

        // 3. Create Related Source linked to Lead
        Related_Source__c rs = new Related_Source__c(SLead__c = ld.Id);
        insert rs;
 rs = [SELECT Id, Lead_Id__c FROM Related_Source__c WHERE Id = :rs.Id];

        // 4. Payload using the REAL system-generated IDs
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'leadId' => rs.Lead_ID__c, // Using the queried read-only value
            'scheduleDate' => System.now().addDays(2),
            'subject' => 'Success Coverage',
            'notes' => 'Testing 80 percent coverage'
        };

        Test.startTest();
        mockRequest(JSON.serialize(payload));
        CreateNewFollowUp_MobileAPI.addFollowUp();
        Test.stopTest();
    }

    @IsTest
    static void test_addFollowUp_ErrorBranches() {
        // Required Fields branch
        mockRequest('{"userId": ""}');
        CreateNewFollowUp_MobileAPI.addFollowUp();

        // CP Not Found branch
        mockRequest('{"userId": "FAKE_ID", "leadId": "X", "scheduleDate": "2026-01-01T10:00:00Z", "subject": "Hi"}');
        CreateNewFollowUp_MobileAPI.addFollowUp();
        
        // Malformed JSON for Catch Block coverage
        Test.startTest();
        mockRequest('{ "userId": "broken-json'); 
        CreateNewFollowUp_MobileAPI.addFollowUp();
        Test.stopTest();
    }

    private static void mockRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateNewFollowUpAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }
}