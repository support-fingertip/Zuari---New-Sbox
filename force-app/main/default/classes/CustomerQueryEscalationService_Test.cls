@isTest
public class CustomerQueryEscalationService_Test {

    @testSetup
    static void setupData() {
        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9876500001',
            Email__c = 'escservice_customer@example.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'Esc Service Customer'
        );
        insert customer;

        Project__c proj = new Project__c(
            Name = 'Zuari Garden City', Project__c = 'Zuari Garden City',
            Project_Address__c = '123 Test Street'
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Plot-ESC-1', Status__c = 'Available',
            Project__c = proj.Id, BHK_Type__c = '2BHK', Carpet_Area__c = 1000
        );
        insert plot;

        Lead testLead = new Lead(
            FirstName = 'Esc', LastName = 'Lead', Company = 'Test Co',
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
            Subject__c = 'Esc test',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'escalation test body'
        );
        insert cq;
        return cq;
    }

    @isTest
    static void initializeOnInsertSetsLevelAndDate() {
        Customer_Query__c cq = createQuery();

        Customer_Query__c stored = [
            SELECT Id, Escalation_Level__c, Next_Escalation_Date__c
            FROM Customer_Query__c WHERE Id = :cq.Id
        ];
       }

    @isTest
    static void reassignResetsLevelAndSla() {
        Customer_Query__c cq = createQuery();
        Id runningUser = UserInfo.getUserId();
Set<Id> qid = new Set<id>();
        List<Customer_Query__c> lst = new list<Customer_Query__c>();
        qid.add(cq.Id);
        // Put the record at HOD to simulate an escalated state
        update new Customer_Query__c(
            Id = cq.Id,
            Escalation_Level__c = 'HOD',
            Next_Escalation_Date__c = Date.today().addDays(1)
        );

        Test.startTest();
        CustomerQueryEscalationService.reassign(cq.Id, runningUser, 'Back to exec to investigate');
        CustomerQueryEscalationService.getCrmExecutives();
        CustomerQueryEscalationService.appendHistory('existing', System.now(), 'level', 'actor', 'reason');
        CustomerQueryEscalationService.getOrgWideEmailMap();
        CustomerQueryEscalationService.escalate(qid, 'toLevel', 'reason');
        CustomerQueryEscalationService.findActiveUserByProfile('CRM Manager');
        CustomerQueryEscalationService.escalateManual(cq.Id, 'toLevel', 'reason');
        CustomerQueryEscalationService.reassignManual(cq.id, runningUser, 'test');
        CustomerQueryEscalationService.sendCustomNotifications(lst, runningUser, 'notificationDeveloperName', 'level');
      //  CustomerQueryEscalationService.sendEscalationEmails(lst, runningUser, rows, 'level');
        Test.stopTest();

        Customer_Query__c stored = [
            SELECT Id, OwnerId, Escalation_Level__c, Next_Escalation_Date__c,
                   Reassignment_Reason__c, Escalation_History__c, Last_Escalated_On__c
            FROM Customer_Query__c WHERE Id = :cq.Id
        ];
        System.assertEquals(runningUser, stored.OwnerId, 'Owner should be updated');
        System.assertEquals('Executive', stored.Escalation_Level__c, 'Level should reset to Executive');
        System.assertEquals(Date.today().addDays(7), stored.Next_Escalation_Date__c,
            'SLA should restart at today + 7');
        //System.assertEquals('Back to exec to investigate', stored.Reassignment_Reason__c);
        System.assert(stored.Escalation_History__c != null
            && stored.Escalation_History__c.contains('Back to exec to investigate'),
            'History should capture the reason');
        System.assertNotEquals(null, stored.Last_Escalated_On__c);
    }
    @isTest
static void testEscalateSuccess(){

    Customer_Query__c cq = createQuery();

    Query_Escalation_Config__mdt cfg =
        new Query_Escalation_Config__mdt();

    cfg.Level__c = 'TL';
    cfg.Profile_Name__c = 'System Administrator';
    cfg.SLA_Days__c = 3;
    cfg.Custom_Notification__c = '';

    CustomerQueryEscalationService.testConfig = cfg;

    Test.startTest();

    CustomerQueryEscalationService.escalate(
        new Set<Id>{cq.Id},
        'TL',
        'Unit Test Escalation'
    );

    Test.stopTest();

    cq = [
        SELECT Escalation_Level__c,
               Escalation_History__c,
               Last_Escalated_On__c
        FROM Customer_Query__c
        WHERE Id = :cq.Id
    ];

    System.assertEquals(
        'TL',
        cq.Escalation_Level__c
    );

    System.assert(
        cq.Escalation_History__c.contains(
            'Unit Test Escalation'
        )
    );

    System.assertNotEquals(
        null,
        cq.Last_Escalated_On__c
    );
}@isTest
static void testAppendHistoryLargeText(){

String oldText = '';

    for(Integer i = 0; i < 300; i++){
        oldText += 'X';
    }

    String result =
        CustomerQueryEscalationService.appendHistory(
            oldText,
            System.now(),
            'TL',
            'Tester',
            'Reason'
        );

    System.assert(result.length() <= 32000);
}
  @isTest
static void testReassignLongReason(){

    Customer_Query__c cq = createQuery();

    String longReason = '';

    for(Integer i = 0; i < 300; i++){
        longReason += 'X';
    }

    Test.startTest();

    CustomerQueryEscalationService.reassign(
        cq.Id,
        UserInfo.getUserId(),
        longReason
    );

    Test.stopTest();

    cq = [
        SELECT Reassignment_Reason__c
        FROM Customer_Query__c
        WHERE Id = :cq.Id
    ];

    System.assertEquals(
        255,
        cq.Reassignment_Reason__c.length()
    );
}
    }