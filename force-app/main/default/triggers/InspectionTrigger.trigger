trigger InspectionTrigger on Inspection__c (before update, after update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        InspectionTriggerHandler.preventCompletionIfSnagsOpen(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        InspectionTriggerHandler.sendCompletionEmail(Trigger.new, Trigger.oldMap);
    }
}