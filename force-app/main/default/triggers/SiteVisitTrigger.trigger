trigger SiteVisitTrigger on Site_Visit__c (before insert, after insert, after update, after delete) {

     if (SiteVisitTriggerHandler.bypassTrigger) return;   // Added By Siddaling On 09/06/2026
    
    if(Trigger.isBefore && Trigger.isInsert){
        SiteVisitController.checkSiteVisitForRoundRobin(Trigger.New);
       // RoundRobinHandler.siteVisitRoundRobin(Trigger.New);
    }

    if(Trigger.IsAfter && (Trigger.IsInsert || Trigger.IsUpdate)){
        SiteVisitTriggerHandler.handleAfterInsertUpdate(Trigger.new,Trigger.oldMap,Trigger.IsInsert,Trigger.IsUpdate);
        SiteVisitTriggerHandler.handleSiteVisitRoleNotifications(Trigger.new, Trigger.oldMap, Trigger.IsInsert, Trigger.IsUpdate);
        SiteVisitTriggerHandler.handleCustomerArrivedAlert(Trigger.new, Trigger.oldMap, Trigger.IsInsert);
    }

    if(Trigger.IsAfter && Trigger.IsInsert){
        // Send "First Site Visit Scheduled" BEFORE updateChannelPartnerSiteVisitDates
        // stamps First_Site_Visit_Date_Time__c, so the service's null-probe holds.
        CPEmailNotificationService.sendFirstSiteVisitScheduled(Trigger.new);
        SiteVisitTriggerHandler.updateChannelPartnerSiteVisitDates(Trigger.new);
    }

    if(Trigger.IsUpdate && Trigger.IsAfter){
         // Update Channel Partner Completed Site Visit Count
        Set<Id> cpIdsForSVCount = new Set<Id>();
        for (Site_Visit__c sv : Trigger.new) {
            Site_Visit__c oldSv = Trigger.oldMap.get(sv.Id);
            if (sv.Status__c == 'Completed' && oldSv.Status__c != 'Completed' && sv.Channel_Partner1__c != null) {
                cpIdsForSVCount.add(sv.Channel_Partner1__c);
            }
        }
        if (!cpIdsForSVCount.isEmpty()) {
            ChannelPartnerCountHelper.updateCompletedSiteVisitCount(cpIdsForSVCount);
        }
        
          /* ============================================================
       FOR NOTIFICATION RECORD CREATION
        ============================================================ */
        NotificationHandler.createNotificationRecordsForSiteVisit(Trigger.new, Trigger.oldMap);
        // for Creating Reward
        
        SiteVisitTriggerHandler.createReward(Trigger.new, Trigger.oldMap);
    }
    
}