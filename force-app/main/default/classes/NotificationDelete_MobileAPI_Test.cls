@IsTest
private class NotificationDelete_MobileAPI_Test {

    @IsTest
    static void test_deleteNotification_FullCoverage() {
        // 1. SETUP: Dynamic Data
        String seed = String.valueOf(System.now().getTime()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Email__c', 'notif' + seed + '@test.com');
        insert cp;
        
        // Re-query for auto-populated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        Notification__c notif = new Notification__c();
        setIfWriteable(notif, 'Title__c', 'Alert ' + seed);
        insert notif;
        
        // Re-query for system-generated Name (e.g., NOTIF-001)
        notif = [SELECT Id, Name FROM Notification__c WHERE Id = :notif.Id];

        // Create the Subscriber record (the record actually being deleted)
        Notification_Subscriber__c sub = new Notification_Subscriber__c(
            Channel_Partner__c = cp.Id,
            Notification__c = notif.Id,
            isRead__c = false
        );
        insert sub;

        
        // EXECUTION PATHS
        Test.startTest();
        
        // Path A: SUCCESS (Delete existing notification)
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'notificationId' => new List<String>{ notif.Name }
        };
        mock(JSON.serialize(payload));
        NotificationDelete_MobileAPI.deleteNotification();

        // Path B: VALIDATIONS (Missing Fields / Not Found)
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '' }));
        NotificationDelete_MobileAPI.deleteNotification();

        mock(JSON.serialize(new Map<String, Object>{ 
            'userId' => 'FAKE-ID', 
            'notificationId' => new List<String>{'FAKE-000'} 
        }));
        NotificationDelete_MobileAPI.deleteNotification();

        // Path C: EXCEPTIONS (Catch Block)
        mock('{ "userId": "broken-json'); 
        NotificationDelete_MobileAPI.deleteNotification();
        
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/NotificationDeleteAPI/';
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