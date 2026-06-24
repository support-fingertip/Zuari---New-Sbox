@isTest
public class BookingPDFControllerTest {

    @isTest
    public static void testBookingPDFController_FullFlow() {

        // Create Lead
        Lead testLead = new Lead(
            LastName            = 'Test Lead',
            Allocated_Project__c = 'Zuari Garden City',
            Reassigned_By__c    = UserInfo.getUserId(),
            Re_assigned_date__c = System.now(),
            Lead_status__c      = 'New',
            Email               = 'lead@sample.com',
            LeadSource          = 'Advertisement',
            Source_Type__c      = 'Referral',
            Phone__c            = '9876543210',
            Company             = 'Test Co'
        );
        insert testLead;

        // Create Quote
        Quote__c testQuote = new Quote__c(
            Project__c            = 'Zuari Garden City',
            Payment_Type__c       = 'Standard',
            Quote_status__c       = 'Converted',
            SLead__c              = testLead.Id,
            Super_Built_UpArea__c = 100
        );
        insert testQuote;

        // Create Booking (IMPORTANT: set Email__c)
        Booking__c bk = new Booking__c(
            SLead__c                = testLead.Id,
            Quote__c                = testQuote.Id,
            Booking_Amount__c       = 100000,
            Notes_and_Comments__c   = 'Line1\r\nLine2',
            Date_of_Birth1__c       = Date.today(),
            Spouse_Date_Of_Birth__c = Date.today(),
            Anniverssary_Date1__c   = Date.today(),
            Email__c                = 'customer@test.com'
        );
        insert bk;

        // Create Co-Applicant
        Co_Applicant__c coApp = new Co_Applicant__c(
            Booking__c                   = bk.Id,
            Name                         = 'Co Applicant',
            PAN_Number__c                = 'ABCDE1234F',
            Passport_Number__c           = 'A8888888',
            Date_of_Birth__c             = Date.today().addYears(-30),
            Spouse_Date_Of_Birth_coapp__c = Date.today().addYears(-28),
            Anniverssary_Date__c         = Date.today().addYears(-5)
        );
        insert coApp;

        // ContentVersion so file queries in controller have data
        ContentVersion cv = new ContentVersion(
            Title          = 'Applicant Passport Photo Sample',
            PathOnClient   = 'photo.jpg',
            VersionData    = Blob.valueOf('Sample Data'),
            IsMajorVersion = true
        );
        insert cv;

        // Set current page and instantiate controller
        PageReference pref = Page.BookingForm;
        Test.setCurrentPage(pref);
        pref.getParameters().put('id', bk.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(bk);
        BookingPDFController ctrl = new BookingPDFController(sc);

        // Call address & state/country getters for coverage
        String pAddr  = ctrl.getPermanentFullAddress();
        String cAddr  = ctrl.getCorrespondenceFullAddress();
        String oAddr  = ctrl.getOfficeFullAddress();

        String fpAddr = ctrl.getFirstCoApplicantPermanentFullAddress();
        String fcAddr = ctrl.getFirstCoApplicantCommunicationFullAddress();
        String foAddr = ctrl.getFirstCoApplicantOfficeFullAddress();

        String pState  = ctrl.getPermanentStateName();
        String cState  = ctrl.getCorrespondenceStateName();
        String oState  = ctrl.getOfficeStateName();

        String fpState = ctrl.getFirstCoApplicantPermanentStateName();
        String fcState = ctrl.getFirstCoApplicantCommunicationStateName();
        String foState = ctrl.getFirstCoApplicantOfficeStateName();

        String pCountry  = ctrl.getPermanentCountryName();
        String cCountry  = ctrl.getCorrespondenceCountryName();
        String oCountry  = ctrl.getOfficeCountryName();
        String fpCountry = ctrl.getFirstCoApplicantPermanentCountryName();
        String fcCountry = ctrl.getFirstCoApplicantCommunicationCountryName();
        String foCountry = ctrl.getFirstCoApplicantOfficeCountryName();

        // Basic sanity asserts on controller state
        System.assertNotEquals(null, ctrl.booking, 'Booking should be set');
        System.assertNotEquals(null, ctrl.textLines, 'Text lines should be initialized');

        // Test sendEmailtoCustomer
        Test.startTest();
        String result = BookingPDFController.sendEmailtoCustomer(bk.Id);
        Test.stopTest();

        // Do NOT expect exact text; just make sure email was attempted
        System.assertNotEquals(
            'Please enter email address',
            result,
            'Method should not say missing email when Email__c is populated'
        );
    }
}