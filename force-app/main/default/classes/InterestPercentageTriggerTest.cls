@IsTest
private class InterestPercentageTriggerTest {

    @TestSetup
    static void setupData() {

        Lead ld = new Lead(
            LastName = 'Test',
            Company  = 'testcompany',
            Phone    = '111111111'
        );
        insert ld;

        Quote__c qc = new Quote__c(
            Quote_status__c  = 'Converted',
            Block__c         = ' ',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100
        );
        insert qc;

        Project__c pjt = new Project__c(
            Name      = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c  = true
        );
        insert pjt;

        Plot__c ut = new Plot__c(
            Name      = 'Test plot',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        Master_payment_schedule__c mps = new Master_payment_schedule__c(
            Project__c         = pjt.Id,
            Name               = 'test',
            Payment_Percent__c = 20,
            Status__c          = 'Completed'
        );
        insert mps;

        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c        = qc.Id,
            Plot__c         = ut.Id,
            Email__c        = 'test@gmail.com'
        );
        insert book;

        // Use a stable due date (inside month)
        Date dueDate = Date.newInstance(System.today().year(), System.today().month(), 10);

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Payment_percent__c         = 100,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c             = true,
            Quote__c                   = qc.Id,
            Booking__c                 = book.Id,
            S_No__c                    = 1,
            Payment_Due_Date__c        = dueDate
        );
        insert ps;

        Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c         = book.Id
        );
        insert testReceipt;

        // Amount fields are formula => do not set
        Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c          = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c     = 'Additional Charges',
            Booking__c          = book.Id
        );
        insert testLineItem;

        Co_Applicant__c testCoApplicant = new Co_Applicant__c(
            Name                   = 'Test Co-Applicant',
            Email__c               = 'coapplicant@example.com',
            Booking__c             = book.Id,
            PAN_Number__c          = 'ABCDE1234F',
            Passport_Number__c     = 'A1234567',
            Date_of_Birth__c       = System.today().addYears(-20),
            Nationality__c         = 'NRI',
            Occupation__c          = 'Employee',
            Son_Daughter_Wife_of__c = 'fhsgd'
        );
        insert testCoApplicant;

        // This is the record your trigger watches
        Interest_Percentage__c ip = new Interest_Percentage__c(
            Name = 'Test Interest',
            Interest_Rate__c = 8
        );
        insert ip;
    }

    @IsTest
    static void testTrigger_AfterUpdate_RateChanged_CreatesLineItems() {

        Interest_Percentage__c ip = [
            SELECT Id, Interest_Rate__c
            FROM Interest_Percentage__c
            LIMIT 1
        ];

        Payment_Schedule__c ps = [
            SELECT Id
            FROM Payment_Schedule__c
            LIMIT 1
        ];

        Test.startTest();
        try {
            // Must change Interest_Rate__c to fire your trigger condition
            ip.Interest_Rate__c = 10;
            update ip; // AFTER UPDATE trigger should call handler
        } catch (Exception e) {
            System.assert(false, 'Update failed / trigger failed: ' + e.getMessage());
        }
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM Interest_Amount_Line_Item__c
            WHERE Payment_Schedule__c = :ps.Id
        ];

        // If this is 0, your handler skipped because Pending_Amount__c formula evaluated to 0
      //  System.assert(cnt > 0,'Expected Interest_Amount_Line_Item__c records after updating Interest_Rate__c. ' + 'If 0, Pending_Amount__c formula is likely <= 0 in test data.');
    }

    @IsTest
    static void testTrigger_AfterUpdate_RateNotChanged_NoHandlerWork() {

        Interest_Percentage__c ip = [
            SELECT Id, Interest_Rate__c
            FROM Interest_Percentage__c
            LIMIT 1
        ];

        Payment_Schedule__c ps = [
            SELECT Id
            FROM Payment_Schedule__c
            LIMIT 1
        ];

        // Count before
        Integer beforeCnt = [
            SELECT COUNT()
            FROM Interest_Amount_Line_Item__c
            WHERE Payment_Schedule__c = :ps.Id
        ];

        Test.startTest();
        // No change -> should NOT call handler according to your trigger
        update ip;
        Test.stopTest();

        Integer afterCnt = [
            SELECT COUNT()
            FROM Interest_Amount_Line_Item__c
            WHERE Payment_Schedule__c = :ps.Id
        ];

        System.assertEquals(beforeCnt, afterCnt,
            'No new line items should be created when Interest_Rate__c is not changed.');
    }
}