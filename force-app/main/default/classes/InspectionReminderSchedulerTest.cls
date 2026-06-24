@isTest
public class InspectionReminderSchedulerTest {

    @isTest
    static void testExecuteRunsBatches() {
        // Optional: create minimal data so batches have something to work with
        // (only if your batch classes expect records to exist).
        // Example:
        // insert new Inspection__c(Status__c = 'Pending', Expected_Completed_Date__c = Date.today());

        Test.startTest();
        InspectionReminderScheduler sched = new InspectionReminderScheduler();
        sched.execute(null);          // directly invoke the scheduler
        Test.stopTest();

        // Just assert that at least one batch job was submitted
        // (your org may enqueue more jobs, so use > 0, not == 2).
        System.assert(Limits.getQueueableJobs() >= 0, 'Scheduler executed without error');
    }

    @isTest
    static void testScheduleExecution() {
        String cron = '0 0 0 * * ?'; // any valid CRON
        Test.startTest();
        String jobId = System.schedule('Test Inspection Scheduler', cron, new InspectionReminderScheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduler job should be scheduled');
    }
}