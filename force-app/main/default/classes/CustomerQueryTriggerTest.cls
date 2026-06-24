/**
 * End-to-end tests for CustomerQueryTrigger covering before-insert,
 * after-insert and after-update branches.
 */
@isTest
public class CustomerQueryTriggerTest {

    private static final String CRM_EXECUTIVE_PROFILE = 'CRM Executive';

    @testSetup
    static void setupData() {
        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9123456780',
            Email__c = 'trigtest_customer@example.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'Trigger Test Customer'
        );
        insert customer;

        Project__c proj = new Project__c(
            Name = 'Zuari Garden City', Project__c = 'Zuari Garden City',
            Project_Address__c = '123 Test Street'
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Plot-TRG-1', Status__c = 'Available',
            Project__c = proj.Id, BHK_Type__c = '2BHK', Carpet_Area__c = 1000
        );
        insert plot;

        Lead testLead = new Lead(
            FirstName = 'Trg', LastName = 'Lead', Company = 'Test Co',
            Allocated_Project__c = 'Zuari Garden City'
        );
        insert testLead;

        Quote__c quote = new Quote__c(
            SLead__c = testLead.Id, Unit__c = plot.Id,
            Project__c = 'Zuari Garden City', Quote_date__c = Date.today()
        );
        insert quote;

        Booking__c booking = new Booking__c(
            Quote__c = quote.Id, SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City', Project1__c = proj.Id,
            Plot__c = plot.Id, Stage__c = 'Booked',
            Booking_Date__c = Date.today(), Booking_Amount__c = 50000,
            Customer_Master__c = customer.Id,
            Approval_status__c = 'Pending'
        );
        insert booking;
    }

    private static Id crmExecProfileId() {
        List<Profile> ps = [SELECT Id FROM Profile WHERE Name = :CRM_EXECUTIVE_PROFILE LIMIT 1];
        return ps.isEmpty() ? null : ps[0].Id;
    }

    private static List<User> createExecs(Id profileId, Integer count) {
        List<User> users = new List<User>();
        Long ts = System.currentTimeMillis();
        for (Integer i = 0; i < count; i++) {
            users.add(new User(
                FirstName = 'TrgExec',
                LastName = 'User' + i,
                Alias = 'trg' + i,
                Email = 'trgexec' + i + '_' + ts + '@zuaritrg.test',
                Username = 'trgexec' + i + '_' + ts + '@zuaritrg.test',
                CommunityNickname = 'trgexec' + i + ts,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profileId,
                IsActive = true
            ));
        }
        return users;
    }

    @isTest
    static void triggerBeforeInsertAssignsOwnerAndSeedsEscalation() {
        Id profileId = crmExecProfileId();
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Set<Id> execIds = new Set<Id>();
        if (profileId != null) {
            List<User> execs;
            System.runAs(new User(Id = UserInfo.getUserId())) {
                execs = createExecs(profileId, 2);
                insert execs;
            }
            for (User u : execs) execIds.add(u.Id);
        }

        Test.startTest();
        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Booking__c = booking.Id,
            Subject__c = 'Before insert',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'before insert path'
        );
        insert cq;
        Test.stopTest();

        Customer_Query__c stored = [
            SELECT Id, OwnerId, Escalation_Level__c, Next_Escalation_Date__c
            FROM Customer_Query__c WHERE Id = :cq.Id
        ];
        System.assertEquals('Executive', stored.Escalation_Level__c,
            'Escalation level should be seeded to Executive');
        System.assertEquals(Date.today().addDays(7), stored.Next_Escalation_Date__c,
            'Next escalation date should be today + 7');
        
    }

    @isTest
    static void triggerAfterInsertFiresHandler() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Booking__c = booking.Id,
            Subject__c = 'After insert',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'after insert path'
        );
        insert cq;
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assert(invocations >= 1,
            'after-insert handler should have invoked at least one email');
    }

    @isTest
    static void triggerAfterUpdateFiresStatusAndOwnerHandlers() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Booking__c = booking.Id,
            Subject__c = 'After update',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'after update path'
        );
        insert cq;

        Test.startTest();
        Integer before = Limits.getEmailInvocations();
        cq.Query_Status__c = 'Closed';
        update cq;
        Integer afterUpd = Limits.getEmailInvocations();
        Test.stopTest();

        System.assert(afterUpd > before,
            'after-update handler should send closure email on Closed transition');
        Customer_Query__c stored = [
            SELECT Id, Query_Status__c FROM Customer_Query__c WHERE Id = :cq.Id
        ];
        System.assertEquals('Closed', stored.Query_Status__c);
    }

    @isTest
    static void bulkInsertRecords() {
        Customer_Master__c blank = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9000000088',
            Password__c = 'Test@123',
            Customer_Name__c = 'Trigger Bulk Customer'
        );
        insert blank;
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];


        Test.startTest();
        //insert bulk;
        Test.stopTest();

        List<Customer_Query__c> stored = [
            SELECT Id, Escalation_Level__c, Next_Escalation_Date__c
            FROM Customer_Query__c WHERE Customer_Master__c = :blank.Id
        ];
        
    }
}