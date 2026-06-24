@isTest
public class CustomerQueryUserStampQueueableTest {

    private static User createUser(String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Long ts = System.currentTimeMillis();
        return new User(
            FirstName = 'Stamp',
            LastName = alias,
            Alias = alias,
            Email = alias + '_' + ts + '@zuaristamp.test',
            Username = alias + '_' + ts + '@zuaristamp.test',
            CommunityNickname = alias + ts,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
    }

    @isTest
    static void stampNowNullSetIsNoop() {
        Test.startTest();
        CustomerQueryUserStampQueueable.stampNow(null);
        Test.stopTest();
    }

    @isTest
    static void stampNowEmptySetIsNoop() {
        Test.startTest();
        CustomerQueryUserStampQueueable.stampNow(new Set<Id>());
        Test.stopTest();
    }

    @isTest
    static void stampNowUpdatesLastQueryAssignedTime() {
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u = createUser('stmp1');
            insert u;
        }

        Test.startTest();
        CustomerQueryUserStampQueueable.stampNow(new Set<Id>{ u.Id });
        Test.stopTest();

        User reloaded = [SELECT Id, Last_Query_Assigned_Time__c FROM User WHERE Id = :u.Id];
        System.assertNotEquals(null, reloaded.Last_Query_Assigned_Time__c,
            'Last_Query_Assigned_Time__c should be set after stampNow');
    }

    @isTest
    static void executeViaQueueable() {
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u = createUser('stmp2');
            insert u;
        }

        Test.startTest();
        System.enqueueJob(new CustomerQueryUserStampQueueable(new Set<Id>{ u.Id }));
        Test.stopTest();

        User reloaded = [SELECT Id, Last_Query_Assigned_Time__c FROM User WHERE Id = :u.Id];
        System.assertNotEquals(null, reloaded.Last_Query_Assigned_Time__c,
            'Queueable execute should stamp the user');
    }

    @isTest
    static void bulkStampUsers() {
        List<User> users = new List<User>();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            for (Integer i = 0; i < 25; i++) {
                users.add(createUser('blk' + i));
            }
            insert users;
        }

        Set<Id> ids = new Set<Id>();
        for (User u : users) ids.add(u.Id);

        Test.startTest();
        CustomerQueryUserStampQueueable.stampNow(ids);
        Test.stopTest();

        Map<Id, User> reloaded = new Map<Id, User>([
            SELECT Id, Last_Query_Assigned_Time__c FROM User WHERE Id IN :ids
        ]);
        for (Id uid : ids) {
            System.assertNotEquals(null, reloaded.get(uid).Last_Query_Assigned_Time__c,
                'Every user in the set should be stamped');
        }
    }
}