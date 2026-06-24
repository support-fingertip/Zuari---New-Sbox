@IsTest
private class AddCallHistory_MobileAPI_Test {

    private static Integer counter = 0;

    private static Channel_Partner__c createActiveCP() {
        counter++;
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        Map<String, Schema.SObjectField> fm = Channel_Partner__c.SObjectType.getDescribe().fields.getMap();
        if (fm.containsKey('Email__c') && fm.get('Email__c').getDescribe().isCreateable())
            cp.put('Email__c', 'callhist' + System.now().getTime() + counter + '@test.com');
        if (fm.containsKey('User_Id__c') && fm.get('User_Id__c').getDescribe().isCreateable())
            cp.put('User_Id__c', 'UID-CALL-' + System.now().getTime() + counter);
        insert cp;
        Channel_Partner__c result = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertNotEquals(null, result.User_Id__c, 'User_Id__c must be populated');
        return result;
    }

    private static String getPickVal(Schema.SObjectType objType, String fieldName) {
        Map<String, Schema.SObjectField> fm = objType.getDescribe().fields.getMap();
        if (!fm.containsKey(fieldName)) return 'Default';
        List<Schema.PicklistEntry> entries = fm.get(fieldName).getDescribe().getPicklistValues();
        for (Schema.PicklistEntry pe : entries) {
            if (pe.isActive()) return pe.getValue();
        }
        return 'Default';
    }

    private static void setField(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable())
            sob.put(field, val);
    }

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AddCallHistoryAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void test_successPath() {
        Lead l = new Lead(LastName = 'CallTest', Company = 'Test Co');
        insert l;
        Channel_Partner__c cp = createActiveCP();
        Related_Source__c rs = new Related_Source__c(SLead__c = l.Id);
        setField(rs, 'Is_Locked__c', false);
        insert rs;
        rs = [SELECT Id, Lead_Id__c FROM Related_Source__c WHERE Id = :rs.Id];
        String typeVal = getPickVal(Call_Detail__c.SObjectType, 'Call_Type__c');
        String statusVal = getPickVal(Call_Detail__c.SObjectType, 'Status__c');
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c, 'leadId' => rs.Lead_Id__c,
            'callDate' => System.now(), 'callTypeId' => typeVal, 'callStatusId' => statusVal,
            'callDuration' => 60, 'description' => 'Test call'
        }));
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_missingAllFields() {
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => '', 'leadId' => '', 'callTypeId' => '', 'callStatusId' => ''
        }));
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_missingLeadId() {
        Channel_Partner__c cp = createActiveCP();
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c, 'leadId' => '',
            'callDate' => System.now(), 'callTypeId' => 'X', 'callStatusId' => 'Y',
            'callDuration' => 10, 'description' => 'test'
        }));
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_missingCallDate() {
        Channel_Partner__c cp = createActiveCP();
        String typeVal = getPickVal(Call_Detail__c.SObjectType, 'Call_Type__c');
        String statusVal = getPickVal(Call_Detail__c.SObjectType, 'Status__c');
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c, 'leadId' => 'LD-001',
            'callTypeId' => typeVal, 'callStatusId' => statusVal,
            'callDuration' => 10, 'description' => 'test'
        }));
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_missingCallStatus() {
        Channel_Partner__c cp = createActiveCP();
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c, 'leadId' => 'LD-001',
            'callDate' => System.now(), 'callTypeId' => 'Inbound', 'callStatusId' => '',
            'callDuration' => 10, 'description' => 'test'
        }));
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_cpNotFound() {
        String typeVal = getPickVal(Call_Detail__c.SObjectType, 'Call_Type__c');
        String statusVal = getPickVal(Call_Detail__c.SObjectType, 'Status__c');
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => 'FAKE-USER-999', 'leadId' => 'FAKE-LEAD',
            'callDate' => System.now(), 'callTypeId' => typeVal, 'callStatusId' => statusVal,
            'callDuration' => 30, 'description' => 'test'
        }));
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_relatedSourceNotFound() {
        Channel_Partner__c cp = createActiveCP();
        String typeVal = getPickVal(Call_Detail__c.SObjectType, 'Call_Type__c');
        String statusVal = getPickVal(Call_Detail__c.SObjectType, 'Status__c');
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c, 'leadId' => 'NONEXISTENT-LEAD-ID',
            'callDate' => System.now(), 'callTypeId' => typeVal, 'callStatusId' => statusVal,
            'callDuration' => 30, 'description' => 'test'
        }));
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_relatedSourceLocked() {
        Lead l = new Lead(LastName = 'LockedTest', Company = 'Test Co');
        insert l;
        Channel_Partner__c cp = createActiveCP();
        Related_Source__c rs = new Related_Source__c(SLead__c = l.Id);
        setField(rs, 'Is_Locked__c', true);
        insert rs;
        rs = [SELECT Id, Lead_Id__c FROM Related_Source__c WHERE Id = :rs.Id];
        String typeVal = getPickVal(Call_Detail__c.SObjectType, 'Call_Type__c');
        String statusVal = getPickVal(Call_Detail__c.SObjectType, 'Status__c');
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => cp.User_Id__c, 'leadId' => rs.Lead_Id__c,
            'callDate' => System.now(), 'callTypeId' => typeVal, 'callStatusId' => statusVal,
            'callDuration' => 45, 'description' => 'Locked source'
        }));
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_malformedJson() {
        mock('{ broken json');
        Test.startTest();
        AddCallHistory_MobileAPI.addCallHistory();
        Test.stopTest();
    }

    @IsTest
    static void test_wrappers() {
        AddCallHistory_MobileAPI.AddCallWrapper aw = new AddCallHistory_MobileAPI.AddCallWrapper();
        aw.userId = 'u1'; aw.leadId = 'l1'; aw.callDate = System.now();
        aw.callTypeId = 'Inbound'; aw.callStatusId = 'ANSWER';
        aw.callDuration = 120; aw.description = 'desc';
        AddCallHistory_MobileAPI.ResponseWrapper rw = new AddCallHistory_MobileAPI.ResponseWrapper(true, 'ok');
        System.assertEquals(true, rw.status);
        System.assertEquals('ok', rw.message);
    }
}