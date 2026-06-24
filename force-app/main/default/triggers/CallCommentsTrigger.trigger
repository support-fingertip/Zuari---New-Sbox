trigger CallCommentsTrigger on Call_Comments__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        CallCommentsTriggerHandler.afterInsert(Trigger.new);
    }
}