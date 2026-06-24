@isTest
private class GetInvoiceData_MobileAPILatest_Test {

    @isTest
    static void test_getInvoiceData_FullCoverage() {
        String seed = String.valueOf(System.now().getTime());

        // 1. SETUP: Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Email__c', 'inv' + seed + '@test.com');
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 2. SETUP: Invoice
        Invoice__c inv = new Invoice__c(
            Agreement_Amount__c = 1000, 
            Commission_Amount__c = 100, 
            Net_Invoice_Amount__c = 900
        );
        insert inv;

        // 3. SETUP: Multiple Bookings linked to same Invoice
        Booking__c b1 = new Booking__c(Channel_Partner__c = cp.Id, Invoice__c = inv.Id);
        Booking__c b2 = new Booking__c(Channel_Partner__c = cp.Id, Invoice__c = inv.Id);
        insert new List<Booking__c>{b1, b2};
        
        // Re-query names for payload
        List<Booking__c> bkList = [SELECT Name FROM Booking__c WHERE Invoice__c = :inv.Id];

      
        // PATH A: SUCCESS (Multiple Bookings, Single Invoice)
        GetInvoiceData_MobileAPILatest.GetInvoiceRequestWrapper req = new GetInvoiceData_MobileAPILatest.GetInvoiceRequestWrapper();
        req.userId = cp.User_Id__c;
        req.bookingId = new List<String>{ bkList[0].Name, bkList[1].Name };

        Test.startTest();
        mock(JSON.serialize(req));
        GetInvoiceData_MobileAPILatest.getInvoiceData();

        // -----------------------------------------------------------------------
        // PATH B: VALIDATIONS
        // -----------------------------------------------------------------------
        // 1. Missing fields
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '' }));
        GetInvoiceData_MobileAPILatest.getInvoiceData();

        // 2. CP Not Found
        req.userId = 'FAKE-ID';
        mock(JSON.serialize(req));
        GetInvoiceData_MobileAPILatest.getInvoiceData();

        // -----------------------------------------------------------------------
        // PATH C: EXCEPTIONS (Catch Block)
        // -----------------------------------------------------------------------
        mock('{ "userId": "broken'); 
        GetInvoiceData_MobileAPILatest.getInvoiceData();
        Test.stopTest();
    }

    @isTest
    static void test_MultipleInvoices_ErrorPath() {
        String seed = 'err' + System.now().getTime();
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Email__c', seed + '@test.com');
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // Two different invoices
        Invoice__c i1 = new Invoice__c();
        Invoice__c i2 = new Invoice__c();
        insert new List<Invoice__c>{i1, i2};

        Booking__c b1 = new Booking__c(Channel_Partner__c = cp.Id, Invoice__c = i1.Id);
        Booking__c b2 = new Booking__c(Channel_Partner__c = cp.Id, Invoice__c = i2.Id);
        insert new List<Booking__c>{b1, b2};

        List<Booking__c> bkList = [SELECT Name FROM Booking__c WHERE Channel_Partner__c = :cp.Id];
        
        GetInvoiceData_MobileAPILatest.GetInvoiceRequestWrapper req = new GetInvoiceData_MobileAPILatest.GetInvoiceRequestWrapper();
        req.userId = cp.User_Id__c;
        req.bookingId = new List<String>{ bkList[0].Name, bkList[1].Name };

        mock(JSON.serialize(req));
        GetInvoiceData_MobileAPILatest.getInvoiceData();
    }

    /* ============================= HELPERS ============================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetInvoiceDataAPIlatest/';
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