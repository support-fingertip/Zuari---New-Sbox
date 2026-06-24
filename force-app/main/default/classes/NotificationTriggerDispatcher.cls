/**
 * @description
 * Dispatcher class to invoke notification logic from trigger context
 * in a bulk-safe and decoupled manner.
 *
 * This class acts as an intermediary between triggers 
 *
 * @author
 * Praveen Kumar
 *
 * @lastModifiedDate
 * 16/01/2026
 *
 */
public with sharing class NotificationTriggerDispatcher {

    public static void invokeFromTrigger(Set<Id> notificationIds) {
    for (Id recordId : notificationIds) {
        SendNotificationController.sendNotification(recordId);
    }
}
}