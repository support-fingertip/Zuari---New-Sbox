public with sharing class LeadDedupBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        List<AggregateResult> dupPhones = [SELECT Phone__c phone, COUNT(Id) cnt
            FROM Lead WHERE Phone__c != null GROUP BY Phone__c HAVING COUNT(Id) > 1 ];
        Set<String> phoneSet = new Set<String>();
        for (AggregateResult ar : dupPhones) {
            phoneSet.add((String)ar.get('phone'));
        }
        return Database.getQueryLocator([
            SELECT Id, Name, Phone__c, Allocated_Project__c,
            Tertiary_Source__c, Email, Sub_Source__c, Lead_source__c,
            CreatedDate
            FROM Lead
            WHERE Phone__c IN :phoneSet
            ORDER BY Phone__c, CreatedDate ASC
        ]);
        // ✅ Query leads that belong to duplicate phone groups
        // return Database.getQueryLocator('SELECT Id, Name, Phone__c,Allocated_Project__c,Tertiary_Source__c,Email,Sub_Source__c,Lead_source__c FROM Lead WHERE Phone__c IN (SELECT Phone__c FROM Lead WHERE Phone__c != null GROUP BY Phone__c HAVING COUNT(Id) > 1 ) ' );
    }
    
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        // Group the leads by phone within this batch scope
        Map<String, List<Lead>> leadsByPhone = new Map<String, List<Lead>>();
        for (Lead l : scope) {
            if (String.isBlank(l.Phone__c)) continue;
            if (!leadsByPhone.containsKey(l.Phone__c)) {
                leadsByPhone.put(l.Phone__c, new List<Lead>());
            }
            leadsByPhone.get(l.Phone__c).add(l);
        }
        
        List<Related_Source__c> sourcesToInsert = new List<Related_Source__c>();
        List<Lead> dupLeadsToDelete = new List<Lead>();
        
        // Process each phone group in this batch chunk
        for (String phone : leadsByPhone.keySet()) {
            List<Lead> groupLeads = leadsByPhone.get(phone);
            if (groupLeads.size() < 2) continue;
            
            // keep the first (earliest created because of ORDER BY in start query)
            Lead mainLead = groupLeads[0];
             sourcesToInsert.add(new Related_Source__c(
                    SLead__c     = mainLead.Id,
                    Phone__c    = mainLead.Phone__c,
                    Allocated_Project__c  = mainLead.Allocated_Project__c,
                    Source__c   = mainLead.Lead_source__c,
                    scheck__c=true,
                    Sub_Source__c= mainLead.Tertiary_Source__c
                ));
            for (Integer i = 1; i < groupLeads.size(); i++) {
                Lead dup = groupLeads[i];
                dupLeadsToDelete.add(dup);
                
                sourcesToInsert.add(new Related_Source__c(
                    SLead__c     = mainLead.Id,
                    Phone__c    = dup.Phone__c,
                    Allocated_Project__c  = dup.Allocated_Project__c,
                    Source__c   = dup.Lead_source__c,
                    scheck__c=true,
                    Lead_Type__c='Re-Engaged',
                    Sub_Source__c= dup.Tertiary_Source__c
                ));
            }
        }
        
        if (!sourcesToInsert.isEmpty()) {
            insert sourcesToInsert;
        }
        if (!dupLeadsToDelete.isEmpty()) {
            delete dupLeadsToDelete;
        }
        
        System.debug('Batch chunk done: inserted ' + sourcesToInsert.size() +
                     ', deleted ' + dupLeadsToDelete.size());
    }
    
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Lead deduplication batch finished.');
    }
}