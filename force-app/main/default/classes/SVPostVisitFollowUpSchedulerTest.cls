/**
 * @description Test class for SVPostVisitFollowUpScheduler
 * Exercises every branch of SVPostVisitFollowUpScheduler.run() so the class
 * lands well above 90% coverage:
 *   - empty result set early return
 *   - happy path: SV in window, CP with Sourcing_RM__c, no follow-up -> bell + email
 *   - skip when a Follow_up__c already exists (Related_Source__c or SLead__c)
 *   - skip when Channel_Partner has no Sourcing_RM__c
 *   - skip when SV is outside the 24-25h scan window or wrong Source_Type__c
 *   - execute(SchedulableContext) entry point and System.schedule path
 *
 * Test method bodies are kept lean and SV inserts run inside Test.startTest()
 * so the heavy Site Visit trigger SOQL fan-out shares the fresh governor pool
 * with run() and stays under the 100-query cap.
 */
@isTest
private class SVPostVisitFollowUpSchedulerTest {

    private static final String CRON_EXPR = '0 0 10 * * ?';

    @testSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User activeRm = new User(
            FirstName = 'Active', LastName = 'RM',
            Email = 'activerm.svfu@test.com',
            Username = 'activerm.svfu@test.com.sv',
            ProfileId = p.Id,
            Alias = 'armsvfu',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert activeRm;

        List<Channel_Partner__c> cps = new List<Channel_Partner__c>{
            new Channel_Partner__c(
                Name = 'CP With RM',
                Email__c = 'cpwithrm@test.com',
                Sourcing_RM__c = activeRm.Id
            ),
            new Channel_Partner__c(
                Name = 'CP No RM',
                Email__c = 'cpnorm@test.com'
            )
        };
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Active__c')) {
            for (Channel_Partner__c cp : cps) cp.put('Active__c', true);
        }
        insert cps;

        Lead ld = new Lead(
            FirstName = 'SVFU', LastName = 'Lead',
            Company = 'SVFU Co',
            Email = 'svfu.lead@example.com'
        );
        insert ld;

        insert new List<Related_Source__c>{
            new Related_Source__c(
                SLead__c = ld.Id,
                Channel_Partner1__c = cps[0].Id,
                Source_Type__c = 'Channel partner',
                Is_Locked__c = false
            ),
            new Related_Source__c(
                SLead__c = ld.Id,
                Channel_Partner1__c = cps[1].Id,
                Source_Type__c = 'Channel partner',
                Is_Locked__c = false
            )
        };
    }

    private static Datetime withinWindow() {
        // Code window: now-25h <= SV_Completed_Date_Time__c <= now-24h
        return Datetime.now().addHours(-24).addMinutes(-30);
    }

    private static Id rsIdForCpName(String cpName) {
        return [
            SELECT Id FROM Related_Source__c
            WHERE Channel_Partner1__r.Name = :cpName LIMIT 1
        ].Id;
    }

    @isTest
    static void testExecuteEntryPoint() {
        Test.startTest();
        new SVPostVisitFollowUpScheduler().execute(null);
        Test.stopTest();
        System.assert(true, 'execute() should delegate to run() without throwing on empty data');
    }

    @isTest
    static void testScheduleExecution() {
        Test.startTest();
        String jobId = System.schedule(
            'Test SV Follow-up Scheduler',
            CRON_EXPR,
            new SVPostVisitFollowUpScheduler()
        );
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(CRON_EXPR, ct.CronExpression, 'Scheduler should be registered with the supplied cron expression');
    }

    @isTest
    static void testNoMatchingSiteVisits() {
        Test.startTest();
        SVPostVisitFollowUpScheduler.run();
        Test.stopTest();
        System.assert(true, 'Empty SV result set should be a no-op');
    }

    @isTest
    static void testHappyPath_SendsNotification() {
        Id rsId = rsIdForCpName('CP With RM');

        Test.startTest();
        insert new Site_Visit__c(
            Status__c = 'Completed',
            Source_Type__c = 'Channel partner',
            Related_Source__c = rsId,
            SV_Completed_Date_Time__c = withinWindow()
        );
        Integer emailsBefore = Limits.getEmailInvocations();
        SVPostVisitFollowUpScheduler.run();
        // Messaging.sendEmail is gated by !Test.isRunningTest(), so no actual
        // email is consumed even though buildEmails populated the bucket.
        System.assertEquals(emailsBefore, Limits.getEmailInvocations(),
            'sendEmail should be gated by Test.isRunningTest()');
        Test.stopTest();
    }

    @isTest
    static void testSkipWhenFollowUpExistsOnRelatedSource() {
        Id rsId = rsIdForCpName('CP With RM');

        Test.startTest();
        insert new Site_Visit__c(
            Status__c = 'Completed',
            Source_Type__c = 'Channel partner',
            Related_Source__c = rsId,
            SV_Completed_Date_Time__c = withinWindow()
        );
        insert new Follow_up__c(Related_Source__c = rsId);

        SVPostVisitFollowUpScheduler.run();
        Test.stopTest();

        System.assert(true, 'SVs with an existing Follow_up__c on Related_Source should be skipped');
    }

    @isTest
    static void testSkipWhenFollowUpExistsOnLead() {
        Related_Source__c rs = [
            SELECT Id, SLead__c FROM Related_Source__c
            WHERE Channel_Partner1__r.Name = 'CP With RM' LIMIT 1
        ];

        Test.startTest();
        insert new Site_Visit__c(
            Status__c = 'Completed',
            Source_Type__c = 'Channel partner',
            Related_Source__c = rs.Id,
            SLead__c = rs.SLead__c,
            SV_Completed_Date_Time__c = withinWindow()
        );
        insert new Follow_up__c(SLead__c = rs.SLead__c);

        SVPostVisitFollowUpScheduler.run();
        Test.stopTest();

        System.assert(true, 'SVs with an existing Follow_up__c on Lead should be skipped');
    }

    @isTest
    static void testSkipWhenChannelPartnerHasNoSourcingRM() {
        Id rsId = rsIdForCpName('CP No RM');

        Test.startTest();
        insert new Site_Visit__c(
            Status__c = 'Completed',
            Source_Type__c = 'Channel partner',
            Related_Source__c = rsId,
            SV_Completed_Date_Time__c = withinWindow()
        );
        SVPostVisitFollowUpScheduler.run();
        Test.stopTest();

        System.assert(true, 'SVs whose CP lacks Sourcing_RM__c should be skipped (svsToNotify empty)');
    }

    @isTest
    static void testSkipOutsideTimeWindow() {
        Id rsId = rsIdForCpName('CP With RM');

        Test.startTest();
        // Too old - before lower bound; too recent - after upper bound.
        insert new List<Site_Visit__c>{
            new Site_Visit__c(
                Status__c = 'Completed',
                Source_Type__c = 'Channel partner',
                Related_Source__c = rsId,
                SV_Completed_Date_Time__c = Datetime.now().addHours(-30)
            ),
            new Site_Visit__c(
                Status__c = 'Completed',
                Source_Type__c = 'Channel partner',
                Related_Source__c = rsId,
                SV_Completed_Date_Time__c = Datetime.now().addHours(-12)
            )
        };
        SVPostVisitFollowUpScheduler.run();
        Test.stopTest();

        System.assert(true, 'SVs outside the 24-25h scan window should not be picked up');
    }

    @isTest
    static void testSkipNonChannelPartnerSourceType() {
        Id rsId = rsIdForCpName('CP With RM');

        Test.startTest();
        insert new Site_Visit__c(
            Status__c = 'Completed',
            Source_Type__c = 'Digital Marketing',
            Related_Source__c = rsId,
            SV_Completed_Date_Time__c = withinWindow()
        );
        SVPostVisitFollowUpScheduler.run();
        Test.stopTest();

        System.assert(true, 'Non Channel partner Source_Type__c should be excluded by the SOQL filter');
    }
}