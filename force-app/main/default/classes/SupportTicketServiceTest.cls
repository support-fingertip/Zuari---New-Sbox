@IsTest
private class SupportTicketServiceTest {

    /* ── onBeforeInsert: valid ticket gets defaults ── */
    @IsTest
    static void test_onBeforeInsert_validTicket() {
        Id userId = UserInfo.getUserId();

        Support_Ticket__c t = new Support_Ticket__c(
            Sourcing_RM__c                 = userId,
            Sourcing_Head__c               = userId,
            Head_of_Sales_and_Marketing__c = userId
        );

        Test.startTest();
        insert t;
        Test.stopTest();

        Support_Ticket__c inserted = [
            SELECT OwnerId, Ticket_Status__c, Escalation_Level__c,
                   Last_Escalated_On__c, Auto_Close_On__c
            FROM Support_Ticket__c WHERE Id = :t.Id
        ];

        System.assertEquals(userId, inserted.OwnerId, 'Owner should be RM');
        System.assertEquals('In Progress', inserted.Ticket_Status__c, 'Status should be In Progress');
        System.assertEquals('RM', inserted.Escalation_Level__c, 'Level should be RM');
        System.assertNotEquals(null, inserted.Last_Escalated_On__c, 'Last_Escalated_On should be set');
        System.assertEquals(Date.today().addDays(60), inserted.Auto_Close_On__c, 'Auto close should be +60 days');
    }

    /* ── onBeforeInsert: missing hierarchy → error ── */
    @IsTest
    static void test_onBeforeInsert_missingHierarchy() {
        Support_Ticket__c t = new Support_Ticket__c(
            Sourcing_RM__c = UserInfo.getUserId()
            // Sourcing_Head__c and HOSM missing
        );

        Boolean threw = false;
        Test.startTest();
        try {
            insert t;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('Sourcing RM, Sourcing Head'),
                'Error should mention required fields');
        }
        Test.stopTest();
        System.assert(threw, 'Should throw when hierarchy fields are null');
    }

    /* ── processEscalations: no open tickets → no error ── */
    @IsTest
    static void test_processEscalations_noTickets() {
        Test.startTest();
        SupportTicketService.processEscalations();
        Test.stopTest();
        System.assert(true, 'Should run without error when no tickets');
    }

    /* ── processEscalations: escalate RM → Sourcing Head ── */
    @IsTest
    static void test_processEscalations_rmToSourcingHead() {
        Id userId = UserInfo.getUserId();

        Support_Ticket__c t = new Support_Ticket__c(
            Sourcing_RM__c                 = userId,
            Sourcing_Head__c               = userId,
            Head_of_Sales_and_Marketing__c = userId
        );
        insert t;

        // Backdate Last_Escalated_On to 8 days ago to trigger escalation
        t = [SELECT Id FROM Support_Ticket__c WHERE Id = :t.Id];
        Test.setCreatedDate(t.Id, DateTime.now().addDays(-10));

        // Directly update the field so processEscalations sees it as stale
        t.Last_Escalated_On__c = DateTime.now().addDays(-8);
        update t;

        Test.startTest();
        SupportTicketService.processEscalations();
        Test.stopTest();

        Support_Ticket__c updated = [
            SELECT Escalation_Level__c, OwnerId
            FROM Support_Ticket__c WHERE Id = :t.Id
        ];
        System.assertEquals('Sourcing Head', updated.Escalation_Level__c,
            'Should escalate to Sourcing Head');
    }

    /* ── processEscalations: auto-close after 60 days ── */
    @IsTest
    static void test_processEscalations_autoClose() {
        Id userId = UserInfo.getUserId();

        Support_Ticket__c t = new Support_Ticket__c(
            Sourcing_RM__c                 = userId,
            Sourcing_Head__c               = userId,
            Head_of_Sales_and_Marketing__c = userId
        );
        insert t;

        // Set auto-close date to yesterday
        t.Auto_Close_On__c = Date.today().addDays(-1);
        t.Last_Escalated_On__c = DateTime.now().addDays(-1);
        update t;

        Test.startTest();
        SupportTicketService.processEscalations();
        Test.stopTest();

        Support_Ticket__c closed = [
            SELECT Ticket_Status__c, Closure_Message__c
            FROM Support_Ticket__c WHERE Id = :t.Id
        ];
        System.assertEquals('Close', closed.Ticket_Status__c, 'Ticket should be auto-closed');
        System.assert(closed.Closure_Message__c != null, 'Closure message should be set');
    }
}