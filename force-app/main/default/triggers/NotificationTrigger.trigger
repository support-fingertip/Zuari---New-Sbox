/**
 * @description
 * Trigger responsible for dispatching push notifications
 * when Notification__c records are created or updated.
 *
 * This trigger listens to AFTER INSERT and AFTER UPDATE events
 * on Notification__c and determines whether a notification
 * should be sent based on business conditions.
 *
 * Trigger Behavior:
 * - AFTER INSERT:
 *   Sends notification when the record is active and
 *   the notification has not yet been sent.
 *
 * - AFTER UPDATE:
 *   Sends notification only when the Updated_Status__c field
 *   changes on an active notification record.
 *
 * Design Considerations:
 * - Bulk-safe implementation using Set<Id>
 * - Prevents duplicate notification dispatch
 * - Delegates processing to NotificationTriggerDispatcher
 * - Keeps trigger logic minimal and readable
 *
 * @usage
 * Automatically executed on Notification__c
 * after insert and after update operations.
 *
 * @author
 * Praveen Kumar
 *
 * @lastModifiedDate
 * 16/01/2026
 *
 * @lastModifiedBy
 * Praveen Kumar
 */
trigger NotificationTrigger on Notification__c (after insert, after update) {

    if (Trigger.isAfter) {

        Set<Id> notificationIds = new Set<Id>();

        for (Notification__c noti : Trigger.new) {

            // AFTER INSERT logic
            if (Trigger.isInsert) {
                if (noti.IsActive__c == true &&
                    noti.IsNotificationSent__c == false) {

                    notificationIds.add(noti.Id);
                }
            }

            // AFTER UPDATE logic
            if (Trigger.isUpdate) {
                Notification__c oldNoti = Trigger.oldMap.get(noti.Id);

                if (noti.IsActive__c == true &&
                    oldNoti.Updated_Status__c != noti.Updated_Status__c) {

                    notificationIds.add(noti.Id);
                }
            }
        }

        // Invoke dispatcher once per trigger execution
        if (!notificationIds.isEmpty()) {
            NotificationTriggerDispatcher.invokeFromTrigger(notificationIds);
        }
    }
}