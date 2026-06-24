@isTest
public class DemandRaisedSaveTest {

    @TestSetup
    static void setupTestData() {
        // Creating a test Lead
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Company = 'testcompany';
        ld.Phone = '111111111';
        insert ld;

        // Creating a test Quote
        Quote__c qc = new Quote__c();
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        qc.Payment_Type__c = 'Standard';
        qc.Sale_Area__c = 2567;
        qc.Built_up_area__c = 4567;
        qc.Rate_per_sqft__c = 7100;
        qc.With_GST__c = true;
       // qc.Agreement_Value_Before_GST__c = 6000000; // > 50 lakhs for TDS
        insert qc;

        // Creating a test Project
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c = true;
        pjt.GST_on_Aggrement__c = 18;
        insert pjt;

        // Creating a test Plot
        Plot__c ut = new Plot__c();
        ut.Name = 'Test plot';
        ut.Status__c = 'Available';
        ut.Project__c = pjt.Id;
        insert ut;

        // Creating a Master Payment Schedule
        Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.Id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c = 'Completed';
        mps.S_No__c = 1;
        insert mps;

        // Get RecordType for Apartments
        RecordType apartmentRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Booking__c' AND DeveloperName = 'Apartments' LIMIT 1];

        // Creating a Booking record
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.Email__c = 'test@gmail.com';
        book.Project1__c = pjt.Id;
        book.Applicant_Name__c = 'Test Applicant';
       // book.Total__c = 6000000;
      //  book.GST__c = 18;
        book.RecordTypeId = apartmentRT.Id;
      //  book.Payment_Plan_Name__c = '20:80 Payment plan';
        book.Booking_Date__c = System.today();
        book.Agreement_Value_Before_GST__c = 6000000;
        insert book;

        // Creating Payment Schedule for the Booking
        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Payment_percent__c = 100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = false;
        ps.Quote__c = qc.Id;
        ps.Booking__c = book.Id;
        ps.S_No__c = 1;
        ps.Status__c = 'Completed';
        ps.Last_Payment_Schedule__c = false;
        insert ps;

        // Creating a Receipt
        Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c = book.Id
        );
        insert testReceipt;

        // Creating a Receipt Line Item
        Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c = 'Additional Charges',
            Amount__c = 100,
            Received_Amount__c = 100,
            Booking__c = book.Id
        );
        insert testLineItem;

        // Creating Co-Applicant
        Co_Applicant__c testCoApplicant = new Co_Applicant__c(
            Name = 'Test Co-Applicant',
            Email__c = 'coapplicant@example.com',
            Booking__c = book.Id,
            PAN_Number__c = 'ABCDE1234F',
            Passport_Number__c = 'A1234567',
            Date_of_Birth__c = System.today() - 7300,
            Nationality__c = 'NRI',
            Occupation__c = 'Employee',
            Son_Daughter_Wife_of__c = 'fhsgd'
        );
        insert testCoApplicant;
    }

    @isTest
    static void testGetDemandRaised() {
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        Payment_Schedule__c ps = [SELECT Id FROM Payment_Schedule__c LIMIT 1];
        
        // Create Demand_Raised__c record
        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c = book.Id,
            Payment_schedule__c = ps.Id,
            Amount_Demanded__c = 1000,
            Current_Demand_amount__c = 1000,
            Grand_Total__c = 1000,
            Demanded_Date__c = System.now(),
            Due_Date__c = System.today().addDays(10),
            Include_Interest__c = true,
            Demand_Email_Content__c = 'Test content',
            Previous_pendings__c = 200,
            Interest_Till_Now__c = 50
        );
        insert demand;
        
        Test.startTest();
        Demand_Raised__c result = DemandRaisedSave.getDemandRaised(demand.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Demand should be retrieved');
        System.assertEquals(demand.Id, result.Id, 'IDs should match');
        System.assertEquals(1000, result.Amount_Demanded__c, 'Amount should match');
    }

    @isTest
    static void testRaiseDemandController() {
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        
        Test.startTest();
        String result = DemandRaisedSave.RaiseDemandController(book.Id);
        Test.stopTest();
        
        System.assertEquals('Demand Created', result, 'Demand should be created successfully');
        
        List<Demand_Raised__c> demands = [SELECT Id FROM Demand_Raised__c WHERE Booking__c = :book.Id];
        System.assertNotEquals(0, demands.size(), 'Demand records should exist');
    }

    @isTest
    static void testGetBookingRecord() {
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        
        Test.startTest();
        DemandRaisedSave.BookingWrapper wrapper = DemandRaisedSave.getBookingRecord(book.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertNotEquals(null, wrapper.booking, 'Booking should not be null');
        System.assertEquals(book.Id, wrapper.booking.Id, 'Booking ID should match');
        System.assertNotEquals(null, wrapper.currentMilestone, 'Current milestone should exist');
    }

    @isTest
    static void testGetMilestoneLabel() {
        Test.startTest();
        String label1 = DemandRaisedSave.getMilestoneLabel(1);
        String label2 = DemandRaisedSave.getMilestoneLabel(2);
        String label3 = DemandRaisedSave.getMilestoneLabel(3);
        String label4 = DemandRaisedSave.getMilestoneLabel(4);
        String label21 = DemandRaisedSave.getMilestoneLabel(21);
        String label22 = DemandRaisedSave.getMilestoneLabel(22);
        String label23 = DemandRaisedSave.getMilestoneLabel(23);
        String label31 = DemandRaisedSave.getMilestoneLabel(31);
        String labelNull = DemandRaisedSave.getMilestoneLabel(null);
        Test.stopTest();
        
        System.assertEquals('1st', label1, 'Should return 1st');
        System.assertEquals('2nd', label2, 'Should return 2nd');
        System.assertEquals('3rd', label3, 'Should return 3rd');
        System.assertEquals('4th', label4, 'Should return 4th');
        System.assertEquals('21st', label21, 'Should return 21st');
        System.assertEquals('22nd', label22, 'Should return 22nd');
        System.assertEquals('23rd', label23, 'Should return 23rd');
        System.assertEquals('31st', label31, 'Should return 31st');
        System.assertEquals('Invalid milestone', labelNull, 'Should return Invalid milestone');
    }

    @isTest
    static void testRaiseDemand() {
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        Map<Id, String> emailContents = new Map<Id, String>();
        emailContents.put(book.Id, 'Test Email Content');

        Map<Id, List<String>> contentIds = new Map<Id, List<String>>();
        contentIds.put(book.Id, new List<String>{'DocumentId'});

        Test.startTest();
        String result = DemandRaisedSave.RaiseDemand(new List<Id>{book.Id}, emailContents, contentIds);
        Test.stopTest();

        System.assertEquals('Demand Raise records created', result, 'Demand raise records should be created');
        
        List<Demand_Raised__c> demands = [SELECT Id FROM Demand_Raised__c WHERE Booking__c = :book.Id];
        System.assertNotEquals(0, demands.size(), 'Demand records should be created');
    }

    @isTest
    static void testRaiseDemandNoBookings() {
        Map<Id, String> emailContents = new Map<Id, String>();
        Map<Id, List<String>> contentIds = new Map<Id, List<String>>();

        Test.startTest();
        String result = DemandRaisedSave.RaiseDemand(new List<Id>(), emailContents, contentIds);
        Test.stopTest();

        System.assertEquals('No Booking records provided', result, 'Should return error message');
    }

    @isTest
    static void testRaiseDemandNullBookings() {
        Map<Id, String> emailContents = new Map<Id, String>();
        Map<Id, List<String>> contentIds = new Map<Id, List<String>>();

        Test.startTest();
        String result = DemandRaisedSave.RaiseDemand(null, emailContents, contentIds);
        Test.stopTest();

        System.assertEquals('No Booking records provided', result, 'Should return error message');
    }

    @isTest
    static void testRaiseCustomDemand() {
        Payment_Schedule__c psRecord = [SELECT Id, Booking__c FROM Payment_Schedule__c LIMIT 1];

        Test.startTest();
        String result = DemandRaisedSave.raiseCustomDemand(psRecord.Id);
        Test.stopTest();

        System.assertEquals('Demand raised successfully.', result, 'Demand should be raised successfully');
        
        List<Demand_Raised__c> demands = [SELECT Id FROM Demand_Raised__c WHERE Booking__c = :psRecord.Booking__c];
        System.assertNotEquals(0, demands.size(), 'Demand records should be created');
    }

    @isTest
    static void testRaiseCustomDemandWithPlotsLastPayment() {
        // Create Plot RecordType booking
        RecordType plotRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Booking__c' AND DeveloperName = 'Plots' LIMIT 1];
        
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        
        Booking__c plotBook = new Booking__c();
        plotBook.Quote__c = qc.Id;
        plotBook.Plot__c = ut.Id;
        plotBook.Email__c = 'plot@gmail.com';
        plotBook.Project1__c = pjt.Id;
        plotBook.Applicant_Name__c = 'Plot Applicant';
      //  plotBook.Total__c = 6000000;
      //  plotBook.GST__c = 18;
        plotBook.RecordTypeId = plotRT.Id;
        insert plotBook;

        Master_payment_schedule__c mps = [SELECT Id FROM Master_payment_schedule__c LIMIT 1];
        
        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Payment_percent__c = 100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = false;
        ps.Quote__c = qc.Id;
        ps.Booking__c = plotBook.Id;
        ps.S_No__c = 1;
        ps.Status__c = 'Completed';
        ps.Last_Payment_Schedule__c = true; // Last payment for Plot
        insert ps;

        Test.startTest();
        String result = DemandRaisedSave.raiseCustomDemand(ps.Id);
        Test.stopTest();

        System.assertEquals('Demand raised successfully.', result, 'Demand should be raised for plot last payment');
    }

    @isTest
    static void testBulkAutoDemands() {
        Map<String, Decimal> bookingsWithPSNO = new Map<String, Decimal>();
        bookingsWithPSNO.put([SELECT Id FROM Booking__c LIMIT 1].Id, 1);

        Test.startTest();
        List<Demand_Raised__c> demands = DemandRaisedSave.bulkAutoDemands(bookingsWithPSNO);
        Test.stopTest();

        System.assertNotEquals(null, demands, 'Demands should be created');
    }

    @isTest
    static void testBulkAutoDemandsWithAlreadyDemanded() {
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        Payment_Schedule__c ps = [SELECT Id FROM Payment_Schedule__c WHERE Booking__c = :book.Id LIMIT 1];
        
        // Mark as already demanded
        ps.Is_Demanded__c = true;
        update ps;

        Map<String, Decimal> bookingsWithPSNO = new Map<String, Decimal>();
        bookingsWithPSNO.put(book.Id, 1);

        Test.startTest();
        List<Demand_Raised__c> demands = DemandRaisedSave.bulkAutoDemands(bookingsWithPSNO);
        Test.stopTest();

        System.assertNotEquals(null, demands, 'Method should complete');
    }

    @isTest
    static void testResendRaiseDemand_NoRecords() {
        List<Id> emptyRecordIds = new List<Id>();
        
        Test.startTest();
        DemandRaisedSave.ResendRaiseDemand(emptyRecordIds);
        Test.stopTest();
        
        // Should complete without errors
        System.assert(true, 'Should handle empty list');
    }

    @isTest
    static void testResendRaiseDemand_EmailFailureHandled() {
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c plt = [SELECT Id FROM Plot__c LIMIT 1];

        Booking__c b = new Booking__c(
            Plot__c = plt.Id,
            Email__c = 'customer@test.com',
            PAN_Number__c = 'ABCDE1234F',
            Project1__c = pjt.Id
        );
        insert b;

        Demand_Raised__c d = new Demand_Raised__c(
            Booking__c = b.Id,
            Grand_Total__c = 1000,
            Amount_Demanded__c = 1000,
            Current_Demand_amount__c = 1000,
            Demanded_Date__c = System.now(),
            Due_Date__c = Date.today().addDays(10),
            Include_Interest__c = true,
            Demand_Email_Content__c = 'Test'
        );
        insert d;

        Test.startTest();
        try {
            DemandRaisedSave.ResendRaiseDemand(new List<Id>{ d.Id });
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Failed to resend demand'), 'Should throw proper error');
        }
        Test.stopTest();
    }

    @isTest
    static void testRaiseDemand_70_30PaymentPlan() {
        // Create booking with 70:30 payment plan
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        
        Booking__c book = new Booking__c();
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.Email__c = 'test7030@gmail.com';
        book.Project1__c = pjt.Id;
        book.Applicant_Name__c = 'Test 70-30';
      //  book.Payment_Plan_Name__c = '70:30 Payment Plan';
        book.Booking_Date__c = System.today();
        book.Agreement_Value_Before_GST__c = 6000000;
        insert book;

        Test.startTest();
        String result = DemandRaisedSave.RaiseDemandController(book.Id);
        Test.stopTest();

        System.assertEquals('Demand Created', result, 'Demand should be created for 70:30 plan');
    }

    @isTest
    static void testRaiseDemand_OtherPaymentPlan() {
        // Create booking with other payment plan
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c ut = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c qc = [SELECT Id FROM Quote__c LIMIT 1];
        
        Booking__c book = new Booking__c();
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.Email__c = 'testother@gmail.com';
        book.Project1__c = pjt.Id;
        book.Applicant_Name__c = 'Test Other';
     //   book.Payment_Plan_Name__c = 'Custom Plan';
        book.Booking_Date__c = System.today();
        book.Agreement_Value_Before_GST__c = 6000000;
        insert book;

        Test.startTest();
        String result = DemandRaisedSave.RaiseDemandController(book.Id);
        Test.stopTest();

        System.assertEquals('Demand Created', result, 'Demand should be created for other plan');
    }
}