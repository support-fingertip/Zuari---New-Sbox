@isTest
private class LeadToRelatedSourceBatchTest {
    
   
    @testSetup
    static void setupTestData() {
        
        // Create Record Type for Related Source (if exists)
        // Note: Adjust based on your org's record type
        
        // Create Campaign
        Campaign camp = new Campaign(
            Name = 'Test Campaign',
            IsActive = true
        );
        insert camp;
        
        // Create Channel Partner Account
        Account cpAccount = new Account(
            Name = 'Test Channel Partner'
        );
        insert cpAccount;
        
        // Create test Leads with various scenarios
        List<Lead> testLeads = new List<Lead>();
        
        // Lead 1 - Complete information
        Lead lead1 = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company 1',
            Email = 'john.doe@test.com',
            Phone = '9876543210',
            MobilePhone = '9876543210',
            Status = 'Open',
            LeadSource = 'Web',
            Rating = 'Hot',
            Street = '123 Test Street',
            City = 'Bangalore',
            State = 'Karnataka',
            Country = 'India',
            PostalCode = '560001',
            Industry = 'Technology'
            
        );
        testLeads.add(lead1);
        
        // Lead 2 - Minimal information
        Lead lead2 = new Lead(
            LastName = 'Smith',
            Company = 'Test Company 2',
            Email = 'smith@test.com',
            Phone = '9876543220',
            Status = 'Working',
            LeadSource = 'Phone'
        );
        testLeads.add(lead2);
        
        // Lead 3 - For Re-Opened scenario
        Lead lead3 = new Lead(
            FirstName = 'Jane',
            LastName = 'Wilson',
            Company = 'Test Company 3',
            Email = 'jane.wilson@test.com',
            Phone = '9876543230',
            Status = 'Qualified',
            LeadSource = 'Referral'
        );
        testLeads.add(lead3);
        
        // Lead 4 - For Re-Engaged scenario
        Lead lead4 = new Lead(
            FirstName = 'Bob',
            LastName = 'Brown',
            Company = 'Test Company 4',
            Email = 'bob.brown@test.com',
            Phone = '9876543240',
            Status = 'Nurturing',
            LeadSource = 'Advertisement'
        );
        testLeads.add(lead4);
        
        // Lead 5 - Converted Lead
        Lead lead5 = new Lead(
            FirstName = 'Alice',
            LastName = 'Green',
            Company = 'Test Company 5',
            Email = 'alice.green@test.com',
            Phone = '9876543250',
            Status = 'Qualified',
            LeadSource = 'Web'
        );
        testLeads.add(lead5);
        
        insert testLeads;
        
        // Create Related Source records for each Lead
        List<Related_Source__c> relatedSources = new List<Related_Source__c>();
        
        // Get Record Type if exists
       
        
        for(Lead ld : testLeads) {
            Related_Source__c rs = new Related_Source__c(
                SLead__c = ld.Id,
                Name__c = 'Test Source'
            );
            relatedSources.add(rs);
            
            // Add a second Related Source for lead1 to test multiple sources
            if(ld.LastName == 'Doe') {
                Related_Source__c rs2 = new Related_Source__c(
                    SLead__c = ld.Id,
                    Name__c = 'Test Source 2'
                );
                relatedSources.add(rs2);
            }
        }
        
        insert relatedSources;
    }
    
    /**
     * Test batch execution with all Leads
     */
    @isTest
    static void testBatchExecutionAllLeads() {
        Test.startTest();
        
        // Execute batch without filter
        LeadToRelatedSourceBatch batch = new LeadToRelatedSourceBatch();
        Id batchJobId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
       
    }
    
  
}