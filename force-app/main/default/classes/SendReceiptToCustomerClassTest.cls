@isTest
public class SendReceiptToCustomerClassTest {
     @testSetup
    static void setupTestData() {
        // Create Account for picklist testing
        Account acc = new Account(
            Name = 'Test Account',
            BillingCountryCode = 'IN',
            BillingStateCode = 'KA'
        );
        insert acc;
        
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
        Payment_Schedule__c testPaymentSchedule = new Payment_Schedule__c(
            Name = 'Test Payment Schedule',
            Quote__c = testQuote.Id,
            S_No__c = 1
           
        );
        insert testPaymentSchedule;
        
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
        
         // Create Booking
        Booking__c testBooking = new Booking__c(
            Quote__c = testQuote.Id,
            SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City',
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
            Approval_status__c = 'Approved'
        );
        insert testBooking;
    }
    
    
    @isTest
    static void testSendReceiptToCustomerSuccess() {
        // Get booking with emails
        Booking__c testBooking = [SELECT Id, Owner.Email FROM Booking__c  LIMIT 1];
        
        
        testBooking.OwnerId = UserInfo.getUserId();
        update testBooking;
        
        Test.startTest();
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Set up mock for PageReference
        PageReference mockPage = Page.ConsolidatedReceipt;
        mockPage.getParameters().put('id', testBooking.Id);
        
        // Call the method
        SendReceiptToCustomerClass.sendReceiptToCustomer(testBooking.Id);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testSendReceiptToCustomerNoRecipients() {
        // Get booking without emails
        Booking__c testBooking = [SELECT Id FROM Booking__c  LIMIT 1];
        
        Test.startTest();
        SendReceiptToCustomerClass.sendReceiptToCustomer(testBooking.Id);
        Test.stopTest();
        
      
    }
    
    @isTest
    static void testSendReceiptToCustomerWithCoApplicants() {
        // Get booking with co-applicants
        Booking__c testBooking = [SELECT Id FROM Booking__c LIMIT 1];
        
        // Get co-applicants count
        List<Co_Applicant__c> coApps = [SELECT Id, Email__c FROM Co_Applicant__c WHERE Booking__c = :testBooking.Id AND Email__c != null];
        
        Test.startTest();
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
      SendReceiptToCustomerClass.sendReceiptToCustomer(testBooking.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSendReceiptToCustomerWithOrgWideEmail() {
        // Get booking
        Booking__c testBooking = [SELECT Id, Owner.Email FROM Booking__c LIMIT 1];
        
        
        Test.startTest();
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
      SendReceiptToCustomerClass.sendReceiptToCustomer(testBooking.Id);
        Test.stopTest();
    
    }
    
    @isTest
    static void testSendReceiptToCustomerInvalidBookingId() {
        Test.startTest();
        try {
            SendReceiptToCustomerClass.sendReceiptToCustomer('001000000000000');
            
        } catch (Exception e) {
         
            System.debug('Email exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSendReceiptToCustomerNullBookingId() {
        Test.startTest();
        try {
            SendReceiptToCustomerClass.sendReceiptToCustomer(null);
         
        } catch (Exception e) {
            System.debug('Email exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSendReceiptToCustomerEmptyBookingId() {
        Test.startTest();
        try {
          SendReceiptToCustomerClass.sendReceiptToCustomer('');
           
        } catch (Exception e) {
           System.debug('Email exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSendReceiptToCustomerOnlyPrimaryEmail() {
        // Create a booking with only primary email
        Quote__c testQuote = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c testPlot = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        
        Booking__c booking = new Booking__c(
           
            Quote__c = testQuote.Id,
            SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City',
            Project1__c = testProject.Id,
            Plot__c = testPlot.Id,
            Stage__c = 'Booked',
            OwnerId = UserInfo.getUserId(),
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque',
            Email__c = 'onlyprimary@example.com',
            Email1__c = null,
            First_Applicant_Name__c = 'Only Primary',
          
            Approval_status__c = 'Approved'
        );
        insert booking;
        
        Test.startTest();
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        SendReceiptToCustomerClass.sendReceiptToCustomer(booking.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSendReceiptToCustomerOnlySecondaryEmail() {
        // Create a booking with only secondary email
        Quote__c testQuote = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c testPlot = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Booking__c booking = new Booking__c(
          
            Quote__c = testQuote.Id,
            SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City',
            Project1__c = testProject.Id,
            Plot__c = testPlot.Id,
            Stage__c = 'Booked',
            OwnerId = UserInfo.getUserId(),
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque',
            Email__c = null,
            Email1__c = 'onlysecondary@example.com',
            First_Applicant_Name__c = 'Only Secondary',
          
            Approval_status__c = 'Approved'
        );
        insert booking;
        
        Test.startTest();
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        SendReceiptToCustomerClass.sendReceiptToCustomer(booking.Id);
        Test.stopTest();
     
    }
    
    @isTest
    static void testSendReceiptToCustomerOnlyCoApplicantEmails() {
        // Create a booking with no primary email but with co-applicants
        Quote__c testQuote = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c testPlot = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Booking__c booking = new Booking__c(
         
            Quote__c = testQuote.Id,
            SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City',
            Project1__c = testProject.Id,
            Plot__c = testPlot.Id,
            Stage__c = 'Booked',
            OwnerId = UserInfo.getUserId(),
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque',
            Email__c = null,
            Email1__c = null,
            First_Applicant_Name__c = 'Only Co-App Emails',
         
            Approval_status__c = 'Approved'
        );
        insert booking;
        
        // Create co-applicants with emails
        Co_Applicant__c coApp1 = new Co_Applicant__c(
            Name = 'Co-App Email 1',
            Email__c = 'coappemail1@example.com',
            PAN_Number__c ='ABCDE1234F',
            Passport_Number__c = 'A1234567',
            Booking__c = booking.Id
        );
        insert coApp1;
        
        Co_Applicant__c coApp2 = new Co_Applicant__c(
            Name = 'Co-App Email 2',
            Email__c = 'coappemail2@example.com',
            Booking__c = booking.Id,
            PAN_Number__c ='ABCDE1234F',
            Passport_Number__c = 'A1234567'
        );
        insert coApp2;
        
        Test.startTest();
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
       SendReceiptToCustomerClass.sendReceiptToCustomer(booking.Id);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testSendReceiptToCustomerEmailException() {
        // Get booking
        Booking__c testBooking = [SELECT Id FROM Booking__c LIMIT 1];
        
        Test.startTest();
        // Don't mock email sending to test exception handling
        // In test context, emails are not actually sent, so we'll test the happy path
        try {
            SendReceiptToCustomerClass.sendReceiptToCustomer(testBooking.Id);
           
        } catch (Exception e) {
            // Might get an exception if email limits are exceeded
            System.debug('Email exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSendReceiptToCustomerPageReferenceTestContext() {
        // Get booking
        Booking__c testBooking = [SELECT Id FROM Booking__c LIMIT 1];
        
        Test.startTest();
        // The method uses Test.isRunningTest() to return mock PDF content
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        SendReceiptToCustomerClass.sendReceiptToCustomer(testBooking.Id);
        Test.stopTest();
      
    }
    
    @isTest
    static void testSendReceiptToCustomerWithLeadEmail() {
        // Create booking that uses SLead__r.Email
        Quote__c testQuote = [SELECT Id FROM Quote__c LIMIT 1];
        Plot__c testPlot = [SELECT Id FROM Plot__c LIMIT 1];
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        
        // Create new lead with email
        Lead newLead = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'New Company',
            Email = 'newlead@example.com',
            Phone = '9876543210',
            Allocated_Project__c = 'Zuari Garden city',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId()
        );
        insert newLead;
        
        Booking__c booking = new Booking__c(
           
            Quote__c = testQuote.Id,
            SLead__c = newLead.Id,
            Project__c = 'Zuari Garden City',
            Project1__c = testProject.Id,
            Plot__c = testPlot.Id,
            Stage__c = 'Booked',
            OwnerId = UserInfo.getUserId(),
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque',
            Email__c = null,  // No primary email
            Email1__c = null, // No secondary email
            First_Applicant_Name__c = 'Lead Email Test',
           
            Approval_status__c = 'Approved'
        );
        insert booking;
        
        Test.startTest();
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
         SendReceiptToCustomerClass.sendReceiptToCustomer(booking.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSendReceiptToCustomerEmailBodyFormatting() {
        // Get booking with emails
        Booking__c testBooking = [SELECT Id FROM Booking__c  LIMIT 1];
        
        // Get co-applicants
        List<Co_Applicant__c> coApps = [SELECT Name FROM Co_Applicant__c WHERE Booking__c = :testBooking.Id];
        
        Test.startTest();
        // Mock the email sending
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
         SendReceiptToCustomerClass.sendReceiptToCustomer(testBooking.Id);
        Test.stopTest();
        
    }
    
    // Mock HTTP response generator for email callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
}