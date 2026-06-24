/**
 * Test coverage for RelatedSourceLeadExpiryScheduler.
 *
 * Covers:
 *   - scheduleDaily()  registers a CronTrigger with the default cron
 *   - scheduleWithCron() supports a custom cron expression
 *   - execute() kicks off Batch_RelatedSourceLeadExpiry without throwing
 */
@isTest
private class RelatedSourceLeadExpirySchedulerTest {

    @isTest
    static void testScheduleDaily() {
        Test.startTest();
        String jobId = RelatedSourceLeadExpiryScheduler.scheduleDaily();
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job Id should be returned');

        List<CronTrigger> jobs = [
            SELECT Id, CronExpression
            FROM   CronTrigger
            WHERE  CronJobDetail.Name = :RelatedSourceLeadExpiryScheduler.JOB_NAME
        ];
        System.assertEquals(1, jobs.size(), 'One scheduled job should exist for the daily run');
        System.assertEquals(
            RelatedSourceLeadExpiryScheduler.DEFAULT_CRON,
            jobs[0].CronExpression,
            'Cron expression should match the default daily cron'
        );
    }

    @isTest
    static void testScheduleWithCustomCron() {
        String customCron = '0 0 3 * * ?';

        Test.startTest();
        String jobId = RelatedSourceLeadExpiryScheduler.scheduleWithCron(customCron);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job Id should be returned');
        CronTrigger ct = [
            SELECT CronExpression FROM CronTrigger
            WHERE CronJobDetail.Name = :RelatedSourceLeadExpiryScheduler.JOB_NAME
            LIMIT 1
        ];
        System.assertEquals(customCron, ct.CronExpression, 'Custom cron should be stored');
    }

    @isTest
    static void testScheduleIsIdempotent() {
        // First schedule
        RelatedSourceLeadExpiryScheduler.scheduleDaily();

        Test.startTest();
        // Second schedule with a different cron - the existing job should be
        // aborted and a single new job left behind.
        String customCron = '0 0 4 * * ?';
        RelatedSourceLeadExpiryScheduler.scheduleWithCron(customCron);
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT CronExpression FROM CronTrigger
            WHERE CronJobDetail.Name = :RelatedSourceLeadExpiryScheduler.JOB_NAME
        ];
        System.assertEquals(1, jobs.size(), 'Scheduling twice should leave only one job');
        System.assertEquals(customCron, jobs[0].CronExpression, 'Second schedule should win');
    }

    @isTest
    static void testExecuteFiresBatch() {
        RelatedSourceLeadExpiryScheduler sched = new RelatedSourceLeadExpiryScheduler();

        Test.startTest();
        sched.execute(null);
        Test.stopTest();

        Integer batchCount = [
            SELECT COUNT() FROM AsyncApexJob
            WHERE  JobType = 'BatchApex'
            AND    ApexClass.Name = 'Batch_RelatedSourceLeadExpiry'
        ];
        System.assert(batchCount >= 1, 'execute() should fire Batch_RelatedSourceLeadExpiry');
    }
}