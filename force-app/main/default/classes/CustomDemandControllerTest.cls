@isTest
private class CustomDemandControllerTest {

    @isTest
    static void testCustomDemandController_ApartmentFlow() {
        // Step 1: Create Booking
        Booking__c booking = new Booking__c(
            Email__c = 'test@example.com',
            Stage__c = 'Agreement'
            
        );
        insert booking;

        // Step 2: Create Master Payment Schedule
        Master_Payment_Schedule__c master = new Master_Payment_Schedule__c(
            Name = 'Stage 1',
            S_No__c = 1,
            Completed_Date__c = System.today().addDays(-10),
            Payment_Percent__c = 10,
            Status__c = 'Completed',
            Project__c = null  // add if lookup is required
        );
        insert master;

        // Step 3: Create Payment Schedule (read-only amount fields not set)
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c = booking.Id,
            Master_Payment_Schedule__c = master.Id,
            S_No__c = 1
            
           
        );
        insert ps;

        // Step 4: Set mock parameters
        Test.setCurrentPage(new ApexPages.PageReference('/apex/fakePage'));
        ApexPages.currentPage().getParameters().put('PId', ps.Id);
        ApexPages.currentPage().getParameters().put('Id', booking.Id);

        // Step 5: Run the controller
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(ps);
        CustomDemandController controller = new CustomDemandController(sc);
        Test.stopTest();

        // Step 6: Validate core logic
        System.assertNotEquals(null, controller.currentCompletedStage, 'Stage name should be populated.');
        System.assert(controller.totalAmountPayable >= 0, 'Total amount payable should be initialized.');
        System.assertNotEquals(null, controller.totalAmountPayableInWords, 'Total amount in words should be populated.');
        System.assert(controller.currentMilestoneNumber.endsWith('st') || controller.currentMilestoneNumber.endsWith('th'), 'Milestone label should be formatted.');
    }

    @isTest
    static void testGetMilestoneLabel_CustomCases() {
        System.assertEquals('1st', CustomDemandController.getMilestoneLabel(1));
        System.assertEquals('2nd', CustomDemandController.getMilestoneLabel(2));
        System.assertEquals('3rd', CustomDemandController.getMilestoneLabel(3));
        System.assertEquals('4th', CustomDemandController.getMilestoneLabel(4));
        System.assertEquals('21st', CustomDemandController.getMilestoneLabel(21));
        System.assertEquals('30th', CustomDemandController.getMilestoneLabel(30));
    }
}