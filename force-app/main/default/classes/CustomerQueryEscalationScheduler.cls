/**
 * Schedulable wrapper around CustomerQueryEscalationBatch.
 *
 * To schedule from Execute Anonymous:
 *   CustomerQueryEscalationScheduler.scheduleDaily();
 *
 * To run once for testing:
 *   CustomerQueryEscalationScheduler.executeNow();
 */
public class CustomerQueryEscalationScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CustomerQueryEscalationBatch(), 50);
    }

    public static String scheduleDaily() {
        String cronExp = '0 0 2 * * ?';
        String jobName = 'Customer Query Escalation Daily - ' + System.now().format();
        return System.schedule(jobName, cronExp, new CustomerQueryEscalationScheduler());
    }

    public static Id executeNow() {
        return Database.executeBatch(new CustomerQueryEscalationBatch(), 50);
    }
}