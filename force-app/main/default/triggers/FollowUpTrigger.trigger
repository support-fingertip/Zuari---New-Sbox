trigger FollowUpTrigger on Follow_up__c (After Update) {

    
    if(Trigger.IsUpdate && Trigger.IsAfter){

           /* ============================================================
       FOR NOTIFICATION RECORD CREATION
        ============================================================ */
        NotificationHandler.createNotificationRecordsForFollowUp (Trigger.new, Trigger.oldMap);
        
         /* ============================================================
           UPDATE RELATED SOURCE FOLLOW-UP DATES
        ============================================================ */
        FollowUpHandler.updateRelatedSourceDates(Trigger.new);
      
    }

}