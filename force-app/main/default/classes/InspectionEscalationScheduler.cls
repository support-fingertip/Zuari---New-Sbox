/**
 * Schedulable class to run Inspection Escalation Batch
 * Schedule to run daily to check for escalated inspections
 */
public class InspectionEscalationScheduler implements Schedulable {
    
    public void execute(SchedulableContext SC) {
        // Execute the batch with batch size of 50
        InspectionEscalationBatch batch = new InspectionEscalationBatch();
        Database.executeBatch(batch, 50);
    }
    
    /**
     * Utility method to schedule the job
     * Run this in Execute Anonymous to schedule:
     * 
     * // Schedule to run daily at 9 AM
     * String cronExp = '0 0 9 * * ?';
     * String jobName = 'Inspection Escalation Daily Check';
     * InspectionEscalationScheduler scheduler = new InspectionEscalationScheduler();
     * System.schedule(jobName, cronExp, scheduler);
     */
    public static String scheduleDaily() {
        // Schedule to run every day at 9:00 AM
        String cronExp = '0 0 9 * * ?';
        String jobName = 'Inspection Escalation Daily - ' + System.now().format();
        
        InspectionEscalationScheduler scheduler = new InspectionEscalationScheduler();
        return System.schedule(jobName, cronExp, scheduler);
    }
    
    /**
     * Method to execute batch immediately for testing
     */
    public static Id executeNow() {
        InspectionEscalationBatch batch = new InspectionEscalationBatch();
        return Database.executeBatch(batch, 50);
    }
}

/**
 * SCHEDULING INSTRUCTIONS:
 * 
 * To schedule this job, execute the following in Anonymous Apex:
 * 
 * // Option 1: Schedule to run daily at 9 AM
 * String jobId = InspectionEscalationScheduler.scheduleDaily();
 * System.debug('Job scheduled with ID: ' + jobId);
 * 
 * // Option 2: Custom schedule (e.g., every day at 8 AM)
 * String cronExp = '0 0 8 * * ?';
 * String jobName = 'Inspection Escalation Check - 8 AM';
 * System.schedule(jobName, cronExp, new InspectionEscalationScheduler());
 * 
 * // Option 3: Run immediately for testing
 * Id batchId = InspectionEscalationScheduler.executeNow();
 * System.debug('Batch started with ID: ' + batchId);
 * 
 * CRON EXPRESSION FORMAT:
 * Seconds Minutes Hours Day_of_month Month Day_of_week Optional_year
 * 0 0 9 * * ?  = Every day at 9:00 AM
 * 0 0 8 * * ?  = Every day at 8:00 AM
 * 0 0 12 * * ? = Every day at 12:00 PM (noon)
 */