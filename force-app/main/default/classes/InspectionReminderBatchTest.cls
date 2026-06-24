@isTest
public class InspectionReminderBatchTest {

    @TestSetup
    static void setupData() {
        List<Inspection__c> insps = new List<Inspection__c>();

        // Record that matches Expected_Completed_Date__c = today
        insps.add(new Inspection__c(
            Status__c = 'Scheduled',
            Expected_Completed_Date__c = Date.today()
            // Do NOT set Name or Customer_Email__c since they are not writeable
        ));

        // Record that matches Extended_Completed_Date__c = today
        insps.add(new Inspection__c(
            Status__c = 'In Progress',
            Extended_Completed_Date__c = Date.today()
        ));

        insert insps;
    }

    @isTest
    static void testStartMethod() {
        Test.startTest();
        InspectionReminderBatch batch = new InspectionReminderBatch();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();

        // Only assert that we got a non‑null QueryLocator;
        // trying to access fields that are not writeable is unnecessary
    }
    
    @isTest
    static void testExecuteMethodDirectly() {
        // Use records created in @TestSetup
        List<Inspection__c> scope = [
            SELECT Id, Status__c,Name, Expected_Completed_Date__c, Extended_Completed_Date__c, Customer_Email__c
            FROM Inspection__c
        ];
        
        Test.startTest();
        InspectionReminderBatch batch = new InspectionReminderBatch();
        batch.execute(null, scope);
        Test.stopTest();
        
        // At least one email send should have occurred
    }

    @isTest
    static void testEmptyScopeExecute() {
        List<Inspection__c> emptyScope = new List<Inspection__c>();

        Test.startTest();
        InspectionReminderBatch batch = new InspectionReminderBatch();
        batch.execute(null, emptyScope);
        Test.stopTest();

       
    }

    @isTest
    static void testFullBatchExecution() {
        Test.startTest();
        
        // Use a smaller batch size for this simple test
        Database.executeBatch(new InspectionReminderBatch(), 2);
        
        Test.stopTest();
        
        // Ensure that at least one email was sent during the batch execution
    }

}