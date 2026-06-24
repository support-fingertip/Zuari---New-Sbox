global class PaymentScheduleReminderBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Completed_Date_New__c,Pending_Amount__c, S_No__c, Booking__c, Received_Amount1__c, Demanded_Date__c
            FROM Payment_schedule__c
            WHERE Completed_Date_New__c = :System.today() ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Payment_schedule__c> scope) {
        Map<String, Decimal> bookingsWithPSNO = new Map<String, Decimal>();
        for (Payment_schedule__c ps : scope) {
            if (ps.Booking__c != null && ps.S_No__c != null) {
                bookingsWithPSNO.put(ps.Booking__c, ps.S_No__c);
            }
        }
        // Call your method only if map has data
        if (!bookingsWithPSNO.isEmpty()) {
            DemandRaisedSave.bulkAutoDemands(bookingsWithPSNO);
        }
        
    }
    
    global void finish(Database.BatchableContext bc) {
        // Optional: send summary email or log
    }
}