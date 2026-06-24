trigger ReceiptTrigger on Receipt__c (before insert, after update, after insert) {
    
    // BEFORE INSERT - Generate receipt numbers
    if (Trigger.isBefore && Trigger.isInsert) {
        // Map to track booking IDs and their receipt counts
        Map<Id, Integer> bookingReceiptCountMap = new Map<Id, Integer>();
        Map<Id, String> unitNameMap = new Map<Id, String>();
        List<Receipt__c> existingReceipts = new List<Receipt__c>();
        
        // Collect all booking IDs from the new receipts
        Set<Id> bookingIds = new Set<Id>();
        for (Receipt__c rec : Trigger.new) {
            if (rec.Booking__c != null) {
                bookingIds.add(rec.Booking__c);
            }
        }
        
        // Query existing receipts for each booking to get the count
        if (!bookingIds.isEmpty()) {
            existingReceipts = [SELECT Id, Booking__c, Receipt_No__c 
                               FROM Receipt__c 
                               WHERE Booking__c IN :bookingIds 
                               ORDER BY CreatedDate ASC];
            
            // Query Booking and Unit details
            for (Booking__c booking : [SELECT Id, Plot__r.Name FROM Booking__c WHERE Id IN :bookingIds]) {
                if (booking.Plot__r.Name != null) {
                    unitNameMap.put(booking.Id, booking.Plot__r.Name);
                }
            }
            
            // Count existing receipts per booking
            for (Receipt__c receipt : existingReceipts) {
                Integer count = bookingReceiptCountMap.get(receipt.Booking__c);
                if (count == null) {
                    bookingReceiptCountMap.put(receipt.Booking__c, 1);
                } else {
                    bookingReceiptCountMap.put(receipt.Booking__c, count + 1);
                }
            }
        }
        
        // Process each new receipt
        for (Receipt__c rec : Trigger.new) {
            // Generate receipt number if booking exists
            if (rec.Booking__c != null && unitNameMap.containsKey(rec.Booking__c)) {
                String unitName = unitNameMap.get(rec.Booking__c);
                
                // Get existing count for this booking
                Integer existingCount = bookingReceiptCountMap.get(rec.Booking__c);
                if (existingCount == null) {
                    existingCount = 0;
                }
                
                // Increment for the current receipt
                Integer newReceiptNumber = existingCount + 1;
                
                // Format as three-digit sequence (001, 002, etc.)
                String sequenceNumber = String.valueOf(newReceiptNumber).leftPad(3, '0');
                
                // Create receipt number in format: UnitName/RCP-001
                rec.Receipt_No__c = unitName + '/RCP-' + sequenceNumber;
                
                // Update the count for subsequent receipts in this trigger batch
                bookingReceiptCountMap.put(rec.Booking__c, newReceiptNumber);
            }
        }
    }
    
    // AFTER INSERT/UPDATE - Process approval status changes
    if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter) {
        list<Receipt__c> rejectedReciepts = new list<Receipt__c>();
        list<Receipt__c> approvedReceiptsForNotification = new list<Receipt__c>();
        Set<Id> approvedReciepts = new Set<Id>();
        Set<Id> approvedRecieptsId = new Set<Id>();
        
        for (Receipt__c rcp : Trigger.new) {
            // For insert, just check current status
            if (Trigger.isInsert) {
                if (rcp.Approval_status__c == 'Rejected') {
                    rejectedReciepts.add(rcp);
                }
                if (rcp.Approval_status__c == 'Approved' && rcp.Manual_Upload__c == false) {
                    approvedReciepts.add(rcp.Booking__c);
                    approvedRecieptsId.add(rcp.Id);
                    approvedReceiptsForNotification.add(rcp);
                    DocumentandEmailController.sendEmailGenerateReceiptfromTrigger(rcp.Id);
                }
            }
            
            // For update, check if status changed
            if (Trigger.isUpdate) {
                if (rcp.Approval_status__c != Trigger.oldMap.get(rcp.Id).Approval_status__c) {
                    if (rcp.Approval_status__c == 'Rejected') {
                        rejectedReciepts.add(rcp);
                    }
                    if (rcp.Approval_status__c == 'Approved') {
                        approvedReciepts.add(rcp.Booking__c);
                        approvedRecieptsId.add(rcp.Id);
                        approvedReceiptsForNotification.add(rcp);
                        DocumentandEmailController.sendEmailGenerateReceiptfromTrigger(rcp.Id);
                    }
                }
            }
        }
        
        String title;
        if (!rejectedReciepts.isEmpty()) {
            title = 'Receipt Rejected';
            ReceiptTriggerHandler.sendNotificationAndEmail(title, rejectedReciepts);
        }
        if (!approvedReceiptsForNotification.isEmpty()) {
            title = 'Receipt Approved';
            ReceiptTriggerHandler.sendNotificationAndEmail(title, approvedReceiptsForNotification);
            ReceiptTriggerHandler.processApprovedReceipts(approvedReceiptsForNotification);
        }
        if (!approvedReciepts.isEmpty()) {
            BookingController.moveStageToAgreement(approvedReciepts);
        }
        if (!approvedRecieptsId.isEmpty()) {
            ReceiptController.approvedReceiptsHandler(approvedRecieptsId);
        }
    }
}