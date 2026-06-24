/**
 * @description Scheduler wrapper around RelatedSourceLeadExpiryService.
 *
 * Implements the AMC policy:
 *   - Scenario 1: CP lead with no Site Visit completed within 30 days   -> expire
 *   - Scenario 2: CP lead with Site Visit but no Booking within 45 days -> expire
 *
 * On expiry the related source is transferred to the "Direct Team Sales Head"
 * user, a note + Call_Comments__c audit row is written, and an email is sent
 * to the new owner.
 *
 * ------------------------------------------------------------
 *  HOW TO SCHEDULE
 * ------------------------------------------------------------
 *  Run from anonymous Apex (once - it will recur daily at 2:00 AM org time):
 *
 *      RelatedSourceLeadExpiryScheduler.scheduleDaily();
 *
 *  Or schedule manually from Setup > Apex Classes > Schedule Apex
 *  using cron '0 0 2 * * ?'.
 *
 *  IMPORTANT prerequisites (one-time setup):
 *    - Custom Label `Direct_Sales_Head_Username` must exist and contain
 *      the Username (or Alias / Email) of the Sales Head user.
 *    - Custom fields `Related_Source__c.Lead_Expired__c` (Checkbox) and
 *      `Related_Source__c.Expiry_Remarks__c` (Long Text Area) must be deployed.
 *      Their metadata is included alongside this class.
 *    - The two child relationship names used in SOQL
 *      (Site_Visits__r, Bookings__r) must match the child relationship
 *      names of Site_Visit__c.Related_Source__c and Booking__c.Related_Source__c
 *      in your org. Adjust them in RelatedSourceLeadExpiryService if needed.
 *
 *  Author : Auto-generated for AMC Lead Expiry requirement
 *  Date   : 14-05-2026
 */
global class RelatedSourceLeadExpiryScheduler implements Schedulable {

    /** Default daily cron - 2:00 AM org time, every day */
    public static final String DEFAULT_CRON = '0 0 2 * * ?';

    /** Friendly job name shown in Setup > Scheduled Jobs */
    public static final String JOB_NAME     = 'RelatedSourceLeadExpiryDaily';

    global void execute(SchedulableContext sc) {
        try {
            // Fire the batch in 50-record chunks - each chunk is its own
            // transaction with its own 100-SOQL budget, which keeps us
            // safe even when the RelatedSourceTrigger/Handler chain runs
            // SOQL per record on owner change.
            Database.executeBatch(new Batch_RelatedSourceLeadExpiry(), 50);
        } catch (Exception e) {
            // Don't let a single bad day kill the schedule - log loudly
            System.debug(LoggingLevel.ERROR,
                'RelatedSourceLeadExpiryScheduler failed: ' +
                e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    /**
     * Schedules this class to run every day at 2:00 AM org time.
     * Safe to call repeatedly - aborts the existing job (same name) first.
     */
    public static String scheduleDaily() {
        return scheduleWithCron(DEFAULT_CRON);
    }

    /** Schedule with a custom cron expression. Returns the scheduled job Id. */
    public static String scheduleWithCron(String cron) {
        // Abort any existing job with the same name so re-running is idempotent
        for (CronTrigger ct : [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name = :JOB_NAME
        ]) {
            try { System.abortJob(ct.Id); } catch (Exception ignored) {}
        }
        return System.schedule(JOB_NAME, cron, new RelatedSourceLeadExpiryScheduler());
    }
}