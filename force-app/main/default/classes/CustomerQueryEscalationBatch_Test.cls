@isTest
public class CustomerQueryEscalationBatch_Test {

    @testSetup
    static void setupData() {
        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9876500002',
            Email__c = 'escbatch_customer@example.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'Esc Batch Customer'
        );
        insert customer;

        Project__c proj = new Project__c(
            Name = 'Zuari Garden City', Project__c = 'Zuari Garden City',
            Project_Address__c = '123 Test Street'
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Plot-ESC-B1', Status__c = 'Available',
            Project__c = proj.Id, BHK_Type__c = '2BHK', Carpet_Area__c = 1000
        );
        insert plot;

        Lead testLead = new Lead(
            FirstName = 'EscB', LastName = 'Lead', Company = 'Test Co',
            Allocated_Project__c = 'Zuari Garden City'
        );
        insert testLead;

        Quote__c quote = new Quote__c(
            SLead__c = testLead.Id, Unit__c = plot.Id,
            Project__c = 'Zuari Garden City', Quote_date__c = Date.today()
        );
        insert quote;

        Booking__c booking = new Booking__c(
            Quote__c = quote.Id, SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City', Project1__c = proj.Id,
            Plot__c = plot.Id, Stage__c = 'Booked',
            Booking_Date__c = Date.today(), Booking_Amount__c = 50000,
            Customer_Master__c = customer.Id,
            Approval_status__c = 'Pending'
        );
        insert booking;
    }

    private static Customer_Query__c createQuery() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Booking__c = booking.Id,
            Subject__c = 'Batch test',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'batch body'
        );
        insert cq;
        return cq;
    }

    @isTest
    static void futureDueDateIsNotProcessed() {
        Customer_Query__c cq = createQuery();
        // Fresh insert → Next_Escalation_Date__c is today+7, so batch should skip.
        Test.startTest();
        Database.executeBatch(new CustomerQueryEscalationBatch(), 50);
        Test.stopTest();

        Customer_Query__c stored = [
            SELECT Escalation_Level__c, Query_Status__c, Auto_Closed__c
            FROM Customer_Query__c WHERE Id = :cq.Id
        ];
        System.assertEquals('Executive', stored.Escalation_Level__c);
        System.assertNotEquals('Closed', stored.Query_Status__c);
        System.assertEquals(false, stored.Auto_Closed__c);
    }

    @isTest
    static void recordOlderThanSixtyDaysAutoCloses() {
        Customer_Query__c cq = createQuery();
        Test.setCreatedDate(cq.Id, Datetime.now().addDays(-65));
        // Force the batch to pick it up
        update new Customer_Query__c(Id = cq.Id, Next_Escalation_Date__c = Date.today().addDays(-1));

        Test.startTest();
        Database.executeBatch(new CustomerQueryEscalationBatch(), 50);
        Test.stopTest();

        Customer_Query__c stored = [
            SELECT Query_Status__c, Auto_Closed__c, Escalation_History__c,
                   Next_Escalation_Date__c
            FROM Customer_Query__c WHERE Id = :cq.Id
        ];
        System.assertEquals('Closed', stored.Query_Status__c,
            'Queries older than 60 days must auto-close');
        System.assertEquals(true, stored.Auto_Closed__c);
        System.assertEquals(null, stored.Next_Escalation_Date__c,
            'Closed record should have no further escalation date');
        System.assert(stored.Escalation_History__c != null
            && stored.Escalation_History__c.contains('Auto-Closed'));
    }

    @isTest
    static void levelResolverPickLogic() {
        // Executive at day 7 → TL
        System.assertEquals('TL',  CustomerQueryEscalationBatch.resolveNextLevel('Executive', 7));
        // Executive at day 14 jumps straight to CFO
        System.assertEquals('CFO', CustomerQueryEscalationBatch.resolveNextLevel('Executive', 14));
        // TL at day 7 with stale SLA (age unchanged) → HOD
        System.assertEquals('HOD', CustomerQueryEscalationBatch.resolveNextLevel('TL', 10));
        // HOD → CFO once SLA lapses
        System.assertEquals('CFO', CustomerQueryEscalationBatch.resolveNextLevel('HOD', 13));
        // At 21 days, regardless of current non-CEO level → CEO
        System.assertEquals('CEO', CustomerQueryEscalationBatch.resolveNextLevel('CFO', 21));
        System.assertEquals('CEO', CustomerQueryEscalationBatch.resolveNextLevel('HOD', 25));
        // CEO stays at CEO
        System.assertEquals(null, CustomerQueryEscalationBatch.resolveNextLevel('CEO', 30));
        // Fresh executive still inside SLA window
        System.assertEquals(null, CustomerQueryEscalationBatch.resolveNextLevel('Executive', 3));
    }

    @isTest
    static void schedulerRunsWithoutError() {
        Test.startTest();
        String jobId = System.schedule(
            'CQ Escalation Test ' + System.now().getTime(),
            '0 0 2 * * ?',
            new CustomerQueryEscalationScheduler()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }

    @isTest
    static void executeNowRunsBatch() {
        Test.startTest();
        Id batchId = CustomerQueryEscalationScheduler.executeNow();
        Test.stopTest();
        System.assertNotEquals(null, batchId);
    }
}