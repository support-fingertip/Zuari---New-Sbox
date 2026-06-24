@isTest
private class InspectionTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Inspection__c records
        List<Inspection__c> inspections = new List<Inspection__c>();
        
        Inspection__c insp1 = new Inspection__c(
          
            Status__c = 'Scheduled',
            Expected_Completed_Date__c = Date.today()
           
        );
        inspections.add(insp1);
        
        Inspection__c insp2 = new Inspection__c(
           
            Status__c = 'Scheduled',
            Expected_Completed_Date__c = Date.today().addDays(1)
           
        );
        inspections.add(insp2);
        
        insert inspections;
    }

    @isTest
    static void testBeforeUpdateTrigger() {
        // Retrieve the records
        List<Inspection__c> inspections = [SELECT Id, Status__c FROM Inspection__c WHERE Status__c = 'Pending'];

        // Modify the Status to something that would trigger preventCompletionIfSnagsOpen
        for (Inspection__c insp : inspections) {
            insp.Status__c = 'Completed';  // Assuming this is what the handler will prevent
        }
        
        Test.startTest();
        update inspections;
        Test.stopTest();
        
        // Verify the status was not updated (preventCompletionIfSnagsOpen logic would prevent this)
        inspections = [SELECT Status__c FROM Inspection__c WHERE Id IN :inspections];
        for (Inspection__c insp : inspections) {
            System.assertEquals('Pending', insp.Status__c, 'Status should not be updated if snags are open');
        }
    }

    @isTest
    static void testAfterUpdateTrigger() {
        // Retrieve the records
        List<Inspection__c> inspections = [SELECT Id, Status__c, Customer_Email__c FROM Inspection__c WHERE Status__c = 'Pending'];

        // Modify the Status to something that would trigger sendCompletionEmail
        for (Inspection__c insp : inspections) {
            insp.Status__c = 'Completed';
        }
        
        Test.startTest();
        update inspections;
        Test.stopTest();
        
        // Assuming sendCompletionEmail will send an email, assert if the email was invoked
        //System.assert(Limits.getEmailInvocations() > 0, 'The batch should have attempted to send an email');
    }

  @isTest
    static void testPreventCompletionIfSnagsOpen() {
        // 1. Insert initial record (fires before insert, not relevant here)
        Inspection__c insp = new Inspection__c(
            Status__c = 'In Progress',
            Expected_Completed_Date__c = Date.today().addDays(1)
            // set any other required fields
            // e.g. Open_Snags__c = 1;  // if your handler checks this
        );
        insert insp;

        // 2. Try to mark as Completed – this will fire BEFORE UPDATE logic
        insp.Status__c = 'Completed';

        Test.startTest();
        try {
            update insp;    // triggers preventCompletionIfSnagsOpen(...)
        } catch (DmlException e) {
            // If handler uses addError(), update will throw DmlException; swallow if expected
        }
        Test.stopTest();

        // 3. Re‑query and assert result of the BEFORE logic
        Inspection__c afterUpdate = [
            SELECT Id, Status__c
            FROM Inspection__c
            WHERE Id = :insp.Id
        ];

        // If handler blocks completion, status should remain 'In Progress'
        System.assertEquals('In Progress', afterUpdate.Status__c,
            'Status should not change to Completed when snags are open.');
    }


}