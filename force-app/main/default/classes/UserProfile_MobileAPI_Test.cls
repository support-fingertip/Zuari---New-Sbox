@isTest
private class UserProfile_MobileAPI_Test {

    private static String seed = String.valueOf(System.now().getTime()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));
    
    private static void setIfWriteable(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable()) {
            sob.put(field, val);
        }
    }
    
    @isTest static void test_getUserProfile_FullCoverage() {
        Test.startTest();
        
        //  FORCE Email__c (REQUIRED FIELD WORKAROUND)
        Channel_Partner__c cp = new Channel_Partner__c();
        
        // CRITICAL: Direct assignment for REQUIRED fields FIRST
        try {
            cp.Email__c = 'cp_' + seed + '@test.com';  // Direct set before setIfWriteable
        } catch(Exception e) {
            cp.put('Email__c', 'cp_' + seed + '@test.com');  // Fallback
        }
        
        // Schema-safe fields AFTER required fields
        cp.Active__c = true;
        setIfWriteable(cp, 'Name', 'CP_' + seed.substring(0,8));
        setIfWriteable(cp, 'Mobile_Number__c', '9' + seed.substring(seed.length()-10));
        setIfWriteable(cp, 'PAN__c', 'TEST' + seed.substring(0,6));
        setIfWriteable(cp, 'GST__c', '27TEST' + seed.substring(0,10));
        setIfWriteable(cp, 'Account_Number__c', seed.substring(0,10));
        setIfWriteable(cp, 'Bank_Name__c', 'Dynamic Bank');
        setIfWriteable(cp, 'IFSC_CODE__c', 'TEST' + seed.substring(0,6));
        setIfWriteable(cp, 'Company_Address__c', 'Test Address');
        setIfWriteable(cp, 'Bank_Address__c', 'Test Bank Address');
        setIfWriteable(cp, 'Team_Leader1__c', 'TL_' + seed);
        setIfWriteable(cp, 'Team_Leader_Mobile__c', '9' + seed.substring(0,9));
        setIfWriteable(cp, 'Regional_Manager1__c', 'RM_' + seed);
        setIfWriteable(cp, 'Regional_Manager_Mobile__c', '9' + seed.substring(1,10));
        
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        
        // 7 EXECUTION PATHS
        if(cp.User_Id__c != null) {
            mock(JSON.serialize(new Map<String, Object>{'userId' => cp.User_Id__c}));
            UserProfile_MobileAPI.getUserProfile();
        }
        
        mock(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        UserProfile_MobileAPI.getUserProfile();
        
        mock('{ "userId": "broken');
        UserProfile_MobileAPI.getUserProfile();
        
        RestContext.request.requestBody = null;
        UserProfile_MobileAPI.getUserProfile();
        
        // Inactive CP
        Channel_Partner__c inactiveCP = new Channel_Partner__c();
        try { inactiveCP.Email__c = 'inactive_' + seed + '@test.com'; } 
        catch(Exception e) { inactiveCP.put('Email__c', 'inactive_' + seed + '@test.com'); }
        inactiveCP.Active__c = false;
        setIfWriteable(inactiveCP, 'Name', 'Inactive_' + seed);
        insert inactiveCP;
        inactiveCP = [SELECT User_Id__c FROM Channel_Partner__c WHERE Id = :inactiveCP.Id];
        if(inactiveCP.User_Id__c != null) {
            mock(JSON.serialize(new Map<String, Object>{'userId' => inactiveCP.User_Id__c}));
            UserProfile_MobileAPI.getUserProfile();
        }
        
        mock('');
        UserProfile_MobileAPI.getUserProfile();
        
        Test.stopTest();
    }

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UserProfileAPI/';
        req.httpMethod = 'POST';
        req.requestBody = (body == null) ? null : Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }
}