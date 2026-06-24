@isTest
public class SwappingUnitControllerTest
{
    @isTest
    public static void testMech()
    {
        //Master_Lead__c msl = new Master_Lead__c();
        //msl.Name='Master';
        //msl.Lead_Age__c=12;
        //insert msl;
       
            Lead ld11 = new Lead();
            ld11.LastName='Test lead';
            ld11.Lead_Assigned__c=true;
          //ld11.Projects__c='Apartments';
          //ld11.Allocated_Project__c='Mantri Serenit';
            ld11.Reassigned_By__c=UserInfo.getUserId();
            ld11.Re_assigned_date__c = system.now();
            // ld11.Lead_status__c='New';
           // ld11.Email__c='patil@gmail.com';
          //ld11.Lead_source__c ='Facebook';
            ld11.Phone__c='9898767998';
            ld11.Secondary_Phone__c='8763748300';
            ld11.Company='test';
            //ld11.Master_Lead__c=msl.id;
            insert ld11;
          
          
         
        
        Booking__c ld1 = new Booking__c ();
       // ld1.Followup_Date__c= system.today();
       // ld1.Followup_Subject__c = 'test22';
      //  ld1.Last_Comment__c='test22';
        ld1.Status__c='Welcome call';
        ld1.Project__c='Zuari Garden City';
        ld1.Sub_Status__c ='Positive';
         ld1.Payment_Type__c='Custom';
     //   ld1.Sale_Agreement_Completed__c =false;
        ld1.Funding_Type__c = 'Loan';
        insert ld1;
        
        Booking__c ld = new Booking__c ();
     //   ld.Followup_Date__c= system.today();
      //  ld.Followup_Subject__c = 'test22';
      //  ld.Last_Comment__c='test22';
        ld.Status__c='Welcome call';
        ld.Project__c='Zuari Garden City';
        ld.Sub_Status__c ='Positive';
        ld.Payment_Type__c='Custom';
     //   ld.Sale_Agreement_Completed__c =true;
        ld.Funding_Type__c = 'Loan';
        insert ld;
        
        // Create Project
        Project__c pr = new Project__c();
        pr.Name = 'Zuari Garden City';
        pr.Project__c = 'Zuari Garden City'; // This field is text or picklist on Project, make sure it matches expected values
        insert pr;
        
        // Create Plot, with Status Vacant and Project linked
        Plot__c pl = new Plot__c();
        pl.Status__c = 'Available';
        pl.Project__c = pr.Id;
        insert pl;
        
        // Create Quote - Project picklist must match pr.Name or expected picklist value (like 'Mantri Serenit')
        // Assuming picklist value is 'Mantri Serenit' here to match pr.Name precisely
        Quote__c qc = new Quote__c();
        qc.Project__c = 'Zuari Garden City'; // picklist string, matches pr.Name
        qc.Payment_Type__c = 'Standard';
        qc.Unit__c = pl.Id; // lookup to Plot
        qc.SLead__c = ld11.Id;
        qc.Approval_status__c = 'Approved';
        insert qc;
        
        Master_payment_schedule__c mpy = new Master_payment_schedule__c ();
        mpy .Status__c = 'Completed';
        mpy.Project__c = pr.id;
        mpy.Payment_Percent__c=5;
        insert mpy;
        
        list<Payment_schedule__c> pysch = new  list<Payment_schedule__c>();
        Payment_schedule__c pys = new Payment_schedule__c();
        pys.Payment_Percent__c=10;
        pys.Payment_Due_Date__c = system.today()+3;
        pys.Quote__c =qc.id;
        pys.Booking__c = ld1.id;
        pys.Master_Payment_Schedule__c = mpy.Id;
        pys.name ='on booking';
        insert pys;
        pysch.add(pys);
        string rec= ld11.id;
        
        
        SwappingUnitController.getPlots(ld1.Id);
        
        SwappingUnitController.saveOppPlot(qc,ld1.Id);
        SwappingUnitController.saveOppPlot(qc,ld.Id);
        SwappingUnitController.getPaymentTypePicklistValues();
        SwappingUnitController.getPaymentSchedules('Standard','Zuari Garden City');
        SwappingUnitController.getPaymentSchedules('Custom','Zuari Garden City');
       SwappingUnitController.submitapproval(qc.id);
        SwappingUnitController.insertSchedules(pysch,100.00,qc.id);
    	SwappingUnitController.getPicklistValues('Quote__c','Approval_status__c');
      //SwappingUnitController.insertSchedules(pysch,ld1.id);  
        SwappingUnitController.QuoteCreate (ld11.id,qc.id); 
        SwappingUnitController.deleteSchedule(pys.id);
        SwappingUnitController.getblocks('Zuari Garden City');
        SwappingUnitController.getType(rec);
        
        
    }
}