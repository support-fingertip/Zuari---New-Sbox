@isTest
private class PendingBookingInvoice_MobileAPITest {
    
    private static String seed = String.valueOf(System.now().getTime());
    
    private static Channel_Partner__c createPartner() {
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Name', 'CP_' + seed);
        setIfWriteable(cp, 'Email__c', 'test_' + seed + '@test.com');
        insert cp;
        return [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];
    }
    
    private static void mockRequest(Object payload) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/PendingBookingInvoiceAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = res;
    }
    
    private static void setIfWriteable(SObject sob, String field, Object val) {
        if (sob.getSObjectType().getDescribe().fields.getMap().get(field)?.getDescribe().isCreateable()) {
            sob.put(field, val);
        }
    }
    
    @isTest static void testSuccessValidUser() {
        Channel_Partner__c cp = createPartner();
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c});
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testMissingUserId() {
        mockRequest(new Map<String, Object>());
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testInvalidUserId() {
        Channel_Partner__c cp = createPartner();
        mockRequest(new Map<String, Object>{'userId' => 'FAKE_USER_ID'});
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testWithProjectFilter() {
        Channel_Partner__c cp = createPartner();
        mockRequest(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'projectId' => 'PROJ_' + seed
        });
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testWithBookingDate() {
        Channel_Partner__c cp = createPartner();
        mockRequest(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'bookingDate' => DateTime.now().addDays(-5)
        });
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testWithInvoiceNumber() {
        Channel_Partner__c cp = createPartner();
        mockRequest(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'invoiceNumber' => 'INV_' + seed
        });
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testPaginationVariousSizes() {
        Channel_Partner__c cp = createPartner();
        List<Integer> sizes = new List<Integer>{0, 1, 5};
        
        Test.startTest();
        for (Integer size : sizes) {
            mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'pageSize' => size});
            PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        }
        Test.stopTest();
    }
    
    @isTest static void testAllFiltersCombined() {
        Channel_Partner__c cp = createPartner();
        mockRequest(new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'bookingDate' => DateTime.now(),
            'projectId' => 'PROJ_' + seed,
            'invoiceNumber' => 'INV_' + seed,
            'pageSize' => 10
        });
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testJsonDeserializationError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/PendingBookingInvoiceAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{malformed');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testChannelPartnerQuery() {
        Channel_Partner__c cp = createPartner();
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c});
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testProjectSubQueryPath() {
        Channel_Partner__c cp = createPartner();
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'projectId' => 'TESTPROJ'});
        Test.startTest();
        PendingBookingInvoice_MobileAPI.getPendingBookingInvoices();
        Test.stopTest();
    }
    
    @isTest static void testWrapperClasses() {
        PendingBookingInvoice_MobileAPI.PendingBookingRequest req = new PendingBookingInvoice_MobileAPI.PendingBookingRequest();
        req.userId = 'TEST_' + seed;
        req.pageSize = 5;
        
        PendingBookingInvoice_MobileAPI.PendingBookingWrapper wrapper = new PendingBookingInvoice_MobileAPI.PendingBookingWrapper();
        wrapper.id = 'BK_' + seed;
        wrapper.agreementAmount = 100000;
        
        List<PendingBookingInvoice_MobileAPI.PendingBookingWrapper> data = new List<PendingBookingInvoice_MobileAPI.PendingBookingWrapper>{wrapper};
        PendingBookingInvoice_MobileAPI.PendingBookingResponse res = new PendingBookingInvoice_MobileAPI.PendingBookingResponse(true, 'test', data);
    }
}