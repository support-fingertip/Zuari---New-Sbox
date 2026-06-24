@IsTest
private class AllSiteVisit_MobileAPI_Test {

    @IsTest
    static void test_getAllSiteVisit_FullCoverage() {
        String seed = String.valueOf(System.now().getTime());
        
        // 1. Create Lead
        Lead l = new Lead(LastName = 'L' + seed, Company = 'C' + seed);
        insert l;

        // 2. Create Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfFieldExists(cp, 'Email__c', 'cp' + seed + '@test.com');
        insert cp;
        
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 3. Create Related Source
        Related_Source__c rs = new Related_Source__c(
            SLead__c = l.Id, 
            Channel_Partner1__c = cp.Id, 
            Is_Locked__c = false
        );
        // If Project Name is a formula based on Allocated_Project__c, set it here
        setIfFieldExists(rs, 'Allocated_Project__c', 'Zuari Garden City');
        insert rs;

        // 4. Create Site Visit
        Site_Visit__c sv = new Site_Visit__c(
            Related_Source__c = rs.Id,
            SLead__c = l.Id,
            Date__c = System.now().addDays(1)
        );
        // Removed Project_Name__c assignment to avoid SObjectException
        setIfFieldExists(sv, 'Status__c', 'Open');
        insert sv;

        // 5. Success Payload
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'search' => 'L' + seed,
            'leadStatus' => 'Open',
            'projectName' => 'Zuari Garden City',
            'fromScheduleDate' => System.now().addDays(-1),
            'toScheduleDate' => System.now().addDays(5),
            'pageSize' => 0
        };

        Test.startTest();
        mockRestRequest(JSON.serialize(payload));
        AllSiteVisit_MobileAPI.getAllSiteVisitDetail();
        Test.stopTest();
    }

    @IsTest
    static void test_errorAndCatchPaths() {
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        AllSiteVisit_MobileAPI.getAllSiteVisitDetail();
        
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => 'fake_id'}));
        AllSiteVisit_MobileAPI.getAllSiteVisitDetail();

        Test.startTest();
        mockRestRequest('{ "userId": "broken" '); 
        AllSiteVisit_MobileAPI.getAllSiteVisitDetail();
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AllSiteVisitAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfFieldExists(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isUpdateable()) {
            sob.put(field, val);
        }
    }
}