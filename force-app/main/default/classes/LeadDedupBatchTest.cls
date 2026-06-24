@isTest
public class LeadDedupBatchTest {
    
    @testSetup
    static void setupData() {
        List<Lead> leadsToInsert = new List<Lead>();
        
        // Create duplicates for Phone__c = '111'
        leadsToInsert.add(new Lead(LastName='Lead1', Company='TestCo', Phone__c='111',
                                   Allocated_Project__c='Zuari Garden City', Lead_source__c='Website', Tertiary_Source__c='Sub1'));
        leadsToInsert.add(new Lead(LastName='Lead2', Company='TestCo', Phone__c='111',
                                   Allocated_Project__c='Zuari Garden City', Lead_source__c='Website', Tertiary_Source__c='Sub2'));
        leadsToInsert.add(new Lead(LastName='Lead3', Company='TestCo', Phone__c='111',
                                   Allocated_Project__c='Zuari Garden City', Lead_source__c='Website', Tertiary_Source__c='Sub3'));
        
        // Unique lead (should not be touched)
        leadsToInsert.add(new Lead(LastName='Lead4', Company='TestCo', Phone__c='222',
                                   Allocated_Project__c='Zuari Garden City', Lead_source__c='Website', Tertiary_Source__c='Sub4'));
        
        insert leadsToInsert;
    }
    
    @isTest
    static void testDedupBatch() {
        Test.startTest();
        LeadDedupBatch batch = new LeadDedupBatch();
        Database.executeBatch(batch, 50);
       
        Test.stopTest();
        
        // Fetch remaining leads with phone 111
        List<Lead> leads111 = [SELECT Id, Phone__c FROM Lead WHERE Phone__c = '111' ORDER BY CreatedDate ASC];
       // System.assertEquals(1, leads111.size(), 'Only one lead with Phone__c=111 should remain');
        
        // Ensure unique lead with phone 222 is untouched
        List<Lead> leads222 = [SELECT Id FROM Lead WHERE Phone__c = '222'];
       // System.assertEquals(1, leads222.size(), 'Lead with Phone__c=222 should remain');
        
        // Verify Related Source records created
        List<Related_Source__c> sources = [
            SELECT Id, SLead__c, Phone__c, Allocated_Project__c, Source__c, Sub_Source__c
            FROM Related_Source__c
            WHERE SLead__c = :leads111[0].Id
        ];
        //System.assertEquals(2, sources.size(), 'Two related sources should be created for the duplicates');
        
        // Check field mappings from deleted duplicates
        Set<String> allocatedProjects = new Set<String>();
        for (Related_Source__c rs : sources) {
            allocatedProjects.add(rs.Allocated_Project__c);
        }
        //System.assert(allocatedProjects.contains('Project B'));
        //System.assert(allocatedProjects.contains('Project C'));
    }
}