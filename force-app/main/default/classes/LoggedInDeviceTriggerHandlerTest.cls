@IsTest
private class LoggedInDeviceTriggerHandlerTest {

    @TestSetup
    static void setup() {
        insert new List<Channel_Partner__c>{
            new Channel_Partner__c(Name = 'Logged Time CP A',Email__c='test@gmail.com'),
            new Channel_Partner__c(Name = 'Logged Time CP B',Email__c='test@gmail.com')
        };
    }

    private static Channel_Partner__c cpA() {
        return [SELECT Id, Last_Logged_Time__c FROM Channel_Partner__c WHERE Name = 'Logged Time CP A' LIMIT 1];
    }

    private static Channel_Partner__c cpB() {
        return [SELECT Id, Last_Logged_Time__c FROM Channel_Partner__c WHERE Name = 'Logged Time CP B' LIMIT 1];
    }

    @IsTest
    static void testInsert_PropagatesLastLoggedIn() {
        Channel_Partner__c cp = cpA();
        DateTime loginAt = DateTime.newInstance(2026, 1, 1, 9, 0, 0);

        Test.startTest();
        insert new Logged_in_Device__c(
            Channel_Partner__c = cp.Id,
            Last_Logged_In__c = loginAt,
            Device_Id__c = 'dev-1'
        );
        Test.stopTest();

        System.assertEquals(loginAt, cpA().Last_Logged_Time__c,
            'CP timestamp should equal the inserted device Last_Logged_In__c.');
    }

    @IsTest
    static void testUpdate_PropagatesNewerValue() {
        Channel_Partner__c cp = cpA();
        DateTime t1 = DateTime.newInstance(2026, 1, 1, 9, 0, 0);
        DateTime t2 = DateTime.newInstance(2026, 1, 2, 9, 0, 0);

        Logged_in_Device__c d = new Logged_in_Device__c(
            Channel_Partner__c = cp.Id,
            Last_Logged_In__c = t1,
            Device_Id__c = 'dev-1'
        );
        insert d;
        System.assertEquals(t1, cpA().Last_Logged_Time__c, 'Pre-update sanity check.');

        Test.startTest();
        update new Logged_in_Device__c(Id = d.Id, Last_Logged_In__c = t2);
        Test.stopTest();

        System.assertEquals(t2, cpA().Last_Logged_Time__c,
            'CP timestamp should advance to the newer device value.');
    }

    @IsTest
    static void testUpdate_AlwaysOverwritesEvenWhenOlder() {
        Channel_Partner__c cp = cpA();
        DateTime t2 = DateTime.newInstance(2026, 1, 2, 9, 0, 0);
        DateTime t0 = DateTime.newInstance(2026, 1, 1, 9, 0, 0);

        Logged_in_Device__c d = new Logged_in_Device__c(
            Channel_Partner__c = cp.Id,
            Last_Logged_In__c = t2,
            Device_Id__c = 'dev-1'
        );
        insert d;

        Test.startTest();
        update new Logged_in_Device__c(Id = d.Id, Last_Logged_In__c = t0);
        Test.stopTest();

        System.assertEquals(t0, cpA().Last_Logged_Time__c,
            'Always-overwrite: an older device value must still replace the CP value.');
    }

    @IsTest
    static void testInsert_NullLookupIsIgnored() {
        Test.startTest();
        insert new Logged_in_Device__c(
            Channel_Partner__c = null,
            Last_Logged_In__c = DateTime.newInstance(2026, 1, 1, 9, 0, 0),
            Device_Id__c = 'orphan'
        );
        Test.stopTest();

        System.assertEquals(null, cpA().Last_Logged_Time__c, 'CP A should remain null.');
        System.assertEquals(null, cpB().Last_Logged_Time__c, 'CP B should remain null.');
    }

    @IsTest
    static void testInsert_NullLastLoggedInIsIgnored() {
        Channel_Partner__c cp = cpA();

        Test.startTest();
        insert new Logged_in_Device__c(
            Channel_Partner__c = cp.Id,
            Last_Logged_In__c = null,
            Device_Id__c = 'dev-blank'
        );
        Test.stopTest();

        System.assertEquals(null, cpA().Last_Logged_Time__c,
            'CP timestamp should not be set when Last_Logged_In__c is null.');
    }

    @IsTest
    static void testUpdate_NoChangeToLastLoggedInIsNoop() {
        Channel_Partner__c cp = cpA();
        DateTime t1 = DateTime.newInstance(2026, 1, 1, 9, 0, 0);

        Logged_in_Device__c d = new Logged_in_Device__c(
            Channel_Partner__c = cp.Id,
            Last_Logged_In__c = t1,
            Device_Id__c = 'dev-1',
            Status__c = 'Active'
        );
        insert d;

        // Manually zero the CP timestamp so we can detect any spurious write.
        update new Channel_Partner__c(Id = cp.Id, Last_Logged_Time__c = null);
        System.assertEquals(null, cpA().Last_Logged_Time__c, 'Pre-test reset.');

        Test.startTest();
        update new Logged_in_Device__c(Id = d.Id, Status__c = 'Logged Out');
        Test.stopTest();

        System.assertEquals(null, cpA().Last_Logged_Time__c,
            'Updating an unrelated field must not push to the CP.');
    }

    @IsTest
    static void testBulk_GroupsAndUpdatesMaxPerCp() {
        // 2 CPs already exist from @TestSetup; create 48 more to reach 50.
        List<Channel_Partner__c> extras = new List<Channel_Partner__c>();
        for (Integer i = 0; i < 48; i++) {
            extras.add(new Channel_Partner__c(Name = 'Bulk CP ' + i,Email__c='test@gmail.com'));
        }
        insert extras;

        List<Channel_Partner__c> cps = [SELECT Id FROM Channel_Partner__c];
        System.assertEquals(50, cps.size(), 'Setup should produce 50 CPs.');

        DateTime base = DateTime.newInstance(2026, 3, 1, 0, 0, 0);
        List<Logged_in_Device__c> devices = new List<Logged_in_Device__c>();
        Map<Id, DateTime> expectedMax = new Map<Id, DateTime>();

        // 4 devices per CP -> 200 devices total. Each device's offset is unique
        // so we can predict the max per CP deterministically.
        for (Integer i = 0; i < cps.size(); i++) {
            Id cpId = cps[i].Id;
            DateTime maxForCp = null;
            for (Integer j = 0; j < 4; j++) {
                DateTime t = base.addMinutes(i * 10 + j);
                devices.add(new Logged_in_Device__c(
                    Channel_Partner__c = cpId,
                    Last_Logged_In__c = t,
                    Device_Id__c = 'cp' + i + '-d' + j
                ));
                if (maxForCp == null || t > maxForCp) {
                    maxForCp = t;
                }
            }
            expectedMax.put(cpId, maxForCp);
        }

        Test.startTest();
        insert devices;
        Test.stopTest();

        for (Channel_Partner__c c : [SELECT Id, Last_Logged_Time__c FROM Channel_Partner__c]) {
            System.assertEquals(expectedMax.get(c.Id), c.Last_Logged_Time__c,
                'CP ' + c.Id + ' should carry the max Last_Logged_In__c from its bulk batch.');
        }
    }
}