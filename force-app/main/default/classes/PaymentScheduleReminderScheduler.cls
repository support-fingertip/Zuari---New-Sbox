global class PaymentScheduleReminderScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentScheduleReminderBatch(), 200);
    }
}