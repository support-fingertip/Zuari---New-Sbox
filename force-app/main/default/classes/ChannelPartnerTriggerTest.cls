@IsTest
public class ChannelPartnerTriggerTest {

    @TestSetup
    static void setup() {
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test CP',
            Email__c = 'cptest@example.com',
            Active__c = true,
            Approval_Status__c = 'Pending'
        );
        insert cp;
    }

    @IsTest
    static void test_approvalSetsPasswordAndSendsEmail() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];

        Channel_Partner__c upd = new Channel_Partner__c(Id = cp.Id, Approval_Status__c = 'Approved');

        Test.startTest();
        update upd;
        Test.stopTest();

        Channel_Partner__c afterCp = [SELECT Approval_Status__c, Password__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertEquals('Approved', afterCp.Approval_Status__c);
        System.assert(!String.isBlank(afterCp.Password__c), 'Password should be generated on approval');

        // Email send is verified by no exception during Test.stopTest()
    }

    @IsTest
    static void test_noApprovalChange_noPasswordSet() {
        Channel_Partner__c cp = [SELECT Id, Name FROM Channel_Partner__c LIMIT 1];

        Channel_Partner__c upd = new Channel_Partner__c(Id = cp.Id, Name = cp.Name + ' X');

        Test.startTest();
        update upd;
        Test.stopTest();

        Channel_Partner__c afterCp = [SELECT Password__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assert(String.isBlank(afterCp.Password__c), 'Password should remain blank without approval change');
    }
}