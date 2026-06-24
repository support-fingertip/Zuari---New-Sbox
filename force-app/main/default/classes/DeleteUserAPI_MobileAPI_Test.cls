@IsTest
private class DeleteUserAPI_MobileAPI_Test {

    @IsTest
    static void test_deleteUser_FullCoverage() {
        // 1. Setup Dynamic Data
        String seed = String.valueOf(System.now().getTime());
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        
        // Use helper to set email if field exists
        setIfWriteable(cp, 'Email__c', 'del' + seed + '@test.com');
        insert cp;

        // Re-query for the system-generated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // -----------------------------------------------------------------------
        // PATH A: SUCCESS (Covers Update & Success Log)
        // -----------------------------------------------------------------------
        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => cp.User_Id__c }));
        DeleteUserAPI_MobileAPI.deleteUser();

        // -----------------------------------------------------------------------
        // PATH B: VALIDATION FAILURES (Covers early returns)
        // -----------------------------------------------------------------------
        // Missing userId
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '' }));
        DeleteUserAPI_MobileAPI.deleteUser();

        // User Not Found
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => 'FAKE-' + seed }));
        DeleteUserAPI_MobileAPI.deleteUser();

        // -----------------------------------------------------------------------
        // PATH C: EXCEPTIONS (Covers the Catch Block)
        // -----------------------------------------------------------------------
        // Trigger Deserialization Exception
        mock('{ "userId": "broken-json'); 
        DeleteUserAPI_MobileAPI.deleteUser();
        Test.stopTest();
        
        // Assert Deactivation
        System.assertEquals(false, [SELECT Active__c FROM Channel_Partner__c WHERE Id = :cp.Id].Active__c);
    }

    /* ============================= HELPERS ============================= */
    
    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DeleteUserAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfWriteable(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field)) {
            Schema.DescribeFieldResult d = fm.get(field).getDescribe();
            if (d.isCreateable() || d.isUpdateable()) {
                sob.put(field, val);
            }
        }
    }
}