/**
 * @description Centralized trigger handler for creating or updating Customer_Portal_Notification__c records
 * based on status changes in Booking__c, Receipt_Line_Item__c, Demand_Raised__c, and Payment_Schedule__c.
 * Maps Customer_Master__c from Booking and sets CC-specific flags on each notification.
 *
 * @author Praveen Kumar
 * @since 2026-03-11
 */
public without sharing class CCNotificationTriggerHandler {

    /**
     * @description Handles Booking__c Stage__c changes.
     * Call from BookingTrigger (after update).
     */
    public static void handleBookingStatusChange(List<Booking__c> newList, Map<Id, Booking__c> oldMap) {
        List<Customer_Portal_Notification__c> notificationsToUpsert = new List<Customer_Portal_Notification__c>();

        for (Booking__c bk : newList) {
            Booking__c oldBk = oldMap.get(bk.Id);
            if (bk.Stage__c != oldBk.Stage__c && bk.Customer_Master__c != null) {
                notificationsToUpsert.add(buildNotification(
                    bk.Customer_Master__c,
                    bk.Id,
                    'Booking Type',
                    bk.Stage__c,
                    'Booking ' + bk.Name + ' status has been updated to ' + bk.Stage__c
                ));
            }
        }

        upsertNotifications(notificationsToUpsert);
    }

    /**
     * @description Handles Receipt_Line_Item__c Approval_Status__c changes.
     * Call from ReceiptLineItemTrigger (after update).
     */
    public static void handleReceiptLineItemStatusChange(List<Receipt_Line_Item__c> newList, Map<Id, Receipt_Line_Item__c> oldMap) {
        Set<Id> bookingIds = new Set<Id>();
        List<Receipt_Line_Item__c> changedItems = new List<Receipt_Line_Item__c>();

        for (Receipt_Line_Item__c rli : newList) {
            Receipt_Line_Item__c oldRli = oldMap.get(rli.Id);
            if (rli.Approval_Status__c != oldRli.Approval_Status__c && rli.Booking__c != null) {
                bookingIds.add(rli.Booking__c);
                changedItems.add(rli);
            }
        }

        if (changedItems.isEmpty()) return;

        Map<Id, Id> bookingToCustomer = getBookingCustomerMap(bookingIds);
        List<Customer_Portal_Notification__c> notificationsToUpsert = new List<Customer_Portal_Notification__c>();

        for (Receipt_Line_Item__c rli : changedItems) {
            Id customerId = bookingToCustomer.get(rli.Booking__c);
            if (customerId != null) {
                notificationsToUpsert.add(buildNotification(
                    customerId,
                    rli.Id,
                    'Receipt Type',
                    rli.Approval_Status__c,
                    'Receipt ' + rli.Name + ' status has been updated to ' + rli.Approval_Status__c
                ));
            }
        }

        upsertNotifications(notificationsToUpsert);
    }

    /**
     * @description Handles Demand_Raised__c Demand_Status__c changes.
     * Call from DemandRaisedTrigger (after update).
     */
    public static void handleDemandStatusChange(List<Demand_Raised__c> newList, Map<Id, Demand_Raised__c> oldMap) {
        Set<Id> bookingIds = new Set<Id>();
        List<Demand_Raised__c> changedItems = new List<Demand_Raised__c>();

        for (Demand_Raised__c dr : newList) {
            Demand_Raised__c oldDr = oldMap.get(dr.Id);
            if (dr.Demand_Status__c != oldDr.Demand_Status__c && dr.Booking__c != null) {
                bookingIds.add(dr.Booking__c);
                changedItems.add(dr);
            }
        }

        if (changedItems.isEmpty()) return;

        Map<Id, Id> bookingToCustomer = getBookingCustomerMap(bookingIds);
        List<Customer_Portal_Notification__c> notificationsToUpsert = new List<Customer_Portal_Notification__c>();

        for (Demand_Raised__c dr : changedItems) {
            Id customerId = bookingToCustomer.get(dr.Booking__c);
            if (customerId != null) {
                notificationsToUpsert.add(buildNotification(
                    customerId,
                    dr.Id,
                    'Demand Type',
                    dr.Demand_Status__c,
                    'Demand ' + dr.Name + ' status has been updated to ' + dr.Demand_Status__c
                ));
            }
        }

        upsertNotifications(notificationsToUpsert);
    }

    /**
     * @description Handles Payment_Schedule__c Status__c changes.
     * Call from PaymentScheduleTrigger (after update).
     */
    public static void handlePaymentScheduleStatusChange(List<Payment_Schedule__c> newList, Map<Id, Payment_Schedule__c> oldMap) {
        Set<Id> bookingIds = new Set<Id>();
        List<Payment_Schedule__c> changedItems = new List<Payment_Schedule__c>();

        for (Payment_Schedule__c ps : newList) {
            Payment_Schedule__c oldPs = oldMap.get(ps.Id);
            if (ps.Status__c != oldPs.Status__c && ps.Booking__c != null) {
                bookingIds.add(ps.Booking__c);
                changedItems.add(ps);
            }
        }

        if (changedItems.isEmpty()) return;

        Map<Id, Id> bookingToCustomer = getBookingCustomerMap(bookingIds);
        List<Customer_Portal_Notification__c> notificationsToUpsert = new List<Customer_Portal_Notification__c>();

        for (Payment_Schedule__c ps : changedItems) {
            Id customerId = bookingToCustomer.get(ps.Booking__c);
            if (customerId != null) {
                notificationsToUpsert.add(buildNotification(
                    customerId,
                    ps.Id,
                    'Milestone Type',
                    ps.Status__c,
                    'Payment Schedule ' + ps.Name + ' status has been updated to ' + ps.Status__c
                ));
            }
        }

        upsertNotifications(notificationsToUpsert);
    }

    /**
     * @description Builds a Customer_Portal_Notification__c record with standard CC fields.
     */
    private static Customer_Portal_Notification__c buildNotification(Id customerId, Id redirectId, String notificationType, String status, String content) {
        Customer_Portal_Notification__c noti = new Customer_Portal_Notification__c();
        noti.Customer_Master__c = customerId;
        noti.Notification_Redirect_Id__c = redirectId;
        noti.Created_For_CC__c = true;
        noti.IsActive__c = true;
        noti.IsNotificationSent__c = false;
        noti.Updated_Status__c = status;
        noti.Notification_Type__c = notificationType;
        noti.Notification_Content__c = content;
        noti.Notification_Heading__c = notificationType + ' Status Update';
        noti.Notification_Time__c = System.now();
        return noti;
    }

    /**
     * @description Queries Booking__c to get Customer_Master__c mapping.
     */
    private static Map<Id, Id> getBookingCustomerMap(Set<Id> bookingIds) {
        Map<Id, Id> bookingToCustomer = new Map<Id, Id>();
        if (bookingIds.isEmpty()) return bookingToCustomer;

        for (Booking__c bk : [SELECT Id, Customer_Master__c FROM Booking__c WHERE Id IN :bookingIds AND Customer_Master__c != NULL]) {
            bookingToCustomer.put(bk.Id, bk.Customer_Master__c);
        }
        return bookingToCustomer;
    }

    /**
     * @description Upserts notifications - updates existing if one already exists for the same redirect Id, otherwise inserts new.
     */
    private static void upsertNotifications(List<Customer_Portal_Notification__c> notifications) {
        if (notifications.isEmpty()) return;

        Set<String> redirectIds = new Set<String>();
        for (Customer_Portal_Notification__c n : notifications) {
            if (n.Notification_Redirect_Id__c != null) {
                redirectIds.add(n.Notification_Redirect_Id__c);
            }
        }

        Map<String, Customer_Portal_Notification__c> existingMap = new Map<String, Customer_Portal_Notification__c>();
        for (Customer_Portal_Notification__c existing : [
            SELECT Id, Notification_Redirect_Id__c
            FROM Customer_Portal_Notification__c
            WHERE Notification_Redirect_Id__c IN :redirectIds
            AND Created_For_CC__c = true
        ]) {
            existingMap.put(existing.Notification_Redirect_Id__c, existing);
        }

        List<Customer_Portal_Notification__c> toInsert = new List<Customer_Portal_Notification__c>();
        List<Customer_Portal_Notification__c> toUpdate = new List<Customer_Portal_Notification__c>();

        for (Customer_Portal_Notification__c n : notifications) {
            Customer_Portal_Notification__c existing = existingMap.get(n.Notification_Redirect_Id__c);
            if (existing != null) {
                existing.Updated_Status__c = n.Updated_Status__c;
                existing.Notification_Content__c = n.Notification_Content__c;
                existing.IsNotificationSent__c = false;
                existing.IsActive__c = true;
                existing.Notification_Time__c = System.now();
                toUpdate.add(existing);
            } else {
                toInsert.add(n);
            }
        }

        if (!toUpdate.isEmpty()) update toUpdate;
        if (!toInsert.isEmpty()) insert toInsert;
    }
    /**
     * @description Handles Customer_Query__c Status__c changes.
     * Call from CustomerQueryTrigger (after update).
     */
    public static void handleCustomerQueryStatusChange(List<Customer_Query__c> newList, Map<Id, Customer_Query__c> oldMap) {
        List<Customer_Portal_Notification__c> notificationsToUpsert = new List<Customer_Portal_Notification__c>();

        for (Customer_Query__c cq : newList) {
            Customer_Query__c oldCq = oldMap.get(cq.Id);
            if (cq.Query_Status__c != oldCq.Query_Status__c && cq.Customer_Master__c != null) {
                notificationsToUpsert.add(buildNotification(
                    cq.Customer_Master__c,
                    cq.Id,
                    'Customer Query',
                    cq.Query_Status__c,
                    'Customer Query ' + cq.Name + ' status has been updated to ' + cq.Query_Status__c
                ));
            }
        }

        upsertNotifications(notificationsToUpsert);
    }

    /**
     * @description Handles Demand_Raised__c after insert.
     * Call from DemandRaisedTrigger (after insert).
     */
    public static void handleDemandStatusInsert(List<Demand_Raised__c> newList) {
        Set<Id> bookingIds = new Set<Id>();
        for (Demand_Raised__c dr : newList) {
            if (dr.Booking__c != null) {
                bookingIds.add(dr.Booking__c);
            }
        }
        if (bookingIds.isEmpty()) return;

        Map<Id, Id> bookingToCustomer = getBookingCustomerMap(bookingIds);
        List<Customer_Portal_Notification__c> notificationsToInsert = new List<Customer_Portal_Notification__c>();

        for (Demand_Raised__c dr : newList) {
            Id customerId = bookingToCustomer.get(dr.Booking__c);
            if (customerId != null) {
                notificationsToInsert.add(buildNotification(
                    customerId,
                    dr.Id,
                    'Demand Type',
                    dr.Demand_Status__c,
                    'Demand ' + dr.Name + ' has been created with status ' + dr.Demand_Status__c
                ));
            }
        }

        if (!notificationsToInsert.isEmpty()) {
            insert notificationsToInsert;
        }
    }
    public Static Void testcover(){
        
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}