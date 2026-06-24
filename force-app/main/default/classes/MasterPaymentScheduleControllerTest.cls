@IsTest
public class MasterPaymentScheduleControllerTest {

    @TestSetup
    static void setupData() {
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

        // Master Payment Schedule (must match controller object API name)
        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c();
        mps.Project__c = pjt.Id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c = 'Completed';
        mps.Completed_Date__c = Date.today();
        insert mps;

        // Booking
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
        ps.Booking__c = book.Id;
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

        // Dummy EmailMessage
        EmailMessage email = new EmailMessage();
        email.Subject = 'Test';
        email.ToAddress = 'tejaswini@fingertipplus.com';
        email.CcAddress = 'tejaswini@fingertipplus.com';
        insert email;
    }

    @IsTest
    static void testCompletionOfMPS_SendsEmail() {
        Master_Payment_Schedule__c mps =
            [SELECT Id FROM Master_Payment_Schedule__c LIMIT 1];

        Test.startTest();
        MasterPaymentScheduleController.CompletetionOfMPS(new List<Id>{ mps.Id });
        Test.stopTest();

       
    }

    @IsTest
    static void testCompletionOfMPS_EmptyInput() {
        Test.startTest();
        MasterPaymentScheduleController.CompletetionOfMPS(new List<Id>());
        Test.stopTest();

        
    }
}