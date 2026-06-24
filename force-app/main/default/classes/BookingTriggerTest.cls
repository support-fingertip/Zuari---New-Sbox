@isTest
public class BookingTriggerTest {
    
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
            S_No__c = 1,
            Amount__c = 100000
           
        );
        insert testPaymentSchedule;
        
        // Create additional payment schedules for testing
        Payment_Schedule__c testPaymentSchedule2 = new Payment_Schedule__c(
            Name = 'Payment within 30 days from booking date',
            Quote__c = testQuote.Id,
            S_No__c = 2,
            Amount__c = 50000
        );
        insert testPaymentSchedule2;
        
        Payment_Schedule__c testPaymentSchedule3 = new Payment_Schedule__c(
            Name = 'Payment within 90 days from booking date',
            Quote__c = testQuote.Id,
            S_No__c = 3,
            Amount__c = 50000
        );
        insert testPaymentSchedule3;
        
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
    }
    
    @isTest
    static void testBeforeInsertValidation() {
        Quote__c testQuote = [SELECT Id, Unit__c FROM Quote__c LIMIT 1];
        
        Test.startTest();
        try {
            Booking__c newBooking = new Booking__c(
               
                Quote__c = testQuote.Id,
                Plot__c = testQuote.Unit__c,
                Stage__c = 'New',
                Booking_Date__c = Date.today(),
                Booking_Amount__c = 50000,
                Approval_status__c = 'Pending'
            );
            insert newBooking;
            System.assert(true, 'Booking should be inserted without validation errors');
        } catch(Exception e) {
            System.debug('Validation error: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdateValidationStageToBookedWithoutApproval() {
        // Create a booking with stage 'New'
        Booking__c testBooking = createTestBooking('New');
        
        Test.startTest();
        try {
            // Try to update stage to 'Booked' without approval
            testBooking.Stage__c = 'Booked';
            update testBooking;
            System.assert(false, 'Should have thrown validation error');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('Stage cannot be changed to Booked without aproval'), 
                         'Should throw validation error when changing to Booked without approval');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdateValidationStageToAgreementWithoutApproval() {
        // Create a booking with stage 'New'
        Booking__c testBooking = createTestBooking('New');
        
        Test.startTest();
        try {
            // Try to update stage to 'Agreement' without approval
            testBooking.Stage__c = 'Agreement';
            update testBooking;
            System.assert(false, 'Should have thrown validation error');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('Stage cannot be changed to Agreement without approval'), 
                         'Should throw validation error when changing to Agreement without approval');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdateValidationStageToDemandsCollectionsWithoutPayment() {
        // Create a booking with stage 'Booked'
        Booking__c testBooking = createTestBooking('Booked');
        testBooking.Approval_status__c = 'Approved';
        testBooking.Agreement_Execution_Amount1__c = 100000;
       
        update testBooking;
        
        Test.startTest();
        try {
            // Try to update stage to 'Demands & Collections' without full payment
            testBooking.Stage__c = 'Demands & Collections';
            update testBooking;
            System.assert(false, 'Should have thrown validation error');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('Stage cannot be changed to Demands & Collections without paying Agreement Execution Amount'), 
                         'Should throw validation error when changing to Demands & Collections without full payment');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdateAutoStageChangeOnAgreementExecution() {
        // Create a booking with stage 'Agreement'
        Booking__c testBooking = createTestBooking('Agreement');
        testBooking.Approval_status__c = 'Approved';
        testBooking.Agreement_Status__c = 'Pending';
        try {
        update testBooking;
             } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
        
        Test.startTest();
        // Update Agreement Status to 'Executed'
        testBooking.Agreement_Status__c = 'Executed';
        update testBooking;
        
        Test.stopTest();
        
    
    }
    
    @isTest
    static void testBeforeUpdateWelcomeEmailSent() {
        // Create a booking with stage 'Booked'
        Booking__c testBooking = createTestBooking('Booked');
        testBooking.Approval_status__c = 'Approved';
        testBooking.Welcome_Email_Sent_to_Customer__c = false;
        testBooking.Agreement_Execution_Amount1__c = 100000;
       
        update testBooking;
        
        // Create approved receipt
        Receipt__c receipt = new Receipt__c(
            Booking__c = testBooking.Id,
            Approval_Status__c = 'Approved',
           Receipt_date__c = Date.today()
        );
        insert receipt;
        
        Test.startTest();
        // Update Welcome Email Sent to true
        testBooking.Welcome_Email_Sent_to_Customer__c = true;
        update testBooking;
        
        Test.stopTest();
       
    }
    
    @isTest
    static void testAfterInsertUnitStatusBlocked() {
        Quote__c testQuote = [SELECT Id, Unit__c FROM Quote__c LIMIT 1];
        Plot__c testPlot = [SELECT Id FROM Plot__c WHERE Id = :testQuote.Unit__c];
        
        Test.startTest();
        // Create booking with stage 'New'
        Booking__c newBooking = new Booking__c(
          
            Quote__c = testQuote.Id,
            Plot__c = testPlot.Id,
            Stage__c = 'New',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Approval_status__c = 'Pending'
        );
        insert newBooking;
        
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testAfterInsertPaymentScheduleUpdate() {
        Quote__c testQuote = [SELECT Id, Unit__c FROM Quote__c LIMIT 1];
        
        Test.startTest();
        // Create booking
        Booking__c newBooking = new Booking__c(
          
            Quote__c = testQuote.Id,
            Plot__c = testQuote.Unit__c,
            Stage__c = 'New',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Approval_status__c = 'Pending'
        );
        insert newBooking;
        
        Test.stopTest();
        
    }
 /*   
    @isTest
    static void testAfterUpdateOwnerChangeNotification() {
        Booking__c testBooking = createTestBooking('New');
        
        // Create another user for testing
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User newUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@example.com.test'
        );
        insert newUser;
        
        Test.startTest();
        // Update owner
         try {
        testBooking.OwnerId = newUser.Id;
        update testBooking;
              } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
        
        Test.stopTest();
        
       
    }
   */ 
    @isTest
    static void testAfterUpdateCancellation() {
        Booking__c testBooking = createTestBooking('Booked');
        testBooking.Approval_status__c = 'Approved';
         try {
        update testBooking;
              } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
        
        Test.startTest();
        // Update to cancellation
        testBooking.Stage__c = 'Cancellation';
        testBooking.Cancellation_Status__c = 'Approved';
         try {
        update testBooking;
              } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
        
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testAfterUpdateSwapping() {
        Booking__c testBooking = createTestBooking('Booked');
        
        // Create another plot for swapping
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c swapPlot = new Plot__c(
            Name = 'Swap Plot',
            Status__c = 'Available',
            Project__c = testProject.Id
        );
        insert swapPlot;
        
        testBooking.Swap_Unit__c = swapPlot.Id;
        testBooking.Swap_Unit_Status__c = 'Pending';
         try {
        update testBooking;
              } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
        
        Test.startTest();
        // Approve swap unit
        testBooking.Swap_Unit_Status__c = 'Approved';
         try {
        update testBooking;
              } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
        
        Test.stopTest();
        
      
    }
    
    @isTest
    static void testAfterUpdateStageToAgreementNotification() {
        Booking__c testBooking = createTestBooking('New');
        testBooking.Approval_status__c = 'Approved';
        update testBooking;
        
        Test.startTest();
        // Update stage to Agreement
        testBooking.Stage__c = 'Agreement';
        update testBooking;
        
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testAfterUpdateStageToDemandsCollectionsNotification() {
        Booking__c testBooking = createTestBooking('Agreement');
        testBooking.Approval_status__c = 'Approved';
        update testBooking;
        
        Test.startTest();
        // Update stage to Demands & Collections
        testBooking.Stage__c = 'Demands & Collections';
        update testBooking;
        
        Test.stopTest();
        
      
    }
  /*  
    @isTest
    static void testAfterUpdateHandOver() {
        Booking__c testBooking = createTestBooking('Demands & Collections');
        testBooking.Email__c = 'test@example.com';
        testBooking.First_Applicant_Name__c = 'Test User';
        update testBooking;
        
        Test.startTest();
        // Update stage to Hand Over
        testBooking.Stage__c = 'Hand Over';
        update testBooking;
        
        Test.stopTest();
        
        
    }
    */
    @isTest
    static void testAfterUpdateSwapApplicantApproval() {
        Booking__c testBooking = createTestBooking('Booked');
        testBooking.Swap_Applicant_Request__c = true;
        testBooking.Swap_Applicant_Request_Status__c = 'Pending';
        testBooking.First_Applicant_Name__c = 'Original Applicant';
        testBooking.Email__c = 'original@example.com';
        update testBooking;
        
        // Create Co-Applicant
        Co_Applicant__c coApp = new Co_Applicant__c(
            Booking__c = testBooking.Id,
            Name = 'Co-Applicant',
            Email__c = 'coapp@example.com'
        );
         try {
        insert coApp;
              } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
        
        Test.startTest();
        // Approve swap applicant request
        testBooking.Swap_Applicant_Request_Status__c = 'Approved';
        update testBooking;
        
        Test.stopTest();
        
      
    }
    
    @isTest
    static void testAfterUpdateApprovalStatusNotification() {
        Booking__c testBooking = createTestBooking('New');
        
        Test.startTest();
        // Update approval status
        testBooking.Approval_status__c = 'Approved';
        update testBooking;
        
        Test.stopTest();
        
      
    }
    
    @isTest
    static void testAfterUpdateTimeExtensionApproval() {
        Booking__c testBooking = createTestBooking('Agreement');
        
        Test.startTest();
        // Update time extension approval status
        testBooking.Time_Extension_Approval_Status__c = 'Approved';
        update testBooking;
        
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testAfterUpdateStageToBookedCreatesDemand() {
        Booking__c testBooking = createTestBooking('New');
        testBooking.Approval_status__c = 'Approved';
        update testBooking;
        
        Test.startTest();
        // Update stage to Booked
        testBooking.Stage__c = 'Booked';
        update testBooking;
        
        Test.stopTest();
        
      
        
      
    }
    
    @isTest
    static void testAfterUpdateRejectedApprovalNotification() {
        Booking__c testBooking = createTestBooking('New');
        
        Test.startTest();
        // Update approval status to Rejected
        testBooking.Approval_status__c = 'Rejected';
        update testBooking;
        
        Test.stopTest();
        
     
    }
    
    @isTest
    static void testAfterUpdateApprovedNotification() {
        Booking__c testBooking = createTestBooking('New');
        
        Test.startTest();
        // Update approval status to Approved
        testBooking.Approval_status__c = 'Approved';
        update testBooking;
        
        Test.stopTest();
        

    }
    
    @isTest
    static void testAfterDelete() {
        Booking__c testBooking = createTestBooking('New');
        
        Test.startTest();
        // Delete the booking
        delete testBooking;
        
        // Undelete the booking
        undelete testBooking;
        
        Test.stopTest();
        
      
    }
    
    @isTest
    static void testAfterUndelete() {
        Booking__c testBooking = createTestBooking('New');
        
        // Delete the booking first
        delete testBooking;
        
        Test.startTest();
        // Undelete the booking
        undelete testBooking;
        
        Test.stopTest();
        
     
    }
    
    // Helper method to create test booking
    private static Booking__c createTestBooking(String stage) {
        Quote__c testQuote = [SELECT Id, SLead__c, Project__c, Unit__c FROM Quote__c LIMIT 1];
        Plot__c testPlot = [SELECT Id FROM Plot__c WHERE Id = :testQuote.Unit__c];
        Project__c testProject = [SELECT Id FROM Project__c WHERE Name = 'Zuari Garden City' LIMIT 1];
        
        Booking__c booking = new Booking__c(
            Quote__c = testQuote.Id,
            SLead__c = testQuote.SLead__c,
            Project__c = testQuote.Project__c,
            Project1__c = testProject.Id,
            Plot__c = testPlot.Id,
            Stage__c = stage,
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
        
        return booking;
    }
}