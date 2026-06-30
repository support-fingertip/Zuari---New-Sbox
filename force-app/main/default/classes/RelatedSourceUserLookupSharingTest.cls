/**
 * Tests for RelatedSourceUserLookupSharing and RelatedSourceUserLookupSharingBatch.
 *
 * The RelatedSourceTrigger is bypassed during data setup (it carries heavy unrelated
 * logic); the sharing methods are exercised directly, the same way manulaSharingClassTest
 * tests its sharing methods.
 */
@IsTest
public class RelatedSourceUserLookupSharingTest {

    private static final String ROW_CAUSE = 'User_Lookup_Sharing__c';

    private static final String RS_FIELDS =
        'SELECT Id, OwnerId, Assign_To__c, Extension_Approver__c, Extension_Requested_By__c, ' +
        'Last_Unqualified_by__c, Lead_OwnerSecondary__c, Pre_Sales_User__c, RM_CP_Name__c, ' +
        'Sales_User__c, SV_User__c, STM2__c, Search_Closing_Manager__c, ' +
        'Search_Sourcing_Manager__c, Transfered_By__c FROM Related_Source__c WHERE Id = :rsId';

    private static User createUser(String suffix, Boolean isActive) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'RSL',
            LastName = 'User' + suffix,
            Email = 'rsl' + suffix + '@example.com',
            Username = 'rsl' + suffix + System.currentTimeMillis() + '@example.com.test',
            Alias = ('rs' + suffix).left(8),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = isActive,
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    private static Related_Source__c insertRs() {
        RelatedSourceHandler.bypassTrigger = true; // skip heavy unrelated trigger logic
        Related_Source__c rs = new Related_Source__c(
            Source_Type__c = 'Channel partner',
            Lead_status1__c = 'New'
        );
        insert rs;
        RelatedSourceHandler.bypassTrigger = false;
        return rs;
    }

    private static Related_Source__c requery(Id rsId) {
        return (Related_Source__c) Database.query(RS_FIELDS)[0];
    }

    private static Integer countShares(Id rsId, Id userId) {
        return [
            SELECT COUNT()
            FROM Related_Source__Share
            WHERE ParentId = :rsId AND UserOrGroupId = :userId AND RowCause = :ROW_CAUSE
        ];
    }

    private static Integer totalShares(Id rsId) {
        return [
            SELECT COUNT()
            FROM Related_Source__Share
            WHERE ParentId = :rsId AND RowCause = :ROW_CAUSE
        ];
    }

    @IsTest
    static void insert_sharesDistinctActiveUsers() {
        User u1, u2;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u1 = createUser('A', true);
            u2 = createUser('B', true);
        }

        Related_Source__c rs = insertRs();
        rs = requery(rs.Id);
        rs.Assign_To__c = u1.Id;
        rs.Pre_Sales_User__c = u2.Id;
        rs.Sales_User__c = u1.Id; // duplicate user across fields
        RelatedSourceHandler.bypassTrigger = true;
        update rs;
        RelatedSourceHandler.bypassTrigger = false;

        Test.startTest();
        RelatedSourceUserLookupSharing.shareOnInsert(new List<Related_Source__c>{ requery(rs.Id) });
        Test.stopTest();

        System.assertEquals(2, totalShares(rs.Id), 'One share per distinct user (u1 dedup across 2 fields)');
        System.assertEquals(1, countShares(rs.Id, u1.Id), 'u1 shared once');
        System.assertEquals(1, countShares(rs.Id, u2.Id), 'u2 shared once');

        Related_Source__Share s = [
            SELECT AccessLevel FROM Related_Source__Share
            WHERE ParentId = :rs.Id AND UserOrGroupId = :u1.Id AND RowCause = :ROW_CAUSE LIMIT 1
        ];
        System.assertEquals('Edit', s.AccessLevel, 'Access level should be Edit');
    }

    @IsTest
    static void insert_skipsOwnerSelfShare() {
        Related_Source__c rs = insertRs();
        rs = requery(rs.Id);
        rs.Assign_To__c = rs.OwnerId; // owner already has access
        RelatedSourceHandler.bypassTrigger = true;
        update rs;
        RelatedSourceHandler.bypassTrigger = false;

        Test.startTest();
        RelatedSourceUserLookupSharing.shareOnInsert(new List<Related_Source__c>{ requery(rs.Id) });
        Test.stopTest();

        System.assertEquals(0, totalShares(rs.Id), 'Owner should not be granted a redundant share');
    }

    @IsTest
    static void insert_filtersInactiveUsers() {
        User inactive;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            inactive = createUser('C', false);
        }

        Related_Source__c rs = insertRs();
        rs = requery(rs.Id);
        rs.STM2__c = inactive.Id;
        RelatedSourceHandler.bypassTrigger = true;
        update rs;
        RelatedSourceHandler.bypassTrigger = false;

        Test.startTest();
        RelatedSourceUserLookupSharing.shareOnInsert(new List<Related_Source__c>{ requery(rs.Id) });
        Test.stopTest();

        System.assertEquals(0, totalShares(rs.Id), 'Inactive users should be filtered out');
    }

    @IsTest
    static void insert_isIdempotent() {
        User u1;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u1 = createUser('D', true);
        }

        Related_Source__c rs = insertRs();
        rs = requery(rs.Id);
        rs.Assign_To__c = u1.Id;
        RelatedSourceHandler.bypassTrigger = true;
        update rs;
        RelatedSourceHandler.bypassTrigger = false;

        Test.startTest();
        List<Related_Source__c> recs = new List<Related_Source__c>{ requery(rs.Id) };
        RelatedSourceUserLookupSharing.shareOnInsert(recs);
        RelatedSourceUserLookupSharing.shareOnInsert(recs); // second run must not duplicate
        Test.stopTest();

        System.assertEquals(1, countShares(rs.Id, u1.Id), 'Re-running must not create duplicate shares');
    }

    @IsTest
    static void update_swapsUserShares() {
        User u1, u2;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u1 = createUser('E', true);
            u2 = createUser('F', true);
        }

        Related_Source__c rs = insertRs();
        rs = requery(rs.Id);
        rs.Assign_To__c = u1.Id;
        RelatedSourceHandler.bypassTrigger = true;
        update rs;
        RelatedSourceHandler.bypassTrigger = false;

        Related_Source__c original = requery(rs.Id);
        RelatedSourceUserLookupSharing.shareOnInsert(new List<Related_Source__c>{ original });
        System.assertEquals(1, countShares(rs.Id, u1.Id), 'Precondition: u1 shared');

        // Simulate the lookup changing from u1 to u2.
        Related_Source__c updated = requery(rs.Id);
        updated.Assign_To__c = u2.Id;

        Test.startTest();
        RelatedSourceUserLookupSharing.reshareOnUpdate(
            new List<Related_Source__c>{ updated },
            new Map<Id, Related_Source__c>{ rs.Id => original }
        );
        Test.stopTest();

        System.assertEquals(0, countShares(rs.Id, u1.Id), 'Old user share removed');
        System.assertEquals(1, countShares(rs.Id, u2.Id), 'New user share added');
    }

    @IsTest
    static void batch_backfillsExistingRecords() {
        User u1;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u1 = createUser('G', true);
        }

        RelatedSourceHandler.bypassTrigger = true;
        List<Related_Source__c> list1 = new List<Related_Source__c>();
        for (Integer i = 0; i < 5; i++) {
            list1.add(new Related_Source__c(Source_Type__c = 'Channel partner', Assign_To__c = u1.Id));
        }
        insert list1;
        RelatedSourceHandler.bypassTrigger = false;

        Test.startTest();
        Database.executeBatch(new RelatedSourceUserLookupSharingBatch(), 200);
        Test.stopTest();

        Integer shareCount = [
            SELECT COUNT() FROM Related_Source__Share
            WHERE UserOrGroupId = :u1.Id AND RowCause = :ROW_CAUSE
        ];
        System.assertEquals(5, shareCount, 'Batch should backfill a share for each existing record');
    }
}
