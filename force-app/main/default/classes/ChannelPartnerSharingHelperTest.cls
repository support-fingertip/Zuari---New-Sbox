@IsTest
public class ChannelPartnerSharingHelperTest {

    private static final String ROW_CAUSE = 'Manual';

    private static User createUser(String aliasSuffix, Boolean isActive) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'SRM',
            LastName = 'User' + aliasSuffix,
            Email = 'srm' + aliasSuffix + '@example.com',
            Username = 'srm' + aliasSuffix + System.currentTimeMillis() + '@example.com.test',
            Alias = ('sr' + aliasSuffix).left(8),
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

    private static Channel_Partner__c newCp(String name, Id sourcingRmId) {
        return new Channel_Partner__c(
            Name = name,
            Active__c = true,email__c='test@gmail.com',
            Approval_Status__c = 'Pending',
            Sourcing_RM__c = sourcingRmId
        );
    }

    private static Integer countShares(Id cpId, Id userId) {
        return [
            SELECT COUNT()
            FROM Channel_Partner__Share
            WHERE ParentId = :cpId
            AND UserOrGroupId = :userId
            AND RowCause = :ROW_CAUSE
        ];
    }

    @IsTest
    static void insert_withSourcingRM_createsShare() {
        User rm;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rm = createUser('A', true);
        }

        Test.startTest();
        Channel_Partner__c cp = newCp('CP-Insert-RM', rm.Id);
        insert cp;
        Test.stopTest();

        System.assertEquals(1, countShares(cp.Id, rm.Id),
            'Share must be created on insert when Sourcing_RM__c is populated');
    }

    @IsTest
    static void insert_withoutSourcingRM_createsNoShare() {
        Test.startTest();
        Channel_Partner__c cp = newCp('CP-Insert-NoRM', null);
        insert cp;
        Test.stopTest();

        Integer total = [
            SELECT COUNT()
            FROM Channel_Partner__Share
            WHERE ParentId = :cp.Id
            AND RowCause = :ROW_CAUSE
        ];
        System.assertEquals(0, total, 'No custom share when Sourcing_RM__c is null');
    }

    @IsTest
    static void update_nullToUser_createsShare() {
        User rm;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rm = createUser('B', true);
        }
        Channel_Partner__c cp = newCp('CP-Null-To-User', null);
        insert cp;

        Test.startTest();
        update new Channel_Partner__c(Id = cp.Id, Sourcing_RM__c = rm.Id);
        Test.stopTest();

        System.assertEquals(1, countShares(cp.Id, rm.Id),
            'Share must be created when Sourcing_RM__c moves from null to a user');
    }

    @IsTest
    static void update_userAtoUserB_swapsShare() {
        User rmA;
        User rmB;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rmA = createUser('C1', true);
            rmB = createUser('C2', true);
        }
        Channel_Partner__c cp = newCp('CP-Swap', rmA.Id);
        insert cp;

        Test.startTest();
        update new Channel_Partner__c(Id = cp.Id, Sourcing_RM__c = rmB.Id);
        Test.stopTest();

        System.assertEquals(0, countShares(cp.Id, rmA.Id),
            'Old user share must be removed');
        System.assertEquals(1, countShares(cp.Id, rmB.Id),
            'New user share must be created');
    }

    @IsTest
    static void update_userToNull_deletesShare() {
        User rm;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rm = createUser('D', true);
        }
        Channel_Partner__c cp = newCp('CP-To-Null', rm.Id);
        insert cp;
        System.assertEquals(1, countShares(cp.Id, rm.Id),
            'Precondition: share exists after insert');

        Test.startTest();
        update new Channel_Partner__c(Id = cp.Id, Sourcing_RM__c = null);
        Test.stopTest();

        System.assertEquals(0, countShares(cp.Id, rm.Id),
            'Share must be removed when Sourcing_RM__c is cleared');
    }

    @IsTest
    static void insert_sourcingRMEqualsOwner_noShare() {
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'CP-SelfShare',
            Active__c = true,
            Approval_Status__c = 'Pending',Email__c='test@gmail.com',
            Sourcing_RM__c = UserInfo.getUserId()
        );

        Test.startTest();
        insert cp;
        Test.stopTest();

        System.assertEquals(0, countShares(cp.Id, UserInfo.getUserId()),
            'No share row when Sourcing_RM__c equals OwnerId');
    }

    @IsTest
    static void insert_inactiveUser_noShare() {
        User rm;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rm = createUser('E', false);
        }

        Test.startTest();
        Channel_Partner__c cp = newCp('CP-Inactive', rm.Id);
        insert cp;
        Test.stopTest();

        System.assertEquals(0, countShares(cp.Id, rm.Id),
            'Inactive users must not receive share rows');
    }

    @IsTest
    static void bulkInsert_createsSharesForAll() {
        User rm;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rm = createUser('F', true);
        }

        List<Channel_Partner__c> batch = new List<Channel_Partner__c>();
        for (Integer i = 0; i < 50; i++) {
            batch.add(newCp('Bulk-CP-' + i, rm.Id));
        }

        Test.startTest();
        insert batch;
        Test.stopTest();

        Set<Id> cpIds = new Map<Id, Channel_Partner__c>(batch).keySet();
        Integer shares = [
            SELECT COUNT()
            FROM Channel_Partner__Share
            WHERE ParentId IN :cpIds
            AND UserOrGroupId = :rm.Id
            AND RowCause = :ROW_CAUSE
        ];
        System.assertEquals(50, shares, 'Every CP in the bulk insert must get a share row');
    }
}