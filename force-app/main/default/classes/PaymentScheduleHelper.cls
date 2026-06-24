public class PaymentScheduleHelper {
    public static void recalculateAmounts(Set<Id> quoteIds) {
        // Step 1: Fetch Quotes with fields
        Map<Id, Quote__c> quoteMap = new Map<Id, Quote__c>([SELECT Id, Agreement_Value_Before_GST__c, Clubhouse_Charges__c,Total_Maintenance_Amount__c,GST_On_Other_Charges_Actual__c FROM Quote__c WHERE Id IN :quoteIds] );

        // Step 2: Fetch all related Payment Schedules
        List<Payment_Schedule__c> allSchedules = [
            SELECT Id, Quote__c, S_No__c, Payment_percent__c
            FROM Payment_Schedule__c  WHERE Quote__c IN :quoteIds   ORDER BY Quote__c, S_No__c ASC ];

        // Step 3: Group by Quote
        Map<Id, List<Payment_Schedule__c>> schedulesByQuote = new Map<Id, List<Payment_Schedule__c>>();
        for (Payment_Schedule__c ps : allSchedules) {
            if (!schedulesByQuote.containsKey(ps.Quote__c)) {
                schedulesByQuote.put(ps.Quote__c, new List<Payment_Schedule__c>());
            }
            schedulesByQuote.get(ps.Quote__c).add(ps);
        }

        // Step 4: Calculate Amounts
        List<Payment_Schedule__c> toUpdate = new List<Payment_Schedule__c>();

        for (Id qId : schedulesByQuote.keySet()) {
            Quote__c q = quoteMap.get(qId);
            if (q == null) continue;

            List<Payment_Schedule__c> schedules = schedulesByQuote.get(qId);
            if (schedules.isEmpty()) continue;

            // Identify last schedule (highest serial no)
            Payment_Schedule__c last = schedules[schedules.size() - 1];

            for (Payment_Schedule__c ps : schedules) {
                Decimal baseAmount = (q.Agreement_Value_Before_GST__c != null && ps.Payment_percent__c != null)
                    ? q.Agreement_Value_Before_GST__c * ps.Payment_percent__c / 100
                    : 0;

                if (ps.Id == last.Id) {
                    baseAmount += (q.Clubhouse_Charges__c != null ? q.Clubhouse_Charges__c+ q.Total_Maintenance_Amount__c + q.GST_On_Other_Charges_Actual__c : 0);
                }

                ps.Amount__c = baseAmount;
                toUpdate.add(ps);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}