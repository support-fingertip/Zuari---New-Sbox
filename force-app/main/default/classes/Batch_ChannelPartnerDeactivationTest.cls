@isTest
private class Batch_ChannelPartnerDeactivationTest {

    private static Channel_Partner__c makeCP(String name, String email, Boolean active,
                                             DateTime lastLeadCapturedDt) {
        Channel_Partner__c cp = new Channel_Partner__c(
            Name        = name,
            Email__c    = email,
            Active__c   = active,
            Last_Lead_Captured_Date_Time__c = lastLeadCapturedDt
        );
        insert cp;
        return cp;
    }

    @isTest
    static void deactivatesStaleAndKeepsRecentActive() {
        DateTime stale  = System.now().addMonths(-13);
        DateTime recent = System.now().addMonths(-6);

        Channel_Partner__c staleCp  = makeCP('Stale CP',  'stale@test.com',  true, stale);
        Channel_Partner__c recentCp = makeCP('Recent CP', 'recent@test.com', true, recent);

        Test.startTest();
        Database.executeBatch(new Batch_ChannelPartnerDeactivation(), 200);
        Test.stopTest();

        Map<Id, Channel_Partner__c> after = new Map<Id, Channel_Partner__c>([
            SELECT Id, Active__c FROM Channel_Partner__c
            WHERE Id IN (:staleCp.Id, :recentCp.Id)
        ]);
        System.assertEquals(false, after.get(staleCp.Id).Active__c,
            'Stale CP must be deactivated');
        System.assertEquals(true, after.get(recentCp.Id).Active__c,
            'Recent CP must remain active');
    }

    @isTest
    static void nullLastLeadFallsBackToCreatedDate() {
        // Brand-new CP with no lead capture: within 12-month grace window
        // => must NOT be deactivated.
        Channel_Partner__c freshNoLead = makeCP('Fresh NoLead', 'fresh@test.com', true, null);

        Test.startTest();
        Database.executeBatch(new Batch_ChannelPartnerDeactivation(), 200);
        Test.stopTest();

        Channel_Partner__c after = [
            SELECT Active__c FROM Channel_Partner__c WHERE Id = :freshNoLead.Id
        ];
        System.assertEquals(true, after.Active__c,
            'Newly created CP without leads must remain active');
    }

    @isTest
    static void alreadyInactiveIsSkipped() {
        // Stale lead date but already inactive — locator must filter it out.
        Channel_Partner__c inactive = makeCP('Inactive CP', 'inactive@test.com',
                                             false, System.now().addMonths(-24));

        Test.startTest();
        Database.executeBatch(new Batch_ChannelPartnerDeactivation(), 200);
        Test.stopTest();

        Channel_Partner__c after = [
            SELECT Active__c FROM Channel_Partner__c WHERE Id = :inactive.Id
        ];
        System.assertEquals(false, after.Active__c,
            'Already inactive CP stays inactive');
    }

    @isTest
    static void schedulerEnqueuesBatch() {
        Test.startTest();
        String cron = '0 0 2 * * ?';
        Id jobId = System.schedule('CP Deactivation Test',
                                   cron,
                                   new ChannelPartnerDeactivationScheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduler should register a job');
    }
}
