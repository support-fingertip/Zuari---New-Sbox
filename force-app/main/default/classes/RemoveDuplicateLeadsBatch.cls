global class RemoveDuplicateLeadsBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch all Leads that don't have any Related_Source__c child records
        return Database.getQueryLocator([
            SELECT Id, Name, Phone__c, Allocated_Project__c,
            Tertiary_Source__c, Email, Sub_Source__c, Lead_source__c
            FROM Lead
            WHERE Id NOT IN (
                SELECT SLead__c FROM Related_Source__c
            )
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Related_Source__c> newSources = new List<Related_Source__c>();
        
        for (Lead l : scope) {
            newSources.add(new Related_Source__c(
                SLead__c = l.Id,
                Phone__c = l.Phone__c,
                Email__c = l.Email,
                Allocated_Project__c = l.Allocated_Project__c,
                Source__c = l.Lead_source__c,
                Sub_Source__c = l.Tertiary_Source__c
            ));
        }
        // Step 3: DML operations
        if (!newSources.isEmpty()) {
            insert newSources;
        }
    }
    global void finish(Database.BatchableContext bc) {
        // Optional: send email summary
    }
}