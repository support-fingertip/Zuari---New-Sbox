@IsTest
public class RelatedSourceBulkOwnerAuraCtrlTest {

    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User u1 = new User(
            FirstName        = 'Test',
            LastName         = 'User1',
            Email            = 'testuser1@example.com',
            Username         = 'testuser1@example.com.' + System.currentTimeMillis(),
            Alias            = 'tuser1',
            TimeZoneSidKey   = 'GMT',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId        = p.Id,
            LanguageLocaleKey= 'en_US',
            IsActive         = true
        );
        User u2 = new User(
            FirstName        = 'Test',
            LastName         = 'User2',
            Email            = 'testuser2@example.com',
            Username         = 'testuser2@example.com.' + System.currentTimeMillis(),
            Alias            = 'tuser2',
            TimeZoneSidKey   = 'GMT',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId        = p.Id,
            LanguageLocaleKey= 'en_US',
            IsActive         = true
        );
        insert new List<User>{ u1, u2 };

        List<Related_Source__c> sources = new List<Related_Source__c>();
        for (Integer i = 0; i < 5; i++) {
            sources.add(new Related_Source__c(
                OwnerId              = u1.Id,
                Allocated_Project__c = 'Zuari Garden City'
            ));
        }
        insert sources;
    }

    @IsTest
    static void testFetchRelatedSourcesNoFilters() {
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(null, null, null, null, null);
        Test.stopTest();
    }

    @IsTest
    static void testFetchRelatedSourcesWithUserId() {
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(null, null, u.Id, null, null);
        Test.stopTest();
    }

    @IsTest
    static void testFetchRelatedSourcesWithAllocatedProject() {
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(null, null, null, 'Zuari Garden City', null);
        Test.stopTest();
    }

    @IsTest
    static void testFetchRelatedSourcesWithDateRange() {
        Date fromDate = Date.today().addDays(-1);
        Date toDate   = Date.today().addDays(1);
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(fromDate, toDate, null, null, null);
        Test.stopTest();
    }

    @IsTest
    static void testFetchRelatedSourcesWithSourceType() {
        Test.startTest();
        // Pass a sourceType value — adjust the string to match your picklist if needed
        RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(null, null, null, null, 'Online');
        Test.stopTest();
    }

    @IsTest
    static void testFetchRelatedSourcesAllFilters() {
        User u       = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Date fromDate = Date.today().addDays(-1);
        Date toDate   = Date.today().addDays(1);
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.fetchRelatedSources(fromDate, toDate, u.Id, 'Zuari Garden City', null);
        Test.stopTest();
    }

    @IsTest
    static void testGetUsers() {
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.getUsers();
        Test.stopTest();
    }

    @IsTest
    static void testGetAllocatedProjectPicklistValues() {
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.getAllocatedProjectPicklistValues();
        Test.stopTest();
    }

    @IsTest
    static void testGetSourceTypePicklistValues() {
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.getSourceTypePicklistValues();
        Test.stopTest();
    }

    @IsTest
    static void testBulkUpdateOwner() {
        List<Related_Source__c> sources = [SELECT Id, OwnerId FROM Related_Source__c LIMIT 2];
        User newOwner = [SELECT Id FROM User WHERE IsActive = true AND Id != :sources[0].OwnerId LIMIT 1];

        Test.startTest();
        System.runAs(newOwner) {
            RelatedSourceBulkOwnerAuraCtrl.bulkUpdateOwner(
                new List<Id>{ sources[0].Id, sources[1].Id },
                newOwner.Id
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testBulkUpdateOwnerNoRecordIds() {
        Test.startTest();
        try {
            RelatedSourceBulkOwnerAuraCtrl.bulkUpdateOwner(new List<Id>(), UserInfo.getUserId());
        } catch (AuraHandledException e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testBulkUpdateOwnerNoToUserId() {
        List<Related_Source__c> sources = [SELECT Id FROM Related_Source__c LIMIT 1];
        Test.startTest();
        try {
            RelatedSourceBulkOwnerAuraCtrl.bulkUpdateOwner(new List<Id>{ sources[0].Id }, null);
        } catch (AuraHandledException e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testBulkUpdateEmptySTM2() {
        List<Related_Source__c> sources = [SELECT Id FROM Related_Source__c LIMIT 3];
        User stm2User = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        List<Id> recordIds = new List<Id>();
        for (Related_Source__c rec : sources) {
            recordIds.add(rec.Id);
        }

        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.bulkUpdateEmptySTM2(recordIds, stm2User.Id);
        Test.stopTest();
    }

    @IsTest
    static void testBulkUpdateEmptySTM2NoRecords() {
        // Pass IDs that exist but already have STM2 set — or just an empty list edge case
        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.bulkUpdateEmptySTM2(new List<Id>(), UserInfo.getUserId());
        Test.stopTest();
    }

    @IsTest
    static void testBulkReassignSTM2() {
        List<Related_Source__c> sources = [SELECT Id FROM Related_Source__c LIMIT 3];
        User fromUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        User toUser   = [SELECT Id FROM User WHERE IsActive = true AND Id != :fromUser.Id LIMIT 1];

        // First set STM2 to fromUser so reassign has something to work on
        List<Id> recordIds = new List<Id>();
        for (Related_Source__c rec : sources) {
            recordIds.add(rec.Id);
        }
        RelatedSourceBulkOwnerAuraCtrl.bulkUpdateEmptySTM2(recordIds, fromUser.Id);

        Test.startTest();
        RelatedSourceBulkOwnerAuraCtrl.bulkReassignSTM2(recordIds, fromUser.Id, toUser.Id);
        Test.stopTest();
    }

    @IsTest
    static void testBulkReassignSTM2NoMatchingRecords() {
        List<Related_Source__c> sources = [SELECT Id FROM Related_Source__c LIMIT 2];
        User fromUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        User toUser   = [SELECT Id FROM User WHERE IsActive = true AND Id != :fromUser.Id LIMIT 1];

        List<Id> recordIds = new List<Id>{ sources[0].Id, sources[1].Id };

        Test.startTest();
        // STM2 is not set to fromUser on these records, so nothing should update — covers the no-match path
        RelatedSourceBulkOwnerAuraCtrl.bulkReassignSTM2(recordIds, fromUser.Id, toUser.Id);
        Test.stopTest();
    }
}