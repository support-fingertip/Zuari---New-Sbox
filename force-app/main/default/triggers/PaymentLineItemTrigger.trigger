trigger PaymentLineItemTrigger on Payment_Line_Item__c (after update) {
    
    
    if(Trigger.IsUpdate && Trigger.IsAfter){

           /* ============================================================
       FOR NOTIFICATION RECORD CREATION
        ============================================================ */
        NotificationHandler.createNotificationRecordsForPayment (Trigger.new, Trigger.oldMap);
     
    }
}