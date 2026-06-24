@isTest
private class DemandInvioceControllerTest {

    private static Id setupTestData() {
        // Lead
        Lead ld = new Lead(LastName = 'Test', Company = 'testcompany', Phone = '111111111');
        insert ld;

        // Quote
        Quote__c qc = new Quote__c(
            Quote_status__c = 'Converted',
            Block__c = ' ',
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100
        );
        insert qc;

        // Project
        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c = true
        );
        insert pjt;

        // Plot
        Plot__c ut = new Plot__c(
            Name = 'Test plot',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        // Master Payment Schedule
        Master_payment_schedule__c mps = new Master_payment_schedule__c(
            Project__c = pjt.Id,
            Name = 'test',
            Payment_Percent__c = 20,
            Status__c = 'Completed'
        );
        insert mps;

        // Booking
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            Email__c = 'test@gmail.com'
                         
        );
        insert book;

        // Payment Schedule
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Payment_percent__c = 100,
            Master_Payment_Schedule__c = mps.Id,
            Status__c = 'Completed',
            Is_Demanded__c = true,
            Quote__c = qc.Id,
            Booking__c = book.Id,
            S_No__c = 1
        );
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

        // Optional EmailMessage
        EmailMessage email = new EmailMessage(
            Subject = 'Test',
            ToAddress = 'tejaswini@fingertipplus.com',
            CcAddress = 'tejaswini@fingertipplus.com'
        );
        insert email;

        return book.Id;
    }

    @isTest
    static void testDemandInvioceController_MainFlow() {
        // Setup test data
        Id bookingId = setupTestData();

        // Prepare VF page context
        Test.setCurrentPage(new ApexPages.PageReference('/apex/fakePage'));
        ApexPages.currentPage().getParameters().put('Id', bookingId);

        // Run controller
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController([SELECT Id FROM Booking__c WHERE Id = :bookingId]);
        DemandInvioceController controller = new DemandInvioceController(sc);
        Test.stopTest();

        // Validate some outputs
        System.assertNotEquals(null, controller.currentCompletedStage, 'Expected a valid Completed Stage');
        System.assertNotEquals(null, controller.paymentscheudlename, 'Expected the payment schedule name');
        System.assert(controller.totalAmountPayable >= 0, 'totalAmountPayable should be initialized to >= 0');
        System.assertNotEquals(null, controller.totalAmountPayableInWords, 'Words conversion should be populated');
        System.assert(controller.milestoneAmountInWords != null, 'Milestone amount in words should not be null');
        System.assert(controller.currentMilestoneNumber != null, 'Milestone label should be computed');
    }

    @isTest
    static void testGetMilestoneLabel() {
        // Some static cases for suffix logic
        System.assertEquals('1st', DemandInvioceController.getMilestoneLabel(1));
        System.assertEquals('2nd', DemandInvioceController.getMilestoneLabel(2));
        System.assertEquals('3rd', DemandInvioceController.getMilestoneLabel(3));
        System.assertEquals('4th', DemandInvioceController.getMilestoneLabel(4));
        System.assertEquals('21st', DemandInvioceController.getMilestoneLabel(21));
        System.assertEquals('30th', DemandInvioceController.getMilestoneLabel(30));
    }
}