trigger CustomerQueryTrigger on Customer_Query__c (before insert, after insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        CustomerQueryAssignmentService.assignOwners(Trigger.new);
        CustomerQueryEscalationService.initializeOnInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        System.debug('Called');
        CustomerQueryTriggerHandler.afterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        CustomerQueryTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        CCNotificationTriggerHandler.handleCustomerQueryStatusChange(Trigger.new, Trigger.oldMap);
    }
}