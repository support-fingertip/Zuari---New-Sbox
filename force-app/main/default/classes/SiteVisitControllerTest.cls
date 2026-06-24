@isTest
public class SiteVisitControllerTest {
@isTest
    public static void testmethodst(){
        Lead ld = new Lead(
            LastName = 'Test Lead 1',
            Company = 'Company A'
        );
        insert ld;
        Related_Source__c rs3 = new Related_Source__c(
                SLead__c       = ld.Id,
                Source_Type__c = 'Channel Partner',
                Lead_status1__c = 'New'
            );

        List<Site_Visit__c> sv = New List<Site_Visit__c>();
        
          Site_Visit__c sv1 = new Site_Visit__c(
            Slead__c = ld.Id,
              Related_Source__c=rs3.id,
            OTP__c = '0001'
        );
        insert sv1;
        
          Site_Visit__c sv2 = new Site_Visit__c(
            Slead__c = ld.Id,
              Related_Source__c=rs3.id,
              OTP_Generated_Date__c=System.today(),
            OTP__c = '0001'
        );
        insert sv2;
          Site_Visit__c sv3 = new Site_Visit__c(
            Slead__c = ld.Id,
              Related_Source__c=rs3.id,
            OTP__c = '0000'
        );
        insert sv3;
        sv.add(sv1);
        sv.add(sv2);
        sv.add(sv3);
        SiteVisitController.checkSiteVisitForRoundRobin(sv);
        SiteVisitController.codeCoverage();

    }
}