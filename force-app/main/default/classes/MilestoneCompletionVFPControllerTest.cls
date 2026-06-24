@isTest
private class MilestoneCompletionVFPControllerTest {

    private static Master_payment_schedule__c createTestData() {
        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c = true
        );
        insert pjt;

        Master_payment_schedule__c mps = new Master_payment_schedule__c(
            Project__c = pjt.Id,
            Name = 'Milestone 1',
            Payment_Percent__c = 20,
            Status__c = 'Completed',
            Completed_Date__c = Date.today()
        );
        insert mps;

        return mps;
    }

    @isTest
    static void testControllerWithAllData() {
        Master_payment_schedule__c mps = createTestData();

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(mps);
        MilestoneCompletionVFPController controller = new MilestoneCompletionVFPController(stdController);
        Test.stopTest();

        System.assertNotEquals(null, controller.milestoneRec);
        System.assertEquals('Milestone 1', controller.masterScheduleName);
        System.assertEquals(Date.today(), controller.completedDate);
        System.assertNotEquals(null, controller.projectName);
    }

    @isTest
    static void testGetMilestoneDetails() {
        Master_payment_schedule__c mps = createTestData();

        Test.startTest();
        Map<String, Object> result = MilestoneCompletionVFPController.getMilestoneDetails(mps.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(Date.today(), result.get('completedDate'));
    }
}