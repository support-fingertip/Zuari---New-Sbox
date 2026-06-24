trigger QuoteTrigger on Quote__c (after Update,after Insert) {
     List<Quote__c> quotesToProcess = new List<Quote__c>();
         Set<Id> submittedQuotes = new Set<Id>();
    
    List<Quote__c> quotesToUpdateCriteria = new List<Quote__c>();
    
    if (Trigger.isAfter &&  Trigger.isInsert) {
        for (Quote__c newQuote : Trigger.new) {
            
            if(newQuote.RM_Discount__c !=null && newQuote.CFO_Discount__c !=null && newQuote.Discount_Price__c !=null && newQuote.Discount_Price__c > newQuote.RM_Discount__c && newQuote.Discount_Price__c < newQuote.CFO_Discount__c){
                
                 quotesToProcess.add(newQuote);
                submittedQuotes.add(newQuote.Id);
                 quotesToUpdateCriteria.add(QuoteApprovalHandler.buildCriteriaUpdate(newQuote));
             
            }
           
                
        }
        
    }
    
    
    if (Trigger.isAfter &&  (Trigger.isUpdate)) {
        
        for (Quote__c newQuote : Trigger.new) {
            
            if (newQuote.Discount_Price__c != Trigger.oldMap.get(newQuote.Id).Discount_Price__c && newQuote.Discount_Price__c > newQuote.RM_Discount__c && newQuote.Discount_Price__c < newQuote.CFO_Discount__c) {
                quotesToProcess.add(newQuote);
                submittedQuotes.add(newQuote.Id);
                
                 quotesToUpdateCriteria.add(QuoteApprovalHandler.buildCriteriaUpdate(newQuote));
            }
             // -------------------------------
        // NEW — Approval Status Notification + Email
        // -------------------------------
       if (newQuote.Approval_Status__c != Trigger.oldMap.get(newQuote.Id).Approval_Status__c &&
            (newQuote.Approval_Status__c == 'Approved' || newQuote.Approval_Status__c == 'Rejected')) {
                
            QuoteApprovalHandler.sendQuoteStatusNotificationAndEmail(newQuote);
        }
        }
       
    }
    if (!quotesToUpdateCriteria.isEmpty()) {
        update quotesToUpdateCriteria;
    }
     if (!quotesToProcess.isEmpty()) {
            system.debug('Called Approval Process');
        QuoteApprovalHandler.processQuotes(quotesToProcess);
       // QuoteApprovalHandler.sendApprovalEmail(submittedQuotes);
        }

}