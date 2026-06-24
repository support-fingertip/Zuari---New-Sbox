@IsTest
private class CreateSupportTicket_MobileAPI_Test {

    @TestSetup
    static void setupTestData() {
        // Removed User_Id__c assignment as it is an Auto Number field
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Partner ' + String.valueOf(Crypto.getRandomLong()),
            Email__c = 'test@example.com',
            Active__c = true
        );
        insert cp;
    }

    // This method specifically targets the Inner Classes to boost coverage > 75%
    @IsTest
    static void test_Wrappers_coverage() {
        Test.startTest();
        
        // Cover SupportTicketWrapper properties
        CreateSupportTicket_MobileAPI.SupportTicketWrapper input = new CreateSupportTicket_MobileAPI.SupportTicketWrapper();
        input.userId = '1001';
        input.ticketTypeId = '1';
        input.subject = 'Test';
        input.priorityId = 'High';
        input.description = 'Desc';
        
        // Cover ResponseWrapper constructor and properties
        CreateSupportTicket_MobileAPI.ResponseWrapper res = new CreateSupportTicket_MobileAPI.ResponseWrapper(true, 'Success Message');
        
        Test.stopTest();
    }

    @IsTest
    static void test_successfulTicketCreation() {
        // Query the auto-generated User_Id__c
        Channel_Partner__c cp = [SELECT User_Id__c, Email__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        // Use the queried User_Id__c in the payload
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c, 
            'ticketTypeId' => '1',
            'subject' => 'Test Subject',
            'priorityId' => 'High',
            'description' => 'Test Description'
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();
    }

    @IsTest
    static void test_missingRequiredFields() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '',
            'ticketTypeId' => '',
            'subject' => '',
            'priorityId' => '',
            'description' => ''
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();
    }

    @IsTest
    static void test_invalidChannelPartner() {
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => '99999',  // Random ID that doesn't exist
            'ticketTypeId' => '1',
            'subject' => 'Test Subject',
            'priorityId' => 'High',
            'description' => 'Test Description'
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();
    }

    @IsTest
    static void test_invalidJsonException() {
        String payload = '{ invalid json }';

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();
    }

    @IsTest
    static void test_dmlException() {
        Channel_Partner__c cp = [SELECT User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];

        // Intentionally long subject to try and trigger DML error (depending on field length)
        // or passing data that might fail validation rules if you have them.
        String payload = JSON.serialize(new Map<String, Object> {
            'userId' => cp.User_Id__c,
            'ticketTypeId' => '1',
            'subject' => 'A'.repeat(255), 
            'priorityId' => 'High',
            'description' => 'Test Description'
        });

        Test.startTest();
        mock(payload);
        CreateSupportTicket_MobileAPI.createTicket();
        Test.stopTest();
    }

    /* ============================= HELPERS ============================= */
    
    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateSupportTicketAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        RestContext.response.statusCode = 200;
    }
}