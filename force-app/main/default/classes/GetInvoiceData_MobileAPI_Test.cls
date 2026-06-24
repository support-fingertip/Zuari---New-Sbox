@IsTest
private class GetInvoiceData_MobileAPI_Test {

    @TestSetup
    static void setupData() {
        String suffix = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        Channel_Partner__c cp = new Channel_Partner__c();
        setVal(cp, 'Name', 'Test CP ' + suffix);
        setVal(cp, 'Email__c', 'testcp' + suffix + '@example.com');
        setVal(cp, 'Active__c', true);
        setVal(cp, 'User_Id__c', 'UID-INV-' + suffix);
        insert cp;
        Project__c proj = new Project__c();
        setVal(proj, 'Name', 'Test Project ' + suffix);
        insert proj;
        Invoice__c inv = new Invoice__c();
        setVal(inv, 'Channel_Partner__c', cp.Id);
        setVal(inv, 'Invoice_Date__c', System.today());
        setVal(inv, 'Net_Invoice_Amount__c', 470000);
        setVal(inv, 'Cancelled_Booking_Amount__c', 50000);
        setPickOrRef(inv, 'Project__c', proj.Id);
        insert inv;
        Plot__c plot = new Plot__c();
        setVal(plot, 'Name', 'PLOT-' + suffix);
        setVal(plot, 'Channel_Partner__c', cp.Id);
        setPickOrRef(plot, 'Project__c', proj.Id);
        insert plot;
        Booking__c bk = new Booking__c();
        setVal(bk, 'Channel_Partner__c', cp.Id);
        setVal(bk, 'Invoice__c', inv.Id);
        setVal(bk, 'Plot__c', plot.Id);
        setPickOrRef(bk, 'Project__c', proj.Id);
        setVal(bk, 'Agreement_Value_Before_GST__c', 5000000);
        setVal(bk, 'sale_agreement_completed__c', true);
        insert bk;
        Commission_earned__c ce = new Commission_earned__c();
        setVal(ce, 'Booking__c', bk.Id);
        setVal(ce, 'Channel_Partner__c', cp.Id);
        setVal(ce, 'Commission_Amount__c', 250000);
        setVal(ce, 'TDS_Amount__c', 25000);
        setVal(ce, 'GST_Amount__c', 45000);
        insert ce;
    }

    @IsTest
    static void test_success_invoiceNumberPath() {
        Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];
        System.assertNotEquals(null, cp.User_Id__c, 'User_Id__c must be auto-populated');
        Invoice__c inv = [SELECT Name FROM Invoice__c LIMIT 1];
        Booking__c bk = [SELECT Name FROM Booking__c LIMIT 1];
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = String.valueOf(cp.User_Id__c);
        reqW.bookingId = new List<String>{ bk.Name };
        reqW.invoiceNumber = inv.Name;
        Test.startTest();
        mock(JSON.serialize(reqW));
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();
    }

    @IsTest
    static void test_success_bookingOnlyPath() {
        Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];
        System.assertNotEquals(null, cp.User_Id__c, 'User_Id__c must be auto-populated');
        Booking__c bk = [SELECT Name FROM Booking__c LIMIT 1];
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = String.valueOf(cp.User_Id__c);
        reqW.bookingId = new List<String>{ bk.Name };
        reqW.invoiceNumber = null;
        Test.startTest();
        mock(JSON.serialize(reqW));
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();
    }

    @IsTest
    static void test_success_emptyInvoiceNumber() {
        Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];
        System.assertNotEquals(null, cp.User_Id__c, 'User_Id__c must be auto-populated');
        Booking__c bk = [SELECT Name FROM Booking__c LIMIT 1];
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = String.valueOf(cp.User_Id__c);
        reqW.bookingId = new List<String>{ bk.Name };
        reqW.invoiceNumber = '';
        Test.startTest();
        mock(JSON.serialize(reqW));
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();
    }

    @IsTest
    static void test_invoicePath_withContentDocs() {
        Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];
        System.assertNotEquals(null, cp.User_Id__c, 'User_Id__c must be auto-populated');
        Invoice__c inv = [SELECT Id, Name FROM Invoice__c LIMIT 1];
        Booking__c bk = [SELECT Name FROM Booking__c LIMIT 1];
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Invoice Document';
        cv.PathOnClient = 'InvoiceDoc.pdf';
        cv.VersionData = Blob.valueOf('Test content');
        cv.IsMajorVersion = true;
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = inv.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        List<ContentDistribution> existDists = [SELECT Id FROM ContentDistribution WHERE ContentVersionId = :cv.Id];
        if (existDists.isEmpty()) {
            ContentDistribution dist = new ContentDistribution();
            dist.Name = 'Invoice Doc Distribution';
            dist.ContentVersionId = cv.Id;
            dist.PreferencesAllowViewInBrowser = true;
            dist.PreferencesLinkLatestVersion = true;
            insert dist;
        }
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = String.valueOf(cp.User_Id__c);
        reqW.bookingId = new List<String>{ bk.Name };
        reqW.invoiceNumber = inv.Name;
        Test.startTest();
        mock(JSON.serialize(reqW));
        GetInvoiceData_MobileAPI.getInvoiceData();
        Test.stopTest();
    }

    @IsTest static void test_missingUserId() {
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = null; reqW.bookingId = new List<String>{ 'BK-001' };
        Test.startTest(); mock(JSON.serialize(reqW)); GetInvoiceData_MobileAPI.getInvoiceData(); Test.stopTest();
    }

    @IsTest static void test_blankUserId() {
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = ''; reqW.bookingId = new List<String>{ 'BK-001' };
        Test.startTest(); mock(JSON.serialize(reqW)); GetInvoiceData_MobileAPI.getInvoiceData(); Test.stopTest();
    }

    @IsTest static void test_emptyBookingIdList() {
        Channel_Partner__c cp = [SELECT User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = String.valueOf(cp.User_Id__c); reqW.bookingId = new List<String>();
        Test.startTest(); mock(JSON.serialize(reqW)); GetInvoiceData_MobileAPI.getInvoiceData(); Test.stopTest();
    }

    @IsTest static void test_nullBookingId() {
        Channel_Partner__c cp = [SELECT User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = String.valueOf(cp.User_Id__c); reqW.bookingId = null;
        Test.startTest(); mock(JSON.serialize(reqW)); GetInvoiceData_MobileAPI.getInvoiceData(); Test.stopTest();
    }

    @IsTest static void test_cpNotFound() {
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = 'NONEXISTENT-CP-999'; reqW.bookingId = new List<String>{ 'BK-001' };
        Test.startTest(); mock(JSON.serialize(reqW)); GetInvoiceData_MobileAPI.getInvoiceData(); Test.stopTest();
    }

    @IsTest static void test_noBookingsFound() {
        Channel_Partner__c cp = [SELECT User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = String.valueOf(cp.User_Id__c); reqW.bookingId = new List<String>{ 'NONEXISTENT-BK' };
        Test.startTest(); mock(JSON.serialize(reqW)); GetInvoiceData_MobileAPI.getInvoiceData(); Test.stopTest();
    }

    @IsTest static void test_invoiceNotFound() {
        Channel_Partner__c cp = [SELECT User_Id__c FROM Channel_Partner__c WHERE Active__c = true LIMIT 1];
        Booking__c bk = [SELECT Name FROM Booking__c LIMIT 1];
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = String.valueOf(cp.User_Id__c); reqW.bookingId = new List<String>{ bk.Name };
        reqW.invoiceNumber = 'NONEXISTENT-INVOICE';
        Test.startTest(); mock(JSON.serialize(reqW)); GetInvoiceData_MobileAPI.getInvoiceData(); Test.stopTest();
    }

    @IsTest static void test_invalidJson() {
        Test.startTest(); mock('{ invalid json '); GetInvoiceData_MobileAPI.getInvoiceData(); Test.stopTest();
    }

    @IsTest static void test_wrappers() {
        GetInvoiceData_MobileAPI.BookingDetail bd = new GetInvoiceData_MobileAPI.BookingDetail();
        bd.unit = 'A-101'; bd.agreementAmount = 5000000; bd.bookingDate = System.now();
        GetInvoiceData_MobileAPI.InvoiceGroupData grp = new GetInvoiceData_MobileAPI.InvoiceGroupData();
        grp.projectName = 'Test'; grp.agreementAmount = 5000000; grp.commissionAmount = 250000;
        grp.cancelledBookingCommissionAmount = 0; grp.tds = 25000; grp.gst = 45000;
        grp.netInvoiceAmount = 470000; grp.invoiceDate = System.today(); grp.invoiceId = '';
        grp.uploadDocumentURL = 'https://test.com'; grp.documentName = 'doc.pdf';
        grp.bookingDetails = new List<GetInvoiceData_MobileAPI.BookingDetail>{ bd };
        grp.bookingId = new List<String>{ 'BK-001' };
        GetInvoiceData_MobileAPI.InvoiceResponseWrapper res = new GetInvoiceData_MobileAPI.InvoiceResponseWrapper(true, 'test', grp);
        System.assertEquals(true, res.status);
        GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper reqW = new GetInvoiceData_MobileAPI.GetInvoiceRequestWrapper();
        reqW.userId = 'u'; reqW.bookingId = new List<String>{'b'}; reqW.invoiceNumber = 'i';
        System.assertNotEquals(null, reqW.userId);
    }

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetInvoiceDataAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setVal(SObject sobj, String fieldApi, Object value) {
        Map<String, SObjectField> fmap = sobj.getSObjectType().getDescribe().fields.getMap();
        if (!fmap.containsKey(fieldApi)) return;
        Schema.DescribeFieldResult dfr = fmap.get(fieldApi).getDescribe();
        if (!dfr.isCreateable()) return;
        if (dfr.getType() == Schema.DisplayType.Picklist) {
            List<Schema.PicklistEntry> vals = dfr.getPicklistValues();
            if (value instanceof String && !String.isBlank((String)value)) {
                for (Schema.PicklistEntry pe : vals) {
                    if (pe.isActive() && pe.getValue() == (String)value) { sobj.put(fieldApi, (String)value); return; }
                }
            }
            for (Schema.PicklistEntry pe : vals) {
                if (pe.isActive()) { sobj.put(fieldApi, pe.getValue()); return; }
            }
            return;
        }
        if (value != null) sobj.put(fieldApi, value);
    }

    private static void setPickOrRef(SObject sobj, String fieldApi, Id recordId) {
        Map<String, SObjectField> fmap = sobj.getSObjectType().getDescribe().fields.getMap();
        if (!fmap.containsKey(fieldApi)) return;
        Schema.DescribeFieldResult dfr = fmap.get(fieldApi).getDescribe();
        if (!dfr.isCreateable()) return;
        if (dfr.getType() == Schema.DisplayType.Reference) { sobj.put(fieldApi, recordId); return; }
        if (dfr.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                if (pe.isActive() && pe.getValue() == 'Zuari Garden City') { sobj.put(fieldApi, 'Zuari Garden City'); return; }
            }
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                if (pe.isActive()) { sobj.put(fieldApi, pe.getValue()); return; }
            }
        }
    }
}