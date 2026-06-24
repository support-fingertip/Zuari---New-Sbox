public class LeadToRelatedSourceBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select Id,Name,SLead__c,OwnerId from Related_Source__c where Is_Locked__c = false';
        return Database.getQueryLocator(query);
    }
    
    
    public void execute(Database.BatchableContext bc, List<Related_Source__c> leads) {
        
        manulaSharingClass.manageLeadSharingFromRelatedSource(leads);
    }
    
    
    
    public void finish(Database.BatchableContext bc) {
        
    }
}