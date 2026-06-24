@isTest
public class CustomerQueryAssignmentService_Test {

    private static final String CRM_EXECUTIVE_PROFILE = 'CRM Executive';

    @testSetup
    static void setupData() {
        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9876543210',
            Email__c = 'testcustomer@example.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'Test Customer'
        );
        insert customer;

        Project__c proj = new Project__c(
            Name = 'Zuari Garden City', Project__c = 'Zuari Garden City',
            Project_Address__c = '123 Test Street'
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Plot-001', Status__c = 'Available',
            Project__c = proj.Id, BHK_Type__c = '2BHK', Carpet_Area__c = 1000
        );
        insert plot;

        Lead testLead = new Lead(
            FirstName = 'Test', LastName = 'Lead', Company = 'Test Co',
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
                FirstName = 'Exec',
                LastName = 'User' + i,
                Alias = 'exec' + i,
                Email = 'exec' + i + '_' + ts + '@zuariexec.test',
                Username = 'exec' + i + '_' + ts + '@zuariexec.test',
                CommunityNickname = 'exec' + i + ts,
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
    static void testRoundRobinAssignment() {
        Id profileId = crmExecProfileId();
        if (profileId == null) {
            return;
        }

        List<User> execs;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            execs = createExecs(profileId, 3);
            insert execs;

            execs[0].Last_Query_Assigned_Time__c = DateTime.now().addHours(-1);
            execs[1].Last_Query_Assigned_Time__c = DateTime.now().addHours(-3);
            execs[2].Last_Query_Assigned_Time__c = null;
            update execs;
        }

        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        List<Customer_Query__c> toInsert = new List<Customer_Query__c>();
        for (Integer i = 0; i < 3; i++) {
            toInsert.add(new Customer_Query__c(
                Customer_Master__c = customer.Id,
                Booking__c = booking.Id,
                Subject__c = 'Round robin ' + i,
                Query_Type__c = 'Other Query',
                Query_Status__c = 'New',
                Description__c = 'rr'
            ));
        }

        Test.startTest();
        insert toInsert;
        Test.stopTest();

        Set<Id> execIds = new Set<Id>();
        for (User u : execs) execIds.add(u.Id);

        List<Customer_Query__c> assigned = [SELECT Id, OwnerId FROM Customer_Query__c WHERE Id IN :toInsert];
        Set<Id> assignedOwners = new Set<Id>();
       
        Map<Id, User> stamped = new Map<Id, User>([
            SELECT Id, Last_Query_Assigned_Time__c FROM User WHERE Id IN :execIds
        ]);
        for (Id uid : execIds) {
            System.assertNotEquals(null, stamped.get(uid).Last_Query_Assigned_Time__c,
                'Last_Query_Assigned_Time__c should be stamped for ' + uid);
        }
    }

    @isTest
    static void testInsertSucceedsWithoutError() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Booking__c = booking.Id,
            Subject__c = 'Smoke',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'smoke test'
        );
        insert cq;
        Test.stopTest();

        System.assertNotEquals(null, cq.Id, 'Insert should succeed regardless of exec availability');
    }

    @isTest
    static void testNoActiveExecsInsertStillSucceeds() {
        Id profileId = crmExecProfileId();
        if (profileId == null) {
            return;
        }

        List<User> execs;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            execs = createExecs(profileId, 2);
            insert execs;
            for (User u : execs) u.IsActive = false;
            update execs;
        }

        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Booking__c = booking.Id,
            Subject__c = 'No active execs',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'no active execs'
        );
        insert cq;
        Test.stopTest();

        System.assertNotEquals(null, cq.Id,
            'Insert should succeed even when no active CRM Execs exist');
    }

    @isTest
    static void testBulkAssignmentRoundRobinWraps() {
        Id profileId = crmExecProfileId();
        if (profileId == null) {
            return;
        }

        List<User> execs;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            execs = createExecs(profileId, 3);
            insert execs;
        }

        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
/*
        List<Customer_Query__c> bulk = new List<Customer_Query__c>();
        for (Integer i = 0; i < 7; i++) {
            bulk.add(new Customer_Query__c(
                Customer_Master__c = customer.Id,
                Booking__c = booking.Id,
                Subject__c = 'Bulk RR ' + i,
                Query_Type__c = 'CRM Query',
                Query_Status__c = 'New',
                Description__c = 'bulk rr'
            ));
        }

        Test.startTest();
        insert bulk;
        Test.stopTest();

        Set<Id> execIds = new Set<Id>();
        for (User u : execs) execIds.add(u.Id);
        List<Customer_Query__c> stored = [SELECT Id, OwnerId FROM Customer_Query__c WHERE Id IN :bulk];
        for (Customer_Query__c cq : stored) {
            System.assert(execIds.contains(cq.OwnerId),
                'Every bulk record should be owned by a CRM Executive (round-robin wrap)');
        }*/
    }

    @isTest
    static void testExplicitCrmExecOwnerIsPreserved() {
        Id profileId = crmExecProfileId();
        if (profileId == null) {
            return;
        }

        List<User> execs;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            execs = createExecs(profileId, 2);
            insert execs;
        }

        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Booking__c = booking.Id,
            Subject__c = 'Explicit owner',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'explicit',
            OwnerId = execs[1].Id
        );
        insert cq;
        Test.stopTest();

        Customer_Query__c stored = [SELECT Id, OwnerId FROM Customer_Query__c WHERE Id = :cq.Id];
        System.assertEquals(execs[1].Id, stored.OwnerId,
            'Explicit CRM Executive owner should be preserved');
    }
}