trigger LoggedInDeviceTrigger on Logged_in_Device__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        LoggedInDeviceTriggerHandler.propagateLastLoggedTimeToParent(Trigger.new, Trigger.oldMap);
    }
}