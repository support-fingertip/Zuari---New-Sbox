/**
 * Auto-deactivates Channel Partners that have not captured a lead in the
 * last 12 months. When Last_Lead_Captured_Date_Time__c is null the
 * partner's CreatedDate is used as the reference, so partners that joined
 * long ago without ever capturing a lead are also caught.
 *
 * Paired with ChannelPartnerDeactivationScheduler (daily 02:00 IST).
 *
 * Re-entrancy: the QueryLocator filters Active__c = true so already-
 * deactivated records are never picked up again on subsequent runs.
 */
global without sharing class Batch_ChannelPartnerDeactivation
    implements Database.Batchable<sObject>, Database.Stateful {

    @TestVisible private static final Integer INACTIVITY_MONTHS = 12;

    global Integer totalProcessed   = 0;
    global Integer totalDeactivated = 0;
    global Integer totalFailed      = 0;
    global List<String> errorMessages = new List<String>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime cutoff = System.now().addMonths(-INACTIVITY_MONTHS);
        return Database.getQueryLocator([
            SELECT Id, Name, Active__c,
                   Last_Lead_Captured_Date_Time__c, CreatedDate
            FROM   Channel_Partner__c
            WHERE  Active__c = true
            AND    ((Last_Lead_Captured_Date_Time__c != null
                     AND Last_Lead_Captured_Date_Time__c <= :cutoff)
                 OR (Last_Lead_Captured_Date_Time__c = null
                     AND CreatedDate <= :cutoff))
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Channel_Partner__c> scope) {
        if (scope == null || scope.isEmpty()) return;

        List<Channel_Partner__c> toUpdate = new List<Channel_Partner__c>();
        for (Channel_Partner__c cp : scope) {
            toUpdate.add(new Channel_Partner__c(Id = cp.Id, Active__c = false));
        }

        Database.SaveResult[] results = Database.update(toUpdate, false);
        for (Integer i = 0; i < results.size(); i++) {
            totalProcessed++;
            if (results[i].isSuccess()) {
                totalDeactivated++;
            } else {
                totalFailed++;
                for (Database.Error e : results[i].getErrors()) {
                    errorMessages.add('CP ' + toUpdate[i].Id + ' | ' +
                                      e.getStatusCode() + ' | ' + e.getMessage());
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                   TotalJobItems, CreatedBy.Email
            FROM   AsyncApexJob
            WHERE  Id = :bc.getJobId()
        ];

        String summary = 'Batch_ChannelPartnerDeactivation Completed.\n\n' +
            'Status              : ' + job.Status + '\n' +
            'Total Batches       : ' + job.TotalJobItems + '\n' +
            'Batches Processed   : ' + job.JobItemsProcessed + '\n' +
            'Batch-Level Errors  : ' + job.NumberOfErrors + '\n\n' +
            'Records Processed   : ' + totalProcessed + '\n' +
            'Records Deactivated : ' + totalDeactivated + '\n' +
            'Records Failed      : ' + totalFailed + '\n';

        if (!errorMessages.isEmpty()) {
            summary += '\nError Details:\n';
            for (String e : errorMessages) summary += '- ' + e + '\n';
        }

        System.debug(summary);

        if (!Test.isRunningTest() && String.isNotBlank(job.CreatedBy.Email)) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{ job.CreatedBy.Email });
            mail.setSaveAsActivity(false);
            mail.setSubject('Batch Job Complete: Channel Partner Deactivation');
            mail.setPlainTextBody(summary);
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'Finish email send failed: ' + e.getMessage());
            }
        }
    }
}
