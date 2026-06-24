@isTest
public class MakeCallControllerTest {

    public static testmethod void testCall(){
         Lead lead1 = new Lead();
        lead1.Lastname = 'Test Lead';
        lead1.Company = 'TestCompany';
        lead1.Country_Code__c='91';
        lead1.Lead_source__c = 'Website';
        lead1.Allocated_Project__c = 'Zuari Garden City';
        lead1.Phone__c = '9090909090';
        lead1.Secondary_Country_Code__c='93';
        lead1.Secondary_Phone__c = '9898989898';
        lead1.Email = 'standarduser@testorgfil.com';
        lead1.Site_Visit_Schedule_Date__c = Datetime.newInstance(2025, 10, 8, 0, 0, 0);
        insert lead1;
        
         Related_Source__c existingRS = new Related_Source__c(
                SLead__c       = lead1.Id,
                Source_Type__c = 'Digital Marketing',
                Lead_status1__c = 'New',
             Phone__c = '1467436473'
            );
            insert existingRS;
        
        MCUBE_Object_Api__c  m  = new MCUBE_Object_Api__c ();
        m.name = 'Lead';
        m.Field_to_Compare_Mobile_Incoming_Number__c = 'Phone__c';
        m.Secondary_Mobile_No__c = 'Secondary_Phone__c';
        m.field__c = 'FirstName';
        m.field1__c = 'LastName';
        m.field2__c = 'company';
        m.Value__c = 'company';
        m.value1__c = 'company';
        m.value2__c = 'company';
        insert m;
        
        MakeCallController.readContacts(existingRS.Id);
        MakeCallController.callCustomer(existingRS.Id,'9090909090');
        MakeCallController.callCustomer(existingRS.Id,'+93 9898989898');
        MakeCallController.readstatus(existingRS.Id);
        
         MakeCallController.readContacts(lead1.Id);
        MakeCallController.callCustomer(lead1.Id,'9090909090');
        MakeCallController.callCustomer(lead1.Id,'+93 9898989898');
        MakeCallController.readstatus(lead1.Id);
        
        
        Lead lead = new Lead();
        lead.lastname = 'Test Lead';
        lead.Company = 'TestCompany';
        //lead.Country_Code__c='91';
        lead.Phone__c = '9090909090';
        lead.Allocated_Project__c = 'Zuari Garden City';
        //lead.Secondary_Country_Code__c='93';
        //lead.Secondary_Phone__c = '9898989898';
        lead.Email = 'standarduser@testorgfil.com';
        insert lead;
        
        Task tsk = new Task();
        tsk.Subject = 'Call';
        tsk.WhoId = lead.Id;
     //   insert tsk;
        MakeCallController.readContacts(lead1.Id);
    }
    
    @isTest
static void testUpdateLastNote() {
    
    Lead lead1 = new Lead();
        lead1.Lastname = 'Test Lead';
        lead1.Company = 'TestCompany';
        lead1.Country_Code__c='91';
        lead1.Lead_source__c = 'Website';
        lead1.Allocated_Project__c = 'Zuari Garden City';
        lead1.Phone__c = '9090909090';
        lead1.Secondary_Country_Code__c='93';
        lead1.Secondary_Phone__c = '9898989898';
        lead1.Email = 'standarduser@testorgfil.com';
        lead1.Site_Visit_Schedule_Date__c = Datetime.newInstance(2025, 10, 8, 0, 0, 0);
        insert lead1;

    // Get existing Related Source from your test data
    Related_Source__c rs = new Related_Source__c(
                SLead__c       = lead1.Id,
                Source_Type__c = 'Digital Marketing',
                Lead_status1__c = 'New',
             Phone__c = '1467436473'
            );
            insert rs;

    Test.startTest();

    MakeCallController.updateLastNote(
        rs.Id,
        'Test Call Summary',
        true,          // isPrimary
        false,         // isSecondary
        Datetime.now().addDays(1), // Follow up date
        'Follow Up Call',
        Datetime.now().addDays(2)  // Site visit date
    );

    Test.stopTest();

    // Assertions (important for coverage stability)
    System.assertEquals(
        1,
        [SELECT COUNT() FROM Call_Comments__c WHERE Related_Source__c = :rs.Id]
    );

    System.assertEquals(
        1,
        [SELECT COUNT() FROM Follow_up__c WHERE Related_Source__c = :rs.Id]
    );

    System.assertEquals(
        1,
        [SELECT COUNT() FROM Site_Visit__c WHERE Related_Source__c = :rs.Id]
    );
}
}