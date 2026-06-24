@isTest
public class AddNoteControllerTest {
     @isTest
    public static void notes()
    {
        
        Lead ld = new Lead();
        ld.LastName = 'test';
        ld.Last_Note__c = 'test';
       // ld.Source_Type__c='Digital Marketing';
       // ld.Lead_source__c = 'Facebook';
        ld.Phone = '1234567890';
        ld.Company = 'testcompany';
        ld.TL_RHS_Review__c = 'ewyuew';
        insert ld;
        
        AddNoteController.updateLastNote(ld.Id, 'Test Note');
        AddNoteController.updateTLRHSNote(ld.Id, 'Test Note');
        AddNoteController.fetchLeadLastNotes(ld.Id);
    }
}