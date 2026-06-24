@isTest
public class transferLeadControllerTest
{
    @isTest
    public static void TestMech()
    {
              // Create a Lead record
       Lead testLead = new Lead(
            LastName = 'Test Lead1',
            Allocated_Project__c = 'Zuari Garden City',
            Email = 'leadtest@test.com',
            Secondary_Email__c = 'leadtest2@test.com',
           Company='test'
        );
        insert testLead;
        
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@fingertip.com',
            Username = 'testuser@fingertip.com',
            ProfileId = profile.Id,
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        
        );
        insert testUser;
        
        transferLeadController.getRecordAccess(testLead.id);
        transferLeadController.getUserType();
        transferLeadController.getPickListValues();
        transferLeadController.getAllUsers(testLead.id);
        transferLeadController.getCountryAndCode();
         transferLeadController.getProjectNames(testLead.id);
        //.moveToSales(testLead.id,'ATMOS Silverwoods','tReason',false,testUser.id);
        
    }
}