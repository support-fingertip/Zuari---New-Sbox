/**
 * RelatedSourceSharingServiceTest
 * Test class for RelatedSourceSharingService
 */
@isTest
private class RelatedSourceSharingServiceTest {

    // ─────────────────────────────────────────────
    // Test Data Setup
    // ─────────────────────────────────────────────
    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User stm2User1 = new User(
            FirstName = 'STM2', LastName = 'UserOne',
            Email = 'stm2user1@testorg.com', Username = 'stm2user1@testorg.com.test',
            Alias = 'stm2u1', ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        User stm2User2 = new User(
            FirstName = 'STM2', LastName = 'UserTwo',
            Email = 'stm2user2@testorg.com', Username = 'stm2user2@testorg.com.test',
            Alias = 'stm2u2', ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        insert new List<User>{ stm2User1, stm2User2 };
    }

    // ─────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────
    private static User getUser(String lastName) {
        return [SELECT Id FROM User WHERE LastName = :lastName LIMIT 1];
    }

    private static Lead createLead() {
        Lead l = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Co');
        insert l;
        return l;
    }

    private static Related_Source__c createRecord(Id stm2UserId, Id leadId) {
        Related_Source__c rec = new Related_Source__c(
            STM2__c   = stm2UserId,
            SLead__c  = leadId
        );
        insert rec;
        return rec;
    }

    // ─────────────────────────────────────────────
    // Test 1: Share created for both Related_Source__c and Lead
    // ─────────────────────────────────────────────
    @isTest
    static void testShareCreatedForBothObjects() {
        User stm2User = getUser('UserOne');
        Lead lead = createLead();
        Related_Source__c rec = createRecord(stm2User.Id, lead.Id);

        Test.startTest();
        RelatedSourceSharingService.shareWithSTM2User(new List<Id>{ rec.Id });
        Test.stopTest();

        List<Related_Source__Share> rsShares = [
            SELECT Id, AccessLevel FROM Related_Source__Share
            WHERE ParentId = :rec.Id AND UserOrGroupId = :stm2User.Id
              AND RowCause = :Schema.Related_Source__Share.RowCause.Manual
        ];
        System.assertEquals(1, rsShares.size(), 'Should create 1 Related_Source__c share');
        System.assertEquals('Edit', rsShares[0].AccessLevel, 'Access level should be Edit');

        List<LeadShare> leadShares = [
            SELECT Id, LeadAccessLevel FROM LeadShare
            WHERE LeadId = :lead.Id AND UserOrGroupId = :stm2User.Id
              AND RowCause = 'Manual'
        ];
        System.assertEquals(1, leadShares.size(), 'Should create 1 Lead share');
        System.assertEquals('Edit', leadShares[0].LeadAccessLevel, 'Lead access level should be Edit');
    }

    // ─────────────────────────────────────────────
    // Test 2: No duplicate shares if already shared
    // ─────────────────────────────────────────────
    @isTest
    static void testNoDuplicateShares() {
        User stm2User = getUser('UserOne');
        Lead lead = createLead();
        Related_Source__c rec = createRecord(stm2User.Id, lead.Id);

        // Pre-insert shares
        insert new Related_Source__Share(
            ParentId = rec.Id, UserOrGroupId = stm2User.Id,
            AccessLevel = 'Edit', RowCause = Schema.Related_Source__Share.RowCause.Manual
        );
        insert new LeadShare(
            LeadId = lead.Id, UserOrGroupId = stm2User.Id,
            LeadAccessLevel = 'Edit', RowCause = 'Manual'
        );

        Test.startTest();
        RelatedSourceSharingService.shareWithSTM2User(new List<Id>{ rec.Id });
        Test.stopTest();

        System.assertEquals(1, [
            SELECT Id FROM Related_Source__Share
            WHERE ParentId = :rec.Id AND UserOrGroupId = :stm2User.Id
              AND RowCause = :Schema.Related_Source__Share.RowCause.Manual
        ].size(), 'No duplicate Related_Source__c share');

        System.assertEquals(1, [
            SELECT Id FROM LeadShare
            WHERE LeadId = :lead.Id AND UserOrGroupId = :stm2User.Id
              AND RowCause = 'Manual'
        ].size(), 'No duplicate Lead share');
    }

    // ─────────────────────────────────────────────
    // Test 3: Existing shares for other users preserved
    // ─────────────────────────────────────────────
    @isTest
    static void testExistingSharesPreserved() {
        User stm2User1 = getUser('UserOne');
        User stm2User2 = getUser('UserTwo');
        Lead lead = createLead();
        Related_Source__c rec = createRecord(stm2User2.Id, lead.Id); // STM2 = User2

        // Pre-share with User1
        insert new Related_Source__Share(
            ParentId = rec.Id, UserOrGroupId = stm2User1.Id,
            AccessLevel = 'Edit', RowCause = Schema.Related_Source__Share.RowCause.Manual
        );
        insert new LeadShare(
            LeadId = lead.Id, UserOrGroupId = stm2User1.Id,
            LeadAccessLevel = 'Edit', RowCause = 'Manual'
        );

        Test.startTest();
        RelatedSourceSharingService.shareWithSTM2User(new List<Id>{ rec.Id });
        Test.stopTest();

        // User1 shares preserved
        System.assertEquals(1, [
            SELECT Id FROM Related_Source__Share
            WHERE ParentId = :rec.Id AND UserOrGroupId = :stm2User1.Id
              AND RowCause = :Schema.Related_Source__Share.RowCause.Manual
        ].size(), 'User1 Related_Source__c share should be preserved');

        System.assertEquals(1, [
            SELECT Id FROM LeadShare
            WHERE LeadId = :lead.Id AND UserOrGroupId = :stm2User1.Id
              AND RowCause = 'Manual'
        ].size(), 'User1 Lead share should be preserved');

        // User2 shares created
        System.assertEquals(1, [
            SELECT Id FROM Related_Source__Share
            WHERE ParentId = :rec.Id AND UserOrGroupId = :stm2User2.Id
              AND RowCause = :Schema.Related_Source__Share.RowCause.Manual
        ].size(), 'User2 Related_Source__c share should be created');

        System.assertEquals(1, [
            SELECT Id FROM LeadShare
            WHERE LeadId = :lead.Id AND UserOrGroupId = :stm2User2.Id
              AND RowCause = 'Manual'
        ].size(), 'User2 Lead share should be created');
    }

    // ─────────────────────────────────────────────
    // Test 4: No share when STM2__c is null
    // ─────────────────────────────────────────────
    @isTest
    static void testNoShareWhenSTM2IsNull() {
        Lead lead = createLead();
        Related_Source__c rec = createRecord(null, lead.Id);

        Test.startTest();
        RelatedSourceSharingService.shareWithSTM2User(new List<Id>{ rec.Id });
        Test.stopTest();

        System.assertEquals(0, [
            SELECT Id FROM Related_Source__Share
            WHERE ParentId = :rec.Id
              AND RowCause = :Schema.Related_Source__Share.RowCause.Manual
        ].size(), 'No Related_Source__c share when STM2 is null');

        System.assertEquals(0, [
            SELECT Id FROM LeadShare
            WHERE LeadId = :lead.Id AND RowCause = 'Manual'
        ].size(), 'No Lead share when STM2 is null');
    }

    // ─────────────────────────────────────────────
    // Test 5: Share created for Related_Source__c even when SLead__c is null
    // ─────────────────────────────────────────────
    @isTest
    static void testShareWhenNoLead() {
        User stm2User = getUser('UserOne');
        Related_Source__c rec = createRecord(stm2User.Id, null); // no lead

        Test.startTest();
        RelatedSourceSharingService.shareWithSTM2User(new List<Id>{ rec.Id });
        Test.stopTest();

        System.assertEquals(1, [
            SELECT Id FROM Related_Source__Share
            WHERE ParentId = :rec.Id AND UserOrGroupId = :stm2User.Id
              AND RowCause = :Schema.Related_Source__Share.RowCause.Manual
        ].size(), 'Related_Source__c share should be created even without a Lead');
    }

    // ─────────────────────────────────────────────
    // Test 6: Bulk — multiple records processed
    // ─────────────────────────────────────────────
    @isTest
    static void testBulkRecords() {
        User stm2User1 = getUser('UserOne');
        User stm2User2 = getUser('UserTwo');
        Lead lead1 = createLead();
        Lead lead2 = createLead();

        List<Related_Source__c> records = new List<Related_Source__c>{
            new Related_Source__c(STM2__c = stm2User1.Id, SLead__c = lead1.Id),
            new Related_Source__c(STM2__c = stm2User2.Id, SLead__c = lead2.Id),
            new Related_Source__c(STM2__c = null, SLead__c = null)
        };
        insert records;

        List<Id> recordIds = new List<Id>{ records[0].Id, records[1].Id, records[2].Id };

        Test.startTest();
        RelatedSourceSharingService.shareWithSTM2User(recordIds);
        Test.stopTest();

        System.assertEquals(2, [
            SELECT Id FROM Related_Source__Share
            WHERE ParentId IN :recordIds
              AND RowCause = :Schema.Related_Source__Share.RowCause.Manual
        ].size(), 'Should create 2 Related_Source__c shares');

        System.assertEquals(2, [
            SELECT Id FROM LeadShare
            WHERE LeadId IN (SELECT SLead__c FROM Related_Source__c WHERE Id IN :recordIds)
              AND RowCause = 'Manual'
        ].size(), 'Should create 2 Lead shares');
    }

    // ─────────────────────────────────────────────
    // Test 7: Empty list — no errors
    // ─────────────────────────────────────────────
    @isTest
    static void testEmptyListInput() {
        Test.startTest();
        try {
            RelatedSourceSharingService.shareWithSTM2User(new List<Id>());
            System.assert(true, 'Empty list should not throw');
        } catch (Exception e) {
            System.assert(false, 'Unexpected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // Test 8: Null input — no errors
    // ─────────────────────────────────────────────
    @isTest
    static void testNullInput() {
        Test.startTest();
        try {
            RelatedSourceSharingService.shareWithSTM2User(null);
            System.assert(true, 'Null input should not throw');
        } catch (Exception e) {
            System.assert(false, 'Unexpected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}