public class InspectionTriggerHandler {

    // ❌ BEFORE UPDATE → block status change if snags open
    public static void preventCompletionIfSnagsOpen(List<Inspection__c> newList, Map<Id, Inspection__c> oldMap) {

        Set<Id> inspectionIdsToCheck = new Set<Id>();

        // Identify all inspections trying to change status to Completed
        for (Inspection__c ins : newList) {
            if (
                ins.Status__c == 'Completed' &&
                oldMap.get(ins.Id).Status__c != 'Completed'
            ) {
                inspectionIdsToCheck.add(ins.Id);
            }
        }

        if (inspectionIdsToCheck.isEmpty()) return;

        // Fetch related Snags
        Map<Id, Integer> openSnagCount = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT Inspection__c insId, COUNT(Id) cnt
            FROM Snag_List__c
            WHERE Inspection__c IN :inspectionIdsToCheck
            AND Status__c != 'Resolved'
            GROUP BY Inspection__c
        ]) {
            openSnagCount.put((Id) ar.get('insId'), (Integer) ar.get('cnt'));
        }

        // Throw error if any inspection has open snags
        for (Inspection__c ins : newList) {
            if (inspectionIdsToCheck.contains(ins.Id)) {
                if (openSnagCount.containsKey(ins.Id)) {
                    ins.Status__c = oldMap.get(ins.Id).Status__c; // revert
                    ins.addError(
                        'Inspection cannot be marked Completed because some Snags are still OPEN.'
                    );
                }
            }
        }
    }

    // ✔ AFTER UPDATE → send email when ALL snags are closed
    public static void sendCompletionEmail(List<Inspection__c> newList, Map<Id, Inspection__c> oldMap) {

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Inspection__c ins : newList) {
System.debug('Called');
            // Condition: Status changed to Completed
            if (ins.Status__c == 'Completed' && oldMap.get(ins.Id).Status__c != 'Completed') {

                // Fetch count of open snags (should be zero)
                Integer openCount = [SELECT COUNT() FROM Snag_List__c WHERE Inspection__c = :ins.Id AND Status__c != 'Resolved'];
System.debug(openCount);
                if (openCount == 0) {
System.debug('j');
                    // Build Email
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                    email.toAddresses = new String[]{ins.Customer_Email__c};
                    email.subject = 'Inspection Completed';
                    email.plainTextBody = 'Dear Sir/Madam,\n\nYour inspection has been successfully completed. All snags are closed.\n\nThanks & Regards,\nCRM Team';


                    email.setSaveAsActivity(true);
                    email.setWhatId(ins.Id);
                    emails.add(email);
                }
            }
            System.debug('Called '+ ins.Extended_Completed_Date__c + oldMap.get(ins.Id).Extended_Completed_Date__c+ '=='+ ins.Approval_Status__c);
            if (ins.Extended_Completed_Date__c != null && ins.Approval_Status__c=='Approved') {
                System.debug(ins.Extended_Completed_Date__c +'=== '+oldMap.get(ins.Id).Extended_Completed_Date__c);
                    // Build Email
                    Messaging.SingleEmailMessage email1 = new Messaging.SingleEmailMessage();

                    email1.toAddresses = new String[]{ins.Customer_Email__c};
                    email1.subject = 'Inspection Extended Date Notification';
                  
                Date d = ins.Extended_Completed_Date__c;

                String formattedDate = (d == null)
                    ? 'N/A'
                    : String.valueOf(d.day()).leftPad(2, '0') + '-' +
                        String.valueOf(d.month()).leftPad(2, '0') + '-' +
                        String.valueOf(d.year());
                
                    email1.plainTextBody = 'Dear Sir/Madam,\n\nYour inspection completed date has been updated. New Expected Completed Date ' + formattedDate + '\n\nThanks & Regards,\nCRM Team.';


                    email1.setSaveAsActivity(true);
                    email1.setWhatId(ins.Id);
                    emails.add(email1);
            }

            
            
        }

        if (!emails.isEmpty()) {
            System.debug(emails);
           Messaging.SendEmailResult[] results= Messaging.sendEmail(emails);
            System.debug(results);
        }
    }
}