trigger DemandRaisedTrigger on Demand_Raised__c (after insert, before insert, after update) {
    // BEFORE INSERT - Set dates and generate demand numbers
    if (Trigger.isBefore && Trigger.isInsert) {
        // Map to track booking IDs and their demand counts
        Map<Id, Integer> bookingDemandCountMap = new Map<Id, Integer>();
        Map<Id, String> unitNameMap = new Map<Id, String>();
        List<Demand_Raised__c> existingDemands = new List<Demand_Raised__c>();
        
        // Collect all booking IDs from the new demands
        Set<Id> bookingIds = new Set<Id>();
        for (Demand_Raised__c dd : Trigger.new) {
            if (dd.Booking__c != null) {
                bookingIds.add(dd.Booking__c);
            }
        }
        
        // Query existing demands for each booking to get the count
        if (!bookingIds.isEmpty()) {
            existingDemands = [SELECT Id, Booking__c, Demand_No__c 
                               FROM Demand_Raised__c 
                               WHERE Booking__c IN :bookingIds 
                               ORDER BY CreatedDate ASC];
            
            // Query Booking and Unit details
            for (Booking__c booking : [SELECT Id, Plot__r.Name FROM Booking__c WHERE Id IN :bookingIds]) {
                if (booking.Plot__r.Name != null) {
                    unitNameMap.put(booking.Id, booking.Plot__r.Name);
                }
            }
            
            // Count existing demands per booking
            for (Demand_Raised__c demand : existingDemands) {
                Integer count = bookingDemandCountMap.get(demand.Booking__c);
                if (count == null) {
                    bookingDemandCountMap.put(demand.Booking__c, 1);
                } else {
                    bookingDemandCountMap.put(demand.Booking__c, count + 1);
                }
            }
        }
        
        // Process each new demand
        for (Demand_Raised__c dd : Trigger.new) {
            // Set dates
            dd.X1st_Reminder_Date__c = System.today() + 7;
            dd.X2nd_Reminder_Date__c = System.today() + 14;
            dd.X1st_Reminder_Date_with_Interest__c = System.today() + 21;
            dd.X2nd_Reminder_Interest_Date__c = System.today() + 28;
            dd.X3rd_Reminder_Interest_Date__c = System.today() + 35;
            dd.Pre_Termination_Mail_Date__c = System.today() + 42;
            dd.Termination_Mail_Date__c = System.today() + 49;
            
            // Generate demand number if booking exists
            if (dd.Booking__c != null && unitNameMap.containsKey(dd.Booking__c)) {
                String unitName = unitNameMap.get(dd.Booking__c);
                
                // Get existing count for this booking
                Integer existingCount = bookingDemandCountMap.get(dd.Booking__c);
                if (existingCount == null) {
                    existingCount = 0;
                }
                
                // Increment for the current demand
                Integer newDemandNumber = existingCount + 1;
                
                // Format as three-digit sequence (001, 002, etc.)
                String sequenceNumber = String.valueOf(newDemandNumber).leftPad(3, '0');
                
                // Create demand number in format: UnitName/DEM-001
                dd.Demand_No__c = unitName + '/DEM-' + sequenceNumber;
                
                // Update the count for subsequent demands in this trigger batch
                bookingDemandCountMap.put(dd.Booking__c, newDemandNumber);
            }
        }
    }
    
    // AFTER UPDATE - CC Notification for Demand status change
    if (Trigger.isAfter && Trigger.isUpdate) {
        CCNotificationTriggerHandler.handleDemandStatusChange(Trigger.new, Trigger.oldMap);
    }

    // AFTER INSERT - Send notifications and process emails
    if (Trigger.isAfter && Trigger.isInsert) {
        Set<String> recipientIds = new Set<String>();
        List<Id> demandIdsSet = new List<Id>();
        List<Id> demandMailIdsSet = new List<Id>();
        
        for (Demand_Raised__c demand : Trigger.new) {
            // Add the record creator to the recipient list
            recipientIds.add(demand.CreatedById);
            if (demand.Disable_Demand_Mail__c != true) {
                demandMailIdsSet.add(demand.Id);
            }
            demandIdsSet.add(demand.Id);
            
            // Build notification message
            String title = 'New Demand Raised';
            String body = 'This is to notify that Booking (' + demand.Booking_Name__c + 
                         '), has a new demand raise. The demand raise ' + 
                         demand.Name + ' has been created.';
            String notificationName = 'CustomNotification';
            
            // Send the notification
            if(demand.Manual_Upload__c == false){
                NotificationController.sendCustomNotification(recipientIds, title, body, demand.Id, notificationName);
                
            }
        }
        
        // Call bulkified email method
        if (!demandIdsSet.isEmpty()) {
            DemandRaisedHelper.updatePaymentScheduleFields(demandIdsSet);
        }
        
        if (!demandMailIdsSet.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new DemandRaisedEmailQueueable(new List<Id>(demandMailIdsSet)));
        }
    }
}