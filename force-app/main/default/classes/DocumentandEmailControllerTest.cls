@IsTest
public class DocumentandEmailControllerTest {

    @testSetup
    static void setup() {

        // ---- User (for Owner tests) ----
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // ---- Project ----
        Project__c prj = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden city',
            Active__c = true,
            CRM_executive__c = UserInfo.getUserId(),
            CRM_Manager__c = UserInfo.getUserId(),
            Sales_Head__c = UserInfo.getUserId(),
            Finance_User__c = UserInfo.getUserId(),
            COO__c = UserInfo.getUserId()
        );
        insert prj;

        // ---- Plot ----
        Plot__c plot = new Plot__c(
            Name = 'Plot-001',
            Status__c = 'Available',
            Unit_Facing_Direction__c = 'North',
            Project__c = prj.Id
        );
        insert plot;

        // ---- Lead ----
        Lead ld = new Lead(
            FirstName = 'Test',
            LastName  = 'Lead',
            Company   = 'Test Company',
            Email     = 'test@example.com',
            Phone     = '1234567890',
            Allocated_Project__c = 'Zuari Garden city',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId()
        );
        insert ld;

        // ---- Quote ----
        Quote__c qt = new Quote__c(
            SLead__c = ld.Id,
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
            Legal_Documentation_Charges__c = 5000,
            Unit__c = plot.Id
        );
        insert qt;

        // ---- Booking (for most tests) ----
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            S__c = 'Mr.',
            Email__c = 'customer@example.com',
            PAN_Number__c = 'ABCDE1234F',
            Plot__c = plot.Id,
            Project1__c = prj.Id,
            Funding_Type__c = 'Self',
            Agreement_Execution_Amount1__c = 95000,
            Quote__c = qt.Id,
            SLead__c = ld.Id,
            Project__c = qt.Project__c,
            Stage__c = 'Booked',
            OwnerId = testUser.Id,
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Mode_Of_Payment__c = 'Cheque'
        );
        insert booking;

        // ---- Co-Applicant ----
        Co_Applicant__c ca = new Co_Applicant__c(
            Booking__c = booking.Id,
            Name = 'Co Applicant',
            PAN_Number__c = 'ABCDE1234F',
            Email__c = 'coapp@example.com'
        );
        insert ca;

        // ---- Receipt ----
        Receipt__c rec = new Receipt__c(
            Booking__c = booking.Id,
            Approval_Status__c = 'Approved',
            Receipt_date__c = Date.today()
        );
        insert rec;

        // ---- Demand Raised ----
        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c = booking.Id,
            Demand_Name__c = 'Agreement Amount',
            Demand_Email_Content__c = 'Dear Customer,<br/>Please find the attached demand note.<br/>Thanks.'
        );
        insert demand;

        // ---- Booking with NO Email (for negative receipt test) ----
        Booking__c bookingNoEmail = new Booking__c(
            First_Applicant_Name__c = 'John Doe',
            Plot__c = plot.Id,
            Project1__c = prj.Id,
            Funding_Type__c = 'Self',
            OwnerId = testUser.Id
        );
        insert bookingNoEmail;

        Receipt__c recNoEmail = new Receipt__c(
            Booking__c = bookingNoEmail.Id
        );
        insert recNoEmail;

        // ---- Booking for "Ms. Alice" name test ----
        Booking__c bookingAlice = new Booking__c(
            First_Applicant_Name__c = 'Alice',
            S__c = 'Mr.',
            Email__c = 'alice@example.com',
            PAN_Number__c = 'ABCDE1234F',
            Plot__c = plot.Id,
            Project1__c = prj.Id,
            Funding_Type__c = 'Self',
            Agreement_Execution_Amount1__c = 95000,
            OwnerId = testUser.Id
        );
        insert bookingAlice;
    }

    // -------- Helpers --------
    private static Booking__c getBookingMain() {
        return [
            SELECT Id, Email__c, First_Applicant_Name__c, S__c
            FROM Booking__c
            WHERE First_Applicant_Name__c = 'Test Applicant'
            LIMIT 1
        ];
    }

    private static Booking__c getBookingAlice() {
        return [
            SELECT Id, Email__c, First_Applicant_Name__c, S__c
            FROM Booking__c
            WHERE First_Applicant_Name__c = 'Alice'
            LIMIT 1
        ];
    }

    private static Receipt__c getReceiptMain() {
        return [
            SELECT Id, Booking__c
            FROM Receipt__c
            WHERE Booking__r.First_Applicant_Name__c = 'Test Applicant'
            LIMIT 1
        ];
    }

    private static Receipt__c getReceiptNoEmailBooking() {
        return [
            SELECT Id, Booking__c
            FROM Receipt__c
            WHERE Booking__r.First_Applicant_Name__c = 'John Doe'
            LIMIT 1
        ];
    }

    private static Demand_Raised__c getDemandMain() {
        return [
            SELECT Id
            FROM Demand_Raised__c
            LIMIT 1
        ];
    }

    // -------- Tests --------

    @IsTest
    static void testGetBookingDetails_BasicFields() {
        Booking__c booking = getBookingAlice();

        Test.startTest();
        DocumentandEmailController.BookingDataWrapper result =
            DocumentandEmailController.getBookingDetails(booking.Id);
        Test.stopTest();


    }

    @IsTest
    static void testGetBookingDetails() {
        Booking__c b = getBookingMain();

        Test.startTest();
        DocumentandEmailController.BookingDataWrapper w =
            DocumentandEmailController.getBookingDetails(b.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateReceipt_success() {
        Receipt__c r = getReceiptMain();

        Test.startTest();
        String msg = DocumentandEmailController.sendEmailGenerateReceipt(r.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateReceipt_noBookingEmail() {
        Receipt__c r = getReceiptNoEmailBooking();

        Test.startTest();
        String result = DocumentandEmailController.sendEmailGenerateReceipt(r.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateReceipt_invalidReceipt_nullId() {
        Test.startTest();
        String result = DocumentandEmailController.sendEmailGenerateReceipt(null);
        Test.stopTest();

       
    }

    @IsTest
    static void testSendEmailGenerateReceiptfromTrigger_future() {
        Receipt__c r = getReceiptMain();

        Test.startTest();
        DocumentandEmailController.sendEmailGenerateReceiptfromTrigger(r.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateSA() {
        Booking__c b = getBookingMain();

        Test.startTest();
        String msg = DocumentandEmailController.sendEmailGenerateSA(
            b.Id,
            'Dear Customer,<br/>Please find attached Sale Agreement.<br/>Thanks.'
        );
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateDemand_invocable() {
        Demand_Raised__c d = getDemandMain();

        Test.startTest();
        DocumentandEmailController.sendEmailGenerateDemand(new List<Id>{ d.Id });
        Test.stopTest();

    }

    @IsTest
    static void testValidateEmails() {
        List<String> input = new List<String>{
            'valid@example.com',
            'bad-email',
            null,
            'also.valid+1@test.co'
        };

        Test.startTest();
        List<String> outList = DocumentandEmailController.validateEmails(input);
        Test.stopTest();

    }

    @IsTest
    static void testGetBookingRecordViaReciept() {
        Receipt__c r = getReceiptMain();

        Test.startTest();
        Booking__c b = DocumentandEmailController.getBookingRecordViaReciept(r.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendAgreementRequestMail() {
        Booking__c b = getBookingMain();

        Test.startTest();
        String msg = DocumentandEmailController.sendAgreementRequestMail(
            b.Id,
            'Dear Customer,<br/>Please confirm agreement execution date.<br/>Thanks.'
        );
        Test.stopTest();

    }

    @IsTest
    static void testSendHandoverEmail() {
        Booking__c b = getBookingMain();

        Test.startTest();
        String msg = DocumentandEmailController.sendHandoverEmail(b.Id);
        Test.stopTest();
    }

    @IsTest
    static void testSendHandoverEmail_noCustomerEmail() {
        Booking__c b = getBookingMain();
        b.Email__c = null;
        update b;

        Test.startTest();
        String msg = DocumentandEmailController.sendHandoverEmail(b.Id);
        Test.stopTest();

    }
}