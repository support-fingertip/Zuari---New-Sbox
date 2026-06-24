@isTest
public class ReVisitControllerTest {
      public static testMethod void getFollowUpDetailstest()
    {
        
        Lead lead=new Lead();
        lead.Lastname = 'Test Lead';
        lead.Company = 'TestCompany';
        lead.Phone__c = '9090909090';
        lead.Secondary_Phone__c = '9898989898';
        lead.Email = 'standarduser@testorgfil.com';
        insert lead;
        
        Site_Visit__c sv=new Site_Visit__c();  
        sv.Date__c=System.now()+3;
        sv.Status__c='Scheduled';
        sv.Project__c='Zuari Garden City';
        sv.SLead__c=lead.id;
        sv.Revisit_Count__c=0;
        sv.Reschedule_Date__c=System.now()+3;
        insert sv;
        //follow_up__c fu = new follow_up__c();
        //fu.SLead__c = lead.Id;
        //fu.Status__c = 'Scheduled';
        //datetime dt = system.now();
        //fu.Scheduled_Date__c = dt.addMinutes(5);
        //insert fu;
        ReVisitController.updateLastNote(sv.id,'test', system.now());
       }


}