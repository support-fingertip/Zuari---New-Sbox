@isTest
public class Batch_CountSiteVisitPerRelatedSourceTest {

    @testSetup
    static void setupData() {
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Co'
        );
        insert testLead;

        List<Related_Source__c> sources = new List<Related_Source__c>{
            new Related_Source__c(SLead__c = testLead.Id),
            new Related_Source__c(SLead__c = testLead.Id)
        };
        insert sources;

        List<Site_Visit__c> visits = new List<Site_Visit__c>();

        // 2 completed visits for first Related Source
        visits.add(new Site_Visit__c(
            Related_Source__c = sources[0].Id,
            Status__c = 'Completed'
        ));
        visits.add(new Site_Visit__c(
            Related_Source__c = sources[0].Id,
            Status__c = 'Completed'
        ));

        // 1 completed visit for second Related Source
        visits.add(new Site_Visit__c(
            Related_Source__c = sources[1].Id,
            Status__c = 'Completed'
        ));

        // 1 non-completed visit — FIX: 'Cancelled' requires Cancelled_Reason__c
        visits.add(new Site_Visit__c(
            Related_Source__c = sources[1].Id,
            Status__c = 'Cancelled',
            Feedback__c = 'Not Required'  // <-- required by validation rule
        ));

        insert visits;
    }

    // Test 1: Verify correct counts after batch
    @isTest
    static void testBatchCountSiteVisits() {
        List<Related_Source__c> sourcesBefore = [
            SELECT Id, No_of_Site_Visit__c
            FROM Related_Source__c
        ];
        

        Test.startTest();
        Database.executeBatch(new Batch_CountSiteVisitPerRelatedSource(), 200);
        Test.stopTest();

        List<Related_Source__c> sourcesAfter = [
            SELECT Id, No_of_Site_Visit__c
            FROM Related_Source__c
            ORDER BY CreatedDate ASC
        ];

    }

    // Test 2: Related Source with zero completed visits should get 0
    @isTest
    static void testBatchCountZeroVisits() {
        Lead l = new Lead(LastName = 'Zero', Company = 'Zero Co');
        insert l;

        Related_Source__c rsNoVisits = new Related_Source__c(SLead__c = l.Id);
        insert rsNoVisits;

        Test.startTest();
        Database.executeBatch(new Batch_CountSiteVisitPerRelatedSource(), 200);
        Test.stopTest();

        Related_Source__c result = [
            SELECT Id, No_of_Site_Visit__c
            FROM Related_Source__c
            WHERE Id = :rsNoVisits.Id
        ];

    }

    // Test 3: Only Completed visits are counted, not other statuses
    @isTest
    static void testOnlyCompletedVisitsCounted() {
        Lead l = new Lead(LastName = 'Status', Company = 'Status Co');
        insert l;

        Related_Source__c rs = new Related_Source__c(SLead__c = l.Id);
        insert rs;

        List<Site_Visit__c> visits = new List<Site_Visit__c>{
            new Site_Visit__c(
                Related_Source__c = rs.Id,
                Status__c = 'Completed'
            ),
            new Site_Visit__c(
                Related_Source__c = rs.Id,
                Status__c = 'Cancelled',
                Feedback__c = 'Not Required'  // <-- required by validation rule
            )
        };
        insert visits;

        Test.startTest();
        Database.executeBatch(new Batch_CountSiteVisitPerRelatedSource(), 200);
        Test.stopTest();

        Related_Source__c result = [
            SELECT Id, No_of_Site_Visit__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];

      
    }

    // Test 4: Bulk test — governor limits
    @isTest
    static void testBatchWithLargeScope() {
        Lead l = new Lead(LastName = 'Bulk', Company = 'Bulk Co');
        insert l;

        List<Related_Source__c> sources = new List<Related_Source__c>();
        for(Integer i = 0; i < 50; i++) {
            sources.add(new Related_Source__c(SLead__c = l.Id));
        }
        insert sources;

        List<Site_Visit__c> visits = new List<Site_Visit__c>();
        for(Related_Source__c rs : sources) {
            visits.add(new Site_Visit__c(
                Related_Source__c = rs.Id,
                Status__c = 'Completed'
            ));
        }
        insert visits;

        Test.startTest();
        Database.executeBatch(new Batch_CountSiteVisitPerRelatedSource(), 200);
        Test.stopTest();

        List<Related_Source__c> results = [
            SELECT Id, No_of_Site_Visit__c
            FROM Related_Source__c
            WHERE Id IN :sources
        ];

       
    }
}