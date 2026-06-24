public without sharing class CustomerPortalNotificationTriggerHandler {

    public static void handleAfterInsert(List<Customer_Portal_Notification__c> newList) {
        List<Id> notificationIds = new List<Id>();
        for (Customer_Portal_Notification__c noti : newList) {
            if (noti.IsActive__c == true && noti.IsNotificationSent__c == false && noti.Created_For_CC__c == true) {
                notificationIds.add(noti.Id);
            }
        }
        sendNotifications(notificationIds);
    }

    public static void handleAfterUpdate(List<Customer_Portal_Notification__c> newList, Map<Id, Customer_Portal_Notification__c> oldMap) {
        List<Id> notificationIds = new List<Id>();
        for (Customer_Portal_Notification__c noti : newList) {
            Customer_Portal_Notification__c oldNoti = oldMap.get(noti.Id);
            if (noti.IsActive__c == true && oldNoti.Updated_Status__c != noti.Updated_Status__c) {
                notificationIds.add(noti.Id);
            }
        }
        sendNotifications(notificationIds);
    }

    private static void sendNotifications(List<Id> notificationIds) {
        for (Id notiId : notificationIds) {
            CPSendNotificationController.sendNotification(String.valueOf(notiId));
        }
    }
}