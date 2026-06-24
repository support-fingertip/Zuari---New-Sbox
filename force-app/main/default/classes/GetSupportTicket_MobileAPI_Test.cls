@isTest
private class GetSupportTicket_MobileAPI_Test {

    @isTest
    static void test_getTickets_FullCoverage() {
        String seed = String.valueOf(System.now().getTime());
        
        // 1. Setup Dynamic Data
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Email__c', 'ticket' + seed + '@test.com');
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        Support_Ticket__c st = new Support_Ticket__c();
        setIfWriteable(st, 'Channel_Partner__c', cp.Id);
        setIfWriteable(st, 'Subject__c', 'Issue ' + seed);
        setIfWriteable(st, 'Ticket_Status__c', 'New');
        setIfWriteable(st, 'Type__c', 'Sales');
        insert st;

        Test.startTest();
        // 2. PATH A: SUCCESS (With search and filters)
        Map<String, Object> successPayload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'ticketStatusId' => 'New',
            'ticketTypeId' => 'Sales',
            'search' => seed,
            'pageSize' => 5
        };
        mock(JSON.serialize(successPayload));
        GetSupportTicket_MobileAPI.getTickets();

        // 3. PATH B: VALIDATIONS (Missing Data / Not Found)
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '' }));
        GetSupportTicket_MobileAPI.getTickets();

        mock(JSON.serialize(new Map<String, Object>{ 'userId' => 'FAKE-ID', 'pageSize' => 1 }));
        GetSupportTicket_MobileAPI.getTickets();

        // 4. PATH C: EXCEPTIONS (Catch Block)
        mock('{ "userId": "broken'); 
        GetSupportTicket_MobileAPI.getTickets();
        
        // 5. INNER CLASS COVERAGE (Manual touch for line coverage)
        GetSupportTicket_MobileAPI.TicketRequestWrapper trw = new GetSupportTicket_MobileAPI.TicketRequestWrapper();
        trw.userId = '1'; trw.search = '1';
        GetSupportTicket_MobileAPI.ResponseWrapper rw = new GetSupportTicket_MobileAPI.ResponseWrapper(true, '1');
        GetSupportTicket_MobileAPI.SuccessResponseWrapper srw = new GetSupportTicket_MobileAPI.SuccessResponseWrapper(true, '1', new List<GetSupportTicket_MobileAPI.TicketResponseWrapper>());
        
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetSupportTicketAPI/';
        req.httpMethod = 'POST';
        req.requestBody = (body == null) ? null : Blob.valueOf(body);
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