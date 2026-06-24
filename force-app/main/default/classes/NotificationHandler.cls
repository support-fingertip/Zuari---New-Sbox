/**
 * @description
 * NotificationHandler is a centralized trigger handler class responsible for
 * creating or updating Notification__c records based on status changes
 * in multiple business objects.
 *
 * This class ensures that:
 * - Only one active Notification__c exists per source record
 * - Existing notifications are updated when status changes
 * - New notifications are created only when no active record exists
 *
 * Supported Source Objects:
 * - Related_Source__c
 * - Site_Visit__c
 * - Follow_up__c
 * - Payment_Line_Item__c
 *
 * Key Design Characteristics:
 * - Trigger-safe and bulk-safe
 * - Prevents duplicate notifications
 * - Uses old vs new value comparison
 * - Centralized notification creation logic
 *
 * @usage
 * Called from the following triggers in AFTER UPDATE context:
 * - RelatedSourceTrigger
 * - SiteVisitTrigger
 * - FollowUpTrigger
 * - PaymentLineItemTrigger
 *
 * Each trigger passes Trigger.new and Trigger.oldMap
 * to the corresponding handler method.
 *
 * @author
 * Praveen Kumar
 *
 * @lastModifiedDate
 * 16/01/2026
 *
 * @lastModifiedBy
 * Praveen Kumar
 */
public without sharing class NotificationHandler {

        /**
     * @description
     * Creates or updates Notification__c records for Related_Source__c
     * when the Lead_status1__c field changes and a Channel Partner
     * is associated with the record.
     *
     * If an active User Specific notification already exists
     * for the Related_Source__c record, it is updated.
     * Otherwise, a new Notification__c record is created.
     *
     * @param newList
     * List of Related_Source__c records from Trigger.new
     *
     * @param oldMap
     * Map of Related_Source__c records from Trigger.oldMap
     */

    // Related Source
    public static void createNotificationRecordsForRelatedSource(List<Related_Source__c> newList, Map<Id, Related_Source__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> relatedSourceIds = new Set<Id>();
        for (Related_Source__c r : newList) {
            if (r != null && r.Id != null) relatedSourceIds.add(r.Id);
        }
        if (relatedSourceIds.isEmpty()) return;

        Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();
        for (Notification__c n : [
            SELECT Id, Related_Source__c, IsActive__c, Notification_Category__c,Updated_Status__c, Channel_Partner__c, Notification_Redirect_Id__c
            FROM Notification__c    
            WHERE Related_Source__c IN :relatedSourceIds  AND Notification_Category__c = 'User Specific' AND IsActive__c = true
        ]) {
            if (n.Related_Source__c != null) existingNotifications.put(n.Related_Source__c, n);
        }

        List<Notification__c> toInsert = new List<Notification__c>();
        List<Notification__c> toUpdate = new List<Notification__c>();

        for (Related_Source__c newRec : newList) {
            if (newRec == null) continue;
            Related_Source__c oldRec = (oldMap != null) ? oldMap.get(newRec.Id) : null;
            if (oldRec == null) continue;

            if (newRec.Lead_status1__c != oldRec.Lead_status1__c && newRec.Channel_Partner1__c != null) {
                Notification__c noti;
                if (existingNotifications.containsKey(newRec.Id)) {
                    noti = existingNotifications.get(newRec.Id);
                } else {
                    noti = new Notification__c();
                    noti.Related_Source__c = newRec.Id;
                    noti.Notification_Category__c = 'User Specific';
                    noti.IsActive__c = true;
                    noti.IsNotificationSent__c = false;
                    toInsert.add(noti);
                }

                noti.Updated_Status__c = newRec.Lead_status1__c;
                noti.Notification_Type__c = 'Lead Notification';
                noti.Notification_Heading__c = 'Lead Status Changed';
                noti.Notification_Content__c = 'Status has been updated by this Lead Owner';
                   noti.Notification_Content__c = newRec.Lead_Id__c +' '+'Status has been updated to ' +newRec.Lead_status1__c+ 'by Owner';
             
                noti.Channel_Partner__c = newRec.Channel_Partner1__c;
                noti.Notification_Redirect_Id__c = (newRec.Lead_Id__c != null) ? String.valueOf(newRec.Lead_Id__c) : String.valueOf(newRec.Id);

                if (noti.Id != null) toUpdate.add(noti);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }

        /**
     * @description
     * Creates or updates Notification__c records for Site_Visit__c
     * when the Status__c field changes and a Channel Partner
     * is present on the Site Visit.
     *
     * Ensures only one active User Specific notification
     * exists per Site Visit record.
     *
     * @param newList
     * List of Site_Visit__c records from Trigger.new
     *
     * @param oldMap
     * Map of Site_Visit__c records from Trigger.oldMap
     */

    // Site Visit - now follows same pattern as Related Source: query existing notifications and update or create
    public static void createNotificationRecordsForSiteVisit(List<Site_Visit__c> newList, Map<Id, Site_Visit__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> siteVisitIds = new Set<Id>();
        for (Site_Visit__c sv : newList) {
            if (sv != null && sv.Id != null) siteVisitIds.add(sv.Id);
        }
        if (siteVisitIds.isEmpty()) return;

        Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();
        for (Notification__c n : [
            SELECT Id, Site_Visit__c, IsActive__c, Notification_Category__c,
                   Updated_Status__c, Channel_Partner__c, Notification_Redirect_Id__c
            FROM Notification__c
            WHERE Site_Visit__c IN :siteVisitIds
              AND Notification_Category__c = 'User Specific'
              AND IsActive__c = true
        ]) {
            if (n.Site_Visit__c != null) existingNotifications.put(n.Site_Visit__c, n);
        }

        List<Notification__c> toInsert = new List<Notification__c>();
        List<Notification__c> toUpdate = new List<Notification__c>();

        for (Site_Visit__c newRec : newList) {
            if (newRec == null) continue;
            Site_Visit__c oldRec = (oldMap != null) ? oldMap.get(newRec.Id) : null;
            if (oldRec == null) continue;

            if (newRec.Status__c != oldRec.Status__c && newRec.Related_Source__c != null && newRec.Channel_Partner_Id__c  != null) {
                Notification__c noti;
                if (existingNotifications.containsKey(newRec.Id)) {
                    noti = existingNotifications.get(newRec.Id);
                } else {
                    noti = new Notification__c();
                    noti.Site_Visit__c = newRec.Id;
                    noti.Notification_Category__c = 'User Specific';
                    noti.IsActive__c = true;
                    noti.IsNotificationSent__c = false;
                    toInsert.add(noti);
                }

                noti.Updated_Status__c = newRec.Status__c;
                noti.Notification_Type__c = 'Site Visit Notification';
                noti.Notification_Heading__c = 'Site Visit Status Changed';
              //  noti.Notification_Content__c = 'Status has been updated by Site Visit Owner';
                   noti.Notification_Content__c = newRec.Name +' '+'Status has been updated to ' +newRec.Status__c+ ' by Site Visit Owner';
             
                noti.Channel_Partner__c = newRec.Channel_Partner_Id__c;
                noti.Notification_Redirect_Id__c = String.valueOf(newRec.Id);

                if (noti.Id != null) toUpdate.add(noti);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }

        /**
     * @description
     * Creates or updates Notification__c records for Follow_up__c
     * when the Status__c field changes and a Channel Partner
     * is associated with the Follow Up.
     *
     * Prevents duplicate notifications by updating
     * existing active User Specific notifications.
     *
     * @param newList
     * List of Follow_up__c records from Trigger.new
     *
     * @param oldMap
     * Map of Follow_up__c records from Trigger.oldMap
     */

    // Follow Up - same pattern: check existing Notification__c by Follow_up__c
    public static void createNotificationRecordsForFollowUp(List<Follow_up__c> newList, Map<Id, Follow_up__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> followUpIds = new Set<Id>();
        for (Follow_up__c fu : newList) {
            if (fu != null && fu.Id != null) followUpIds.add(fu.Id);
        }
        if (followUpIds.isEmpty()) return;

        Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();
        for (Notification__c n : [
            SELECT Id, Follow_up__c, IsActive__c, Notification_Category__c,
                   Updated_Status__c, Channel_Partner__c, Notification_Redirect_Id__c
            FROM Notification__c
            WHERE Follow_up__c IN :followUpIds
              AND Notification_Category__c = 'User Specific'
              AND IsActive__c = true
        ]) {
            if (n.Follow_up__c != null) existingNotifications.put(n.Follow_up__c, n);
        }

        List<Notification__c> toInsert = new List<Notification__c>();
        List<Notification__c> toUpdate = new List<Notification__c>();

        for (Follow_up__c newRec : newList) {
            if (newRec == null) continue;
            Follow_up__c oldRec = (oldMap != null) ? oldMap.get(newRec.Id) : null;
            if (oldRec == null) continue;

            if (newRec.Status__c != oldRec.Status__c && newRec.Related_Source__c != null && newRec.Channel_Partner_Id__c  != null) {
                Notification__c noti;
                if (existingNotifications.containsKey(newRec.Id)) {
                    noti = existingNotifications.get(newRec.Id);
                } else {
                    noti = new Notification__c();
                    noti.Follow_up__c = newRec.Id;
                    noti.Notification_Category__c = 'User Specific';
                    noti.IsActive__c = true;
                    noti.IsNotificationSent__c = false;
                    toInsert.add(noti);
                }

                noti.Updated_Status__c = newRec.Status__c;
                noti.Notification_Type__c = 'Followup Notification';
                noti.Notification_Heading__c = 'Follow Up Status Changed';
                noti.Notification_Content__c = newRec.Name +' '+'Status has been updated to ' +newRec.Status__c+ ' by Follow Up Owner';
                noti.Channel_Partner__c = newRec.Channel_Partner_Id__c;
                noti.Notification_Redirect_Id__c = String.valueOf(newRec.Id);

                if (noti.Id != null) toUpdate.add(noti);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }

        /**
     * @description
     * Creates or updates Notification__c records for Payment_Line_Item__c
     * when the Payament_Status__c field changes and a Channel Partner
     * is associated with the payment.
     *
     * Ensures idempotent notification handling by updating
     * existing active notifications instead of creating duplicates.
     *
     * @param newList
     * List of Payment_Line_Item__c records from Trigger.new
     *
     * @param oldMap
     * Map of Payment_Line_Item__c records from Trigger.oldMap
     */

    // Payment - same pattern: check existing Notification__c by Payment_Line_Item__c
    public static void createNotificationRecordsForPayment(List<Payment_Line_Item__c> newList, Map<Id, Payment_Line_Item__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> paymentIds = new Set<Id>();
        for (Payment_Line_Item__c p : newList) {
            if (p != null && p.Id != null) paymentIds.add(p.Id);
        }
        if (paymentIds.isEmpty()) return;

        Map<Id, Notification__c> existingNotifications = new Map<Id, Notification__c>();
        for (Notification__c n : [
            SELECT Id, Payment_Line_Item__c, IsActive__c, Notification_Category__c,
                   Updated_Status__c, Channel_Partner__c, Notification_Redirect_Id__c
            FROM Notification__c
            WHERE Payment_Line_Item__c IN :paymentIds
              AND Notification_Category__c = 'User Specific'
              AND IsActive__c = true
        ]) {
            if (n.Payment_Line_Item__c != null) existingNotifications.put(n.Payment_Line_Item__c, n);
        }

        List<Notification__c> toInsert = new List<Notification__c>();
        List<Notification__c> toUpdate = new List<Notification__c>();

        for (Payment_Line_Item__c newRec : newList) {
            if (newRec == null) continue;
            Payment_Line_Item__c oldRec = (oldMap != null) ? oldMap.get(newRec.Id) : null;
            if (oldRec == null) continue;

            if (newRec.Payament_Status__c != oldRec.Payament_Status__c && newRec.Channel_Partner__c != null) {
                Notification__c noti;
                if (existingNotifications.containsKey(newRec.Id)) {
                    noti = existingNotifications.get(newRec.Id);
                } else {
                    noti = new Notification__c();
                    noti.Payment_Line_Item__c = newRec.Id;
                    noti.Notification_Category__c = 'User Specific';
                    noti.IsActive__c = true;
                    noti.IsNotificationSent__c = false;
                    toInsert.add(noti);
                }

                noti.Updated_Status__c = newRec.Payament_Status__c;
                noti.Notification_Type__c = 'Payment Notification';
                noti.Notification_Heading__c = 'Payment Status Changed';
               // noti.Notification_Content__c = 'Status has been updated by Payment Owner';
                
                noti.Notification_Content__c = newRec.Payment_Line_Item__c +' '+'Status has been updated to ' +newRec.Payament_Status__c+ ' by  Owner';
                noti.Channel_Partner__c = newRec.Channel_Partner__c;
                noti.Notification_Redirect_Id__c = String.valueOf(newRec.Payment_Line_Item__c);

                if (noti.Id != null) toUpdate.add(noti);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }
}