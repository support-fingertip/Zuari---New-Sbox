@isTest
private class Rewards_MobileAPI_Test {
    
    private static String seed = String.valueOf(System.now().getTime());
    
    private static void setIfWriteable(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable()) {
            sob.put(field, val);
        }
    }
    
    private static Channel_Partner__c createPartner(Integer bookings, Boolean topPerformer) {
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true, Top_Perfomer__c = topPerformer);
        setIfWriteable(cp, 'Name', 'CP_' + seed + '_' + bookings);
        setIfWriteable(cp, 'Email__c', 'test_' + seed + '_' + bookings + '@test.com');
        setIfWriteable(cp, 'No_of_Booking__c', bookings);
        setIfWriteable(cp, 'Description__c', 'Test performer ' + bookings);
        insert cp;
        return [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];
    }
    
    private static void mockRequest(Object payload) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/Rewards/';
        RestContext.request = req;
        RestContext.response = res;
    }
    
    @isTest static void testFullCoverage() {
        Test.startTest();
        
        // Create test data dynamically
        List<Channel_Partner__c> topPerformers = new List<Channel_Partner__c>();
        for(Integer i = 20; i >= 16; i--) {
            topPerformers.add(createPartner(i, true));
        }
        List<Channel_Partner__c> regulars = new List<Channel_Partner__c>();
        for(Integer i = 5; i >= 1; i--) {
            regulars.add(createPartner(i, false));
        }
        Channel_Partner__c testUser = createPartner(10, false);
        
        // Path A: SUCCESS - Valid user, get top performers
        mockRequest(new Map<String, Object>{
            'userId' => testUser.User_Id__c,
            'pageSize' => 5
        });
        Rewards_MobileAPI.getTopPerformerDetail();
        
        // Path B: EMPTY pageSize (0)
        mockRequest(new Map<String, Object>{
            'userId' => testUser.User_Id__c,
            'pageSize' => 0
        });
        Rewards_MobileAPI.getTopPerformerDetail();
        
        // Path C: NULL pageSize (missing field)
        mockRequest(new Map<String, Object>{
            'userId' => testUser.User_Id__c
        });
        Rewards_MobileAPI.getTopPerformerDetail();
        
        // Path D: INVALID USER
        mockRequest(new Map<String, Object>{
            'userId' => 'FAKE_USER_ID',
            'pageSize' => 5
        });
        Rewards_MobileAPI.getTopPerformerDetail();
        
        // Path E: INACTIVE USER
        Channel_Partner__c inactiveUser = createPartner(8, false);
        inactiveUser.Active__c = false; 
        update inactiveUser;
        mockRequest(new Map<String, Object>{
            'userId' => inactiveUser.User_Id__c,
            'pageSize' => 5
        });
        Rewards_MobileAPI.getTopPerformerDetail();
        
        // Path F: NO TOP PERFORMERS
        List<Channel_Partner__c> allTop = new List<Channel_Partner__c>(topPerformers);
        for(Channel_Partner__c tp : allTop) {
            tp.Top_Perfomer__c = false; 
            update tp;
        }
        mockRequest(new Map<String, Object>{
            'userId' => testUser.User_Id__c,
            'pageSize' => 5
        });
        Rewards_MobileAPI.getTopPerformerDetail();
        
        // Path G: MALFORMED JSON (Exception handling)
        RestContext.request.requestBody = Blob.valueOf('{malformed');
        Rewards_MobileAPI.getTopPerformerDetail();
        
        // Path H: EMPTY REQUEST BODY
        RestContext.request.requestBody = Blob.valueOf('');
        Rewards_MobileAPI.getTopPerformerDetail();
        
        Test.stopTest();
    }
    
    @isTest static void testPerfomerWrapper() {
        Test.startTest();
        
        // Test perfomerWrapper instantiation and field assignment
        Rewards_MobileAPI.perfomerWrapper req = new Rewards_MobileAPI.perfomerWrapper();
        req.userId = 'test-user-id';
        req.pageSize = 10;
        
        Test.stopTest();
    }
}