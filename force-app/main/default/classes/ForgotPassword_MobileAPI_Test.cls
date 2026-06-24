@IsTest
private class ForgotPassword_MobileAPI_Test {

    @IsTest
    static void test_changePassword_FullCoverage() {
        String seed = String.valueOf(System.now().getTime());
        String phone = seed.substring(seed.length() - 10);

        // 1. SETUP: Create Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Name', 'Test CP ' + seed);
        setIfWriteable(cp, 'Mobile_Number__c', phone);
        setIfWriteable(cp, 'Email__c', 'forgot' + seed + '@test.com');
        insert cp;

        Test.startTest();
        // 2. Success Path (OTP Sent)
        mock(JSON.serialize(new Map<String, Object>{ 'mobileNumber' => phone }));
        ForgotPassword_MobileAPI.changePasswordMethod();

        // 3. Validation Path (Missing Phone)
        mock(JSON.serialize(new Map<String, Object>{ 'mobileNumber' => '' }));
        ForgotPassword_MobileAPI.changePasswordMethod();

        // 4. User Not Found Path
        mock(JSON.serialize(new Map<String, Object>{ 'mobileNumber' => '0000000000' }));
        ForgotPassword_MobileAPI.changePasswordMethod();

        // 5. Exception Path (Catch Block)
        mock('{ "mobileNumber": "broken-json'); 
        ForgotPassword_MobileAPI.changePasswordMethod();
        Test.stopTest();
    }

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/ForgotPasswordAPI/';
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