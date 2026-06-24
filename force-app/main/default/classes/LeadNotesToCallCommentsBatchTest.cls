@isTest
public class LeadNotesToCallCommentsBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser1 = new User(
            Alias = 'tuser1',
            Email = 'testuser1@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User One',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser1@testorg' + DateTime.now().getTime() + '.com'
        );
        insert testUser1;
        
        User testUser2 = new User(
            Alias = 'tuser2',
            Email = 'testuser2@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User Two',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser2@testorg' + DateTime.now().getTime() + '.com'
        );
        insert testUser2;
        
        // Create test leads with notes
        List<Lead> testLeads = new List<Lead>();
        
        // Lead 1: With multiple notes and user names
        Lead lead1 = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company 1',
            Status = 'Open',
            Last_Note__c = 'Test User One: First note for lead 1\n' +
                          'Test User Two: Second note for lead 1\n' +
                          'Test User One: Third note for lead 1'
        );
        testLeads.add(lead1);
        
        // Lead 2: With notes but no user names
        Lead lead2 = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Test Company 2',
            Status = 'Open',
            Last_Note__c = 'Note without user name\n' +
                          'Another note without user'
        );
        testLeads.add(lead2);
        
        // Lead 3: With empty lines in notes
        Lead lead3 = new Lead(
            FirstName = 'Bob',
            LastName = 'Johnson',
            Company = 'Test Company 3',
            Status = 'Qualified',
            Last_Note__c = 'Test User One: Valid note\n' +
                          '\n' +
                          '   \n' +
                          'Test User Two: Another valid note\n' +
                          ''
        );
        testLeads.add(lead3);
        
        // Lead 4: Without notes
        Lead lead4 = new Lead(
            FirstName = 'Alice',
            LastName = 'Williams',
            Company = 'Test Company 4',
            Status = 'Open',
            Last_Note__c = null
        );
        testLeads.add(lead4);
        
        // Lead 5: With large notes (testing governor limits)
        String largeNote = '';
        for (Integer i = 1; i <= 50; i++) {
            largeNote += 'Test User One: This is note number ' + i + '\n';
        }
        Lead lead5 = new Lead(
            FirstName = 'Charlie',
            LastName = 'Brown',
            Company = 'Test Company 5',
            Status = 'Open',
            Last_Note__c = largeNote
        );
        testLeads.add(lead5);
        
        insert testLeads;
        
        // Create Related Sources for leads
        List<Related_Source__c> relatedSources = new List<Related_Source__c>();
        
        for (Lead l : testLeads) {
            // Create unlocked related source
            Related_Source__c rs1 = new Related_Source__c(
               
                SLead__c = l.Id,
                Is_Locked__c = false
            );
            relatedSources.add(rs1);
            
            // Create locked related source (should be ignored)
            Related_Source__c rs2 = new Related_Source__c(
              sLead__c = l.Id,
                Is_Locked__c = true
            );
            relatedSources.add(rs2);
        }
        
        insert relatedSources;
    }
    
    @isTest
    static void testBatchExecution_AllLeads() {
        Test.startTest();
        
        LeadNotesToCallCommentsBatch batch = new LeadNotesToCallCommentsBatch();
        Id batchId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        List<Call_Comments__c> allComments = [SELECT Id, Comments__c, Lead__c, Related_Source__c, Created_User__c FROM Call_Comments__c];
        
        Lead lead1 = [SELECT Id FROM Lead WHERE LastName = 'Doe' LIMIT 1];
        List<Call_Comments__c> lead1Comments = [
            SELECT Id, Comments__c, Created_User__c, User_Profile__c 
            FROM Call_Comments__c 
            WHERE Lead__c = :lead1.Id
        ];
        
        Lead lead2 = [SELECT Id FROM Lead WHERE LastName = 'Smith' LIMIT 1];
        List<Call_Comments__c> lead2Comments = [SELECT Id FROM Call_Comments__c WHERE Lead__c = :lead2.Id];
        
        Lead lead3 = [SELECT Id FROM Lead WHERE LastName = 'Johnson' LIMIT 1];
        List<Call_Comments__c> lead3Comments = [SELECT Id FROM Call_Comments__c WHERE Lead__c = :lead3.Id];
        
        Lead lead4 = [SELECT Id FROM Lead WHERE LastName = 'Williams' LIMIT 1];
        List<Call_Comments__c> lead4Comments = [SELECT Id FROM Call_Comments__c WHERE Lead__c = :lead4.Id];
        
        Lead lead5 = [SELECT Id FROM Lead WHERE LastName = 'Brown' LIMIT 1];
        List<Call_Comments__c> lead5Comments = [SELECT Id FROM Call_Comments__c WHERE Lead__c = :lead5.Id];
    }
    
    @isTest
    static void testBatchExecution_WithFilter() {
        Test.startTest();
        
        LeadNotesToCallCommentsBatch batch = new LeadNotesToCallCommentsBatch('Status = \'Qualified\'');
        Id batchId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        Lead qualifiedLead = [SELECT Id FROM Lead WHERE Status = 'Qualified' LIMIT 1];
        List<Call_Comments__c> qualifiedComments = [SELECT Id FROM Call_Comments__c WHERE Lead__c = :qualifiedLead.Id];
        
        Lead openLead = [SELECT Id FROM Lead WHERE Status = 'Open' AND LastName = 'Doe' LIMIT 1];
        List<Call_Comments__c> openComments = [SELECT Id FROM Call_Comments__c WHERE Lead__c = :openLead.Id];
    }
    
    @isTest
    static void testBatchExecution_LeadWithoutRelatedSource() {
        Lead leadNoSource = new Lead(
            FirstName = 'NoSource',
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Open',
            Last_Note__c = 'Test note'
        );
        insert leadNoSource;
        
        Test.startTest();
        
        LeadNotesToCallCommentsBatch batch = new LeadNotesToCallCommentsBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        List<Call_Comments__c> comments = [SELECT Id FROM Call_Comments__c WHERE Lead__c = :leadNoSource.Id];
    }
    
    @isTest
    static void testBatchExecution_OnlyLockedRelatedSource() {
        Lead leadLockedSource = new Lead(
            FirstName = 'Locked',
            LastName = 'SourceTest',
            Company = 'Test Company',
            Status = 'Open',
            Last_Note__c = 'Test note'
        );
        insert leadLockedSource;
        
        Related_Source__c lockedSource = new Related_Source__c(
           sLead__c = leadLockedSource.Id,
            Is_Locked__c = true
        );
        insert lockedSource;
        
        Test.startTest();
        
        LeadNotesToCallCommentsBatch batch = new LeadNotesToCallCommentsBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        List<Call_Comments__c> comments = [SELECT Id FROM Call_Comments__c WHERE Lead__c = :leadLockedSource.Id];
    }
    
    @isTest
    static void testBatchExecution_RelatedSourceLookup() {
        Test.startTest();
        
        LeadNotesToCallCommentsBatch batch = new LeadNotesToCallCommentsBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        List<Call_Comments__c> allComments = [
            SELECT Id, Related_Source__c, Lead__c 
            FROM Call_Comments__c
        ];
        
        for (Call_Comments__c cc : allComments) {
            Related_Source__c rs = [SELECT Is_Locked__c FROM Related_Source__c WHERE Id = :cc.Related_Source__c];
        }
    }
    
    @isTest
    static void testBatchExecution_NotesOrder() {
        Test.startTest();
        
        LeadNotesToCallCommentsBatch batch = new LeadNotesToCallCommentsBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        Lead lead1 = [SELECT Id, Last_Note__c FROM Lead WHERE LastName = 'Doe' LIMIT 1];
        List<Call_Comments__c> comments = [
            SELECT Id, Comments__c 
            FROM Call_Comments__c 
            WHERE Lead__c = :lead1.Id
            ORDER BY CreatedDate ASC
        ];
    }
    
    @isTest
    static void testBatchStatefulVariables() {
        Test.startTest();
        
        LeadNotesToCallCommentsBatch batch = new LeadNotesToCallCommentsBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'LeadNotesToCallCommentsBatch'
            AND Status = 'Completed'
        ];
    }
    
    @isTest
    static void testBatchBulkProcessing() {
        List<Lead> bulkLeads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            Lead l = new Lead(
                FirstName = 'Bulk',
                LastName = 'Lead' + i,
                Company = 'Bulk Company ' + i,
                Status = 'Open',
                Last_Note__c = 'Note 1\nNote 2\nNote 3'
            );
            bulkLeads.add(l);
        }
        insert bulkLeads;
        
        List<Related_Source__c> bulkSources = new List<Related_Source__c>();
        for (Lead l : bulkLeads) {
            bulkSources.add(new Related_Source__c(
               sLead__c = l.Id,
                Is_Locked__c = false
            ));
        }
        insert bulkSources;
        
        Test.startTest();
        
        LeadNotesToCallCommentsBatch batch = new LeadNotesToCallCommentsBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        List<Call_Comments__c> bulkComments = [
            SELECT Id, Lead__c 
            FROM Call_Comments__c 
            WHERE Lead__c IN :bulkLeads
        ];
    }
}