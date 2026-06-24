@IsTest
public class PaymentScheduleTriggerTest {

    @IsTest
    static void testTriggerContexts_insertUpdateDeleteUndelete() {

        // Create a record with only fields that are very likely writable.
        // IMPORTANT: If your org has required fields on Payment_Schedule__c,
        // add ONLY those required ones here.
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Name = 'Test PS'
        );

        Test.startTest();
        try {
            insert ps;           // after insert
            ps.Name = 'Updated'; 
            update ps;           // after update
            delete ps;           // after delete
            undelete ps;         // after undelete
            System.assert(true, 'All trigger contexts executed');
        } catch (Exception e) {
            System.debug('Trigger test error: ' + e.getMessage());
            // If validation rules block DML, this will fail.
            // In that case, you MUST add the missing required fields above.
            System.assert(false, 'Failed due to org validation/required fields: ' + e.getMessage());
        }
        Test.stopTest();
    }
}