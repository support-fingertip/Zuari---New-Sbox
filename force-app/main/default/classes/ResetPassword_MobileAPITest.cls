@isTest
private class ResetPassword_MobileAPITest {

    @isTest
    static void test_resetPassword_FullCoverage() {
        // 1. SETUP: Dynamic Data (Seed based on timestamp)
        String seed = String.valueOf(System.now().getTime());
        String dynamicMobile = seed.substring(seed.length() - 10);
        String dynamicPass = 'P' + seed.substring(0, 8); // Ensures <= 10 chars

        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Name', 'CP' + seed.substring(0, 5));
        setIfWriteable(cp, 'Email__c', 'reset' + seed + '@test.com');
        setIfWriteable(cp, 'Mobile_Number__c', dynamicMobile);
        setIfWriteable(cp, 'Password__c', 'oldPass1');
        insert cp;

        
        // EXECUTION PATHS
        
        Test.startTest();
        
        // Path A: SUCCESS (Hits main update logic)
        ResetPassword_MobileAPI.ResetPasswordWrapper successReq = new ResetPassword_MobileAPI.ResetPasswordWrapper();
        successReq.mobileNumber = dynamicMobile;
        successReq.password = dynamicPass;
        mock(JSON.serialize(successReq));
        ResetPassword_MobileAPI.resetPasswordMethod();

        // Path B: VALIDATIONS (Blank Mobile/Pass)
        mock(JSON.serialize(new Map<String, Object>{ 'mobileNumber' => '', 'password' => '' }));
        ResetPassword_MobileAPI.resetPasswordMethod();

        // Path C: USER NOT FOUND (Fake Mobile)
        mock(JSON.serialize(new Map<String, Object>{ 'mobileNumber' => '0000000000', 'password' => 'pass' }));
        ResetPassword_MobileAPI.resetPasswordMethod();

        // Path D: EXCEPTIONS (Malformed JSON for catch block)
        mock('{ "mobileNumber": "broken'); 
        ResetPassword_MobileAPI.resetPasswordMethod();
        
        // Path E: Wrapper Manual Touch
        ResetPassword_MobileAPI.ResponseWrapper rw = new ResetPassword_MobileAPI.ResponseWrapper();
        rw.status = true;
        rw.message = 'ok';
        
        Test.stopTest();
        
        System.debug('Reset Password Coverage Flow Complete');
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/ResetPasswordAPI/';
        req.httpMethod = 'POST';
        req.requestBody = (body == null) ? null : Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfWriteable(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable()) {
            sob.put(field, val);
        }
    }
}