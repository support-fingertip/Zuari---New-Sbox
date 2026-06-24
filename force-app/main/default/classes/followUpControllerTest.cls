@isTest
public class followUpControllerTest {
    
    public static testMethod void getFollowUpDetailstest()
    {
        
        Lead lead=new Lead();
        lead.Lastname = 'Test Lead';
        lead.Company = 'TestCompany';
        lead.Phone__c = '9090909090';
        lead.Secondary_Phone__c = '9898989898';
        lead.Email = 'standarduser@testorgfil.com';
        insert lead;
        //follow_up__c fu = new follow_up__c();
        //fu.SLead__c = lead.Id;
        //fu.Status__c = 'Scheduled';
        //datetime dt = system.now();
        //fu.Scheduled_Date__c = dt.addMinutes(5);
        //insert fu;
        //System.debug(followUpController.getFollowUpDetails(lead.id));
        System.debug(followUpController.dateFormat('16/09/2023, 18:00:00'));
    }
}