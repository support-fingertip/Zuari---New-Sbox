global class Batch_CountSiteVisitPerRelatedSource implements Database.Batchable<SObject>, Database.Stateful {
    
    global Integer totalProcessed = 0;
    global Integer totalFailed = 0;
    global List<String> errorMessages = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id FROM Related_Source__c
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Related_Source__c> scope) {
        // Get all parent Related_Source__c Ids in scope
        Set<Id> parentSourceIds = new Set<Id>();
        for(Related_Source__c rs : scope) {
            parentSourceIds.add(rs.Id);
        }
        
        // Map: Related_Source__c Id --> Site Visit count
        Map<Id, Integer> siteVisitCountMap = new Map<Id, Integer>();
        
        // Query the child Site_Visit__c records per parent
        for (AggregateResult ar : [
            SELECT Related_Source__c, COUNT(Id) cnt
            FROM Site_Visit__c 
            WHERE Related_Source__c IN :parentSourceIds 
            AND Status__c = 'Completed'
            GROUP BY Related_Source__c
        ]) {
            siteVisitCountMap.put(
                (Id)ar.get('Related_Source__c'), 
                (Integer)ar.get('cnt')
            );
        }
        
        // Prepare updates using clean record instantiation
        List<Related_Source__c> updates = new List<Related_Source__c>();
        for(Related_Source__c rs : scope) {
            Integer count = siteVisitCountMap.containsKey(rs.Id) 
                ? siteVisitCountMap.get(rs.Id) 
                : 0;
            updates.add(new Related_Source__c(
                Id = rs.Id,
                No_of_Site_Visit__c = count
            ));
        }
        
        // Partial success update — errors won't fail the entire batch
        if(!updates.isEmpty()) {
            Database.SaveResult[] results = Database.update(updates, false);
            for(Integer i = 0; i < results.size(); i++) {
                if(results[i].isSuccess()) {
                    totalProcessed++;
                } else {
                    totalFailed++;
                    for(Database.Error err : results[i].getErrors()) {
                        errorMessages.add(
                            'Record Id: ' + updates[i].Id + 
                            ' | Error: ' + err.getMessage() +
                            ' | Fields: ' + err.getFields()
                        );
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Query the AsyncApexJob for batch summary
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                   TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob 
            WHERE Id = :bc.getJobId()
        ];
        
        // Build summary message
        String summary = 'Batch_CountSiteVisitPerRelatedSource Completed.\n\n' +
            'Status: ' + job.Status + '\n' +
            'Total Batches: ' + job.TotalJobItems + '\n' +
            'Batches Processed: ' + job.JobItemsProcessed + '\n' +
            'Batch-Level Errors: ' + job.NumberOfErrors + '\n\n' +
            'Records Successfully Updated: ' + totalProcessed + '\n' +
            'Records Failed: ' + totalFailed + '\n';
        
        if(!errorMessages.isEmpty()) {
            summary += '\nError Details:\n';
            for(String err : errorMessages) {
                summary += '- ' + err + '\n';
            }
        }
        
        // Send email notification to the job creator
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ job.CreatedBy.Email });
        mail.setSubject('Batch Job Complete: Site Visit Count Update');
        mail.setPlainTextBody(summary);
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
        } catch(Exception e) {
            System.debug('Email send failed: ' + e.getMessage());
        }
        
        System.debug(summary);
    }
}