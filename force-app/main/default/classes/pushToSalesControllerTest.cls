@istest
public class pushToSalesControllerTest {
 @isTest
    public static void method() {
      
          Lead lad= new Lead();
        lad.LastName='test';
        lad.Allocated_Project__c = 'Zuari Garden City';
        lad.Phone = '9182748514';
        lad.Source_Type__c='Digital Marketing';
        lad.Lead_source__c = 'Facebook';
        lad.Lead_Status__c ='New';
        lad.OwnerId = UserInfo.getUserId();
        lad.Lead_Assigned__c = false;
        lad.IsPushed__c = true;
        lad.Company='test';
        insert lad;
		
        Site_Visit__c sv=new Site_Visit__c();  
        sv.Date__c=System.now()+3;
        sv.Status__c='Scheduled';
        sv.Project__c='Zuari Garden City';
        sv.SLead__c=lad.id;
        insert sv;
        Test.startTest();
        pushToSalesController.moveToSales(lad.Id, 'hgbvui');
        pushToSalesController.isSiteVisitScheduled(lad.Id);
        pushToSalesController.CheckFollowups(lad.Id);
        Test.stopTest();
    }
}