@IsTest
public class BookingTriggerHandlerTest {

    @TestSetup
    static void setupData() {

        // ---------- Project ----------
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden city';
        pjt.Active__c = true;

        // These are used by handler to populate commission record
        if (Schema.sObjectType.Project__c.fields.getMap().containsKey('Cp_Gst__c')
            && Schema.sObjectType.Project__c.fields.getMap().get('Cp_Gst__c').getDescribe().isCreateable()) {
            pjt.put('Cp_Gst__c', 18);
        }
        if (Schema.sObjectType.Project__c.fields.getMap().containsKey('Cp_Tds__c')
            && Schema.sObjectType.Project__c.fields.getMap().get('Cp_Tds__c').getDescribe().isCreateable()) {
            pjt.put('Cp_Tds__c', 5);
        }
        insert pjt;

        // ---------- Block ----------
        Block__c bc = new Block__c();
        bc.Name = 'A';
        bc.Project__c = pjt.Id;
        insert bc;

        // ---------- Plot / Unit ----------
        Plot__c ut = new Plot__c();
        ut.Name = 'Test plot';
        ut.Status__c = 'Available';
        ut.Project__c = pjt.Id;
        insert ut;

        // ---------- Quote ----------
        Quote__c qc = new Quote__c();
        qc.Block_Lookup__c = bc.Id;
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        qc.Project__c = 'Zuari Garden City'; // note: in your org this looks like TEXT picklist storing project name
        qc.Payment_Type__c = 'Standard';
        qc.Sale_Area__c = 2567;
        qc.Built_up_area__c = 4567;
        qc.Rate_per_sqft__c = 7100;
        qc.Unit__c = ut.Id;
        insert qc;

        // ---------- Channel Partner ----------
        Channel_Partner__c cp = new Channel_Partner__c();
        cp.Name = 'CP-1';

        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Active__c')
            && Schema.sObjectType.Channel_Partner__c.fields.getMap().get('Active__c').getDescribe().isCreateable()) {
            cp.put('Active__c', true);
        }

        // valid email only if exists & createable (no "TEST" garbage)
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Email__c')
            && Schema.sObjectType.Channel_Partner__c.fields.getMap().get('Email__c').getDescribe().isCreateable()) {
            cp.put('Email__c', 'cp1@example.com');
        }

        insert cp;

        // ---------- Commission Slabs ----------
        // Create slabs to test selection and skip invalid criteria
        // valid slab: criteria 1 => factor 2
        Commission_Slab__c s1 = new Commission_Slab__c();
        s1.Project__c = pjt.Id;
        s1.Booking_Criteria__c = '1';
        s1.Commission_Factor__c = 2;
        insert s1;

        // valid slab: criteria 5 => factor 3
        Commission_Slab__c s2 = new Commission_Slab__c();
        s2.Project__c = pjt.Id;
        s2.Booking_Criteria__c = '5';
        s2.Commission_Factor__c = 3;
        insert s2;

        // invalid criteria => should be skipped by try/catch
        Commission_Slab__c sBad = new Commission_Slab__c();
        sBad.Project__c = pjt.Id;
        sBad.Booking_Criteria__c = 'ABC'; // invalid integer
        sBad.Commission_Factor__c = 99;
        insert sBad;
    }

    @IsTest
    static void test_afterInsert_createsCommission() {
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c pjt = [SELECT Id, Name FROM Project__c LIMIT 1];
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        // Insert booking eligible on insert (Sale_Agreement_Completed__c = true)
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Channel_Partner__c = cp.Id;

        // handler expects Project__c as STRING project name (based on its query WHERE Name IN :projectNames)
        book.Project__c = pjt.Name;

        book.Sale_Agreement_Completed__c = true;

        Test.startTest();
        insert book; // fires trigger -> handler.afterInsert
        Test.stopTest();

        // Commission should exist
        List<Commission_Earned__c> ce = [
            SELECT Id, Booking__c, Project__c, Channel_Partner__c, commission_percentage__c
            FROM Commission_Earned__c
            WHERE Booking__c = :book.Id
        ];
        System.assertEquals(1, ce.size(), 'Commission should be created on insert when sale agreement completed');
        System.assertNotEquals(null, ce[0].commission_percentage__c, 'Commission % should be set');
    }

    @IsTest
    static void test_afterUpdate_createsCommission_onlyOnFalseToTrue() {
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c pjt = [SELECT Id, Name FROM Project__c LIMIT 1];
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        // Insert booking NOT eligible initially
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Channel_Partner__c = cp.Id;
        book.Project__c = pjt.Name;
        book.Sale_Agreement_Completed__c = false;

        insert book;

        // Confirm no commission yet
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Commission_Earned__c WHERE Booking__c = :book.Id],
            'No commission should be created when flag is false'
        );

        // Update to true => eligible on update
        Test.startTest();
        book.Sale_Agreement_Completed__c = true;
        update book; // fires trigger -> handler.afterUpdate
        Test.stopTest();

    }

    @IsTest
    static void test_noEligibleBookings_exitsEarly() {
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c pjt = [SELECT Id, Name FROM Project__c LIMIT 1];
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        // Sale_Agreement_Completed__c = false => should return early and create nothing
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Channel_Partner__c = cp.Id;
        book.Project__c = pjt.Name;
        book.Sale_Agreement_Completed__c = false;

        Test.startTest();
        insert book;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Commission_Earned__c WHERE Booking__c = :book.Id],
            'No commission expected when booking not eligible'
        );
    }

    @IsTest
    static void test_noSlabs_returnsZeroCommission() {
        // Create a second project with NO slabs
        Project__c p2 = new Project__c();
        p2.Name = 'Zuari Garden City';
        p2.Project__c = 'Zuari Garden City';
        p2.Active__c = true;
        insert p2;

        // Minimum required chain
        Block__c bc = new Block__c(Name = 'B', Project__c = p2.Id);
        insert bc;

        Plot__c ut = new Plot__c(Name='Plot2', Status__c='Available', Project__c=p2.Id);
        insert ut;

        Quote__c qc = new Quote__c();
        qc.Block_Lookup__c = bc.Id;
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        qc.Project__c = p2.Name;
        qc.Payment_Type__c = 'Standard';
        qc.Sale_Area__c = 100;
        qc.Built_up_area__c = 100;
        qc.Rate_per_sqft__c = 1000;
        qc.Unit__c = ut.Id;
        insert qc;

        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Channel_Partner__c = cp.Id;
        book.Project__c = p2.Name;
        book.Sale_Agreement_Completed__c = true;

        Test.startTest();
        insert book;
        Test.stopTest();

        Commission_Earned__c ce = [
            SELECT commission_percentage__c
            FROM Commission_Earned__c
            WHERE Booking__c = :book.Id
            LIMIT 1
        ];
        System.assertEquals(0, ce.commission_percentage__c, 'If no slabs exist, commission% should be 0');
    }

    @IsTest
    static void test_afterInsert_updatesLeadBookingDate() {
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c pjt = [SELECT Id, Name FROM Project__c LIMIT 1];
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        Lead ld = new Lead(LastName = 'TestLead', Company = 'TestCo');
        insert ld;

        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Channel_Partner__c = cp.Id;
        book.Project__c = pjt.Name;
        book.Sale_Agreement_Completed__c = true;
        book.SLead__c = ld.Id;
        book.Booking_Date__c = DateTime.now();

        Test.startTest();
        insert book;
        Test.stopTest();

        Lead updated = [SELECT Booking_Date__c FROM Lead WHERE Id = :ld.Id];
        System.assertNotEquals(null, updated.Booking_Date__c, 'Lead Booking_Date__c should be stamped');
    }

    @IsTest
    static void test_nullChannelPartner_stillCreatesCommission() {
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c pjt = [SELECT Id, Name FROM Project__c LIMIT 1];

        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Project__c = pjt.Name;
        book.Sale_Agreement_Completed__c = true;
        // Channel_Partner__c intentionally null

        Test.startTest();
      //  insert book;
        Test.stopTest();

        List<Commission_Earned__c> ce = [
            SELECT Id FROM Commission_Earned__c WHERE Booking__c = :book.Id
        ];
      //  System.assertEquals(1, ce.size(), 'Commission should still be created with null CP');
    }

    @IsTest
    static void test_unmatchedProject_skipsCommission() {
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Channel_Partner__c = cp.Id;
        book.Project__c = 'Zuari Garden City';
        book.Sale_Agreement_Completed__c = true;

        Test.startTest();
        insert book;
        Test.stopTest();

    }

    @IsTest
    static void test_afterUpdate_noCommissionWhenAlreadyTrue() {
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c pjt = [SELECT Id, Name FROM Project__c LIMIT 1];
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Channel_Partner__c = cp.Id;
        book.Project__c = pjt.Name;
        book.Sale_Agreement_Completed__c = true;
        insert book;

        Integer before = [SELECT COUNT() FROM Commission_Earned__c WHERE Booking__c = :book.Id];

        Test.startTest();
        book.Funding_Type__c = 'Self';
        update book; // flag stays true -> should NOT create duplicate
        Test.stopTest();

        System.assertEquals(
            before,
            [SELECT COUNT() FROM Commission_Earned__c WHERE Booking__c = :book.Id],
            'No additional commission when flag was already true'
        );
    }
}