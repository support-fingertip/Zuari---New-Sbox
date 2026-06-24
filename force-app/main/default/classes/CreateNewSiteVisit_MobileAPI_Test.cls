@IsTest
private class CreateNewSiteVisit_MobileAPI_Test {

    @IsTest
    static void test_addSiteVisit_FullSuccess() {
        // 1. Setup Data: Channel Partner with unique email
        String seed = String.valueOf(System.now().getTime());
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Email__c', 'cp' + seed + '@test.com');
        insert cp;
        
        // Re-query for auto-populated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 2. Setup Data: Lead linked to the Channel Partner
        Lead ld = new Lead(LastName = 'VisitLead', Company = 'TestCo');
        // Critical: Link lead to CP so the API's SOQL filter works
        setIfWriteable(ld, 'Channel_Partner__c', cp.Id);
        insert ld;
        
        // RE-QUERY to get the Lead_ID__c (Formula or Auto-number)
        ld = [SELECT Id, Lead_ID__c FROM Lead WHERE Id = :ld.Id];

        // 3. Setup Data: Related Source linked to Lead
        Related_Source__c rs = new Related_Source__c(SLead__c = ld.Id);
        insert rs;
	  rs = [SELECT Id, Lead_Id__c FROM Related_Source__c WHERE Id = :rs.Id];

        // 4. Success Payload - using FUTURE date
        Map<String, Object> payload = new Map<String, Object>{
             'userId' => cp.User_Id__c,
            'leadId' => rs.Lead_Id__c,
           'scheduleDate' => System.now().addDays(2),
            'notes' => 'Site visit scheduled via Mobile API'
        };

        Test.startTest();
        mock(JSON.serialize(payload));
        CreateNewSiteVisit_MobileAPI.addSiteVisit();
        Test.stopTest();
    }

    @IsTest
    static void test_errorAndCatchPaths() {
        // Validation Branch (Required fields)
        mock(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        CreateNewSiteVisit_MobileAPI.addSiteVisit();

        // CP Not Found Branch
        mock(JSON.serialize(new Map<String, Object>{
            'userId' => 'FAKE_USER',
            'leadId' => 'FAKE_LEAD',
            'scheduleDate' => System.now().addDays(2)
        }));
        CreateNewSiteVisit_MobileAPI.addSiteVisit();

        // Catch Block coverage (Malformed JSON)
        Test.startTest();
        mock('{ "userId": "broken'); 
        CreateNewSiteVisit_MobileAPI.addSiteVisit();
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateSiteVisitAPI/';
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