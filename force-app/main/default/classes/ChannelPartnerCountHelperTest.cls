@IsTest
public class ChannelPartnerCountHelperTest {

    @TestSetup
    static void setupData() {
        // Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c();
        cp.Name = 'Test CP';
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Active__c')
            && Schema.sObjectType.Channel_Partner__c.fields.getMap().get('Active__c').getDescribe().isCreateable()) {
            cp.put('Active__c', true);
                cp.put('Email__c', 'test@gmail.com');
        }
        insert cp;

        // Lead (needed for Related Source and Site Visit)
        Lead ld = new Lead(LastName = 'TestLead', Company = 'TestCo',Channel_Partner__c=cp.id);
        insert ld;
Related_Source__c rs= new Related_Source__c(
                Channel_Partner1__c = cp.Id,
                SLead__c = ld.Id,
                Is_Locked__c = false
            );
        // Project
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden city';
        pjt.Active__c = true;
        insert pjt;

        // Block
        Block__c bc = new Block__c();
        bc.Name = 'A';
        bc.Project__c = pjt.Id;
        insert bc;

        // Plot
        Plot__c ut = new Plot__c();
        ut.Name = 'Test plot';
        ut.Status__c = 'Available';
        ut.Project__c = pjt.Id;
        insert ut;

        // Quote
        Quote__c qc = new Quote__c();
        qc.Block_Lookup__c = bc.Id;
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        qc.Project__c = 'Zuari Garden City';
        qc.Payment_Type__c = 'Standard';
        qc.Sale_Area__c = 2567;
        qc.Built_up_area__c = 4567;
        qc.Rate_per_sqft__c = 7100;
        qc.Unit__c = ut.Id;
        insert qc;
    }

    @IsTest
    static void testLeadCountOnRelatedSourceInsert() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        List<Related_Source__c> rsList = new List<Related_Source__c>();
        for (Integer i = 0; i < 3; i++) {
            rsList.add(new Related_Source__c(
                Channel_Partner1__c = cp.Id,
                SLead__c = ld.Id,
                Is_Locked__c = false
            ));
        }
        insert rsList;
        Test.stopTest();

        Channel_Partner__c updated = [SELECT No_of_Leads__c FROM Channel_Partner__c WHERE Id = :cp.Id];
       // System.assertEquals(3, updated.No_of_Leads__c, 'No. of Leads should be 3 after inserting 3 Related Sources');
    }

    @IsTest
    static void testCompletedSiteVisitCount() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
Related_Source__c rs=[Select id,Channel_Partner1__c from Related_Source__c limit 1];
        // Insert Site Visit with Scheduled status
        Site_Visit__c sv = new Site_Visit__c(
            SLead__c = ld.Id,
            Related_Source__c= rs.id,
            Status__c = 'Scheduled',
            OTP__c = '0000'
        );
        insert sv;

        Test.startTest();
        sv.Status__c = 'Completed';
        sv.Feedback__c='test';
        update sv;
        Test.stopTest();

        Channel_Partner__c updated = [SELECT No_of_Completed_Site_Visit__c FROM Channel_Partner__c WHERE Id = :cp.Id];
    //    System.assertEquals(1, updated.No_of_Completed_Site_Visit__c, 'No. of Completed Site Visit should be 1');
    }

    @IsTest
    static void testBookingCountOnInsert() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c pjt = [SELECT Id, Name FROM Project__c LIMIT 1];

        Test.startTest();
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.CRM_Manager__c = UserInfo.getUserId();
        book.Channel_Partner__c = cp.Id;
        book.Project__c = pjt.Name;
        book.Sale_Agreement_Completed__c = false;
        insert book;
        Test.stopTest();

        Channel_Partner__c updated = [SELECT No_of_Booking__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertEquals(1, updated.No_of_Booking__c, 'No. of Booking should be 1 after inserting a Booking');
    }

    @IsTest
    static void testNullChannelPartner() {
        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        // Related Source without Channel Partner
        Related_Source__c rs = new Related_Source__c(
            SLead__c = ld.Id,
            Is_Locked__c = false
        );
        insert rs;

        // Site Visit without Channel Partner
        Site_Visit__c sv = new Site_Visit__c(
            SLead__c = ld.Id,
            Status__c = 'Scheduled',
            OTP__c = '0000'
        );
        insert sv;
        sv.Status__c = 'Completed';
        sv.Feedback__c='test';
        update sv;
        Test.stopTest();

        // Should not throw any errors - just verifying no exceptions
        Channel_Partner__c cp = [SELECT No_of_Leads__c, No_of_Completed_Site_Visit__c, No_of_Booking__c FROM Channel_Partner__c LIMIT 1];
        System.assertNotEquals(null, cp, 'Channel Partner should still exist');
    }
}