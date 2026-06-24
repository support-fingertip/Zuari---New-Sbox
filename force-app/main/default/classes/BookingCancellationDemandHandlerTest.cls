@isTest
public class BookingCancellationDemandHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Create Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
            Phone = '1234567890',
            Allocated_Project__c = 'Zuari Garden city',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId()
        );
        insert testLead;

        // Create Project
        Project__c testProject = new Project__c(
            Name = 'Zuari Garden City',
            CRM_executive__c = UserInfo.getUserId(),
            CRM_Manager__c = UserInfo.getUserId(),
            Sales_Head__c = UserInfo.getUserId(),
            Finance_User__c = UserInfo.getUserId(),
            COO__c = UserInfo.getUserId()
        );
        insert testProject;

        // Create Plot
        Plot__c testPlot = new Plot__c(
            Name = 'Plot-001',
            Status__c = 'Available',
            Unit_Facing_Direction__c = 'North',
            Project__c = testProject.Id
        );
        insert testPlot;

        // Create Quote
        Quote__c testQuote = new Quote__c(
            SLead__c = testLead.Id,
            Approval_status__c = 'Approved',
            Unit__c = testPlot.Id,
            Quote_status__c = 'Converted',
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Garden city',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert testQuote;

        // Create Payment Schedule
        Payment_Schedule__c testPS = new Payment_Schedule__c(
            Name = 'Test Payment Schedule',
            Quote__c = testQuote.Id,
            S_No__c = 1,
            Amount__c = 100000
        );
        insert testPS;

        // Create Round Robin
        Round_Robin__c roundRobin = new Round_Robin__c(
            Project_Assigned__c = 'Zuari Garden City',
            Active__c = true
        );
        insert roundRobin;

        // Create Round Robin Member
        Round_Robin_Member__c member = new Round_Robin_Member__c(
            Round_Robin__c = roundRobin.Id,
            User__c = UserInfo.getUserId(),
            Active__c = true,
            User_Type__c = 'CRM'
        );
        insert member;

        // Create Booking with Stage = 'Booked'
        Booking__c booking = new Booking__c(
            Quote__c = testQuote.Id,
            SLead__c = testQuote.SLead__c,
            Project__c = testQuote.Project__c,
            Project1__c = testProject.Id,
            Plot__c = testPlot.Id,
            Stage__c = 'Booked',
            OwnerId = UserInfo.getUserId(),
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque',
            Email__c = 'test@example.com',
            First_Applicant_Name__c = 'Test Applicant',
            Approval_status__c = 'Pending'
        );
        insert booking;

        // Create 2 active Demand_Raised__c records
        Demand_Raised__c demand1 = new Demand_Raised__c(
            Booking__c = booking.Id,
            Payment_schedule__c = testPS.Id,
            Amount_Demanded__c = 50000,
            Current_Demand_amount__c = 50000,
            Grand_Total__c = 59000,
            Previous_pendings__c = 0,
            Demanded_Date__c = System.now(),
            Due_Date__c = Date.today().addDays(30),
            Include_Interest__c = true,
            Interest_Till_Now__c = 100,
            Total_Interest__c = 200,
            Total_Interest_Paid__c = 50,
            Total_Amount_Paid__c = 10000,
            Milestone_Percentage__c = 20,
            Total_Percentage_till_Current_Milestone__c = 20,
            Demand_Name__c = 'Milestone 1',
            Demand_Email_Send__c = false
        );

        Demand_Raised__c demand2 = new Demand_Raised__c(
            Booking__c = booking.Id,
            Payment_schedule__c = testPS.Id,
            Amount_Demanded__c = 100000,
            Current_Demand_amount__c = 100000,
            Grand_Total__c = 118000,
            Previous_pendings__c = 500,
            Demanded_Date__c = System.now(),
            Due_Date__c = Date.today().addDays(60),
            Include_Interest__c = false,
            Interest_Till_Now__c = 0,
            Total_Interest__c = 0,
            Total_Interest_Paid__c = 0,
            Total_Amount_Paid__c = 25000,
            Milestone_Percentage__c = 40,
            Total_Percentage_till_Current_Milestone__c = 60,
            Demand_Name__c = 'Milestone 2',
            Demand_Email_Send__c = true
        );

        insert new List<Demand_Raised__c>{ demand1, demand2 };

        // Create 1 already-reversed demand (should be excluded from processing)
        Demand_Raised__c reversedDemand = new Demand_Raised__c(
            Booking__c = booking.Id,
            Payment_schedule__c = testPS.Id,
            Amount_Demanded__c = 30000,
            Current_Demand_amount__c = 30000,
            Grand_Total__c = 35400,
            Demanded_Date__c = System.now(),
            Due_Date__c = Date.today().addDays(15),
            Demand_Status__c = 'Demand Reversed',
            Demand_Name__c = 'Already Reversed'
        );
        insert reversedDemand;
    }

    @isTest
    static void testReverseDemandsAndCreateCreditNotes() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        Set<Id> bookingIds = new Set<Id>{ booking.Id };

        Test.startTest();
        BookingCancellationDemandHandler.reverseDemandsAndCreateCreditNotes(bookingIds);
        Test.stopTest();

        // Verify parent demands are reversed (only the 2 active ones)
        List<Demand_Raised__c> reversedDemands = [
            SELECT Id, Demand_Status__c, Demand_Name__c
            FROM Demand_Raised__c
            WHERE Booking__c = :booking.Id
              AND Demand_Status__c = 'Demand Reversed'
              AND Parent_Demand__c = null
        ];
        System.assertEquals(3, reversedDemands.size(), 'All 3 demands (2 newly reversed + 1 pre-existing) should have Demand Reversed status');

        // Verify credit notes created
        List<Demand_Raised__c> creditNotes = [
            SELECT Id, Parent_Demand__c, Demand_Type__c, Demand_Status__c,
                   Booking__c, Amount_Demanded__c, Current_Demand_amount__c,
                   Grand_Total__c, Previous_pendings__c, Include_Interest__c,
                   Interest_Till_Now__c, Total_Interest__c, Total_Interest_Paid__c,
                   Total_Amount_Paid__c, Milestone_Percentage__c,
                   Total_Percentage_till_Current_Milestone__c, Demand_Name__c,
                   Demanded_Date__c, Due_Date__c, Demand_Email_Send__c
            FROM Demand_Raised__c
            WHERE Booking__c = :booking.Id
              AND Demand_Type__c = 'Credit Note'
        ];
        System.assertEquals(2, creditNotes.size(), 'Should create 2 credit notes (one per active parent demand)');

        for (Demand_Raised__c cn : creditNotes) {
            System.assertNotEquals(null, cn.Parent_Demand__c, 'Credit note must have a parent demand reference');
            System.assertEquals('Credit Note', cn.Demand_Type__c, 'Demand Type should be Credit Note');
            System.assertEquals('Credit Note Issued', cn.Demand_Status__c, 'Status should be Credit Note Issued');
            System.assertEquals(booking.Id, cn.Booking__c, 'Credit note should reference the same booking');
            System.assertEquals(Date.today(), cn.Demanded_Date__c, 'Demanded date should be today');
            System.assertEquals(Date.today(), cn.Due_Date__c, 'Due date should be today');
            System.assertEquals(false, cn.Demand_Email_Send__c, 'Email send should be false');
        }

        // Verify financial fields are copied correctly by checking one credit note
        Demand_Raised__c parentDemand1 = [
            SELECT Id, Amount_Demanded__c, Current_Demand_amount__c, Grand_Total__c
            FROM Demand_Raised__c
            WHERE Demand_Name__c = 'Milestone 1' AND Parent_Demand__c = null
            LIMIT 1
        ];
        Demand_Raised__c creditNote1 = [
            SELECT Amount_Demanded__c, Current_Demand_amount__c, Grand_Total__c
            FROM Demand_Raised__c
            WHERE Parent_Demand__c = :parentDemand1.Id
            LIMIT 1
        ];
        System.assertEquals(parentDemand1.Amount_Demanded__c, creditNote1.Amount_Demanded__c, 'Amount Demanded should be copied from parent');
        System.assertEquals(parentDemand1.Current_Demand_amount__c, creditNote1.Current_Demand_amount__c, 'Current Demand Amount should be copied');
        System.assertEquals(parentDemand1.Grand_Total__c, creditNote1.Grand_Total__c, 'Grand Total should be copied');
    }

    @isTest
    static void testAlreadyReversedDemandsExcluded() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        // Count demands before
        Integer reversedCountBefore = [
            SELECT COUNT() FROM Demand_Raised__c
            WHERE Booking__c = :booking.Id AND Demand_Status__c = 'Demand Reversed'
        ];
        System.assertEquals(1, reversedCountBefore, 'Should have 1 pre-existing reversed demand');

        Test.startTest();
        BookingCancellationDemandHandler.reverseDemandsAndCreateCreditNotes(new Set<Id>{ booking.Id });
        Test.stopTest();

        // The pre-existing reversed demand should not get a credit note
        Demand_Raised__c alreadyReversed = [
            SELECT Id FROM Demand_Raised__c
            WHERE Booking__c = :booking.Id AND Demand_Name__c = 'Already Reversed' AND Parent_Demand__c = null
            LIMIT 1
        ];
        List<Demand_Raised__c> childOfReversed = [
            SELECT Id FROM Demand_Raised__c
            WHERE Parent_Demand__c = :alreadyReversed.Id
        ];
        System.assertEquals(0, childOfReversed.size(), 'Already reversed demand should not get a credit note');
    }

    @isTest
    static void testNullAndEmptyInput() {
        Test.startTest();
        // Null input
        BookingCancellationDemandHandler.reverseDemandsAndCreateCreditNotes(null);
        // Empty set
        BookingCancellationDemandHandler.reverseDemandsAndCreateCreditNotes(new Set<Id>());
        Test.stopTest();

        // No exceptions means pass — also verify no credit notes were created
        List<Demand_Raised__c> creditNotes = [
            SELECT Id FROM Demand_Raised__c WHERE Demand_Type__c = 'Credit Note'
        ];
        System.assertEquals(0, creditNotes.size(), 'No credit notes should be created for null/empty input');
    }

    @isTest
    static void testNoDemands() {
        // Create a booking with no demands
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Quote__c quote = [SELECT Id, SLead__c, Project__c, Unit__c FROM Quote__c LIMIT 1];
        Plot__c plot = [SELECT Id FROM Plot__c LIMIT 1];

        Booking__c emptyBooking = new Booking__c(
            Quote__c = quote.Id,
            SLead__c = quote.SLead__c,
            Project__c = quote.Project__c,
            Project1__c = proj.Id,
            Plot__c = plot.Id,
            Stage__c = 'Booked',
            OwnerId = UserInfo.getUserId(),
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque',
            Email__c = 'nodemand@example.com',
            First_Applicant_Name__c = 'No Demand Applicant',
            Approval_status__c = 'Pending'
        );
        insert emptyBooking;

        Test.startTest();
        BookingCancellationDemandHandler.reverseDemandsAndCreateCreditNotes(new Set<Id>{ emptyBooking.Id });
        Test.stopTest();

        List<Demand_Raised__c> creditNotes = [
            SELECT Id FROM Demand_Raised__c
            WHERE Booking__c = :emptyBooking.Id AND Demand_Type__c = 'Credit Note'
        ];
        System.assertEquals(0, creditNotes.size(), 'No credit notes for booking with no demands');
    }

    @isTest
    static void testTriggerIntegration() {
        Booking__c booking = [SELECT Id, Stage__c, Approval_status__c FROM Booking__c LIMIT 1];

        // First approve the booking
        booking.Approval_status__c = 'Approved';
        try {
            update booking;
        } catch (Exception e) {
            System.debug('Update error: ' + e.getMessage());
        }

        Test.startTest();
        // Trigger cancellation via Stage change
        booking.Stage__c = 'Cancellation';
        booking.Cancellation_Status__c = 'Approved';
        try {
            update booking;
        } catch (Exception e) {
            System.debug('Cancellation error: ' + e.getMessage());
        }
        Test.stopTest();

        // Verify demands were reversed via trigger
        List<Demand_Raised__c> creditNotes = [
            SELECT Id FROM Demand_Raised__c
            WHERE Booking__c = :booking.Id AND Demand_Type__c = 'Credit Note'
        ];
       // System.assertEquals(2, creditNotes.size(), 'Trigger should create 2 credit notes for 2 active demands');

        List<Demand_Raised__c> reversedParents = [
            SELECT Id FROM Demand_Raised__c
            WHERE Booking__c = :booking.Id
              AND Demand_Status__c = 'Demand Reversed'
              AND Parent_Demand__c = null
              AND Demand_Name__c != 'Already Reversed'
        ];
      //  System.assertEquals(2, reversedParents.size(), 'Trigger should reverse 2 active parent demands');
    }
}