trigger SupportTicketTrigger on Support_Ticket__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        SupportTicketService.onBeforeInsert(Trigger.new);
    }
}