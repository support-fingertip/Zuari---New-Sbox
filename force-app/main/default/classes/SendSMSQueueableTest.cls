@isTest
public class SendSMSQueueableTest {

    @isTest
    static void testQueueableWithValidData() {
        Test.startTest();
        // Simulate queueable execution with valid data...
        System.enqueueJob(new SendSMSQueueable('9876543210', 'Test User', '123456'));
        Test.stopTest();

        // Check last log entry...
        Apex_Log__c logRec = [SELECT Status__c, Response__c FROM Apex_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertNotEquals(null, logRec, 'Apex Log must be inserted');
    }

    @isTest
    static void testQueueableWithMissingPhone() {
        Test.startTest();
        // Missing phone → should fail...
        System.enqueueJob(new SendSMSQueueable(null, 'User', '123456'));
        Test.stopTest();

        Apex_Log__c logRec = [SELECT Status__c FROM Apex_Log__c ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('FAILED', logRec.Status__c, 'Should fail if phone is blank');
    }

    @isTest
    static void testQueueableWithMissingAllData() {
        Test.startTest();
        // Missing everything...
        System.enqueueJob(new SendSMSQueueable(null, null, null));
        Test.stopTest();

        Apex_Log__c logRec = [SELECT Status__c FROM Apex_Log__c ORDER BY CreatedDate DESC LIMIT 1];
		System.assertEquals('FAILED', logRec.Status__c, 'Should fail if everything is blank');
    }
}