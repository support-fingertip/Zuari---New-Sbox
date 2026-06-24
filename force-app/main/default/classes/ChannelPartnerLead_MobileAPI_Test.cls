@IsTest
private class ChannelPartnerLead_MobileAPI_Test {

    @IsTest
    static void test_getLeadData_Success() {
        // 1. Create Unique Sample Data
        String seed = String.valueOf(System.now().getTime());
        
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfFieldExists(cp, 'Email__c', 'cp' + seed + '@test.com');
        insert cp;
        
        // Re-query for auto-populated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 2. Create Lead linked to CP
        Lead l = new Lead(LastName = 'L' + seed, Company = 'C' + seed);
        setIfFieldExists(l, 'Channel_Partner__c', cp.Id);
        insert l;

        // 3. Call method with real dynamic userId
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c
        };

        Test.startTest();
        mockRestRequest(JSON.serialize(payload));
        ChannelPartnerLead_MobileAPI.getLeadData();
        Test.stopTest();
    }

    @IsTest
    static void test_errorAndCatchPaths() {
        // Test 1: Empty userId validation
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        ChannelPartnerLead_MobileAPI.getLeadData();
        
        // Test 2: Fake userId (No CP found)
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => 'fake_id'}));
        ChannelPartnerLead_MobileAPI.getLeadData();

        // Test 3: Catch block via malformed JSON
        Test.startTest();
        mockRestRequest('{ "userId": "missing_bracket" '); 
        ChannelPartnerLead_MobileAPI.getLeadData();
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/ChannelPartnerLeadAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfFieldExists(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable()) {
            sob.put(field, val);
        }
    }

  
}