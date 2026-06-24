@isTest
public class newProjectBoardControllerClassTest {
    
    @TestSetup
    static void setup() {
        Project__c pr1 = new  Project__c();
        pr1.Name = 'Zuari Garden City';
      //  pr1.Project_Type__c='Apartments';
        insert pr1;
        
        Block__c blk = new Block__c();
        blk.Name='A';
        blk.Project__c=pr1.id;
        insert blk;
        
        Plot__c pl = new Plot__c();
        pl.Name = '101';
       
        // Pick a valid Status__c value dynamically
		List<Schema.PicklistEntry> statusValues = Plot__c.Status__c.getDescribe().getPicklistValues();
		pl.Status__c = statusValues[0].getValue();
        
        pl.Project__c = pr1.Id;
        pl.Block__c = 'A4';
        pl.Block_Lookup__c = blk.Id;
        pl.Carpet_Area__c = 850;
       // pl.Balcony_Sq_mts__c = 20;
       // pl.Balcony_Area__c = 100;
      //  pl.BHK_Type__c = '3 BHK + 2T';
      //  pl.Premium_Status__c = 'Premium';
        pl.Floor__c = '1';
      //  pl.Share__c = 'MHPL';
       // pl.Facing__c = 'EAST';
       // pl.Carpet_Sq_mts__c = 80;
       // pl.CA__c = 75;
        pl.Built_up_area__c = 1200;
        pl.UDS__c = 300;
      //  pl.UDS_Sq_mts__c = 50;
        pl.Super_built_up_area__c = 1500;
      //  pl.Price_Per_Sq_Ft__c = 5000;
        pl.Floor_Rise__c = 200;
        //pl.Premium_Charge__c = 100000;
       // pl.Covered_Park_Parking__c = 50000;
        pl.Other_Charges__c = 20000;
       // pl.Solar_Charges__c = 15000;
        pl.GST1__c = 18;
        
        insert pl;
        
        
    }
     @IsTest
    static void projectBoardControllerClassTest() {
        id projectId = [Select id from project__c limit 1].id;
        Test.startTest();
        newProjectBoardControllerClass.getProjects();
        newProjectBoardControllerClass.getPlots(projectId);
        newProjectBoardControllerClass.getPicklistValues('Plot__c','Status__c');
        newProjectBoardControllerClass.getBlockNames(projectId);
        Test.stopTest();
    }

}