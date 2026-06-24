trigger PaymentScheduleTrigger on Payment_Schedule__c (after insert, after update, after delete, after undelete) {
    // CC Notification for Payment Schedule status change
    if (Trigger.isAfter && Trigger.isUpdate) {
        CCNotificationTriggerHandler.handlePaymentScheduleStatusChange(Trigger.new, Trigger.oldMap);
    }

    Set<Id> quoteIds = new Set<Id>();
/*
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Payment_Schedule__c ps : Trigger.new) {
            if (ps.Quote__c != null) quoteIds.add(ps.Quote__c);
        }
    }
    if (Trigger.isDelete) {
        for (Payment_Schedule__c ps : Trigger.old) {
            if (ps.Quote__c != null) quoteIds.add(ps.Quote__c);
        }
    }

    if (!quoteIds.isEmpty()) {
       // PaymentScheduleHelper.recalculateAmounts(quoteIds);
    }
    
    */
}