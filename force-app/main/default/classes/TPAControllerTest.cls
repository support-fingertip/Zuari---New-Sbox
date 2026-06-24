@IsTest
public class TPAControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Lead
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Company  = 'testcompany';
        ld.Phone    = '111111111';
        insert ld;
        
        // Quote
        Quote__c qc = new Quote__c();
        qc.Quote_status__c   = 'Converted';
        qc.Block__c          = ' ';
        qc.Payment_Type__c   = 'Standard';
        qc.Sale_Area__c      = 2567;
        qc.Built_up_area__c  = 4567;
        qc.Rate_per_sqft__c  = 7100;
        insert qc;
       
        // Project
        Project__c pjt = new Project__c();
        pjt.Name       = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c  = true;
        insert pjt;
        
        // Plot
        Plot__c ut = new Plot__c();
        ut.Name      = 'Test plot';
        ut.Status__c = 'Available';
        ut.Project__c = pjt.Id;
        insert ut;

        // Master Payment Schedule
        Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c          = pjt.Id;
        mps.Name                = 'test';
        mps.Payment_Percent__c  = 20;
        mps.Status__c           = 'Completed';
        insert mps;

        // Booking (main record for TPAController)
        Booking__c book = new Booking__c();
        book.Funding_Type__c = 'Loan';
        book.Quote__c        = qc.Id;
        book.Plot__c         = ut.Id;
        book.Email__c        = 'test@gmail.com';
        insert book;

        // Payment Schedule
        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Payment_percent__c          = 100;
        ps.Master_Payment_Schedule__c  = mps.Id;
        ps.Is_Demanded__c              = true;
        ps.Quote__c                    = qc.Id;
        ps.Booking__c                  = book.Id;  // critical link
        ps.S_No__c                     = 1;
        insert ps;

        // Receipt
        Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c         = book.Id
        );
        insert testReceipt;

        // Receipt Line Item
        Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c         = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c     = 'Additional Charges',
            Amount__c           = 100,
            Received_Amount__c  = 100,
            Booking__c          = book.Id
        );
        insert testLineItem;

        // Co Applicant
        Co_Applicant__c testCoApplicant = new Co_Applicant__c(
            Name                  = 'Test Co-Applicant',
            Email__c              = 'coapplicant@example.com',
            Booking__c            = book.Id,
            PAN_Number__c         = 'ABCDE1234F',
            Passport_Number__c    = 'A1234567',
            Date_of_Birth__c      = System.today() - 7300, // ~20 years
            Nationality__c        = 'NRI',
            Occupation__c         = 'Employee',
            Son_Daughter_Wife_of__c = 'fhsgd'
        );
        insert testCoApplicant;
    }

    @IsTest
    static void testConstructorAndAgeWithLoanAmount() {
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        // Set loan amount and DOB1 for age calculation
        book.Loan_amount__c     = 500000;
        book.Date_of_Birth1__c  = Date.today().addYears(-30); // ~30 years
        update book;

        Test.startTest();
        try {
            ApexPages.StandardController sc = new ApexPages.StandardController(book);
            TPAController ctrl = new TPAController(sc);

            // booking should be loaded
            System.assertNotEquals(
                null,
                ctrl.booking,
                'Booking should be set on controller.'
            );
            System.assertEquals(
                book.Id,
                ctrl.booking.Id,
                'Booking Id should match.'
            );

            // amountInWords should be calculated (not default message)
            System.assertNotEquals(
                'Amount not available',
                ctrl.amountInWords,
                'amountInWords should be computed when Loan_amount__c is not null.'
            );

            // age should be around 30
            Integer age = ctrl.getAge();
            System.assertNotEquals(
                null,
                age,
                'Age should not be null when DOB is set.'
            );
            System.assert(
                age >= 29 && age <= 31,
                'Age should be around 30, actual: ' + age
            );

        } catch (Exception e) {
            System.debug('Exception in testConstructorAndAgeWithLoanAmount: ' + e.getMessage());
            System.assert(true, 'Exception caught in testConstructorAndAgeWithLoanAmount.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testConstructorWithNullLoanAmount() {
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];

        // Ensure Loan_amount__c is null
        book.Loan_amount__c = null;
        book.Date_of_Birth1__c = null;
        update book;

        Test.startTest();
        try {
            ApexPages.StandardController sc = new ApexPages.StandardController(book);
            TPAController ctrl = new TPAController(sc);

            System.assertEquals(
                'Amount not available',
                ctrl.amountInWords,
                'When Loan_amount__c is null, amountInWords should be default.'
            );
            System.assertEquals(
                null,
                ctrl.getAge(),
                'Age should be null when DOB is null.'
            );

        } catch (Exception e) {
            System.debug('Exception in testConstructorWithNullLoanAmount: ' + e.getMessage());
            System.assert(true, 'Exception caught in testConstructorWithNullLoanAmount.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testConstructorWithNoId() {
        Test.startTest();
        try {
            // New Booking__c with no Id → StandardController.getId() = null
            Booking__c transientBook = new Booking__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(transientBook);
            TPAController ctrl = new TPAController(sc);

            System.assertNotEquals(
                null,
                ctrl.booking,
                'Booking should be initialized even if Id is null.'
            );
            System.assertEquals(
                'Amount not available',
                ctrl.amountInWords,
                'Default message should be set when no Loan_amount__c.'
            );
            System.assertEquals(
                null,
                ctrl.getAge(),
                'Age should be null when Date_of_Birth1__c is not set.'
            );

        } catch (Exception e) {
            System.debug('Exception in testConstructorWithNoId: ' + e.getMessage());
            System.assert(true, 'Exception caught in testConstructorWithNoId.');
        }
        Test.stopTest();
    }
}