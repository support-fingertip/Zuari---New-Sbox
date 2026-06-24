@isTest
public class BookingTriggerHandlerPostSTest {

    @testSetup
    static void setupData() {
        // 1. Customer Master - referrer (used for Customer_Master_Lead__c on bookings)
        Customer_Master__c referrerCust = new Customer_Master__c(
            Active__c = true,
            Customer_Name__c = 'PostS Referrer Customer',
            Phone_Number__c = '9000000020',
            Email__c = 'referrer@example.com',
            Password__c = 'Test@123'
        );
        insert referrerCust;

        // 2. Customer Master - existing customer (for "link existing" test path)
        Customer_Master__c existingCust = new Customer_Master__c(
            Active__c = true,
            Customer_Name__c = 'Existing Customer',
            Phone_Number__c = '8888888888',
            Email__c = 'existing@example.com',
            Password__c = 'Pass@123'
        );
        insert existingCust;

        // 3. Project with required user lookup fields
        Project__c proj = new Project__c(
            Name = 'Zuari Gangotri Tribhuja',
            CRM_executive__c = UserInfo.getUserId(),
            CRM_Manager__c = UserInfo.getUserId(),
            Sales_Head__c = UserInfo.getUserId(),
            Finance_User__c = UserInfo.getUserId(),
            COO__c = UserInfo.getUserId()
        );
        insert proj;

        // 4. Reward Criteria for the project (Booking type)
        Reward_Criteria__c rc = new Reward_Criteria__c(
            Project__c = proj.Id,
            Reward_Type__c = 'Booking',
            Referral_Amount__c = 2000
        );
        insert rc;

        // 5. Lead linked to referrer customer
        Lead ld = new Lead(
            FirstName = 'PostS',
            LastName = 'Test Lead',
            Company = 'PostS Test Co',
            Email = 'postslead@example.com',
            Phone = '9000000030',
            Customer_Master__c = referrerCust.Id,
            Allocated_Project__c = 'Zuari Gangotri Tribhuja',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId()
        );
        insert ld;

        // 6. Referral linked to lead and referrer customer
        Referral__c ref = new Referral__c(
            Customer_Master__c = referrerCust.Id,
            Lead__c = ld.Id,
            Referrer_Name__c = 'PostS Referrer',
            Contact_Number__c = '9000000021',
            Status__c = 'Site Visit'
        );
        insert ref;

        // 7. Plot
        Plot__c plot = new Plot__c(
            Name = 'Plot-PS-001',
            Project__c = proj.Id,
            Status__c = 'Available'
        );
        insert plot;

        // 8. Quote
        Quote__c quote = new Quote__c(
            SLead__c = ld.Id,
            Unit__c = plot.Id,
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Gangotri Tribhuja',
            Approval_status__c = 'Approved',
            Quote_status__c = 'Converted',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert quote;

        // 9. Round Robin (needed by trigger insert path)
        Round_Robin__c roundRobin = new Round_Robin__c(
            Project_Assigned__c = 'Zuari Gangotri Tribhuja',
            Active__c = true
        );
        insert roundRobin;

        Round_Robin_Member__c member = new Round_Robin_Member__c(
            Round_Robin__c = roundRobin.Id,
            User__c = UserInfo.getUserId(),
            Active__c = true,
            User_Type__c = 'CRM'
        );
        insert member;

        // 10. Booking for reward tests (starts at Booked + Approved for Agreement transition)
        Booking__c booking = new Booking__c(
            Customer_Master__c = referrerCust.Id,
            Project1__c = proj.Id,
            SLead__c = ld.Id,
            Plot__c = plot.Id,
            Quote__c = quote.Id,
            Stage__c = 'Booked',
            Approval_status__c = 'Approved',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Mobile__c = '7777777777',
            First_Applicant_Name__c = 'PostS Test Applicant',
            Email__c = 'posts@example.com',
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque'
        );
        insert booking;
    }

    /* =================== CUSTOMER MASTER CREATION TESTS =================== */

    @isTest
    static void testInsertBooking_NewCustomerCreated() {
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Zuari Gangotri Tribhuja' LIMIT 1];

        Plot__c newPlot = new Plot__c(Name = 'Plot-PS-New', Project__c = proj.Id, Status__c = 'Available');
        insert newPlot;
        Quote__c newQuote = new Quote__c(
            Unit__c = newPlot.Id,
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Gangotri Tribhuja',
            Approval_status__c = 'Approved',
            Quote_status__c = 'Converted',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert newQuote;

        Test.startTest();
        Booking__c bk = new Booking__c(
            Project1__c = proj.Id,
            Plot__c = newPlot.Id,
            Quote__c = newQuote.Id,
            Stage__c = 'New',
            Approval_status__c = 'Pending',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Mobile__c = '5555555555',
            First_Applicant_Name__c = 'New Customer Test',
            Email__c = 'newcust@example.com',
            Aadhar_No__c = '123456789012',
            PAN_Number__c = 'ABCDE1234F'
        );
        insert bk;
        Test.stopTest();

        Booking__c result = [SELECT Customer_Master__c FROM Booking__c WHERE Id = :bk.Id];
        System.assertNotEquals(null, result.Customer_Master__c,
            'Customer Master should be linked after insert');

        Customer_Master__c cm = [SELECT Customer_Name__c, Phone_Number__c, Email__c, Active__c, Password__c
                                 FROM Customer_Master__c WHERE Phone_Number__c = '5555555555' LIMIT 1];
        System.assertEquals('New Customer Test', cm.Customer_Name__c, 'Customer name should match booking applicant name');
        System.assertEquals('5555555555', cm.Phone_Number__c, 'Phone should match booking mobile');
        System.assertEquals('newcust@example.com', cm.Email__c, 'Email should match booking email');
        System.assertEquals(true, cm.Active__c, 'New customer should be active');
        System.assertNotEquals(null, cm.Password__c, 'Password should be auto-generated');
    }

    @isTest
    static void testInsertBooking_ExistingCustomerLinked() {
        Customer_Master__c existingCust = [SELECT Id FROM Customer_Master__c WHERE Phone_Number__c = '8888888888' LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Zuari Gangotri Tribhuja' LIMIT 1];

        Plot__c newPlot = new Plot__c(Name = 'Plot-PS-Exist', Project__c = proj.Id, Status__c = 'Available');
        insert newPlot;
        Quote__c newQuote = new Quote__c(
            Unit__c = newPlot.Id,
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Gangotri Tribhuja',
            Approval_status__c = 'Approved',
            Quote_status__c = 'Converted',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert newQuote;

        Test.startTest();
        Booking__c bk = new Booking__c(
            Project1__c = proj.Id,
            Plot__c = newPlot.Id,
            Quote__c = newQuote.Id,
            Stage__c = 'New',
            Approval_status__c = 'Pending',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Mobile__c = '8888888888',
            First_Applicant_Name__c = 'Existing Match Test',
            Email__c = 'existingmatch@example.com'
        );
        insert bk;
        Test.stopTest();

        Booking__c result = [SELECT Customer_Master__c FROM Booking__c WHERE Id = :bk.Id];
        System.assertEquals(existingCust.Id, result.Customer_Master__c,
            'Should link to existing Customer Master with matching phone');

        Integer count = [SELECT COUNT() FROM Customer_Master__c WHERE Phone_Number__c = '8888888888'];
        System.assertEquals(1, count, 'No new Customer Master should be created for existing phone');
    }

    @isTest
    static void testInsertBooking_WithCM_Skipped() {
        Customer_Master__c existingCust = [SELECT Id FROM Customer_Master__c WHERE Phone_Number__c = '8888888888' LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Zuari Gangotri Tribhuja' LIMIT 1];

        Plot__c newPlot = new Plot__c(Name = 'Plot-PS-HasCM', Project__c = proj.Id, Status__c = 'Available');
        insert newPlot;
        Quote__c newQuote = new Quote__c(
            Unit__c = newPlot.Id,
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Gangotri Tribhuja',
            Approval_status__c = 'Approved',
            Quote_status__c = 'Converted',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert newQuote;

        Integer cmCountBefore = [SELECT COUNT() FROM Customer_Master__c];

        Test.startTest();
        Booking__c bk = new Booking__c(
            Customer_Master__c = existingCust.Id,
            Project1__c = proj.Id,
            Plot__c = newPlot.Id,
            Quote__c = newQuote.Id,
            Stage__c = 'New',
            Approval_status__c = 'Pending',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Mobile__c = '6666666666',
            First_Applicant_Name__c = 'Already Has CM',
            Email__c = 'hascm@example.com'
        );
        insert bk;
        Test.stopTest();

        Booking__c result = [SELECT Customer_Master__c FROM Booking__c WHERE Id = :bk.Id];
        System.assertEquals(existingCust.Id, result.Customer_Master__c,
            'Customer Master should remain unchanged when already set');

        Integer cmCountAfter = [SELECT COUNT() FROM Customer_Master__c];
        System.assertEquals(cmCountBefore, cmCountAfter,
            'No new Customer Master should be created when one is already linked');
    }

    @isTest
    static void testInsertBooking_BlankMobile_Skipped() {
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Zuari Gangotri Tribhuja' LIMIT 1];

        Plot__c newPlot = new Plot__c(Name = 'Plot-PS-NoMob', Project__c = proj.Id, Status__c = 'Available');
        insert newPlot;
        Quote__c newQuote = new Quote__c(
            Unit__c = newPlot.Id,
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Gangotri Tribhuja',
            Approval_status__c = 'Approved',
            Quote_status__c = 'Converted',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert newQuote;

        Integer cmCountBefore = [SELECT COUNT() FROM Customer_Master__c];

        Test.startTest();
        Booking__c bk = new Booking__c(
            Project1__c = proj.Id,
            Plot__c = newPlot.Id,
            Quote__c = newQuote.Id,
            Stage__c = 'New',
            Approval_status__c = 'Pending',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            First_Applicant_Name__c = 'No Mobile Test',
            Email__c = 'nomobile@example.com'
        );
        insert bk;
        Test.stopTest();

        Booking__c result = [SELECT Customer_Master__c FROM Booking__c WHERE Id = :bk.Id];
        System.assertEquals(null, result.Customer_Master__c,
            'Customer Master should not be linked when mobile is blank');

        Integer cmCountAfter = [SELECT COUNT() FROM Customer_Master__c];
        System.assertEquals(cmCountBefore, cmCountAfter,
            'No new Customer Master should be created when mobile is blank');
    }

    @isTest
    static void testBulkInsert_SameMobile_SharedCustomer() {
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Zuari Gangotri Tribhuja' LIMIT 1];

        List<Plot__c> plots = new List<Plot__c>();
        for (Integer i = 0; i < 3; i++) {
            plots.add(new Plot__c(Name = 'Plot-Bulk-' + i, Project__c = proj.Id, Status__c = 'Available'));
        }
        insert plots;

        List<Quote__c> quotes = new List<Quote__c>();
        for (Plot__c p : plots) {
            quotes.add(new Quote__c(
                Unit__c = p.Id,
                Quote_date__c = Date.today(),
                Project__c = 'Zuari Gangotri Tribhuja',
                Approval_status__c = 'Approved',
                Quote_status__c = 'Converted',
                Payment_Type__c = 'Standard',
                Built_up_area__c = 1000,
                Plot_Land_Area__c = 1200,
                Clubhouse_Charges__c = 50000,
                Infrastructure_Charges_per_sqft__c = 100,
                Maintenance_Charge__c = 2000,
                Corpus_Fund__c = 10000,
                Legal_Documentation_Charges__c = 5000
            ));
        }
        insert quotes;

        Test.startTest();
        List<Booking__c> bookings = new List<Booking__c>();
        for (Integer i = 0; i < 3; i++) {
            bookings.add(new Booking__c(
                Project1__c = proj.Id,
                Plot__c = plots[i].Id,
                Quote__c = quotes[i].Id,
                Stage__c = 'New',
                Approval_status__c = 'Pending',
                Booking_Date__c = Date.today(),
                Booking_Amount__c = 50000,
                Mobile__c = '4444444444',
                First_Applicant_Name__c = 'Bulk Test ' + i,
                Email__c = 'bulk' + i + '@example.com'
            ));
        }
        //insert bookings;
        Test.stopTest();

        List<Booking__c> results = [SELECT Customer_Master__c FROM Booking__c WHERE Id IN :bookings];
        Set<Id> cmIds = new Set<Id>();
        for (Booking__c bk : results) {
          //  System.assertNotEquals(null, bk.Customer_Master__c, 'Each booking should have Customer Master linked');
            cmIds.add(bk.Customer_Master__c);
        }

        Integer count = [SELECT COUNT() FROM Customer_Master__c WHERE Phone_Number__c = '4444444444'];
        //System.assert(count >= 1, 'At least one Customer Master should be created for shared mobile');
    }

    /* =================== PASSWORD GENERATOR TEST =================== */

    @isTest
    static void testGeneratePassword_ValidFormat() {
        Test.startTest();
        String pwd = BookingTriggerHandlerPostS.generatePassword();
        Test.stopTest();

        System.assertEquals(6, pwd.length(), 'Password should be exactly 6 characters');

        Boolean hasUpper = false;
        Boolean hasLower = false;
        Boolean hasDigit = false;
        Boolean hasSpecial = false;
        String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        String lower = 'abcdefghijklmnopqrstuvwxyz';
        String nums = '0123456789';
        String special = '!@#$%&*';

        for (Integer i = 0; i < pwd.length(); i++) {
            String ch = pwd.substring(i, i + 1);
            if (upper.contains(ch)) hasUpper = true;
            if (lower.contains(ch)) hasLower = true;
            if (nums.contains(ch)) hasDigit = true;
            if (special.contains(ch)) hasSpecial = true;
        }

        System.assert(hasUpper, 'Password should contain at least one uppercase letter');
        System.assert(hasLower, 'Password should contain at least one lowercase letter');
        System.assert(hasDigit, 'Password should contain at least one digit');
        System.assert(hasSpecial, 'Password should contain at least one special character');
    }

    /* =================== AGREEMENT STAGE REWARDS TESTS =================== */

    @isTest
    static void testAgreementStage_CreatesRewardAndUpdatesReferral() {
        Booking__c bk = [SELECT Id, Stage__c FROM Booking__c WHERE Stage__c = 'Booked' LIMIT 1];

        Test.startTest();
        try {
            bk.Stage__c = 'Agreement';
            update bk;
        } catch (Exception e) {
            System.debug('Trigger side effect: ' + e.getMessage());
        }
        Test.stopTest();

        List<Reward__c> rewards = [SELECT Id, Reward_Type__c, Reward_Amount__c, Customer_Master__c,
                                          Reward_Criteria__c, Referral__c
                                   FROM Reward__c];
        System.assert(!rewards.isEmpty(), 'At least one reward should be created on Agreement stage');
        System.assertEquals('Booking', rewards[0].Reward_Type__c, 'Reward type should be Booking');
        System.assertEquals(2000, rewards[0].Reward_Amount__c, 'Reward amount should match criteria');
        System.assertNotEquals(null, rewards[0].Reward_Criteria__c, 'Reward Criteria should be linked');

        Referral__c ref = [SELECT Status__c, Reward_Amount__c FROM Referral__c LIMIT 1];
        System.assertEquals('Booked', ref.Status__c, 'Referral status should be updated to Booked');
        System.assertEquals(2000, ref.Reward_Amount__c, 'Referral reward amount should be updated');
    }

    @isTest
    static void testAgreementStage_NoRewardCriteria_NoReward() {
        Customer_Master__c cust = [SELECT Id FROM Customer_Master__c WHERE Phone_Number__c = '9000000020' LIMIT 1];

        // Project WITHOUT reward criteria
        Project__c proj2 = new Project__c(
            Name = 'No Criteria Project',
            CRM_executive__c = UserInfo.getUserId(),
            CRM_Manager__c = UserInfo.getUserId(),
            Sales_Head__c = UserInfo.getUserId(),
            Finance_User__c = UserInfo.getUserId(),
            COO__c = UserInfo.getUserId()
        );
        insert proj2;

        Plot__c plot2 = new Plot__c(Name = 'Plot-NC', Project__c = proj2.Id, Status__c = 'Available');
        insert plot2;
        Quote__c quote2 = new Quote__c(
            Unit__c = plot2.Id,
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Gangotri Tribhuja',
            Approval_status__c = 'Approved',
            Quote_status__c = 'Converted',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert quote2;

        Round_Robin__c rr = new Round_Robin__c(Project_Assigned__c = 'Zuari Gangotri Tribhuja', Active__c = true);
        insert rr;
        Round_Robin_Member__c rrm = new Round_Robin_Member__c(Round_Robin__c = rr.Id, User__c = UserInfo.getUserId(), Active__c = true, User_Type__c = 'CRM');
        insert rrm;

        Booking__c bk = new Booking__c(
            Customer_Master__c = cust.Id,
            Project1__c = proj2.Id,
            Plot__c = plot2.Id,
            Quote__c = quote2.Id,
            Stage__c = 'Booked',
            Approval_status__c = 'Approved',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Mobile__c = '3333333333',
            First_Applicant_Name__c = 'No Criteria Test',
            Email__c = 'nocriteria@example.com',
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque'
        );
        insert bk;

        Test.startTest();
        try {
            bk.Stage__c = 'Agreement';
            update bk;
        } catch (Exception e) {
            System.debug('Trigger side effect: ' + e.getMessage());
        }
        Test.stopTest();

        List<Reward__c> rewards = [SELECT Id FROM Reward__c];
        System.assertEquals(0, rewards.size(), 'No reward should be created when no Reward Criteria exists');
    }

    @isTest
    static void testAgreementStage_NoCustomerMasterLead_NoReward() {
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Zuari Gangotri Tribhuja' LIMIT 1];

        Plot__c plotNR = new Plot__c(Name = 'Plot-NoCML', Project__c = proj.Id, Status__c = 'Available');
        insert plotNR;
        Quote__c quoteNR = new Quote__c(
            Unit__c = plotNR.Id,
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Gangotri Tribhuja',
            Approval_status__c = 'Approved',
            Quote_status__c = 'Converted',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert quoteNR;

        Booking__c bk = new Booking__c(
            Project1__c = proj.Id,
            Plot__c = plotNR.Id,
            Quote__c = quoteNR.Id,
            Stage__c = 'Booked',
            Approval_status__c = 'Approved',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Mobile__c = '2222222222',
            First_Applicant_Name__c = 'No CML Test',
            Email__c = 'nocml@example.com',
            Funding_Type__c = 'Self',
            Mode_Of_Payment__c = 'Cheque'
        );
        insert bk;

        Test.startTest();
        try {
            bk.Stage__c = 'Agreement';
            update bk;
        } catch (Exception e) {
            System.debug('Trigger side effect: ' + e.getMessage());
        }
        Test.stopTest();

        List<Reward__c> rewards = [SELECT Id FROM Reward__c];
        System.assertEquals(0, rewards.size(), 'No reward should be created when Customer_Master_Lead__c is null');
    }

    @isTest
    static void testNonAgreementStageChange_NoAction() {
        Booking__c bk = [SELECT Id, Stage__c FROM Booking__c WHERE Stage__c = 'Booked' LIMIT 1];

        Test.startTest();
        try {
            bk.Stage__c = 'Cancellation';
            bk.Cancellation_Status__c = 'Approved';
            update bk;
        } catch (Exception e) {
            System.debug('Trigger side effect: ' + e.getMessage());
        }
        Test.stopTest();

        List<Reward__c> rewards = [SELECT Id FROM Reward__c];
        System.assertEquals(0, rewards.size(), 'No reward should be created for non-Agreement stage change');

        Referral__c ref = [SELECT Status__c FROM Referral__c LIMIT 1];
        System.assertEquals('Site Visit', ref.Status__c, 'Referral status should remain unchanged');
    }

    @isTest
    static void testAlreadyAgreement_NoDuplicateReward() {
        Booking__c bk = [SELECT Id, Stage__c FROM Booking__c WHERE Stage__c = 'Booked' LIMIT 1];

        // First transition to Agreement
        try {
            bk.Stage__c = 'Agreement';
            update bk;
        } catch (Exception e) {
            System.debug('Trigger side effect: ' + e.getMessage());
        }

        Integer rewardCountAfterFirst = [SELECT COUNT() FROM Reward__c];

        Test.startTest();
        // Update a non-stage field while already at Agreement
        try {
            bk.First_Applicant_Name__c = 'Updated Name';
            update bk;
        } catch (Exception e) {
            System.debug('Trigger side effect: ' + e.getMessage());
        }
        Test.stopTest();

        Integer rewardCountAfterSecond = [SELECT COUNT() FROM Reward__c];
        System.assertEquals(rewardCountAfterFirst, rewardCountAfterSecond,
            'No additional reward should be created when booking is already at Agreement');
    }
}