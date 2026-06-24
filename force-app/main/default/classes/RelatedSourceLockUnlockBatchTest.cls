@isTest
public class RelatedSourceLockUnlockBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create test leads
        List<Lead> testLeads = new List<Lead>();
        for(Integer i = 0; i < 3; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test' + i,
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                Status = 'Open - Not Contacted'
            ));
        }
        insert testLeads;
        
        // Create test related sources
        List<Related_Source__c> testSources = new List<Related_Source__c>();
        
        for(Lead l : testLeads) {
            // Add sources with different types
            testSources.add(new Related_Source__c(
                Name__c = 'Re-Opened Source',
                SLead__c = l.Id,
                Lead_Type__c = 'Re-Opened',
                Is_Locked__c = true
            ));
            
            testSources.add(new Related_Source__c(
                Name__c = 'Re-Engaged Source',
                SLead__c = l.Id,
                Lead_Type__c = 'Re-Engaged',
                Is_Locked__c = true
            ));
            
            testSources.add(new Related_Source__c(
                Name__c = 'Fresh Source',
                SLead__c = l.Id,
                Lead_Type__c = 'Fresh',
                Is_Locked__c = false
            ));
        }
        
        insert testSources;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        
        // Run the batch
        RelatedSourceLockUnlockBatch batch = new RelatedSourceLockUnlockBatch();
        Database.executeBatch(batch);
        
        Test.stopTest();
        

        
      
    }
    
    
}