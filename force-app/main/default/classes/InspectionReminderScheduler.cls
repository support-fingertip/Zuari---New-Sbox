global class InspectionReminderScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Call batch class for the actual logic
        Database.executeBatch(new InspectionReminderBatch(), 50);
        Database.executeBatch(new InspectionEsclationBatch(), 50);
    }
}