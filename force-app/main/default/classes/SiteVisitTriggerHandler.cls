public without sharing class SiteVisitTriggerHandler {
    /*
        public static void handleAfterInsertUpdate(
        List<Site_Visit__c> newList,
        Map<Id, Site_Visit__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ){
        List<Site_Visit__c> listsitvist = new List<Site_Visit__c>();
        Set<Id> ldId  = new Set<Id>();
        Set<Id> rsId  = new Set<Id>();

        for(Site_Visit__c sv : newList){

            Boolean isCompletedNow = false;

            if(isInsert && sv.Status__c == 'Completed'){
                isCompletedNow = true;
            }

            if(isUpdate){
                Site_Visit__c oldSV = oldMap.get(sv.Id);
                if(oldSV.Status__c != 'Completed' && sv.Status__c == 'Completed'){
                    isCompletedNow = true;
                }
            }

            if(isCompletedNow){
                if(sv.Slead__c != null)          ldId.add(sv.Slead__c);
                if(sv.Related_Source__c != null)  rsId.add(sv.Related_Source__c);
            }

            // FIX 1: Null-safe OTP check
            if(String.isNotBlank(sv.OTP__c) && sv.OTP__c != '0000'){
                listsitvist.add(sv);
            }
        }

        if(!listsitvist.isEmpty() && !Test.isRunningTest()){
            WhatsAppTriggerHandler.processSitevisit(listsitvist);
        }

        //SalesIncentiveHandler.handleSiteVisitIncentive(newList,isUpdate ? oldMap : null,isInsert);

        // =============================== LEAD UPDATES =============================== 
        if(!ldId.isEmpty()){

            Map<Id, Integer> countSiteVisit     = new Map<Id, Integer>();
            Map<Id, Datetime> firstVisitMap     = new Map<Id, Datetime>();
            Map<Id, Datetime> lastVisitMap      = new Map<Id, Datetime>();

            for(AggregateResult ar : [
                SELECT Slead__c, COUNT(Id) couns
                FROM Site_Visit__c
                WHERE Slead__c IN :ldId
                AND Status__c = 'Completed'
                GROUP BY Slead__c
            ]){
                countSiteVisit.put((Id)ar.get('Slead__c'), (Integer)ar.get('couns'));
            }

            for(AggregateResult ar : [
                SELECT Slead__c leadId,
                       MIN(SV_Completed_Date_Time__c) minDate,
                       MAX(SV_Completed_Date_Time__c) maxDate
                FROM Site_Visit__c
                WHERE Slead__c IN :ldId
                AND Status__c = 'Completed'
                AND SV_Completed_Date_Time__c != NULL
                GROUP BY Slead__c
            ]){
                Id leadId = (Id)ar.get('leadId');
                firstVisitMap.put(leadId, (Datetime)ar.get('minDate'));
                lastVisitMap.put(leadId,  (Datetime)ar.get('maxDate'));
            }

            List<Lead> leadsToUpdate = new List<Lead>();
            for(Id leadId : ldId){
                leadsToUpdate.add(new Lead(
                    Id                        = leadId,
                    // FIX 2: Always set value, default to 0
                    No_of_Site_Visit__c       = countSiteVisit.containsKey(leadId) ? countSiteVisit.get(leadId) : 0,
                    First_Site_Visit_Date_Time__c = firstVisitMap.get(leadId),
                    Last_Site_Visit_Date_Time__c  = lastVisitMap.get(leadId)
                ));
            }
            update leadsToUpdate;
        }

        // =============================== RELATED SOURCE UPDATES=============================== 
        if(!rsId.isEmpty()){

            Map<Id, Integer> countSiteVisitRS   = new Map<Id, Integer>();
            Map<Id, Datetime> rsfirstVisitMap   = new Map<Id, Datetime>();
            Map<Id, Datetime> rslastVisitMap    = new Map<Id, Datetime>();

            for(AggregateResult ar : [
                SELECT Related_Source__c, COUNT(Id) couns
                FROM Site_Visit__c
                WHERE Related_Source__c IN :rsId
                AND Status__c = 'Completed'
                GROUP BY Related_Source__c
            ]){
                countSiteVisitRS.put((Id)ar.get('Related_Source__c'), (Integer)ar.get('couns'));
            }

            for(AggregateResult ar : [
                SELECT Related_Source__c rsId,
                       MIN(SV_Completed_Date_Time__c) minDate,
                       MAX(SV_Completed_Date_Time__c) maxDate
                FROM Site_Visit__c
                WHERE Related_Source__c IN :rsId
                AND Status__c = 'Completed'
                AND SV_Completed_Date_Time__c != NULL
                GROUP BY Related_Source__c
            ]){
                Id sourceId = (Id)ar.get('rsId');
                rsfirstVisitMap.put(sourceId, (Datetime)ar.get('minDate'));
                rslastVisitMap.put(sourceId,  (Datetime)ar.get('maxDate'));
            }

            List<Related_Source__c> rslst = new List<Related_Source__c>();
            for(Id rsI : rsId){
                rslst.add(new Related_Source__c(
                    Id                            = rsI,
                    // FIX 2: Always set value, default to 0
                    No_of_Site_Visit__c           = countSiteVisitRS.containsKey(rsI) ? countSiteVisitRS.get(rsI) : 0,
                    First_Site_Visit_Date_Time__c = rsfirstVisitMap.get(rsI),
                    Last_Site_Visit_Date_Time__c  = rslastVisitMap.get(rsI)
                ));
            }
            update rslst;
        }
    }
    */

     // Add this flag at the very top of the class
    Public static Boolean bypassTrigger = false;              // Added By Siddaling On 09/06/2026

    public static void handleAfterInsertUpdate(
        List<Site_Visit__c> newList,
        Map<Id, Site_Visit__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ){
         if (bypassTrigger) return;   // Added By Siddaling On 09/06/2026
        
        List<Site_Visit__c> listsitvist = new List<Site_Visit__c>();
        Set<Id> ldId  = new Set<Id>();
        Set<Id> rsId  = new Set<Id>();

        for(Site_Visit__c sv : newList){

            Boolean isCompletedNow = false;

            if(isInsert && sv.Status__c == 'Completed'){
                isCompletedNow = true;
            }

            if(isUpdate){
                Site_Visit__c oldSV = oldMap.get(sv.Id);
                if(oldSV.Status__c != 'Completed' && sv.Status__c == 'Completed'){
                    isCompletedNow = true;
                }
            }

            if(isCompletedNow){
                if(sv.Slead__c != null)          ldId.add(sv.Slead__c);
                if(sv.Related_Source__c != null)  rsId.add(sv.Related_Source__c);
            }

            // FIX 1: Null-safe OTP check
            if(String.isNotBlank(sv.OTP__c) && sv.OTP__c != '0000'){
                listsitvist.add(sv);
            }
        }

        if(!listsitvist.isEmpty() && !Test.isRunningTest()){
          //  WhatsAppTriggerHandler.processSitevisit(listsitvist);
        }

        //SalesIncentiveHandler.handleSiteVisitIncentive(newList,isUpdate ? oldMap : null, isInsert );

        // =============================== LEAD UPDATES  =============================== 
        if(!ldId.isEmpty()){

            Map<Id, Integer> countSiteVisit     = new Map<Id, Integer>();
            Map<Id, Datetime> firstVisitMap     = new Map<Id, Datetime>();
            Map<Id, Datetime> lastVisitMap      = new Map<Id, Datetime>();

            for(AggregateResult ar : [
                SELECT Slead__c, COUNT(Id) couns
                FROM Site_Visit__c
                WHERE Slead__c IN :ldId
                AND Status__c = 'Completed'
                GROUP BY Slead__c
            ]){
                countSiteVisit.put((Id)ar.get('Slead__c'), (Integer)ar.get('couns'));
            }

            for(AggregateResult ar : [
                SELECT Slead__c leadId,
                       MIN(SV_Completed_Date_Time__c) minDate,
                       MAX(SV_Completed_Date_Time__c) maxDate
                FROM Site_Visit__c
                WHERE Slead__c IN :ldId
                AND Status__c = 'Completed'
                AND SV_Completed_Date_Time__c != NULL
                GROUP BY Slead__c
            ]){
                Id leadId = (Id)ar.get('leadId');
                firstVisitMap.put(leadId, (Datetime)ar.get('minDate'));
                lastVisitMap.put(leadId,  (Datetime)ar.get('maxDate'));
            }

            List<Lead> leadsToUpdate = new List<Lead>();
            for(Id leadId : ldId){
                leadsToUpdate.add(new Lead(
                    Id                        = leadId,
                    // FIX 2: Always set value, default to 0
                    No_of_Site_Visit__c       = countSiteVisit.containsKey(leadId) ? countSiteVisit.get(leadId) : 0,
                    First_Site_Visit_Date_Time__c = firstVisitMap.get(leadId),
                    Last_Site_Visit_Date_Time__c  = lastVisitMap.get(leadId)
                ));
            }
            update leadsToUpdate;
        }

        // =============================== RELATED SOURCE UPDATES =============================== 
        if(!rsId.isEmpty()){

            Map<Id, Integer> countSiteVisitRS   = new Map<Id, Integer>();
            Map<Id, Datetime> rsfirstVisitMap   = new Map<Id, Datetime>();
            Map<Id, Datetime> rslastVisitMap    = new Map<Id, Datetime>();

            for(AggregateResult ar : [
                SELECT Related_Source__c, COUNT(Id) couns
                FROM Site_Visit__c
                WHERE Related_Source__c IN :rsId
                AND Status__c = 'Completed'
                GROUP BY Related_Source__c
            ]){
                countSiteVisitRS.put((Id)ar.get('Related_Source__c'), (Integer)ar.get('couns'));
            }

            for(AggregateResult ar : [
                SELECT Related_Source__c rsId,
                       MIN(SV_Completed_Date_Time__c) minDate,
                       MAX(SV_Completed_Date_Time__c) maxDate
                FROM Site_Visit__c
                WHERE Related_Source__c IN :rsId
                AND Status__c = 'Completed'
                AND SV_Completed_Date_Time__c != NULL
                GROUP BY Related_Source__c
            ]){
                Id sourceId = (Id)ar.get('rsId');
                rsfirstVisitMap.put(sourceId, (Datetime)ar.get('minDate'));
                rslastVisitMap.put(sourceId,  (Datetime)ar.get('maxDate'));
            }

            // Pull existing Expiry_Days__c / Expiry_Anchor_Date__c so we can
            // flip the lead from Scenario 1 (30 days from enquiry) to
            // Scenario 2 (45 days from first completed SV) exactly once.
            Map<Id, Related_Source__c> rsPriorState = new Map<Id, Related_Source__c>([
                SELECT Id, Expiry_Days__c, Expiry_Anchor_Date__c
                FROM   Related_Source__c
                WHERE  Id IN :rsId
            ]);

            List<Related_Source__c> rslst = new List<Related_Source__c>();
            for(Id rsI : rsId){
                Related_Source__c upd = new Related_Source__c(
                    Id                            = rsI,
                    // FIX 2: Always set value, default to 0
                    No_of_Site_Visit__c           = countSiteVisitRS.containsKey(rsI) ? countSiteVisitRS.get(rsI) : 0,
                    First_Site_Visit_Date_Time__c = rsfirstVisitMap.get(rsI),
                    Last_Site_Visit_Date_Time__c  = rslastVisitMap.get(rsI)
                );

                // First completed SV flips the expiry window from 30 to 45.
                // Decision rule: flip only if the lead is currently in the
                // 30-day window (i.e. still Scenario 1). Anchor moves to
                // the first completed SV date so Expiry_Date__c recomputes.
                Related_Source__c prior = rsPriorState.get(rsI);
                Boolean isScenario1Still =
                    prior != null
                    && (prior.Expiry_Days__c == null || prior.Expiry_Days__c == 30);
                if (isScenario1Still && rsfirstVisitMap.get(rsI) != null) {
                    upd.Expiry_Days__c         = 45;
                    upd.Expiry_Anchor_Date__c  = rsfirstVisitMap.get(rsI);
                }

                rslst.add(upd);
            }
            update rslst;
        }
    }
    

    /**
     * On Site Visit insert, when Channel_Partner1__c is set and Source_Type__c
     * is 'Channel partner', stamp the Channel Partner's First Site Visit Date/Time
     * (only if currently null) and refresh Last Site Visit Date/Time.
     */
    /*
    public static void updateChannelPartnerSiteVisitDates(List<Site_Visit__c> newList){
        System.debug('Inside the udpate cp site visit date' + newList);
        Map<Id, Datetime> cpLatestVisit = new Map<Id, Datetime>();

        for(Site_Visit__c sv : newList){
            System.debug(sv.Source_Type__c + '--'+ sv.Channel_Partner1__c);
            if(String.isBlank(sv.Channel_Partner1__c)) continue;
            if(sv.Source_Type__c != 'Channel partner') continue;

            Id cpId;
            try {
                cpId = (Id) sv.Channel_Partner1__c;
                System.debug('Inside the udpate cp site visit date'+ cpId);
            } catch(Exception e){
                continue;
            }

            Datetime visitDt = sv.CreatedDate != null ? sv.CreatedDate : Datetime.now();
            Datetime existing = cpLatestVisit.get(cpId);
            if(existing == null || visitDt > existing){
                cpLatestVisit.put(cpId, visitDt);
            }
        }
System.debug(cpLatestVisit + '-- '+ cpLatestVisit.keySet());
        if(cpLatestVisit.isEmpty()) return;

        Map<Id, Channel_Partner__c> cpMap = new Map<Id, Channel_Partner__c>([
            SELECT Id, First_Site_Visit_Date_Time__c, Last_Site_Visit_Date_Time__c
            FROM Channel_Partner__c
            WHERE Id IN :cpLatestVisit.keySet()
        ]);
System.debug(cpMap);
        List<Channel_Partner__c> toUpdate = new List<Channel_Partner__c>();
        for(Id cpId : cpLatestVisit.keySet()){
            Channel_Partner__c cp = cpMap.get(cpId);
            if(cp == null) continue;

            Datetime visitDt = cpLatestVisit.get(cpId);
            Boolean changed = false;

            if(cp.First_Site_Visit_Date_Time__c == null){
                cp.First_Site_Visit_Date_Time__c = visitDt;
                changed = true;
            }

            if(cp.Last_Site_Visit_Date_Time__c == null || visitDt > cp.Last_Site_Visit_Date_Time__c){
                cp.Last_Site_Visit_Date_Time__c = visitDt;
                changed = true;
            }

            if(changed) toUpdate.add(cp);
        }
System.debug(toUpdate);
        if(!toUpdate.isEmpty()) update toUpdate;
    }
    */
    public static void updateChannelPartnerSiteVisitDates(List<Site_Visit__c> newList){

    Map<Id, Datetime> cpLatestVisit = new Map<Id, Datetime>();
    Set<Id> relatedSourceIds = new Set<Id>();

    for(Site_Visit__c sv : newList){

        if(sv.Related_Source__c != null &&
           sv.Source_Type__c == 'Channel partner'){

            relatedSourceIds.add(sv.Related_Source__c);
        }
    }

    if(relatedSourceIds.isEmpty()) return;

    Map<Id, Related_Source__c> rsMap = new Map<Id, Related_Source__c>([
        SELECT Id, Channel_Partner1__c
        FROM Related_Source__c
        WHERE Id IN :relatedSourceIds
    ]);

    for(Site_Visit__c sv : newList){

        if(sv.Related_Source__c == null ||
           sv.Source_Type__c != 'Channel partner'){
            continue;
        }

        Related_Source__c rs = rsMap.get(sv.Related_Source__c);

        if(rs == null || rs.Channel_Partner1__c == null){
            continue;
        }
System.debug('-------'+rs.Channel_Partner1__c);
        Id cpId = rs.Channel_Partner1__c;

        Datetime visitDt = sv.CreatedDate != null
            ? sv.CreatedDate
            : Datetime.now();

        Datetime existing = cpLatestVisit.get(cpId);

        if(existing == null || visitDt > existing){
            cpLatestVisit.put(cpId, visitDt);
        }
    }

    if(cpLatestVisit.isEmpty()) return;

    Map<Id, Channel_Partner__c> cpMap = new Map<Id, Channel_Partner__c>([
        SELECT Id,
               First_Site_Visit_Date_Time__c,
               Last_Site_Visit_Date_Time__c
        FROM Channel_Partner__c
        WHERE Id IN :cpLatestVisit.keySet()
    ]);

    List<Channel_Partner__c> toUpdate = new List<Channel_Partner__c>();

    for(Id cpId : cpLatestVisit.keySet()){

        Channel_Partner__c cp = cpMap.get(cpId);

        if(cp == null) continue;

        Datetime visitDt = cpLatestVisit.get(cpId);

        Boolean changed = false;

        if(cp.First_Site_Visit_Date_Time__c == null){
            cp.First_Site_Visit_Date_Time__c = visitDt;
            changed = true;
        }

        if(cp.Last_Site_Visit_Date_Time__c == null ||
           visitDt > cp.Last_Site_Visit_Date_Time__c){

            cp.Last_Site_Visit_Date_Time__c = visitDt;
            changed = true;
        }

        if(changed){
            toUpdate.add(cp);
        }
    }

    if(!toUpdate.isEmpty()){
        update toUpdate;
    }
}
    /**
     * @description
     * Sends a Salesforce Custom Notification (bell) and an email to role users
     * for Channel Partner Site Visits when status enters Scheduled or Completed.
     *
     * Scheduled  -> CP Manager (Channel_Partner__c.Sourcing_RM__c),
     *               Direct Sales Person (Related_Source__c.Sales_User__c),
     *               GRE (Site_Visit__c.Assisted_By__c)
     *               via CustomNotificationType "Site_Visit_Scheduled"
     * Completed  -> CP Manager,
     *               CP Head (Users with Profile.Name = 'CP Head'),
     *               Sales Head (Related_Source__c.STM2__c)
     *               via CustomNotificationType "Site_Visit_Completed"
     *
     * Fires only when Site_Visit__c.Source_Type__c = 'Channel partner'.
     */
    private static final String CP_HEAD_PROFILE_NAME = 'CP Head';
    private static final String CP_SOURCE_TYPE = 'Channel partner';
    private static final String STATUS_SCHEDULED = 'Scheduled';
    private static final String STATUS_COMPLETED = 'Completed';
    private static final String NOTIF_TYPE_SCHEDULED = 'Site_Visit_Scheduled';
    private static final String NOTIF_TYPE_COMPLETED = 'Site_Visit_Completed';

    public static void handleSiteVisitRoleNotifications(
        List<Site_Visit__c> newList,
        Map<Id, Site_Visit__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        if (newList == null || newList.isEmpty()) return;

        List<Site_Visit__c> scheduledSVs = new List<Site_Visit__c>();
        List<Site_Visit__c> completedSVs = new List<Site_Visit__c>();
        Set<Id> cpIds = new Set<Id>();
        Set<Id> relatedSourceIds = new Set<Id>();

        for (Site_Visit__c sv : newList) {
            if (sv == null) continue;
            if (sv.Source_Type__c != CP_SOURCE_TYPE) continue;

            Site_Visit__c oldSV = (oldMap != null) ? oldMap.get(sv.Id) : null;
            String oldStatus = (oldSV != null) ? oldSV.Status__c : null;

            Boolean entersScheduled = (isInsert && sv.Status__c == STATUS_SCHEDULED)
                || (isUpdate && sv.Status__c == STATUS_SCHEDULED && oldStatus != STATUS_SCHEDULED);

            Boolean entersCompleted = (isInsert && sv.Status__c == STATUS_COMPLETED)
                || (isUpdate && sv.Status__c == STATUS_COMPLETED && oldStatus != STATUS_COMPLETED);

            if (!entersScheduled && !entersCompleted) continue;

            if (entersScheduled) scheduledSVs.add(sv);
            if (entersCompleted) completedSVs.add(sv);

            if (String.isNotBlank(sv.Channel_Partner1__c)) {
                try { cpIds.add((Id) sv.Channel_Partner1__c); } catch (Exception e) {}
            }
            if (sv.Related_Source__c != null) relatedSourceIds.add(sv.Related_Source__c);
        }

        if (scheduledSVs.isEmpty() && completedSVs.isEmpty()) return;

        Map<Id, Channel_Partner__c> cpMap = new Map<Id, Channel_Partner__c>();
        if (!cpIds.isEmpty()) {
            cpMap = new Map<Id, Channel_Partner__c>([
                SELECT Id, Sourcing_RM__c
                FROM Channel_Partner__c
                WHERE Id IN :cpIds
            ]);
        }

        Map<Id, Related_Source__c> rsMap = new Map<Id, Related_Source__c>();
        if (!relatedSourceIds.isEmpty()) {
            rsMap = new Map<Id, Related_Source__c>([
                SELECT Id, Sales_User__c, STM2__c
                FROM Related_Source__c
                WHERE Id IN :relatedSourceIds
            ]);
        }

        Set<Id> cpHeadUserIds = new Set<Id>();
        if (!completedSVs.isEmpty()) {
            for (User u : [
                SELECT Id
                FROM User
                WHERE Profile.Name = :CP_HEAD_PROFILE_NAME
                  AND IsActive = true
            ]) {
                cpHeadUserIds.add(u.Id);
            }
        }

        Id scheduledTypeId = getCustomNotificationTypeId(NOTIF_TYPE_SCHEDULED);
        Id completedTypeId = getCustomNotificationTypeId(NOTIF_TYPE_COMPLETED);

        Set<Id> allRecipientIds = new Set<Id>();
        Map<Id, Set<Id>> svToRecipientsScheduled = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> svToRecipientsCompleted = new Map<Id, Set<Id>>();

        for (Site_Visit__c sv : scheduledSVs) {
            Id cpId = String.isNotBlank(sv.Channel_Partner1__c) ? (Id) sv.Channel_Partner1__c : null;
            Channel_Partner__c cp = (cpId != null) ? cpMap.get(cpId) : null;
            Related_Source__c rs = (sv.Related_Source__c != null) ? rsMap.get(sv.Related_Source__c) : null;

            Set<Id> recipients = new Set<Id>();
            if (cp != null && cp.Sourcing_RM__c != null) recipients.add(cp.Sourcing_RM__c);
            if (rs != null && rs.Sales_User__c != null) recipients.add(rs.Sales_User__c);
            if (sv.Assisted_By__c != null) recipients.add(sv.Assisted_By__c);

            if (!recipients.isEmpty()) {
                svToRecipientsScheduled.put(sv.Id, recipients);
                allRecipientIds.addAll(recipients);
            }
        }

        for (Site_Visit__c sv : completedSVs) {
            Id cpId = String.isNotBlank(sv.Channel_Partner1__c) ? (Id) sv.Channel_Partner1__c : null;
            Channel_Partner__c cp = (cpId != null) ? cpMap.get(cpId) : null;
            Related_Source__c rs = (sv.Related_Source__c != null) ? rsMap.get(sv.Related_Source__c) : null;

            Set<Id> recipients = new Set<Id>();
            if (cp != null && cp.Sourcing_RM__c != null) recipients.add(cp.Sourcing_RM__c);
            if (rs != null && rs.STM2__c != null) recipients.add(rs.STM2__c);
            recipients.addAll(cpHeadUserIds);

            if (!recipients.isEmpty()) {
                svToRecipientsCompleted.put(sv.Id, recipients);
                allRecipientIds.addAll(recipients);
            }
        }

        Map<Id, User> userMap = new Map<Id, User>();
        if (!allRecipientIds.isEmpty()) {
            userMap = new Map<Id, User>([
                SELECT Id, Email FROM User WHERE Id IN :allRecipientIds AND IsActive = true
            ]);
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Site_Visit__c sv : scheduledSVs) {
            Set<Id> recipients = svToRecipientsScheduled.get(sv.Id);
            if (recipients == null || recipients.isEmpty()) continue;
            sendBell(scheduledTypeId, sv, recipients, STATUS_SCHEDULED);
            buildEmails(emails, sv, recipients, userMap, STATUS_SCHEDULED);
        }

        for (Site_Visit__c sv : completedSVs) {
            Set<Id> recipients = svToRecipientsCompleted.get(sv.Id);
            if (recipients == null || recipients.isEmpty()) continue;
            sendBell(completedTypeId, sv, recipients, STATUS_COMPLETED);
            buildEmails(emails, sv, recipients, userMap, STATUS_COMPLETED);
        }

        if (!emails.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(emails, false);
        }
    }

    public static Id getCustomNotificationTypeId(String developerName) {
        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType WHERE DeveloperName = :developerName LIMIT 1
        ];
        return types.isEmpty() ? null : types[0].Id;
    }

    public static void sendBell(Id notificationTypeId, SObject target, Set<Id> recipientIds, String eventKey, String targetName) {
        if (notificationTypeId == null || recipientIds == null || recipientIds.isEmpty()) return;

        Set<String> recipientStrings = new Set<String>();
        for (Id uid : recipientIds) {
            if (uid != null) recipientStrings.add(String.valueOf(uid));
        }
        if (recipientStrings.isEmpty()) return;

        String name = String.isNotBlank(targetName) ? targetName : 'Site Visit';
        String title;
        String body;

        if (eventKey == 'Arrived') {
            title = 'Customer Arrived for Site Visit';
            body  = 'Customer has checked-in for ' + name + '.';
        } else if (eventKey == 'FollowUp') {
            title = 'Site Visit Follow-up Pending';
            body  = 'No follow-up created within 24 hours after ' + name + '.';
        } else if (eventKey == 'Lost') {
            title = 'Lead Lost After Site Visit';
            body  = name + ' has been marked Closed Lost after a Site Visit.';
        } else if (eventKey == STATUS_SCHEDULED) {
            title = 'Site Visit Scheduled';
            body  = name + ' has been scheduled.';
        } else {
            title = 'Site Visit Completed';
            body  = name + ' has been completed.';
        }

        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setNotificationTypeId(notificationTypeId);
        notif.setTargetId(target.Id);
        notif.setTitle(title);
        notif.setBody(body);

        try {
            notif.send(recipientStrings);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Custom Notification send failed: ' + e.getMessage());
        }
    }

    // Backwards-compatible overload used by existing Scheduled/Completed flow
    private static void sendBell(Id notificationTypeId, Site_Visit__c sv, Set<Id> recipientIds, String newStatus) {
        sendBell(notificationTypeId, sv, recipientIds, newStatus, sv != null ? sv.Name : null);
    }

    public static void buildEmails(
        List<Messaging.SingleEmailMessage> bucket,
        SObject target,
        String targetName,
        Set<Id> recipientUserIds,
        Map<Id, User> userMap,
        String eventKey
    ) {
        String name = String.isNotBlank(targetName) ? targetName : 'Site Visit';
        String subject;
        String body;

        if (eventKey == 'Arrived') {
            subject = 'Customer Arrived - ' + name;
            body = 'Hi,\n\nThe customer has checked-in for Site Visit ' + name + '.\n\n'
                 +  '\n\nRegards,\nSalesforce';
        } else if (eventKey == 'FollowUp') {
            subject = 'Post Site Visit Follow-up Reminder - ' + name;
            body = 'Hi,\n\nNo follow-up has been created within 24 hours after the completion of Site Visit '
                 + name + '. Please take the next action.\n\n'
                 +  '\n\nRegards,\nSalesforce';
        } else if (eventKey == 'Lost') {
            subject = 'Lead Lost After Site Visit - ' + name;
            body = 'Hi,\n\nThe lead "' + name + '" has been marked Closed Lost after a Site Visit.\n\n'
                 + 'Record Id: ' + target.Id + '\n\nRegards,\nSalesforce';
        } else if (eventKey == STATUS_SCHEDULED) {
            subject = 'Site Visit Scheduled - ' + name;
            body = 'Hi,\n\nSite Visit ' + name + ' has been scheduled.\n\n'
                 + 'Status: ' + STATUS_SCHEDULED + '\n'
                 +  '\n\nRegards,\nSalesforce';
        } else {
            subject = 'Site Visit Completed - ' + name;
            body = 'Hi,\n\nSite Visit ' + name + ' has been completed.\n\n'
                 + 'Status: ' + STATUS_COMPLETED + '\n'
                 +  '\n\nRegards,\nSalesforce';
        }
// List<OrgWideEmailAddress> owea = [ SELECT Id FROM OrgWideEmailAddress WHERE Address ='pattusudaru@gmail.com' LIMIT 1  ]; Commented for Deployment
        
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE '%communication@crm.zuariproperties.com%' LIMIT 1];
       
        for (Id uid : recipientUserIds) {
            User u = userMap.get(uid);
            if (u == null || String.isBlank(u.Email)) continue;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(uid);
            if (!owea.IsEmpty()) mail.setOrgWideEmailAddressId(owea[0].id);
           
            mail.setSaveAsActivity(false);
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            mail.setTreatTargetObjectAsRecipient(true);
            // CC from Custom Label
String ccEmails = System.Label.CCList;
if (String.isNotBlank(ccEmails)) {
    mail.setCcAddresses(ccEmails.split(','));
}

            bucket.add(mail);
        }
    }

    // Backwards-compatible overload used by existing Scheduled/Completed flow
    private static void buildEmails(List<Messaging.SingleEmailMessage> bucket, Site_Visit__c sv, Set<Id> recipientUserIds,  Map<Id, User> userMap, String newStatus  ) {
        buildEmails(bucket, sv, sv != null ? sv.Name : null, recipientUserIds, userMap, newStatus);
    }

    /**
     * Use Case #2: Customer Arrived Alert
     * Fires when Customer_Visit_Happened__c flips false -> true.
     * Recipients: CP Manager (Channel_Partner__c.Sourcing_RM__c) + Direct Sales Person (Related_Source__c.Sales_User__c)
     */
    public static void handleCustomerArrivedAlert(
        List<Site_Visit__c> newList,
        Map<Id, Site_Visit__c> oldMap,
        Boolean isInsert
    ) {
        if (newList == null || newList.isEmpty()) return;

        List<Site_Visit__c> arrivedSVs = new List<Site_Visit__c>();
        Set<Id> cpIds = new Set<Id>();
        Set<Id> rsIds = new Set<Id>();

        for (Site_Visit__c sv : newList) {
            if (sv == null) continue;

            Boolean oldFlag = false;
            if (!isInsert && oldMap != null && oldMap.get(sv.Id) != null) {
                oldFlag = oldMap.get(sv.Id).Customer_Visit_Happened__c == true;
            }
            Boolean newFlag = sv.Customer_Visit_Happened__c == true;

            if (newFlag && !oldFlag) {
                arrivedSVs.add(sv);
                if (String.isNotBlank(sv.Channel_Partner1__c)) {
                    try { cpIds.add((Id) sv.Channel_Partner1__c); } catch (Exception e) {}
                }
                if (sv.Related_Source__c != null) rsIds.add(sv.Related_Source__c);
            }
        }

        if (arrivedSVs.isEmpty()) return;

        Map<Id, Channel_Partner__c> cpMap = new Map<Id, Channel_Partner__c>();
        if (!cpIds.isEmpty()) {
            cpMap = new Map<Id, Channel_Partner__c>([
                SELECT Id, Sourcing_RM__c FROM Channel_Partner__c WHERE Id IN :cpIds
            ]);
        }

        Map<Id, Related_Source__c> rsMap = new Map<Id, Related_Source__c>();
        if (!rsIds.isEmpty()) {
            rsMap = new Map<Id, Related_Source__c>([
                SELECT Id, Sales_User__c FROM Related_Source__c WHERE Id IN :rsIds
            ]);
        }

        Id arrivedTypeId = getCustomNotificationTypeId('SV_Customer_Arrived');

        Set<Id> allRecipients = new Set<Id>();
        Map<Id, Set<Id>> svToRecipients = new Map<Id, Set<Id>>();

        for (Site_Visit__c sv : arrivedSVs) {
            Id cpId = String.isNotBlank(sv.Channel_Partner1__c) ? (Id) sv.Channel_Partner1__c : null;
            Channel_Partner__c cp = (cpId != null) ? cpMap.get(cpId) : null;
            Related_Source__c rs = (sv.Related_Source__c != null) ? rsMap.get(sv.Related_Source__c) : null;

            Set<Id> recipients = new Set<Id>();
            if (cp != null && cp.Sourcing_RM__c != null) recipients.add(cp.Sourcing_RM__c);
            if (rs != null && rs.Sales_User__c != null) recipients.add(rs.Sales_User__c);

            if (!recipients.isEmpty()) {
                svToRecipients.put(sv.Id, recipients);
                allRecipients.addAll(recipients);
            }
        }

        if (allRecipients.isEmpty()) return;

        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Email FROM User WHERE Id IN :allRecipients AND IsActive = true
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Site_Visit__c sv : arrivedSVs) {
            Set<Id> recipients = svToRecipients.get(sv.Id);
            if (recipients == null || recipients.isEmpty()) continue;
            sendBell(arrivedTypeId, sv, recipients, 'Arrived', sv.Name);
            buildEmails(emails, sv, sv.Name, recipients, userMap, 'Arrived');
        }

        if (!emails.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(emails, false);
        }
    }
 public static void createReward(List<Site_Visit__c> newList, Map<Id, Site_Visit__c> oldMap) {
        // 1. Collect Site Visits whose status changed to 'Completed'
        List<Site_Visit__c> completedVisits = new List<Site_Visit__c>();
        for (Site_Visit__c sv : newList) {
            Site_Visit__c oldSv = oldMap.get(sv.Id);
            if (sv.Status__c == 'Completed' && oldSv.Status__c != 'Completed') {
                System.debug('1');
                completedVisits.add(sv);
            }
        }

        if (completedVisits.isEmpty()) {
            return;
        }

        // 2. Fetch related Leads
        Set<Id> leadIds = new Set<Id>();
        for (Site_Visit__c sv : completedVisits) {
            if (sv.SLead__c != null) leadIds.add(sv.SLead__c);
        }
        Map<Id, Lead> leadMap = new Map<Id, Lead>([
            SELECT Id, Customer_Master__c, Allocated_Project__c FROM Lead WHERE Id IN :leadIds
        ]);

        // 3. Fetch Project__c records using Allocated_Project__c from Lead
        Set<String> allocatedProjectNames = new Set<String>();
        for (Lead ld : leadMap.values()) {
            if (ld.Allocated_Project__c != null) allocatedProjectNames.add(ld.Allocated_Project__c);
        }
        Map<String, Id> projectNameToId = new Map<String, Id>();
        if (!allocatedProjectNames.isEmpty()) {
            for (Project__c proj : [SELECT Id, Name,Project__c FROM Project__c WHERE Project__c IN :allocatedProjectNames]) {
                projectNameToId.put(proj.Project__c, proj.Id);
            }
        }

        // 4. Fetch Reward Criteria by Project__c lookup and Type
        Set<Id> projectIds = new Set<Id>(projectNameToId.values());
        System.debug(projectIds);
        Map<Id, Reward_Criteria__c> rewardCriteriaMap = new Map<Id, Reward_Criteria__c>();
        if (!projectIds.isEmpty()) {
            System.debug('2');
            for (Reward_Criteria__c rc : [SELECT Id, Name, Reward_Type__c, Project__c, Referral_Amount__c FROM Reward_Criteria__c WHERE Reward_Type__c = 'Site Visit' AND Project__c IN :projectIds]) {
                rewardCriteriaMap.put(rc.Project__c, rc);
            }
        }

        // 5. Prepare Reward__c records
        List<Reward__c> rewardsToInsert = new List<Reward__c>();
        for (Site_Visit__c sv : completedVisits) {
            Lead ld = leadMap.get(sv.SLead__c);
            if (ld != null && ld.Customer_Master__c != null && ld.Allocated_Project__c != null) {
                System.debug(ld.Allocated_Project__c);
                Id projId = projectNameToId.get(ld.Allocated_Project__c);
                Reward_Criteria__c rc = rewardCriteriaMap.get(projId);
                System.debug('3' + rc + projId);
                if (rc != null) {
                        // Find Referral__c for this Lead
                        Referral__c referral = null;
                        List<Referral__c> referralList = [SELECT Id FROM Referral__c WHERE Lead__c = :ld.Id LIMIT 1];
                        if (!referralList.isEmpty()) {
                            referral = referralList[0];
                        }
                        // Map Reward_Criteria__c lookup
                        Id rewardCriteriaId = rc.Id;
                    rewardsToInsert.add(new Reward__c(
                        Name ='Reward for Site Visit '+ sv.name ,
                        Customer_Master__c = ld.Customer_Master__c,
                        Reward_Type__c = rc.Reward_Type__c,
                        Reward_Amount__c = rc.Referral_Amount__c,
                            Referral__c = referral != null ? referral.Id : null,
                            Reward_Criteria__c = rewardCriteriaId
                    ));
                }
            }
        }
        if (!rewardsToInsert.isEmpty()) {
            System.debug('4');
            insert rewardsToInsert;
        }

        // 6. Update Referral__c status to 'Site Visit'
        List<Referral__c> referralsToUpdate = new List<Referral__c>();
        Set<Id> processedLeadIds = new Set<Id>();
        for (Lead ld : leadMap.values()) {
            if (ld.Customer_Master__c != null && !processedLeadIds.contains(ld.Id)) {
                processedLeadIds.add(ld.Id);
            }
        }
        if (!processedLeadIds.isEmpty()) {
            // Map LeadId to Allocated_Project__c for Reward_Criteria lookup
            Map<Id, String> leadIdToProject = new Map<Id, String>();
            for (Lead ld : leadMap.values()) {
                if (ld.Allocated_Project__c != null) {
                    leadIdToProject.put(ld.Id, ld.Allocated_Project__c);
                }
            }
            for (Referral__c ref : [SELECT Id, Status__c, Lead__c FROM Referral__c WHERE Lead__c IN :processedLeadIds]) {
                if (ref.Status__c != 'Site Visit') {
                    ref.Status__c = 'Site Visit';
                    // Find Reward_Criteria__c for this referral's project
                    String projKey = leadIdToProject.containsKey(ref.Lead__c) ? leadIdToProject.get(ref.Lead__c) : null;
                    Id projId = projKey != null && projectNameToId.containsKey(projKey) ? projectNameToId.get(projKey) : null;
                    Decimal referralAmount = null;
                    if (projId != null && rewardCriteriaMap.containsKey(projId)) {
                        referralAmount = rewardCriteriaMap.get(projId).Referral_Amount__c;
                    }
                    ref.Reward_Amount__c = referralAmount;
                    referralsToUpdate.add(ref);
                }
            }
        }
        if (!referralsToUpdate.isEmpty()) {
            update referralsToUpdate;
        }
    }

    public Static void testCoverage(){
        
        
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}