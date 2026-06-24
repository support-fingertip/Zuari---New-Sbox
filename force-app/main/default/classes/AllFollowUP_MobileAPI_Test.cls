@IsTest
private class AllFollowUP_MobileAPI_Test {

    @IsTest
    static void test_getAllFollowups_Success() {
        // Create Required Sample Data
        Lead l = new Lead(LastName = 'FollowupTest', Company = 'Test Co');
        insert l;

        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfFieldExists(cp, 'Email__c', 'testcp@example.com');
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        Related_Source__c rs = new Related_Source__c(
            SLead__c = l.Id, 
            Channel_Partner1__c = cp.Id, 
            Is_Locked__c = false
        );
        insert rs;

        // FIXED: Using .addDays(1) to bypass "Please select future date" validation
        Follow_up__c fu = new Follow_up__c(
            SLead__c = l.Id,
            Related_Source__c = rs.Id,
            Scheduled_Date__c = System.now().addDays(1), 
            Subject__c = 'Dynamic Subject'
        );
        insert fu;

        // Use all payload keys to cover every conditional 'if' branch in the class
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'search' => 'Dynamic',
            'leadStatus' => 'Open',
            'projectName' => 'Test Project',
            'fromScheduleDate' => System.now().addDays(-1),
            'toScheduleDate' => System.now().addDays(5),
            'fromCompletedDate' => System.now().addDays(-1),
            'toCompletedDate' => System.now().addDays(5),
            'pageSize' => 1
        };

        Test.startTest();
        mockRestRequest(JSON.serialize(payload));
        AllFollowUP_MobileAPI.getAllSiteVisitDetail();
        Test.stopTest();
    }

    @IsTest
    static void test_errorAndCatchPaths() {
        // Covers 'userId is required' branch
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        AllFollowUP_MobileAPI.getAllSiteVisitDetail();
        
        // Covers 'User Not Found' branch
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => 'fake_user_id'}));
        AllFollowUP_MobileAPI.getAllSiteVisitDetail();

        // Covers Catch Block by sending malformed JSON
        Test.startTest();
        mockRestRequest('{ "userId": "incomplete-json" '); 
        AllFollowUP_MobileAPI.getAllSiteVisitDetail();
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AllFollowUpAPI/';
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