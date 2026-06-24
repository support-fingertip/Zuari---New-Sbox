@isTest
private class VerifyOTP_MobileAPI_Test {

    @isTest
    static void test_verifyOTP_FullCoverage() {
        // 1. SETUP: Unique Seed to prevent Duplicate Errors
        String seed = String.valueOf(System.now().getTime()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        String dynamicMobile = seed.substring(seed.length() - 10);
        String dynamicOtp = seed.substring(0, 4);

        // 2. SETUP: Dynamic Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Name', 'CP' + seed.substring(0,5));
        setIfWriteable(cp, 'Email__c', 'otp' + seed + '@test.com');
        setIfWriteable(cp, 'Mobile_Number__c', dynamicMobile);
        
        // Handles OTP field regardless of it being Number or Text
        setSafeOTP(cp, 'OTP_Number__c', dynamicOtp);
        insert cp;

        Test.startTest();
        
        // Path A: SUCCESS (Hits main validation and update logic)
        Map<String, Object> successMap = new Map<String, Object>{
            'mobileNumber' => dynamicMobile,
            'otp' => dynamicOtp
        };
        mock(JSON.serialize(successMap));
        VerifyOTP_MobileAPI.verifyOTPMethod();

        // Path B: INVALID OTP
        Map<String, Object> invalidOtpMap = new Map<String, Object>{
            'mobileNumber' => dynamicMobile,
            'otp' => '0000'
        };
        mock(JSON.serialize(invalidOtpMap));
        VerifyOTP_MobileAPI.verifyOTPMethod();

        // Path C: VALIDATIONS (Blank inputs)
        mock(JSON.serialize(new Map<String, Object>{ 'mobileNumber' => '', 'otp' => '' }));
        VerifyOTP_MobileAPI.verifyOTPMethod();

        // Path D: EXCEPTIONS (Malformed JSON for Catch block)
        mock('{ "mobileNumber": "broken'); 
        VerifyOTP_MobileAPI.verifyOTPMethod();
        
        Test.stopTest();
        
        System.debug('Verify OTP Coverage Flow Complete');
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/VerifyOTPAPI/';
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

    private static void setSafeOTP(SObject sob, String field, String val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(field)) return;
        Schema.DescribeFieldResult d = fm.get(field).getDescribe();
        if (d.getType() == Schema.DisplayType.Integer || d.getType() == Schema.DisplayType.Double) {
            sob.put(field, Decimal.valueOf(val));
        } else {
            sob.put(field, val);
        }
    }
}