public with sharing class InterestCalculatorHandler {
    
    @AuraEnabled
    public static void createInterestLineItems(Date interestChangeDate, Decimal newInterestRate) {
        // 1️⃣ Get all eligible payment schedules
        List<Payment_Schedule__c> schedules = [
            SELECT Id, Name, Pending_Amount__c, Payment_Due_Date__c, Last_Payment_Date__c,Booking__c
            FROM Payment_Schedule__c
            WHERE Pending_Amount__c > 0 
            AND Payment_Due_Date__c < :Date.today() and Booking__c != null
        ];
        
        if (schedules.isEmpty()) return;
        
        List<Interest_Amount_Line_Item__c> lineItemsToInsert = new List<Interest_Amount_Line_Item__c>();
        
        for (Payment_Schedule__c ps : schedules) {
            // Skip invalid records
            if (ps.Payment_Due_Date__c == null || ps.Pending_Amount__c <= 0) continue;
            
            // Determine start & end dates
            Date prevStartDate = ps.Payment_Due_Date__c;
            //   Date prevEndDate = Date.newInstance(prevStartDate.year(), prevStartDate.month(), prevStartDate.daysInMonth());
            Integer lastDay = Date.daysInMonth(prevStartDate.year(), prevStartDate.month());
            Date prevEndDate = Date.newInstance(prevStartDate.year(), prevStartDate.month(), lastDay);
            
            Date currStartDate = prevEndDate.addDays(1);
            Date currEndDate = interestChangeDate;
            
            // Calculate days
            Integer daysPrev = prevEndDate.daysBetween(prevStartDate) + 1;
            Integer daysCurr = currEndDate.daysBetween(currStartDate) + 1;
            
            // Calculate interest
            Decimal interestPrev = (ps.Pending_Amount__c * newInterestRate * daysPrev) / 36500;
            Decimal interestCurr = (ps.Pending_Amount__c * newInterestRate * daysCurr) / 36500;
            
            // Create line item for previous month
            Interest_Amount_Line_Item__c prevItem = new Interest_Amount_Line_Item__c();
            prevItem.Payment_Schedule__c = ps.Id;
            prevItem.Interest_Start_Date__c = prevStartDate;
            prevItem.Interest_End_Date__c = prevEndDate;
            prevItem.Interest_Amount__c = interestPrev;
            prevItem.Booking__c = ps.Booking__c;
            lineItemsToInsert.add(prevItem);
            
            // Create line item for current month (up to interest change date)
            Interest_Amount_Line_Item__c currItem = new Interest_Amount_Line_Item__c();
            currItem.Payment_Schedule__c = ps.Id;
            currItem.Booking__c = ps.Booking__c;
            currItem.Interest_Start_Date__c = currStartDate;
            currItem.Interest_End_Date__c = currEndDate;
            currItem.Interest_Amount__c = interestCurr;
            lineItemsToInsert.add(currItem);
        }
        
        if (!lineItemsToInsert.isEmpty()) {
            insert lineItemsToInsert;
        }
    }
}