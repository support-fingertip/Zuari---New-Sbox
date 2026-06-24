@isTest
public class AddRelatedSourceNoteController_Test {

    @testSetup
    static void setupData() {
        // Create a User for running context
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
             IsActive = true,
            ProfileId = p.Id
        );
        insert u;

        // Create a Related_Source__c record
        Related_Source__c rs = new Related_Source__c(
           
            Last_Note__c = null,
            Execuive_Count__c = 0,
            TL_RHS_Review__c = 'ewyuew'
        );
        insert rs;
        
        Site_Visit__c sv = new Site_Visit__c(
        Site_Visit_Remarks__c='null',Related_Source__c =rs.id
        );
        insert sv;
    }

    @isTest
    static void testUpdateLastNote_FirstNote() {
        // Set User Context
        User u = [SELECT Id FROM User LIMIT 1];
       

            Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];

            Test.startTest();
            AddRelatedSourceNoteController.updateLastNote(rs.Id, 'First test note');
            Test.stopTest();

           
      
    }
        @isTest
    static void testUpdateLastNote_SvFirstNote() {
        // Set User Context
        User u = [SELECT Id FROM User LIMIT 1];
       

            Site_Visit__c rs = [SELECT Id FROM Site_Visit__c LIMIT 1];

            Test.startTest();
            AddRelatedSourceNoteController.updateSiteVisitRemark(rs.Id, 'First test note');
            Test.stopTest();

           
      
    }


    @isTest
    static void testUpdateLastNote_MultipleNotes() {
        User u = [SELECT Id FROM User LIMIT 1];

      
            Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];

            // Add first note
            AddRelatedSourceNoteController.updateLastNote(rs.Id, 'Note 1');

            // Add second note
            Test.startTest();
            AddRelatedSourceNoteController.updateLastNote(rs.Id, 'Note 2');
        AddRelatedSourceNoteController.fetchLeadLastNotes(rs.Id);
            Test.stopTest();

          
    }

    @isTest
    static void testUpdateLastNote_BlankIgnored() {
        User u = [SELECT Id FROM User LIMIT 1];
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];

      
            // Passing blank note should do nothing
            Test.startTest();
            AddRelatedSourceNoteController.updateLastNote(rs.Id, '');
            Test.stopTest();

          

           
        
    }

    @isTest
    static void testFetchLeadLastNotes() {
        // Prepare Related Source with notes
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];
        rs.Last_Note__c = '\nCall Summary 1: Test User: Hello\nCall Summary 2: Test User: Hi\n';
        update rs;

        Test.startTest();
        AddRelatedSourceNoteController.updateTLRHSNote(rs.Id, 'Test Note');
        Test.stopTest();

     

        
    }
}