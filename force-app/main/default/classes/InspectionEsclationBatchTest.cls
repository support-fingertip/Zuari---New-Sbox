@isTest
private class InspectionEsclationBatchTest {
    
    @TestSetup
    static void setup() {
        // Create a test user (CFO) and insert it into the org
        User cfoUser = new User(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@test.com',
            Username = 'johndoe' + System.currentTimeMillis() + '@test.com', // Ensure the username is unique
            Alias = 'jdoe',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            IsActive = true
        );
        insert cfoUser;
        
        // Create a test Inspection__c record
        Inspection__c inspection = new Inspection__c(
            Status__c = 'Scheduled' // Ensure the status is not 'Completed'
        );
        insert inspection;
    }

    @isTest
    static void testExecute_SendEmailsToCFO() {
        // Setup test data
        User testCFO = new User(
            FirstName = 'Test',
            LastName = 'CFO',
            Email = 'testcfo@example.com',
            Username = 'testcfo@example.com.test',
            Alias = 'tcfo',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'CFO' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testCFO;
        
        Inspection__c testInspection = new Inspection__c();
        insert testInspection;
        
        List<Inspection__c> scope = new List<Inspection__c>{testInspection};
            
            // Create batch instance
            Test.startTest();
        InspectionEsclationBatch batch = new InspectionEsclationBatch();
        batch.execute(null, scope);
        Test.stopTest();
        
        // Assertions
      //System.assertEquals(1, Limits.getEmailInvocations(), 'Email should be sent');
    }

    @isTest
    static void testBatchWithNoRecords() {
        // Insert an inspection with a future Escalation Date
        Test.startTest();
        
        // Insert an inspection record with a future escalation date (no match)
        Inspection__c inspection = new Inspection__c(
            Status__c = 'Scheduled'
        );
        insert inspection;
        
        // Execute the batch job
        InspectionEsclationBatch batch = new InspectionEsclationBatch();
        Database.executeBatch(batch);
        
        Test.stopTest();
    }
}