public without sharing class QuotePdfController {
    @AuraEnabled
    public static string sendEmailtoCustomer(String recId)
    {
        Quote__c qt = [SELECT Id,payment_type__c,Quote_status__c,Approval_status__c, Project__c, SLead__r.Email, SLead__r.Secondary_Email__c,Plot_Type__c,SLead__c ,RecordType.DeveloperName  FROM Quote__c WHERE Id=:recId];
    //    if(qt.Quote_status__c == 'Approved' || qt.Quote_status__c == 'Drafted'){
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            PageReference pref;
            
            if(qt.RecordType.DeveloperName=='Plots'){
                pref= page.CostSheet;
                
            }else{
                pref= page.ZuariCostSheet;
            }
            
            //pref=page.EIPL;
            pref.getParameters().put('id',recId);
            pref.setRedirect(true);
            system.debug(pref);
            Blob b;
            
            Boolean isTest = System.Test.isRunningTest();
            if(isTest){
                b = blob.valueOf('Unit.Test');
            }else{
                b = pref.getContent();
            }
            attach.setFileName('Zuari_CostSheet.pdf');
            attach.setBody(b);
            semail.setSubject('Zuari Cost Sheet');
            system.debug(qt.SLead__r.Email);
            List<string> sendTo = new List<string>();
            if(qt.SLead__r.Email !=null){
                sendTo.add(qt.SLead__r.Email);
            }
            
            if(qt.SLead__r.Secondary_Email__c !=null){
                sendTo.add(qt.SLead__r.Secondary_Email__c);
            }
            
            semail.setToAddresses(sendTo);
            semail.setHtmlBody('Dear Sir/Madam,<br/> <br/> Thank you very much for your interest in '+qt.Project__c +'.<br/>Please find the attached quote for your kind Perusal.<br/>Note: This is a sample quote purely for reference.<br/>Please feel free to talk us for clarification if any.,<br/> Warm Regards <br/> Zuari Infraworld India Ltd');
            semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
            if(sendTo.size()>0){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
                system.debug(semail);
                
                Quote__c q = [select Id, Name, Quote_status__c from Quote__c where id = :recId limit 1];
                q.Quote_status__c = 'sent to customer';
                update q;
                return 'Quotation sent to customer';
            }else{
                return 'Please enter email address in lead';
            }
     //  }else{
           // return 'Quote is not approved, you can not send Quote';
      //  }
    }
    /*@AuraEnabled*/
    /*public static void callUnitHoldController(String recId){
        Quote__c qt = [SELECT Id,Quote_status__c,Unit__c, Project__c,Unit__r.Project__c, Unit__r.Project__r.TAT_for_Holding_Unit__c   FROM Quote__c WHERE Id=:recId];
        
        plot__c pt=new plot__c();
        pt.id = qt.Unit__c;
        System.debug('samp2'+pt.Id);
        pt.Status__c='Hold';
        qt.Quote_status__c = 'Hold';
		update new List<SObject>{ pt, qt };
        DateTime dt = System.now(); 
        if(qt.Unit__r.Project__r.TAT_for_Holding_Unit__c>0){
            
        Decimal tat = qt.Unit__r.Project__r.TAT_for_Holding_Unit__c;
        DateTime newDateTime = dt.addMinutes(Integer.ValueOf(tat)); 
        
        if(newDateTime!=null && newDateTime> system.now()){
            system.debug(newDateTime);
            pt.Holding_Time__c= newDateTime ;  
        }
        
        if(pt.Id!=null){
            update pt;
        }
        }
    } */
    
    
}