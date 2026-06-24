@IsTest
private class InvoiceList_MobileAPI_Test {

    private static Integer counter = 0;

    private static void mockRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/InvoiceListAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static Channel_Partner__c createActiveCP() {
        counter++;
        Channel_Partner__c cp = new Channel_Partner__c();
        Map<String, Schema.SObjectField> fm = Channel_Partner__c.SObjectType.getDescribe().fields.getMap();
        if (fm.containsKey('Active__c') && fm.get('Active__c').getDescribe().isCreateable()) cp.Active__c = true;
        if (fm.containsKey('Email__c') && fm.get('Email__c').getDescribe().isCreateable())
            cp.Email__c = 'cp' + System.now().getTime() + counter + '@test.com';
        if (fm.containsKey('User_Id__c') && fm.get('User_Id__c').getDescribe().isCreateable())
            cp.put('User_Id__c', 'UID-IL-' + System.now().getTime() + counter);
        if (fm.containsKey('Name')) {
            Schema.DescribeFieldResult nf = fm.get('Name').getDescribe();
            if (nf.isCreateable() && !nf.isAutoNumber()) cp.Name = 'CP_' + counter;
        }
        insert cp;
        Channel_Partner__c result = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertNotEquals(null, result.User_Id__c, 'User_Id__c must be auto-populated');
        return result;
    }

    private static Invoice__c createInvoice(Id cpId) {
        Invoice__c inv = new Invoice__c();
        Map<String, Schema.SObjectField> fm = Invoice__c.SObjectType.getDescribe().fields.getMap();
        if (fm.containsKey('Channel_Partner__c') && fm.get('Channel_Partner__c').getDescribe().isCreateable()) inv.Channel_Partner__c = cpId;
        if (fm.containsKey('Invoice_Status__c') && fm.get('Invoice_Status__c').getDescribe().isCreateable()) inv.Invoice_Status__c = 'Pending';
        if (fm.containsKey('Agreement_Amount__c') && fm.get('Agreement_Amount__c').getDescribe().isCreateable()) inv.Agreement_Amount__c = 50000;
        if (fm.containsKey('Commission_Amount__c') && fm.get('Commission_Amount__c').getDescribe().isCreateable()) inv.Commission_Amount__c = 5000;
        if (fm.containsKey('TDS__c') && fm.get('TDS__c').getDescribe().isCreateable()) inv.TDS__c = 500;
        if (fm.containsKey('GST__c') && fm.get('GST__c').getDescribe().isCreateable()) inv.GST__c = 900;
        insert inv;
        return inv;
    }

    private static void setPicklistOrRef(SObject sob, String fieldApi, Id recordId, String preferredPickVal) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return;
        Schema.DescribeFieldResult dfr = fm.get(fieldApi).getDescribe();
        if (!dfr.isCreateable()) return;
        if (dfr.getType() == Schema.DisplayType.Picklist) {
            if (String.isNotBlank(preferredPickVal)) {
                for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                    if (pe.isActive() && pe.getValue() == preferredPickVal) { sob.put(fieldApi, preferredPickVal); return; }
                }
            }
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                if (pe.isActive()) { sob.put(fieldApi, pe.getValue()); return; }
            }
        } else if (dfr.getType() == Schema.DisplayType.Reference) {
            sob.put(fieldApi, recordId);
        }
    }

    private static void setField(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable()) sob.put(field, val);
    }

    @IsTest static void test_userIdBlank() {
        mockRestRequest(JSON.serialize(new Map<String, Object>{ 'userId' => '', 'search' => '', 'pageSize' => 0 }));
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
    }

    @IsTest static void test_cpNotFound() {
        mockRestRequest(JSON.serialize(new Map<String, Object>{ 'userId' => 'NONEXISTENT-USER-999', 'search' => '', 'pageSize' => 0 }));
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
    }

    @IsTest static void test_invalidJson() {
        mockRestRequest('{invalid json');
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
    }

    @IsTest static void test_success_noInvoices() {
        Channel_Partner__c cp = createActiveCP();
        mockRestRequest(JSON.serialize(new Map<String, Object>{ 'userId' => cp.User_Id__c, 'search' => '', 'pageSize' => 0 }));
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest static void test_success_invoiceWithoutBookings() {
        Channel_Partner__c cp = createActiveCP();
        createInvoice(cp.Id);
        mockRestRequest(JSON.serialize(new Map<String, Object>{ 'userId' => cp.User_Id__c, 'search' => '', 'pageSize' => 0 }));
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest static void test_success_invoiceWithBookings() {
        Channel_Partner__c cp = createActiveCP();
        Invoice__c inv = createInvoice(cp.Id);
        Project__c proj = new Project__c();
        setField(proj, 'Name', 'Proj1');
        insert proj;
        Plot__c plot = new Plot__c();
        Map<String, Schema.SObjectField> plf = Plot__c.SObjectType.getDescribe().fields.getMap();
        if (plf.containsKey('Name') && plf.get('Name').getDescribe().isCreateable() && !plf.get('Name').getDescribe().isAutoNumber()) plot.put('Name', 'PLOT-1');
        setPicklistOrRef(plot, 'Project__c', proj.Id, 'Zuari Garden City');
        setField(plot, 'Channel_Partner__c', cp.Id);
        insert plot;
        Booking__c bk = new Booking__c();
        setField(bk, 'Invoice__c', inv.Id);
        setField(bk, 'Plot__c', plot.Id);
        setField(bk, 'Channel_Partner__c', cp.Id);
        setField(bk, 'Agreement_Value_Before_GST__c', 5000000);
        setField(bk, 'Booking_Date__c', System.now());
        setPicklistOrRef(bk, 'Project__c', null, 'Zuari Garden City');
        insert bk;
        mockRestRequest(JSON.serialize(new Map<String, Object>{ 'userId' => cp.User_Id__c, 'search' => '', 'pageSize' => 0 }));
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest static void test_success_nullPageSize() {
        Channel_Partner__c cp = createActiveCP();
        createInvoice(cp.Id);
        mockRestRequest(JSON.serialize(new Map<String, Object>{ 'userId' => cp.User_Id__c, 'search' => '' }));
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest static void test_success_withSearch() {
        Channel_Partner__c cp = createActiveCP();
        createInvoice(cp.Id);
        mockRestRequest(JSON.serialize(new Map<String, Object>{ 'userId' => cp.User_Id__c, 'search' => 'INV', 'pageSize' => 0 }));
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest static void test_success_withPagination() {
        Channel_Partner__c cp = createActiveCP();
        createInvoice(cp.Id);
        mockRestRequest(JSON.serialize(new Map<String, Object>{ 'userId' => cp.User_Id__c, 'search' => '', 'pageSize' => 1 }));
        Test.startTest(); InvoiceList_MobileAPI.getInvoiceList(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest static void test_wrapperClasses() {
        InvoiceList_MobileAPI.BookingDetailWrapper bd = new InvoiceList_MobileAPI.BookingDetailWrapper();
        bd.unit = 'A-1'; bd.bookingId = 'BK1'; bd.agreementValue = 100; bd.bookingDate = System.now();
        InvoiceList_MobileAPI.InvoiceListWrapper w = new InvoiceList_MobileAPI.InvoiceListWrapper();
        w.id = '1'; w.invoiceNumber = 'INV1'; w.agreementAmount = 100; w.commissionAmount = 10;
        w.cancelledBookingAmount = 0; w.netInvestAmount = 90; w.commissionPercentage = 10;
        w.invoiceStatusId = 'Pending'; w.projectName = 'P1'; w.TDS = 5; w.GST = 9;
        w.bookingDetail = new List<InvoiceList_MobileAPI.BookingDetailWrapper>{ bd };
        InvoiceList_MobileAPI.InvoiceListRequestWrapper rw = new InvoiceList_MobileAPI.InvoiceListRequestWrapper();
        rw.userId = 'u'; rw.search = 's'; rw.pageSize = 0;
        InvoiceList_MobileAPI.InvoiceListResponseWrapper res =
            new InvoiceList_MobileAPI.InvoiceListResponseWrapper(true, 'ok', new List<InvoiceList_MobileAPI.InvoiceListWrapper>{ w });
        System.assertEquals(true, res.status);
    }
}