/**
 * Daily scheduler: sends "Training Reminder" emails one day before
 * Channel_Partner__c.Training_Date__c...
 *
 * Schedule (one-time, anonymous Apex):
 *   System.schedule('CP Training Reminder Daily', '0 0 10 * * ?', new CPTrainingReminderScheduler());
 *
 * @description   Daily job sending "Training Reminder" emails (notification #5)
 * @author        support2@fingertipplus.com
 * @created       2026-05-25
 * @lastModified  2026-05-25 (one-shot bundle deploy)
 */
public without sharing class CPTrainingReminderScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        run();
    }

    @TestVisible
    private static void run() {
        Date tomorrow = Date.today().addDays(1);
        List<Channel_Partner__c> cps = [
            SELECT Id, User_Id__c, Name, Email__c, OwnerId,
                   Training_Date__c, Training_Completed__c,
                   Mobile_APP_login_Time__c
            FROM Channel_Partner__c
            WHERE Training_Date__c = :tomorrow
            LIMIT 200
        ];
        if (cps.isEmpty()) return;
        CPEmailNotificationService.sendTrainingReminder(cps);
    }
}