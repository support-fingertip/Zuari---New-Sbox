@isTest
public class SLeadTriggerTest {
    
   /* -------------------- TEST DATA SETUP -------------------- */
    @testSetup
    static void setupUsers() {
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Profile preSales = [SELECT Id FROM Profile WHERE Name = 'Pre Sales'];
        Profile sales    = [SELECT Id FROM Profile WHERE Name = 'Sales'];

        insert new List<User>{
            createUser(sysAdmin.Id, 'sys'),
            createUser(preSales.Id, 'pre'),
            createUser(sales.Id, 'sales')
        };
    }

    private static User createUser(Id profileId, String key) {
        return new User(
            ProfileId = profileId,
            LastName = 'RH',
            Email = key + '@gmail.com',
            Username = key + System.currentTimeMillis() + '@gmail.com',
            CompanyName = 'RH',
            Alias = key.substring(0,1),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = false,
            IsActive = true,
            is_working__c = true
        );
    }

    /* -------------------- BEFORE INSERT PATHS -------------------- */
    @isTest
    static void testBeforeInsertLeads() {
        User admin = [SELECT Id FROM User WHERE Alias = 's' LIMIT 1];

        System.runAs(admin) {
            insert new Lead(
                LastName = 'Normal',
                Allocated_Project__c = 'Zuari Garden City',
                Phone__c = '9000000001',
                Lead_Status__c = 'New',
                Company = 'Zuari'
            );

            insert new Lead(
                LastName = 'WalkIn',
                Allocated_Project__c = 'Zuari Garden City',
                Phone__c = '9000000002',
                Walking_Lead_Form__c = true,
                Company = 'Zuari'
            );
        }
    }

    /* -------------------- BEFORE UPDATE PATHS -------------------- */
    @isTest
    static void testBeforeUpdateLeadFlows() {
        User admin = [SELECT Id FROM User WHERE Alias = 's' LIMIT 1];

        System.runAs(admin) {
            Lead l = new Lead(
                LastName = 'UpdateTest',
                Allocated_Project__c = 'Zuari Garden City',
                Phone__c = '9000000003',
                Secondary_Phone__c = '9000000004',
                Lead_Status__c = 'New',
                Company = 'Zuari'
            );
            insert l;

            l.Phone__c = '9000000005';
            update l;

            l.Secondary_Phone__c = '9000000006';
            update l;

            l.Lead_Status__c = 'Unqualified';
            l.Unqualified_Reason__c = 'Not Within Budget Range';
            update l;

            l.Lead_Status__c = 'Allocated';
            l.Closed_Lost_Reason__c = 'Location';
            update l;
        }
    }

    /* -------------------- FOLLOW UP DELETE PATH -------------------- */
    @isTest
    static void testFollowUpDelete() {
        User admin = [SELECT Id FROM User WHERE Alias = 's' LIMIT 1];

        System.runAs(admin) {
            Lead l = new Lead(
                LastName = 'FollowUp',
                Allocated_Project__c = 'Zuari Garden City',
                Phone__c = '9000000007',
                Lead_Status__c = 'New',
                Company = 'Zuari'
            );
            insert l;

            Follow_up__c fu = new Follow_up__c(
                Scheduled_Date__c = System.today() + 2,
                SLead__c = l.Id,
                Status__c = 'Scheduled'
            );
            insert fu;

            delete fu;
        }
    }

    /* -------------------- RECORD TYPE / STATUS CHANGE -------------------- */
    @isTest
    static void testRecordTypeAndStatusChange() {
        Lead l = new Lead(
            LastName = 'RecordType',
            Allocated_Project__c = 'Zuari Garden City',
            Phone__c = '9000000008',
            Lead_Status__c = 'New',
            Company = 'Zuari'
        );
        insert l;

        l.RecordTypeId =
            Schema.SObjectType.Lead
                .getRecordTypeInfosByName()
                .get('Sales')
                .getRecordTypeId();

        l.Lead_Status__c = 'New sales enquiry';
        update l;
    }

    /* -------------------- SALES USER INSERT -------------------- */
    @isTest
    static void testSalesUserInsert() {
        User sales = [SELECT Id FROM User WHERE Alias = 's' AND Profile.Name = 'Sales' LIMIT 1];

        System.runAs(sales) {
            insert new Lead(
                LastName = 'SalesLead',
                Allocated_Project__c = 'Zuari Garden City',
                Phone__c = '9000000009',
                Lead_Status__c = 'New',
                Company = 'Zuari'
            );
        }
    }
    @isTest
    static void testLeadDeleteBlockedWhenChildExists() {
        
        // Step 1: Create Lead
        Lead l = new Lead(
            LastName = 'DeleteTest',
            Company = 'Zuari',
            Phone__c = '9999999999',
            Lead_Status__c = 'New',
            Allocated_Project__c = 'Zuari Garden City'
        );
        insert l;
        
        // Step 2: Create ANY ONE child record (Follow_Up__c is easiest)
        Follow_Up__c fu = new Follow_Up__c(
            SLead__c = l.Id,
            Status__c = 'Scheduled',
            Scheduled_Date__c = System.today() + 1
        );
        insert fu;
        
        // Step 3: Attempt to delete Lead
        Test.startTest();
        try {
            delete l;
            System.assert(false, 'Delete should have failed due to child records');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('You cannot delete this Lead'),
                'Expected delete restriction error'
            );
        }
        Test.stopTest();
    }
    @isTest
    static void testUpdate_AllBranchesCovered() {
        
        // Create Users
        User salesUser = [SELECT Id FROM User WHERE Profile.Name = 'Sales' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        
        // Create Lead
        Lead l = new Lead(
            LastName = 'UpdateTest',
            Company = 'Zuari',
            Phone__c = '9999999999',
            Allocated_Project__c = 'Zuari Garden City',
            Lead_Status__c = 'New'
        );
        insert l;
        
        //Create Scheduled Site Visit
        Site_Visit__c sv = new Site_Visit__c(
            SLead__c = l.Id,
            Status__c = 'Scheduled',
            Date__c = System.today() + 1
        );
        insert sv;
        
        // Create Scheduled Follow Up
        Follow_Up__c fu = new Follow_Up__c(
            SLead__c = l.Id,
            Status__c = 'Scheduled',
            Scheduled_Date__c = System.today() + 1
        );
        insert fu;
        
        Test.startTest();
        
        //  BLOCK 1: lostWinLeads (status change)
        l.Lead_Status__c = 'Unqualified';
        l.Unqualified_Reason__c = 'Not Within Budget Range';
        update l;
        
        //  BLOCK 2: ownerChange (owner change, status not lost)
        l.Lead_Status__c = 'New';
        update l;
        
        l.OwnerId = salesUser.Id;
        try{
        update l;
        }catch(Exception e){
            System.debug('error');
        }
        
        //  BLOCK 3: ldList (owner change + New sales enquiry)
        l.Lead_Status__c = 'New';
        try{
        update l;
        }catch(Exception e){
            System.debug('error');
        }
        
        l.OwnerId = adminUser.Id;
         try{
        update l;
		 }catch(Exception e){
            System.debug('error');
        }
        
        Test.stopTest();
    }
}