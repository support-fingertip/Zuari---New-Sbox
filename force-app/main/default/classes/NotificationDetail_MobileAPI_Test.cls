@IsTest
private class NotificationDetail_MobileAPI_Test {

    @IsTest
    static void test_getNotifications_FullCoverage() {
        // 1. SETUP: Dynamic Unique Data
        String seed = String.valueOf(System.now().getTime()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Email__c', 'notif' + seed + '@test.com');
        insert cp;
        
        // Re-query for auto-populated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        Notification__c n = new Notification__c(IsActive__c = true);
        setIfWriteable(n, 'Channel_Partner__c', cp.Id);
        setIfWriteable(n, 'Notification_Heading__c', 'Heading ' + seed);
        setIfWriteable(n, 'Notification_Type__c', 'Lead Notification');
        insert n;
        
        // Create Subscriber (Required for the isRead logic in your API)
        insert new Notification_Subscriber__c(
            Channel_Partner__c = cp.Id,
            Notification__c = n.Id,
            isRead__c = false
        );

        // ---------------------------------------------------------
        // EXECUTION PATHS
        // ---------------------------------------------------------
        Test.startTest();
        
        // Path A: SUCCESS (Hits main query and wrapper mapping)
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'pageSize' => 5
        };
        mock(JSON.serialize(payload));
        NotificationDetail_MobileAPI.getNotifications();

        // Path B: VALIDATIONS (Missing userId)
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '' }));
        NotificationDetail_MobileAPI.getNotifications();

        // Path C: NOT FOUND (Triggers the catch or empty return)
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => 'FAKE-ID' }));
        NotificationDetail_MobileAPI.getNotifications();

        // Path D: EXCEPTIONS (Catch Block via malformed JSON)
        mock('{ "userId": "broken'); 
        NotificationDetail_MobileAPI.getNotifications();
        
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/NotificationDetailAPI/';
        req.httpMethod = 'POST';
        req.requestBody = (body == null) ? null : Blob.valueOf(body);
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