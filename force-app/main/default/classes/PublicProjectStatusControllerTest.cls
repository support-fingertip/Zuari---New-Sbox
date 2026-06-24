@isTest
private class PublicProjectStatusControllerTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        Block__c block = new Block__c(Name = 'Block A', Project__c = project.Id);
        insert block;

        Payment_Plan__c plan = new Payment_Plan__c(
            Name = 'Plan 1',
            Project__c = project.Id,
            Block__c = block.Id,
            Active__c = true
        );
        insert plan;

        List<Master_Payment_Schedule__c> mpsList = new List<Master_Payment_Schedule__c>();
        for (Integer i = 1; i <= 2; i++) {
            mpsList.add(new Master_Payment_Schedule__c(
                Payment_Plan__c = plan.Id,
                Project__c = project.Id,
                S_No__c = i,
                Status__c = 'Not Started',
                Payment_Percent__c = 50
            ));
        }
        insert mpsList;

        // Attach a file to the first MPS to exercise the image-url branch.
        ContentVersion cv = new ContentVersion(
            Title = 'milestone.png',
            PathOnClient = 'milestone.png',
            VersionData = Blob.valueOf('dummy'),
            IsMajorVersion = true
        );
        insert cv;
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        insert new ContentDocumentLink(
            LinkedEntityId = mpsList[0].Id,
            ContentDocumentId = contentDocumentId,
            ShareType = 'V'
        );
    }

    @isTest
    static void testFetchHierarchy() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Block__c block = [SELECT Id FROM Block__c LIMIT 1];
        Payment_Plan__c plan = [SELECT Id FROM Payment_Plan__c LIMIT 1];

        Test.startTest();

        Project__c fetched = PublicProjectStatusController.getProject(project.Id);
        System.assertEquals(project.Id, fetched.Id, 'Project should be returned');

        List<Block__c> blocks = PublicProjectStatusController.getBlocks(project.Id);
        System.assertEquals(1, blocks.size(), 'One block expected');

        List<Payment_Plan__c> plans = PublicProjectStatusController.getPaymentPlans(block.Id);
        System.assertEquals(1, plans.size(), 'One active payment plan expected');

        List<PublicProjectStatusController.MpsWrapper> mps =
            PublicProjectStatusController.getMasterPaymentSchedule(plan.Id);
        System.assertEquals(2, mps.size(), 'Two MPS records expected');
        System.assertNotEquals(null, mps[0].imageUrl, 'First MPS should have an image URL');
        System.assertEquals(null, mps[1].imageUrl, 'Second MPS should have no image URL');

        Test.stopTest();
    }

    @isTest
    static void testNullInputs() {
        Test.startTest();
        System.assertEquals(null, PublicProjectStatusController.getProject(null));
        System.assert(PublicProjectStatusController.getBlocks(null).isEmpty());
        System.assert(PublicProjectStatusController.getPaymentPlans(null).isEmpty());
        System.assert(PublicProjectStatusController.getMasterPaymentSchedule(null).isEmpty());
        Test.stopTest();
    }
}