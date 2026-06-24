public class LeadUpdateCommonBatchClass implements Database.Batchable<SObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name,Last_Note__c,TL_RHS_Count__c,Execuive_Count__c,TL_RHS_Review__c
            FROM Lead
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Lead> leadsToProcess = new List<Lead>();
        
        for(Lead lds : scope){
            Boolean hasChanges = false;
            if (String.isNotBlank(lds.Last_Note__c)) {
                List<String> notes = lds.Last_Note__c.split('\n');
                lds.Execuive_Count__c = notes.size();
                hasChanges = true;
            }
            if (String.isNotBlank(lds.TL_RHS_Review__c)) {
                List<String> notes = lds.TL_RHS_Review__c.split('\n');
                lds.TL_RHS_Count__c = notes.size();
                hasChanges = true;
            }
            if(hasChanges == true){
                leadsToProcess.add(lds);
            }
            
        }
        if(leadsToProcess.size() >0){
            update leadsToProcess;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Lead Update batch finished.');
    }
}