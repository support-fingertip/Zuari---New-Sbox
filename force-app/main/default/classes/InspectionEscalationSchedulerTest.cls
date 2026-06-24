@IsTest
public class InspectionEscalationSchedulerTest {

    @IsTest
    static void testScheduleDaily_createsCronJob() {
        Test.startTest();
        String jobId = InspectionEscalationScheduler.scheduleDaily();
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'scheduleDaily must return a job id');
        
        // Verify job exists
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime, State
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];
        System.assertEquals('WAITING', ct.State, 'Scheduled job should be in WAITING state');
        System.assertEquals('0 0 9 * * ?', ct.CronExpression, 'Cron expression should match daily 9AM schedule');
    }

    @IsTest
    static void testExecute_schedulable_runsAndEnqueuesBatch() {
        // Schedule the job (any cron in test is fine)
        String cronExp = '0 0 0 1 1 ? 2099'; // future date, won’t run except via stopTest()
        Test.startTest();
        String jobId = System.schedule('Inspection Escalation Test Job', cronExp, new InspectionEscalationScheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'System.schedule should return a job id');

        // After stopTest(), scheduled job executes once, which should enqueue the batch.
        // We verify that at least one batch job exists for InspectionEscalationBatch.
        List<AsyncApexJob> batchJobs = [
            SELECT Id, ApexClass.Name, JobType, Status
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'InspectionEscalationBatch'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assert(!batchJobs.isEmpty(),
            'Scheduler should enqueue InspectionEscalationBatch when executed');
    }

    @IsTest
    static void testExecuteNow_returnsBatchId() {
        Test.startTest();
        Id batchJobId = InspectionEscalationScheduler.executeNow();
        Test.stopTest();

        System.assertNotEquals(null, batchJobId, 'executeNow must return batch job id');

        AsyncApexJob job = [
            SELECT Id, ApexClass.Name, JobType, Status
            FROM AsyncApexJob
            WHERE Id = :batchJobId
            LIMIT 1
        ];
        System.assertEquals('BatchApex', job.JobType, 'executeNow should start a BatchApex job');
        System.assertEquals('InspectionEscalationBatch', job.ApexClass.Name, 'Batch class name should match');
    }
}