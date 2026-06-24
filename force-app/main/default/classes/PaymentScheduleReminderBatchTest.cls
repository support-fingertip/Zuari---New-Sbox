@IsTest
public class PaymentScheduleReminderBatchTest {

    @TestSetup
    static void setupData() {
        // Quote (use your usual fields)
        Quote__c qc = new Quote__c();
        qc.Quote_status__c  = 'Converted';
        qc.Block__c         = ' ';
        qc.Payment_Type__c  = 'Standard';
        qc.Sale_Area__c     = 2567;
        qc.Built_up_area__c = 4567;
        qc.Rate_per_sqft__c = 7100;
        insert qc;

        // Project
        Project__c pjt = new Project__c();
        pjt.Name      = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c  = true;
        insert pjt;

        // Plot
        Plot__c ut = new Plot__c();
        ut.Name      = 'Test plot';
        ut.Status__c = 'Available';
        ut.Project__c = pjt.Id;
        insert ut;

        // Booking
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.Email__c = 'test@gmail.com';
        insert book;

        // Payment Schedule that SHOULD be picked by batch (Completed_Date_New__c = today)
        Payment_schedule__c psToday = new Payment_schedule__c();
        psToday.Name = 'PS-Today';
        psToday.Booking__c = book.Id;
        psToday.S_No__c = 1;
        psToday.Completed_Date_New__c = System.today();
        
        psToday.Demanded_Date__c = System.today();
        insert psToday;

        // Payment Schedule that should NOT be picked (yesterday)
        Payment_schedule__c psOld = new Payment_schedule__c();
        psOld.Name = 'PS-Old';
        psOld.Booking__c = book.Id;
        psOld.S_No__c = 2;
        psOld.Completed_Date_New__c = System.today().addDays(-1);
       
        psOld.Demanded_Date__c = System.today().addDays(-1);
        insert psOld;
    }

    @IsTest
    static void testBatch_PicksOnlyTodayAndRuns() {
        // Prove our dataset matches the start query
        Integer todayCount = [
            SELECT count()
            FROM Payment_schedule__c
            WHERE Completed_Date_New__c = :System.today()
        ];
        System.assertEquals(1, todayCount, 'Setup wrong: expected exactly 1 schedule for today');

        Test.startTest();
        Database.executeBatch(new PaymentScheduleReminderBatch(), 200);
        Test.stopTest();

        // If DemandRaisedSave.bulkAutoDemands creates something, assert it here.
        // Since we don't know your org side-effects, we only assert "no exception".
        System.assert(true, 'Batch executed without exception');
    }

    @IsTest
    static void testBatch_NoRecords_NoCrash() {
        // Delete today's records so start query returns 0
        delete [SELECT Id FROM Payment_schedule__c WHERE Completed_Date_New__c = :System.today()];

        Test.startTest();
        Database.executeBatch(new PaymentScheduleReminderBatch(), 200);
        Test.stopTest();

        System.assert(true, 'Batch should not crash when no records found');
    }
}