@IsTest
private class DemandRaisedEmailQueueableTest {

    @IsTest
    static void testQueueableRuns() {
        // TODO: create test data that matches what DemandRaisedHelper expects
        // Example (replace with your actual object):
        // Demand__c d = new Demand__c(Name='Test');
        // insert d;

        List<Id> ids = new List<Id>(); // add inserted record ids here

        Test.startTest();
        System.enqueueJob(new DemandRaisedEmailQueueable(ids));
        Test.stopTest();

        // Assert expected side effects (status update / log record / etc.)
        // System.assertEquals(...);
    }
}