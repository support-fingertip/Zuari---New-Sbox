@IsTest
private class AnnouncementList_MobileAPI_Test {

    @IsTest
    static void test_getAnnouncements_FullSuccess() {
        // 1. Create Unique Sample Data
        String seed = String.valueOf(System.now().getTime());
        
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfFieldExists(cp, 'Email__c', 'cp' + seed + '@test.com');
        insert cp;
        
        // Re-query for auto-populated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 2. Create Lead linked to CP (Satisfies the API's check for "No Lead Found")
        Lead l = new Lead(LastName = 'L' + seed, Company = 'C' + seed);
        setIfFieldExists(l, 'Channel_Partner__c', cp.Id);
        insert l;

        // 3. Create Announcement
        Announcement__c a = new Announcement__c();
        setIfFieldExists(a, 'Title__c', 'Promo ' + seed);
        setIfFieldExists(a, 'Posted_Date__c', Date.today());
        insert a;

        // 4. Call method with real dynamic userId
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'pageSize' => 0
        };

        Test.startTest();
        mockRestRequest(JSON.serialize(payload));
        AnnouncementList_MobileAPI.getAllSiteVisitDetail();
        Test.stopTest();
    }

    @IsTest
    static void test_errorAndCatchPaths() {
        // Validation Branch (Blank userId)
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        AnnouncementList_MobileAPI.getAllSiteVisitDetail();
        
        // User Not Found Branch
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => 'fake_user_id'}));
        AnnouncementList_MobileAPI.getAllSiteVisitDetail();

        // Catch Block (Malformed JSON)
        Test.startTest();
        mockRestRequest('{ "userId": "missing_bracket" '); 
        AnnouncementList_MobileAPI.getAllSiteVisitDetail();
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AnnouncementListAPI/';
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