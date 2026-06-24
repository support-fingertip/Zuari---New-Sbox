@IsTest
private class ChannelPartnerPaymentControllerTest {

    @TestSetup
    static void setupData() {
        // Project — must use a valid restricted picklist value
        Project__c prj = new Project__c(Name = 'Zuari Garden City');
        insert prj;

        // Block
        Block__c blk = new Block__c(Name = 'A', Project__c = prj.Id);
        insert blk;

        // Plot
        Plot__c plt = new Plot__c(
            Name         = 'Plot-CPPay',
            Project__c   = prj.Id,
            Status__c    = 'Available'
        );
        insert plt;

        // Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(
            Name      = 'Test CP Payment',
            Email__c  = 'cptest@pay.com',
            Active__c = true
        );
        insert cp;

        // Quote
        Quote__c qt = new Quote__c(
            Block_Lookup__c  = blk.Id,
            Quote_status__c  = 'Converted',
            Block__c         = ' ',
            Project__c       = prj.Name,
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 100,
            Built_up_area__c = 100,
            Rate_per_sqft__c = 1000,
            Unit__c          = plt.Id
        );
        insert qt;

        // Booking
        Booking__c bk = new Booking__c(
            Quote__c            = qt.Id,
            Plot__c             = plt.Id,
            Channel_Partner__c  = cp.Id,
            Project__c          = prj.Name,
            Funding_Type__c     = 'Loan',
            Agreement_Value_Before_GST__c = 5000000
        );
        insert bk;

        // Commission Slab (needed by existing booking trigger)
        Commission_Slab__c cs = new Commission_Slab__c(
            Project__c          = prj.Id,
            Booking_Criteria__c = '10',
            Commission_Factor__c = 2
        );
        insert cs;

        // Invoice
        Invoice__c inv = new Invoice__c(
            Channel_Partner__c  = cp.Id,
            Invoice_Status__c   = 'Pending',
            Project_Name__c     = prj.Name,
            Agreement_Amount__c = 5000000,
            Commission_Amount__c = 50000,
            Net_Invoice_Amount__c = 45000
        );
        insert inv;

        // Invoice Line Item
        Invoice_Line_Item__c ili = new Invoice_Line_Item__c(
            Invoice__c         = inv.Id,
            Booking__c         = bk.Id,
            Commission_Amount__c = 50000,
            Invoice_Date__c    = Date.today()
        );
        insert ili;
    }

    /* ── getInvoices: valid CP ── */
    @IsTest
    static void test_getInvoices_valid() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        Test.startTest();
        List<Invoice__c> result = ChannelPartnerPaymentController.getInvoices(cp.Id);
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return pending invoices');
    }

    /* ── getInvoices: null Id → exception ── */
    @IsTest
    static void test_getInvoices_nullId() {
        Boolean threw = false;
        Test.startTest();
        try {
            ChannelPartnerPaymentController.getInvoices(null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Should throw when recId is null');
    }

    /* ── createPayment: happy path ── */
    @IsTest
    static void test_createPayment_success() {
        Channel_Partner__c cp  = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Invoice__c         inv = [SELECT Id FROM Invoice__c LIMIT 1];

        Test.startTest();
        Id payId = ChannelPartnerPaymentController.createPayment(
            'PAY', Date.today(), 'UTR123', 'Pending', 'NEFT',
            new List<Id>{ inv.Id }, cp.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, payId, 'Should return payment Id');
        System.assert(
            [SELECT COUNT() FROM Payment_Line_Item__c WHERE Payment__c = :payId] > 0,
            'Should create line items'
        );
    }

    /* ── createPayment: empty invoices → exception ── */
    @IsTest
    static void test_createPayment_emptyInvoices() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Boolean threw = false;

        Test.startTest();
        try {
            ChannelPartnerPaymentController.createPayment(
                'PAY', Date.today(), 'UTR', 'Pending', 'NEFT',
                new List<Id>(), cp.Id
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Should throw when no invoices selected');
    }
}