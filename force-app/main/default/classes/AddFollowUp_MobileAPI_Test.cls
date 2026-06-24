@IsTest
private class AddFollowUp_MobileAPI_Test {

    @IsTest
    static void test_addFollowUp_MainPath() {
        // Create Required Sample Data
        Lead l = new Lead(LastName = 'FollowUpTest', Company = 'Test Co');
        insert l;

        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfFieldExists(cp, 'Email__c', 'followup@test.com');
        insert cp;
        // Re-query for auto-populated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        Related_Source__c rs = new Related_Source__c(SLead__c = l.Id);
        insert rs;
        // Re-query for auto-populated Lead_Id__c
        rs = [SELECT Id, Lead_Id__c FROM Related_Source__c WHERE Id = :rs.Id];

        // Call method with real record data
        Map<String, Object> data = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'leadId' => rs.Lead_Id__c,
            'scheduleDate' => System.now().addDays(1),
            'subject' => 'Follow Up Task',
            'notes' => 'Dynamic notes'
        };

        Test.startTest();
        mockRestRequest(JSON.serialize(data));
        AddFollowUp_MobileAPI.addFollowUp();
        Test.stopTest();
    }

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AddFollowUpAPI/';
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