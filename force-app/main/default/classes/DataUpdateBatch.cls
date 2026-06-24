public class DataUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Optional: track stats across batches (requires Database.Stateful)
    public Integer recordsProcessed = 0;
    public Integer recordsFailed = 0;
    
    // 1. START - Collect records to process
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id ' +
            'FROM Booking__c ' +
            'WHERE CreatedById = \'005Wd000000aDmjIAE\'';
        return Database.getQueryLocator(query);
    }
    
    // 2. EXECUTE - Process each chunk (default 200 records)
    public void execute(Database.BatchableContext bc, List<Booking__c> scope) {
        for(Booking__c bk : scope){
            RecreatingPaymentSchedules.recreateReceipts(bk.Id);
        }
        
    }
    
    // 3. FINISH - Cleanup, send notifications, chain jobs
    public void finish(Database.BatchableContext bc) {
        // Query AsyncApexJob for job details
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, 
                   TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob 
            WHERE Id = :bc.getJobId()
        ];
        
        // Send completion email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { job.CreatedBy.Email });
        mail.setSubject('Batch Job Completed: ' + job.Status);
        mail.setPlainTextBody(
            'Records Processed: ' + recordsProcessed + '\n' +
            'Records Failed: ' + recordsFailed + '\n' +
            'Total Batches: ' + job.TotalJobItems + '\n' +
            'Errors: ' + job.NumberOfErrors
        );
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}