trigger CustomerPortalNotificationTrigger on Customer_Portal_Notification__c (after insert, after update) {

    if (Trigger.isAfter && Trigger.isInsert) {
        CustomerPortalNotificationTriggerHandler.handleAfterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        CustomerPortalNotificationTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}