@IsTest
private class CreateQuoteRelatedsourceController_Test {
  @isTest
    public static void CreateQuotetest(){
        
        // Create a User object that uses that Profile
        
        
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c = true;
        insert pjt;
        
        Block__c bc = new Block__c();
        bc.Name='A';
        bc.Project__c=pjt.id;
        insert bc;
         Lead sLead = new Lead();
        sLead.LastName = 'Test';
        sLead.Company = 'testcompany';
        sLead.Phone__c = '8778987789';
        sLead.Allocated_Project__c = 'Zuari Garden City';
        insert sLead;
        
        Related_Source__c ld = new Related_Source__c();
        ld.Phone__c = '8778987789';
        ld.Allocated_Project__c ='Zuari Garden City';
        ld.SLead__c = sLead.id;
        insert ld;
      plot__c ut = new Plot__c();
        ut.Name='Test plot';
        ut.Status__c='Available';
        ut.Project__c = pjt.Id;
        
        insert ut;
       
          Payment_Plan__c pp = new Payment_Plan__c();
        pp.Name = 'test';
        pp.Active__c =true;
        pp.Project__c =pjt.Id;
        insert pp;
       Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c ='Completed';
        insert mps;
      
       
        
        Quote__c qc = new Quote__c();
        qc.Quote_status__c = 'Converted';
        qc.Block__c = ' ';
        qc.Block_Lookup__c=bc.Id;
        qc.Related_Source__c =ld.id;
        qc.Payment_Type__c = 'Standard';
        qc.Unit__c=ut.id;
        insert qc;
       
        
        
        
        Payment_schedule__c ps = new Payment_schedule__c();
         ps.Payment_percent__c =100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = true;
        ps.Quote__c = qc.id;
         insert ps;
        List<Payment_schedule__c> PaymentList = new List<Payment_schedule__c>();
        
        PaymentList.add(ps);
        
      // CreateQuoteRelatedsourceController.getPlots(ld.Id, pjt.Name); 
      //  CreateQuoteRelatedsourceController.getvillasPlots( pjt.Name);
        CreateQuoteRelatedsourceController.saveOppPlot(qc);
        
        CreateQuoteRelatedsourceController.getPaymentTypePicklistValues();
        CreateQuoteRelatedsourceController.getBlock(ld.id);
      CreateQuoteRelatedsourceController.getPlots(ld.id);
        CreateQuoteRelatedsourceController.getPlotsByBlock(bc.Id);
        CreateQuoteRelatedsourceController.getPyamentPlan('Zuari Garden City');
        CreateQuoteRelatedsourceController.quotationqquery(ld.Id);
        CreateQuoteRelatedsourceController.getUpdatedPaymentSchedules(pp.Id,ld.Allocated_Project__c);
        CreateQuoteRelatedsourceController.getPaymentSchedules('Standard','Mantri Serenity');
        CreateQuoteRelatedsourceController.getPaymentSchedules('Custom','Mantri Serenity');
        CreateQuoteRelatedsourceController.deleteSchedule(ps.id);
        String qid =qc.id;
       CreateQuoteRelatedsourceController.insertSchedules(PaymentList,1000,qid);
       CreateQuoteRelatedsourceController.QuoteCreate(ld.Id,qc.Id);
         CreateQuoteRelatedsourceController.getLeadId(ld.Id);
        try{
            CreateQuoteRelatedsourceController.callQuoteApproval(qc.Id);
        }catch(Exception e){
            System.debug('Expected: ' + e.getMessage());
        }
        
       // CreateQuoteRelatedsourceController.getblocks('Mantri Serenity');
        //CreateQuoteRelatedsourceController.getType(ld.Id);
       // CreateQuoteRelatedsourceController.getPicklistValues('Lead','Allocated_Project__c');
        ///getQuoteData testclass
        PageReference pageRef = Page.MantriquotationVF;
        //Test.setCurrentPage(pageRef);
        
        pageRef.getParameters().put('Id', String.valueOf(qc.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(qc);
        //getQuoteData testp = new getQuoteData(sc);
        
      CreateQuoteRelatedsourceController.deleteQuote(qc.id);
    }
}