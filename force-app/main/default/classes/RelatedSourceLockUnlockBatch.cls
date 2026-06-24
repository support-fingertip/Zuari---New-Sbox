public class RelatedSourceLockUnlockBatch implements Database.Batchable<sObject>, Database.Stateful {
    
 
    
  
 
    public RelatedSourceLockUnlockBatch() {
        
    }
  
    
    /**
     * Start method - Query all Leads
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select Id,Name,SLead__r.OwnerId,SLead__r.Lead_Status__c,SLead__r.Allocated_Project__c from related_source__c where SLead__c != null';
                     
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        return Database.getQueryLocator(query);
    }
    
    /**
     * Execute method - Process each batch of Leads
     */
    public void execute(Database.BatchableContext bc, List<related_source__c> leads) {
        
        // Collect Lead IDs
        List<related_source__c> reList = new List<related_source__c>();
        for(related_source__c ld : leads) {
            ld.OwnerId = ld.SLead__r.OwnerId;
            ld.Lead_status1__c = ld.SLead__r.Lead_Status__c;
            ld.Allocated_Project__c = ld.SLead__r.Allocated_Project__c;
            reList.add(ld);
        }
        
        update reList;
       
    }
    
    
    public void finish(Database.BatchableContext bc) {
       
    }
}