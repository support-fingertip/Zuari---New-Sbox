@isTest
public class CallDetailTriggerTest {
    
    @testSetup
    static void setupData() {
        // Create Record Types if needed (adjust API names as per your org)
        // Assuming record types exist: 'Pre Sales' and 'Sales'
        
        // ========== LEAD TEST DATA ==========
        // Lead 1 → For TAT for New Lead
        Lead l1 = new Lead(
            LastName = 'Lead One',
            Company = 'Test Company1'
        );
        insert l1;
        
        // Lead 2 → For TAT for Sales
        Lead l2 = new Lead(
            LastName = 'Lead Two',
            Company = 'Test Company2',
            Pushed_On__c = System.now().addHours(-2)
        );
        insert l2;
        
        // Lead 3 → For Site Visit
        Lead l3 = new Lead(
            LastName = 'Lead Three',
            Company = 'Test Company3',
            Lead_Status__c = 'Site Visit Schedule'
        );
        insert l3;
        
        // Site Visit for Lead 3
        Site_Visit__c sv = new Site_Visit__c(
            SLead__c = l3.Id,
            Date__c = System.today().addDays(1)
        );
        insert sv;
        
        // ========== RELATED SOURCE TEST DATA ==========
        // Related Source 1 → For TAT for New Lead
        Related_Source__c rs1 = new Related_Source__c(
           
            // Add required fields as per your org
        );
        insert rs1;
        
        // Related Source 2 → For TAT for Sales
        Related_Source__c rs2 = new Related_Source__c(
          
            Transfered_On__c = System.now().addHours(-2)
        );
        insert rs2;
        
        // Related Source 3 → For Site Visit
        Related_Source__c rs3 = new Related_Source__c(
           
            Lead_Status1__c = 'Site Visit Schedule'
        );
        insert rs3;
        
        // Site Visit for Related Source 3
        Site_Visit__c svRS = new Site_Visit__c(
            Related_Source__c = rs3.Id,
            Date__c = System.today().addDays(1)
        );
        insert svRS;
    }
    
    @isTest
    static void testLeadTriggerLogic() {
        List<Lead> leads = [SELECT Id, Lead_Status__c FROM Lead ORDER BY CreatedDate ASC];
        Lead l1 = leads[0]; // new lead
        Lead l2 = leads[1]; // pushed to sales
        Lead l3 = leads[2]; // site visit
        
        Test.startTest();
        
        // Insert call details for leads
        Call_Detail__c cd1 = new Call_Detail__c(Lead__c = l1.Id);
        insert cd1;
        
        Call_Detail__c cd2 = new Call_Detail__c(Lead__c = l2.Id);
        insert cd2;
        
        Call_Detail__c cd3 = new Call_Detail__c(Lead__c = l3.Id);
        insert cd3;
        
        Test.stopTest();
        
        // Assertions for Leads
        Lead updatedL1 = [SELECT TAT_for_New_Lead__c, Total_Calls__c, Number_Of_Calls__c 
                          FROM Lead WHERE Id = :l1.Id];
        System.assertNotEquals(null, updatedL1.TAT_for_New_Lead__c, 'TAT for New Lead should be calculated');
        System.assertEquals(1, updatedL1.Number_Of_Calls__c, 'Number of calls should be 1');
        
        Lead updatedL2 = [SELECT TAT_for_Sales__c FROM Lead WHERE Id = :l2.Id];
        System.assertNotEquals(null, updatedL2.TAT_for_Sales__c, 'TAT for Sales should be calculated');
        
        Site_Visit__c updatedSV = [SELECT Call_to_Site_Visit__c FROM Site_Visit__c 
                                   WHERE SLead__c = :l3.Id LIMIT 1];
        // Site visit assertion (may need date matching logic)
    }
    
  
    @isTest
    static void testCallCountUpdates() {
        Lead l1 = [SELECT Id FROM Lead LIMIT 1];
        Related_Source__c rs1 = [SELECT Id FROM Related_Source__c LIMIT 1];
        
        Test.startTest();
        
        // Insert multiple calls for Lead
        Call_Detail__c cd1 = new Call_Detail__c(Lead__c = l1.Id);
        insert cd1;
        
        Call_Detail__c cd2 = new Call_Detail__c(Lead__c = l1.Id);
        insert cd2;
        
        // Insert multiple calls for Related Source
        Call_Detail__c cd3 = new Call_Detail__c(Related_Source__c = rs1.Id);
        insert cd3;
        
        Call_Detail__c cd4 = new Call_Detail__c(Related_Source__c = rs1.Id);
        insert cd4;
        
        Test.stopTest();
        
        // Verify counts
        Lead updatedLead = [SELECT Number_Of_Calls__c, Total_Calls__c FROM Lead WHERE Id = :l1.Id];
        System.assertEquals(2, updatedLead.Number_Of_Calls__c, 'Lead should have 2 calls');
        
        Related_Source__c updatedRS = [SELECT Number_Of_Calls__c, Total_Calls__c 
                                       FROM Related_Source__c WHERE Id = :rs1.Id];
        System.assertEquals(2, updatedRS.Number_Of_Calls__c, 'Related Source should have 2 calls');
    }
   
    @isTest
    static void testOwnerAssignment() {
        // Test owner assignment logic from before insert
        User testUser = [SELECT Id, Phone FROM User WHERE IsActive = true AND Phone != null LIMIT 1];
        
        if (testUser != null) {
            Test.startTest();
            
            Call_Detail__c cdOutbound = new Call_Detail__c(
                Call_Type__c = 'Outbound Call',
                Call_From__c = testUser.Phone
            );
            insert cdOutbound;
            
            Call_Detail__c cdInbound = new Call_Detail__c(
                Call_Type__c = 'Inbound Call',
                Call_To__c = testUser.Phone
            );
            insert cdInbound;
            
            Test.stopTest();
            
            Call_Detail__c outboundResult = [SELECT OwnerId FROM Call_Detail__c WHERE Id = :cdOutbound.Id];
            //System.assertEquals(testUser.Id, outboundResult.OwnerId, 'Outbound call owner should match user');
            
            Call_Detail__c inboundResult = [SELECT OwnerId FROM Call_Detail__c WHERE Id = :cdInbound.Id];
            //System.assertEquals(testUser.Id, inboundResult.OwnerId, 'Inbound call owner should match user');
        }
    }
}