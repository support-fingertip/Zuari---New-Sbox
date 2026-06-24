@IsTest
public class PaymentScheduleHelperTest {

    @TestSetup
    static void setupData() {
        Quote__c qc = new Quote__c();
        // Use only writable fields (based on what you already use elsewhere)
        qc.Quote_status__c  = 'Converted';
        qc.Block__c         = ' ';
        qc.Payment_Type__c  = 'Standard';
        qc.Sale_Area__c     = 2567;
        qc.Built_up_area__c = 4567;
        qc.Rate_per_sqft__c = 7100;
        insert qc;

        List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>();

        schedules.add(new Payment_Schedule__c(
            Quote__c = qc.Id,
            S_No__c = 1,
            Payment_percent__c = 10
        ));

        schedules.add(new Payment_Schedule__c(
            Quote__c = qc.Id,
            S_No__c = 2,
            Payment_percent__c = 20
        ));

        schedules.add(new Payment_Schedule__c(
            Quote__c = qc.Id,
            S_No__c = 3, // last
            Payment_percent__c = 70
        ));

        insert schedules;
    }

    @IsTest
    static void testRecalculateAmounts_UsesLastScheduleExtraCharges() {

        Quote__c qc = [
            SELECT Id,
                   Agreement_Value_Before_GST__c,
                   Clubhouse_Charges__c,
                   Total_Maintenance_Amount__c,
                   GST_On_Other_Charges_Actual__c
            FROM Quote__c
            LIMIT 1
        ];

        Test.startTest();
        PaymentScheduleHelper.recalculateAmounts(new Set<Id>{ qc.Id });
        Test.stopTest();

        List<Payment_Schedule__c> updated = [
            SELECT Id, S_No__c, Payment_percent__c, Amount__c
            FROM Payment_Schedule__c
            WHERE Quote__c = :qc.Id
            ORDER BY S_No__c ASC
        ];
        System.assertEquals(3, updated.size(), 'Expected 3 schedules');

        Decimal agreement = (qc.Agreement_Value_Before_GST__c == null) ? 0 : qc.Agreement_Value_Before_GST__c;

        Decimal expected1 = agreement * 10 / 100;
        Decimal expected2 = agreement * 20 / 100;
        Decimal expected3 = agreement * 70 / 100;

        // Your production code adds extras ONLY if Clubhouse_Charges__c != null
        Decimal extras = 0;
        if (qc.Clubhouse_Charges__c != null) {
            extras =
                qc.Clubhouse_Charges__c +
                (qc.Total_Maintenance_Amount__c == null ? 0 : qc.Total_Maintenance_Amount__c) +
                (qc.GST_On_Other_Charges_Actual__c == null ? 0 : qc.GST_On_Other_Charges_Actual__c);
        }

        System.assertEquals(expected1, updated[0].Amount__c, 'Schedule 1 amount mismatch');
        System.assertEquals(expected2, updated[1].Amount__c, 'Schedule 2 amount mismatch');
        System.assertEquals(expected3 + extras, updated[2].Amount__c, 'Last schedule amount mismatch');
    }
}