global class PaymentScheduleBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext info) { 
        return Database.getQueryLocator([
            SELECT Id, Total_Interest__c, 
                   (SELECT Id, Pending_Amount__c, Interest_Up_to_Date__c, Interest_Percent__c, Payment_Due_Date__c, Last_Payment_Date__c, Include_Interest__c 
                    FROM Payment_Schedules__r)
            FROM Booking__c WHERE Stage__c != 'Cancellation'
        ]);
    }

    global void execute(Database.BatchableContext info, List<Booking__c> scope) {
        Map<Id, Decimal> bookingInterestMap = new Map<Id, Decimal>();
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();

        // Loop through each Booking record
        for (Booking__c booking : scope) {
            Decimal totalInterest = 0.0;

            // Loop through the related Payment Schedules and calculate total interest
            for (Payment_Schedule__c schedule : booking.Payment_Schedules__r) {
                if (schedule.Include_Interest__c) {
                    totalInterest += schedule.Interest_Up_to_Date__c;
                }
            }

            // Store the total interest in the map for each booking
            bookingInterestMap.put(booking.Id, totalInterest);
        }

        // Update the bookings based on the accumulated interest
        for (Booking__c booking : scope) {
           
            if (bookingInterestMap.containsKey(booking.Id)) {
                booking.Total_Interest__c = bookingInterestMap.get(booking.Id);
                bookingsToUpdate.add(booking);
            }
        }

        // Perform the DML update once after processing all bookings
        if (!bookingsToUpdate.isEmpty()) {
            update bookingsToUpdate;
        }
    }

    global void finish(Database.BatchableContext info) { 
        // Implement any logic to be executed after the batch is completed
    }

    global void execute(SchedulableContext SC) {
        database.executeBatch(new PaymentScheduleBatch(), 100);
    }
}