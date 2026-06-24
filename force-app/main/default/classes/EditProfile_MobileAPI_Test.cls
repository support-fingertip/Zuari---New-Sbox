@IsTest
private class EditProfile_MobileAPI_Test {

    @IsTest
    static void test_editProfile_FullCoverage() {
        String seed = String.valueOf(System.now().getTime());
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        
        setIfWriteable(cp, 'Email__c', 'old' + seed + '@test.com');
        insert cp;

        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'fullName' => 'New Name ' + seed,
            'email' => 'new' + seed + '@test.com',
            'address' => 'New Address ' + seed,
            'tlName' => 'TL Name',
            'tlPhoneNumber' => '9000000000',
            'rmName' => 'RM Name',
            'rmPhoneNumber' => '9000000001'
        };

        Test.startTest();
        // 1. Success Path
        mock(JSON.serialize(payload));
        EditProfile_MobileAPI.editProfile();

        // 2. Missing Fields Path
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '' }));
        EditProfile_MobileAPI.editProfile();

        // 3. User Not Found Path
        payload.put('userId', 'FAKE-' + seed);
        mock(JSON.serialize(payload));
        EditProfile_MobileAPI.editProfile();

        // 4. Exception Path (Catch Block)
        mock('{ "userId": "broken-json'); 
        EditProfile_MobileAPI.editProfile();
        Test.stopTest();
    }

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/EditProfileAPI/';
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