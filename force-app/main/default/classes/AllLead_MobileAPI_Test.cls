@IsTest
private class AllLead_MobileAPI_Test {

    @IsTest
    static void test_getAllLeads_FullCoverage() {
        // Create Required Sample Data
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfFieldExists(cp, 'Email__c', 'leadtest@example.com');
        insert cp;
        
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        Related_Source__c rs = new Related_Source__c(
            Channel_Partner1__c = cp.Id,
            Is_Locked__c = false
        );
        setIfFieldExists(rs, 'Name__c', 'Dynamic Lead');
        setIfFieldExists(rs, 'Lead_status1__c', 'Open');
        // Setting fields to cover date filter logic
        setIfFieldExists(rs, 'Booking_Date__c', System.now());
        setIfFieldExists(rs, 'Last_Site_Visit_Date_Time__c', System.now());
        setIfFieldExists(rs, 'Rejection_Date__c', Date.today());
        insert rs;

        // Payload using ALL filters to cover every "if" block in the class
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'search' => 'Dynamic',
            'leadStatus' => 'Open',
            'projectName' => 'Test Project',
            'rejectedReason' => 'Price',
            'fromCreatedDate' => System.now().addDays(-1),
            'toCreatedDate' => System.now().addDays(1),
            'fromBookingDate' => System.now().addDays(-1),
            'toBookingDate' => System.now().addDays(1),
            'fromSVDate' => System.now().addDays(-1),
            'toSVDate' => System.now().addDays(1),
            'fromRejectionDate' => System.now().addDays(-1),
            'toRejectionDate' => System.now().addDays(1),
            'pageSize' => 1
        };

        Test.startTest();
        mockRestRequest(JSON.serialize(payload));
        AllLead_MobileAPI.getAllLeadDetail();
        Test.stopTest();
    }

    @IsTest
    static void test_triggerCatchAndErrors() {
        // 1. Triggers "userId is required" branch
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => ''}));
        AllLead_MobileAPI.getAllLeadDetail();

        // 2. Triggers "User Not Found" branch
        mockRestRequest(JSON.serialize(new Map<String, Object>{'userId' => 'fake_id'}));
        AllLead_MobileAPI.getAllLeadDetail();

        // 3. Triggers Catch Block (Malformed JSON causes deserialize to fail)
        Test.startTest();
        mockRestRequest('{"userId": "invalid-json-structure"'); // Missing closing brace
        AllLead_MobileAPI.getAllLeadDetail();
        Test.stopTest();
    }

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AllLeadAPI/';
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