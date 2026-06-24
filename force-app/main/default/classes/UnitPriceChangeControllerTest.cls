@isTest
public class UnitPriceChangeControllerTest {
    @isTest
    public static void testmethodunit(){
        
         Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c = true;
        insert pjt;
        
         plot__c ut = new Plot__c();
        ut.Name='Test plot';
      //ut.Status__c='Available';
        ut.Project__c = pjt.Id;
        ut.BHK_Type__c = '1BHK';
        insert ut;
       List<Plot__c> pltList = new List<Plot__c>();
        pltList.add(ut);
        
        Test.StartTest();
        UnitPriceChangeController.getuserdetails();
        UnitPriceChangeController.getTowers();
        UnitPriceChangeController.getBlocks();
        UnitPriceChangeController.getUnitStatus();
        UnitPriceChangeController.getBhkType();
        UnitPriceChangeController.getcon(UserInfo.getUserId(),pjt.Id,'1BHK','','');
        UnitPriceChangeController.updateOwner(pltList,10000);
        Test.StopTest();
        
    }

}