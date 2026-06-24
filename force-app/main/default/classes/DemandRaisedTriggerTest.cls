@isTest
public class DemandRaisedTriggerTest {

    @TestSetup
    static void makeData() {
        // Lead
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Company = 'testcompany';
        ld.Phone = '111111111';
        insert ld;
        
        // Quote
        Quote__c qc = new Quote__c();
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        qc.Payment_Type__c = 'Standard';
        qc.Sale_Area__c = 2567;
        qc.Built_up_area__c = 4567;
        qc.Rate_per_sqft__c = 7100;
        insert qc;
        
        // Project
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c = true;
        insert pjt;
        
        // Plot
        Plot__c ut = new Plot__c();
        ut.Name = 'Test plot';
        ut.Status__c = 'Available';
        ut.Project__c = pjt.Id;
        insert ut;
        
        // Master Payment Schedule
        Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.Id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c = 'Completed';
        insert mps;
        
        // Booking (Make sure to insert Booking__c, this is the missing required field for Demand_Raised__c)
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c = qc.Id;
        book.Plot__c = ut.Id;
        book.Email__c = 'test@gmail.com';
        insert book;
        
        // Payment Schedule
        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Payment_percent__c = 100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = true;
        ps.Quote__c = qc.Id;
        ps.Booking__c = book.Id;  // Associate the Booking__c here
        ps.S_No__c = 1;           
        insert ps;
        
        // Receipt
        Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c = book.Id
        );
        insert testReceipt;
        
        // Receipt Line Item
        Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c = 'Additional Charges',
            Amount__c = 100,
            Received_Amount__c = 100,
            Booking__c = book.Id
        );
        insert testLineItem;
        
        // Co Applicant
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
        
        // Dummy EmailMessage (not strictly needed, but keeping as in original)
        EmailMessage email = new EmailMessage();
        email.Subject = 'Test';
        email.ToAddress = 'tejaswini@fingertipplus.com';
        email.CcAddress = 'tejaswini@fingertipplus.com';
        insert email;
        
        // ContentVersion used as attachment
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testContentVersion;
    }
/*
    @isTest
    static void testBeforeInsert() {
        // Test the before insert logic: setting date fields
        Demand_Raised__c demand = new Demand_Raised__c();
        demand.Booking__c = [SELECT Id FROM Booking__c LIMIT 1].Id; // Set Booking__c field
        
        Test.startTest();
        insert demand;
        Test.stopTest();
        
        // Query the inserted record to verify date fields
        Demand_Raised__c insertedDemand = [
            SELECT Id, X1st_Reminder_Date__c, X2nd_Reminder_Date__c, X1st_Reminder_Date_with_Interest__c,
            X2nd_Reminder_Interest_Date__c, X3rd_Reminder_Interest_Date__c, Pre_Termination_Mail_Date__c,
            Termination_Mail_Date__c
            FROM Demand_Raised__c
            WHERE Id = :demand.Id
        ];
        
        Date today = System.today();
        System.assertEquals(today.addDays(7), insertedDemand.X1st_Reminder_Date__c, 'X1st_Reminder_Date__c should be today + 7');
        System.assertEquals(today.addDays(14), insertedDemand.X2nd_Reminder_Date__c, 'X2nd_Reminder_Date__c should be today + 14');
        System.assertEquals(today.addDays(21), insertedDemand.X1st_Reminder_Date_with_Interest__c, 'X1st_Reminder_Date_with_Interest__c should be today + 21');
        System.assertEquals(today.addDays(28), insertedDemand.X2nd_Reminder_Interest_Date__c, 'X2nd_Reminder_Interest_Date__c should be today + 28');
        System.assertEquals(today.addDays(35), insertedDemand.X3rd_Reminder_Interest_Date__c, 'X3rd_Reminder_Interest_Date__c should be today + 35');
        System.assertEquals(today.addDays(42), insertedDemand.Pre_Termination_Mail_Date__c, 'Pre_Termination_Mail_Date__c should be today + 42');
        System.assertEquals(today.addDays(49), insertedDemand.Termination_Mail_Date__c, 'Termination_Mail_Date__c should be today + 49');
    }

    @isTest
    static void testAfterInsertWithMailEnabled() {
        // Test the after insert logic: notification and helper method calls when Disable_Demand_Mail__c is false
        Demand_Raised__c demand = new Demand_Raised__c();
        demand.Booking__c = [SELECT Id FROM Booking__c LIMIT 1].Id; // Set Booking__c field
        
        demand.Disable_Demand_Mail__c = false; // Enable mail
        Test.startTest();
        insert demand;
        Test.stopTest();
        
        // Verify the record was inserted and the trigger ran without errors
        Demand_Raised__c insertedDemand = [SELECT Id FROM Demand_Raised__c WHERE Id = :demand.Id];
        System.assertNotEquals(null, insertedDemand.Id, 'Demand should be inserted');
    }
    */
    @isTest
    static void testAfterInsertWithMailDisabled() {
        // Test the after insert logic when Disable_Demand_Mail__c is true
        Demand_Raised__c demand = new Demand_Raised__c();
        demand.Booking__c = [SELECT Id FROM Booking__c LIMIT 1].Id; // Set Booking__c field
        
        demand.Disable_Demand_Mail__c = true; // Disable mail
        Test.startTest();
        insert demand;
        Test.stopTest();
        
        // Verify insertion
        Demand_Raised__c insertedDemand = [SELECT Id FROM Demand_Raised__c WHERE Id = :demand.Id];
        System.assertNotEquals(null, insertedDemand.Id, 'Demand should be inserted');
    }
}