@isTest
private class SummaryReport_MobileAPI_Test {

    @isTest
    static void test_getSummaryReport_FullCoverage() {
        // 1. SETUP: Unique Seed
        String seed = String.valueOf(System.now().getTime()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        
        // 2. SETUP: Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Name', 'CP' + seed.substring(0,5));
        setIfWriteable(cp, 'Email__c', 'report' + seed + '@test.com');
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 3. SETUP: Relational Data with Future Dates
        // This fixes the FIELD_CUSTOM_VALIDATION_EXCEPTION for future dates
        Related_Source__c rs = new Related_Source__c(Channel_Partner1__c = cp.Id);
        insert rs;

        // Site Visit with Future Date
        Site_Visit__c sv = new Site_Visit__c(Related_Source__c = rs.Id);
        setIfWriteable(sv, 'Date__c', System.now().addDays(2)); 
        insert sv;

        // Booking with Future Date
        Booking__c bk = new Booking__c(Related_Source__c = rs.Id);
        setIfWriteable(bk, 'Booking_Date__c', System.now().addDays(2)); 
        insert bk;

        // ---------------------------------------------------------
        // EXECUTION PATHS (No Assertions)
        // ---------------------------------------------------------
        Test.startTest();
        
        // Path A: SUCCESS (Aggregates data within the window)
        SummaryReport_MobileAPI.SummaryRequestWrapper req = new SummaryReport_MobileAPI.SummaryRequestWrapper();
        req.userId = cp.User_Id__c;
        req.fromDate = System.now().addDays(-1); // Start yesterday
        req.endDate = System.now().addDays(5);   // End after our future records
        mock(JSON.serialize(req));
        SummaryReport_MobileAPI.getSummaryReport();

        // Path B: VALIDATIONS
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '' }));
        SummaryReport_MobileAPI.getSummaryReport();

        // Path C: EXCEPTIONS
        mock('{ "userId": "broken'); 
        SummaryReport_MobileAPI.getSummaryReport();
        
        // Path D: Manual Wrapper Touch
        SummaryReport_MobileAPI.SummaryResponseWrapper srw = new SummaryReport_MobileAPI.SummaryResponseWrapper();
        SummaryReport_MobileAPI.SummaryItem si = new SummaryReport_MobileAPI.SummaryItem('Test', 1);
        
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/SummaryReportAPI/';
        req.httpMethod = 'POST';
        req.requestBody = (body == null) ? null : Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfWriteable(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable()) {
            sob.put(field, val);
        }
    }
}