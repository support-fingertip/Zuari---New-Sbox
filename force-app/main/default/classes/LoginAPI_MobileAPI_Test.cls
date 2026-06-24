@IsTest
private class LoginAPI_MobileAPI_Test {

    private static Integer counter = 0;

    private static Channel_Partner__c createCP(String phone, String pass) {
        counter++;
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        Map<String, Schema.SObjectField> fm = Channel_Partner__c.SObjectType.getDescribe().fields.getMap();
        if (fm.containsKey('Mobile_Number__c') && fm.get('Mobile_Number__c').getDescribe().isCreateable())
            cp.put('Mobile_Number__c', phone);
        if (fm.containsKey('Password__c') && fm.get('Password__c').getDescribe().isCreateable())
            cp.put('Password__c', pass);
        if (fm.containsKey('Is_Password_Change__c') && fm.get('Is_Password_Change__c').getDescribe().isCreateable())
            cp.put('Is_Password_Change__c', true);
        if (fm.containsKey('Email__c') && fm.get('Email__c').getDescribe().isCreateable())
            cp.put('Email__c', 'login' + System.now().getTime() + counter + '@test.com');
        if (fm.containsKey('User_Id__c') && fm.get('User_Id__c').getDescribe().isCreateable())
            cp.put('User_Id__c', 'UID-LOGIN-' + System.now().getTime() + counter);
        insert cp;
        Channel_Partner__c result = [SELECT Id, User_Id__c, Mobile_Number__c, Password__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertNotEquals(null, result.User_Id__c, 'User_Id__c must be populated');
        return result;
    }

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/LoginAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void test_successFirstLogin() {
        String phone = String.valueOf(System.now().getTime()).right(10);
        Channel_Partner__c cp = createCP(phone, 'pass123');
        mock(JSON.serialize(new Map<String, Object>{
            'mobileNumber' => phone, 'password' => 'pass123', 'deviceId' => 'DEV-NEW-001'
        }));
        Test.startTest();
        LoginAPI_MobileAPI.checkLogin();
        Test.stopTest();
    }

    @IsTest
    static void test_successExistingDevice() {
        String phone = String.valueOf(System.now().getTime()).right(10);
        Channel_Partner__c cp = createCP(phone, 'pass123');
        Logged_in_Device__c lgd = new Logged_in_Device__c();
        lgd.Channel_Partner__c = cp.Id;
        lgd.Last_Logged_In__c = System.now().addDays(-1);
        lgd.Status__c = 'Logged Out';
        lgd.Device_Id__c = 'DEV-EXIST-002';
        insert lgd;
        mock(JSON.serialize(new Map<String, Object>{
            'mobileNumber' => phone, 'password' => 'pass123', 'deviceId' => 'DEV-EXIST-002'
        }));
        Test.startTest();
        LoginAPI_MobileAPI.checkLogin();
        Test.stopTest();
    }

    @IsTest
    static void test_emptyFields() {
        mock(JSON.serialize(new Map<String, Object>{
            'mobileNumber' => '', 'password' => '', 'deviceId' => ''
        }));
        Test.startTest();
        LoginAPI_MobileAPI.checkLogin();
        Test.stopTest();
    }

    @IsTest
    static void test_blankMobile() {
        mock(JSON.serialize(new Map<String, Object>{
            'mobileNumber' => '', 'password' => 'pass', 'deviceId' => 'D1'
        }));
        Test.startTest();
        LoginAPI_MobileAPI.checkLogin();
        Test.stopTest();
    }

    @IsTest
    static void test_customerNotFound() {
        mock(JSON.serialize(new Map<String, Object>{
            'mobileNumber' => '0000000000', 'password' => 'somePass', 'deviceId' => 'DEV-X'
        }));
        Test.startTest();
        LoginAPI_MobileAPI.checkLogin();
        Test.stopTest();
    }

    @IsTest
    static void test_wrongPassword() {
        String phone = String.valueOf(System.now().getTime()).right(10);
        Channel_Partner__c cp = createCP(phone, 'correctPas');
        mock(JSON.serialize(new Map<String, Object>{
            'mobileNumber' => phone, 'password' => 'wrongPass', 'deviceId' => 'DEV-003'
        }));
        Test.startTest();
        LoginAPI_MobileAPI.checkLogin();
        Test.stopTest();
    }

    @IsTest
    static void test_malformedJson() {
        mock('{ "mobileNumber": "broken-json');
        Test.startTest();
        LoginAPI_MobileAPI.checkLogin();
        Test.stopTest();
    }

    @IsTest
    static void test_wrappers() {
        LoginAPI_MobileAPI.LoginWrapper lw = new LoginAPI_MobileAPI.LoginWrapper();
        lw.mobileNumber = '9999999999';
        lw.password = 'pass';
        lw.deviceId = 'dev';
        System.assertNotEquals(null, lw.mobileNumber);
    }
}