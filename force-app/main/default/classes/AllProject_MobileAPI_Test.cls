@IsTest
private class AllProject_MobileAPI_Test {

    @IsTest
    static void test_getAllProjects_Success() {
        // Create Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfFieldExists(cp, 'Email__c', 'projecttest@example.com');
        insert cp;
        
        // Re-query for auto-populated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // Create Project Record
        Project__c p = new Project__c(Active__c = true);
        setIfFieldExists(p, 'Name', 'Project Dynamic');
        setIfFieldExists(p, 'City1__c', 'Bangalore');
        setIfFieldExists(p, 'Project_Status__c', 'Active');
        insert p;

        // Payload using real dynamic userId and filter values
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'search' => 'Dynamic',
            'cityId' => 'Bangalore',
            'projectStatusId' => 'Active',
            'pageSize' => 0
        };

        Test.startTest();
        mockRestRequest(JSON.serialize(payload));
        AllProject_MobileAPI.getAllprojectDetail();
        Test.stopTest();
    }

    @IsTest
    static void test_errorAndCatchPaths() {
        // Test 1: Empty userId triggers validation error
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        AllProject_MobileAPI.getAllprojectDetail();
        
        // Test 2: Fake userId triggers User Not Found
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => 'fake_user'}));
        AllProject_MobileAPI.getAllprojectDetail();

        // Test 3: Invalid JSON to trigger the catch block
        Test.startTest();
        mockRestRequest('{ "userId": "missing_bracket" '); 
        AllProject_MobileAPI.getAllprojectDetail();
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AllProjectAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfFieldExists(SObject sob, String field, Object val) {
        if (sob.getSObjectType().getDescribe().fields.getMap().containsKey(field)) {
            sob.put(field, val);
        }
    }
}