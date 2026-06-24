@IsTest
private class CustomerQueryEscalationSchedulerTest {

    @IsTest
    static void testSchedulerMethods() {

        Test.startTest();

        // Test scheduleDaily()
        String jobId = CustomerQueryEscalationScheduler.scheduleDaily();
        System.assertNotEquals(null, jobId);

        // Verify scheduled job created
        CronTrigger ct = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];
        System.assertNotEquals(null, ct);

        // Test executeNow()
        Id batchJobId = CustomerQueryEscalationScheduler.executeNow();
        System.assertNotEquals(null, batchJobId);

        // Test execute() through System.schedule
        String testCron = '0 0 0 1 1 ? 2099';
        System.schedule(
            'CustomerQueryEscalationSchedulerTest',
            testCron,
            new CustomerQueryEscalationScheduler()
        );

        Test.stopTest();
    }
}