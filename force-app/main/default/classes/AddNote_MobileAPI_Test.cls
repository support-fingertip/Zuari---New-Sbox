@IsTest
private class AddNote_MobileAPI_Test {

    @IsTest
    static void test_addNote_Success() {
        // Create Lead
        Lead l = new Lead(LastName = 'Test', Company = 'Test Co');
        insert l;

        // Create Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfFieldExists(cp, 'Email__c', 'test@example.com');
        insert cp;
        
        // Re-query to get the auto-generated User_Id__c or the Record Id
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // Create Related Source
        Related_Source__c rs = new Related_Source__c(SLead__c = l.Id);
        insert rs;
        
        // Re-query to get the auto-generated Lead_Id__c
        rs = [SELECT Id, Lead_Id__c FROM Related_Source__c WHERE Id = :rs.Id];

        // Use real IDs from the records above
        Map<String, Object> data = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'leadId' => rs.Lead_Id__c,
            'scheduleDate' => System.now(),
            'title' => 'Test Note',
            'notes' => 'Test Body'
        };

        Test.startTest();
        mockRestRequest(JSON.serialize(data));
        AddNote_MobileAPI.addNote();
        Test.stopTest();
    }

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AddNoteAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfFieldExists(SObject sob, String field, Object val) {
        if (sob.getSObjectType().getDescribe().fields.getMap().containsKey(field)) {
            sob.put(field, val);
        }
    }
}