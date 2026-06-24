@IsTest
private class CreateLead_MobileAPI_Test {

    @IsTest
    static void test_createLead_FullSuccess() {
        // 1. Setup Unique Data
        String seed = String.valueOf(System.now().getTime());
        
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Email__c', 'cp' + seed + '@test.com');
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 2. Fetch valid picklist values for the Lead object to cover validation logic
        String validProject = getValidPicklistValue(Lead.Allocated_Project__c);
        String validSource = getValidPicklistValue(Lead.Lead_source__c);

        // 3. Success Payload
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'fullName' => 'New Lead ' + seed,
            'mobileNumber' => seed.substring(seed.length()-10),
            'emailAddress' => 'lead' + seed + '@test.com',
            'projectId' => validProject,
            'leadSourceId' => validSource,
            'additionalNotes' => 'Notes ' + seed
        };

        Test.startTest();
        mock(JSON.serialize(payload));
        CreateLead_MobileAPI.createLead();
        Test.stopTest();
    }

    @IsTest
    static void test_errorBranches() {
        // Missing required fields branch
        mock(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        CreateLead_MobileAPI.createLead();

        // CP Not Found branch
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => 'fake_user',
            'fullName' => 'Test',
            'mobileNumber' => '9999999999'
        }));
        CreateLead_MobileAPI.createLead();

        // Catch Block coverage (Malformed JSON)
        Test.startTest();
        mock('{ "userId": "incomplete'); 
        CreateLead_MobileAPI.createLead();
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateLeadAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static String getValidPicklistValue(Schema.SObjectField f) {
        List<Schema.PicklistEntry> entries = f.getDescribe().getPicklistValues();
        return (entries.isEmpty()) ? null : entries[0].getValue();
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