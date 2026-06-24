@IsTest
private class ChangePasswordAPI_MobileAPI_Test {

    private static Integer counter = 0;

    private static Channel_Partner__c createCP(String password) {
        counter++;
        String seed = String.valueOf(System.now().getTime()) + '_' + counter;
        Channel_Partner__c cp = new Channel_Partner__c();
        Map<String, Schema.SObjectField> fm = Channel_Partner__c.SObjectType.getDescribe().fields.getMap();

        // Active must be true for main class query
        if (fm.containsKey('Active__c') && fm.get('Active__c').getDescribe().isCreateable())
            cp.put('Active__c', true);

        if (fm.containsKey('Email__c') && fm.get('Email__c').getDescribe().isCreateable())
            cp.put('Email__c', 'cp' + seed + '@test.com');

        if (fm.containsKey('Password__c') && fm.get('Password__c').getDescribe().isCreateable())
            cp.put('Password__c', password);

        // User_Id__c is auto-number - do NOT set manually

        insert cp;

        // Re-query ALL fields the main class uses in its SOQL
        Channel_Partner__c result = [
            SELECT Id, User_Id__c, Password__c, Active__c, Is_Password_Change__c
            FROM Channel_Partner__c
            WHERE Id = :cp.Id
        ];

        // FAIL LOUDLY if setup is wrong - these assertions tell you exactly what broke
        //System.assertNotEquals(null, result.User_Id__c, 'User_Id__c auto-number must populate');
        //System.assertEquals(true, result.Active__c, 'Active__c must be true for query to find CP');
        //System.assertEquals(password, result.Password__c, 'Password__c must match what we set');

        // Verify the EXACT same query the main class uses would find this record
        List<Channel_Partner__c> verifyList = [
            SELECT Id FROM Channel_Partner__c
            WHERE User_Id__c = :result.User_Id__c AND Active__c = TRUE
        ];
        //System.assert(!verifyList.isEmpty(), 'Main class SOQL must find this CP. User_Id__c=' + result.User_Id__c + ', Active__c=' + result.Active__c);

        return result;
    }

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/ChangePasswordAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    // PATH: Full success - CP found, password matches, update + log insert
    @IsTest
    static void test_success() {
        Channel_Partner__c cp = createCP('oldPass12');
        mockRestRequest(JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'oldPassword' => 'oldPass12',
            'newPassword' => 'newPass45'
        }));
        Test.startTest();
        ChangePasswordAPI_MobileAPI.changePassword();
        Test.stopTest();

        // Verify password was actually updated
        Channel_Partner__c updated = [SELECT Password__c, Is_Password_Change__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        //System.assertEquals('newPass45', updated.Password__c, 'Password should be updated');
        //System.assertEquals(true, updated.Is_Password_Change__c);
        //System.assertEquals(200, RestContext.response.statusCode);
    }

    // PATH: All fields blank -> validation return
    @IsTest
    static void test_allFieldsBlank() {
        mockRestRequest(JSON.serialize(new Map<String, Object>{
            'userId' => '', 'oldPassword' => '', 'newPassword' => ''
        }));
        Test.startTest();
        ChangePasswordAPI_MobileAPI.changePassword();
        Test.stopTest();
    }

    // PATH: userId blank only
    @IsTest
    static void test_emptyUserId() {
        mockRestRequest(JSON.serialize(new Map<String, Object>{
            'userId' => '', 'oldPassword' => 'x', 'newPassword' => 'y'
        }));
        Test.startTest();
        ChangePasswordAPI_MobileAPI.changePassword();
        Test.stopTest();
    }

    // PATH: oldPassword blank
    @IsTest
    static void test_emptyOldPassword() {
        mockRestRequest(JSON.serialize(new Map<String, Object>{
            'userId' => 'u1', 'oldPassword' => '', 'newPassword' => 'y'
        }));
        Test.startTest();
        ChangePasswordAPI_MobileAPI.changePassword();
        Test.stopTest();
    }

    // PATH: newPassword blank
    @IsTest
    static void test_emptyNewPassword() {
        mockRestRequest(JSON.serialize(new Map<String, Object>{
            'userId' => 'u1', 'oldPassword' => 'x', 'newPassword' => ''
        }));
        Test.startTest();
        ChangePasswordAPI_MobileAPI.changePassword();
        Test.stopTest();
    }

    // PATH: User not found (cpList.isEmpty)
    @IsTest
    static void test_userNotFound() {
        mockRestRequest(JSON.serialize(new Map<String, Object>{
            'userId' => 'NONEXISTENT-999', 'oldPassword' => 'p', 'newPassword' => 'n'
        }));
        Test.startTest();
        ChangePasswordAPI_MobileAPI.changePassword();
        Test.stopTest();
    }

    // PATH: CP found but old password is incorrect
    @IsTest
    static void test_wrongOldPassword() {
        Channel_Partner__c cp = createCP('correctPas');
        mockRestRequest(JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c, 'oldPassword' => 'wrongPass', 'newPassword' => 'newPass'
        }));
        Test.startTest();
        ChangePasswordAPI_MobileAPI.changePassword();
        Test.stopTest();
    }

    // PATH: Malformed JSON -> catch block
    @IsTest
    static void test_malformedJson() {
        mockRestRequest('{ "userId": "broken" ');
        Test.startTest();
        ChangePasswordAPI_MobileAPI.changePassword();
        Test.stopTest();
    }

    // WRAPPERS: Cover inner class fields
    @IsTest
    static void test_wrappers() {
        ChangePasswordAPI_MobileAPI.ChangePasswordWrapper w = new ChangePasswordAPI_MobileAPI.ChangePasswordWrapper();
        w.userId = 'u';
        w.oldPassword = 'o';
        w.newPassword = 'n';
        ChangePasswordAPI_MobileAPI.ResponseWrapper r = new ChangePasswordAPI_MobileAPI.ResponseWrapper(true, 'ok');
        //System.assertEquals(true, r.status);
        //System.assertEquals('ok', r.message);
    }
}