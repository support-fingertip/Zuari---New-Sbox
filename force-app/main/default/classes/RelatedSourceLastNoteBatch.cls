global class RelatedSourceLastNoteBatch
implements Database.Batchable<SObject>, Database.Stateful {

    // ================================
    // START
    // ================================
    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Last_Note__c
            FROM Related_Source__c
            WHERE Is_Locked__c = false
        ]);
    }

    // ================================
    // EXECUTE
    // ================================
    global void execute(Database.BatchableContext bc, List<Related_Source__c> scope) {

        // Step 1: Filter only records with Last_Note__c = NULL
        Set<Id> rsIds = new Set<Id>();
        for (Related_Source__c rs : scope) {
            if (rs.Last_Note__c == null) {
                rsIds.add(rs.Id);
            }
        }

        if (rsIds.isEmpty()) {
            System.debug('No Related_Source__c records need update in this scope');
            return;
        }

        // Step 2: Fetch Call Comments
        List<Call_Comments__c> comments = [
            SELECT Comments__c,
                   Created_user__c,
                   Created_Date__c,
                   Related_Source__c
            FROM Call_Comments__c
            WHERE Related_Source__c IN :rsIds
            ORDER BY Created_Date__c ASC
        ];

        if (comments.isEmpty()) {
            System.debug('No Call_Comments__c found for current scope');
            return;
        }

        // Step 3: Build summaries
        Map<Id, String> summaryMap = new Map<Id, String>();
        Map<Id, Integer> counterMap = new Map<Id, Integer>();

        for (Call_Comments__c cc : comments) {

            if (!summaryMap.containsKey(cc.Related_Source__c)) {
                summaryMap.put(cc.Related_Source__c, '');
                counterMap.put(cc.Related_Source__c, 1);
            }

            // Clean comment text
            String actualComment = cc.Comments__c;
            if (actualComment != null && actualComment.startsWith('Call Summary')) {
                Integer idx = actualComment.indexOf(']:');
                if (idx != -1) {
                    actualComment = actualComment.substring(idx + 2).trim();
                }
            }

            if (String.isBlank(actualComment)) {
                continue; // nothing meaningful to add
            }

            Boolean hasDate = cc.Created_Date__c != null;
            Boolean hasUser = !String.isBlank(cc.Created_user__c);

            Integer count = counterMap.get(cc.Related_Source__c);

            String line = 'Call Summary ' + count + ': ';

            // Apply your EXACT rules
            if (hasUser) {
                line += cc.Created_user__c + ' ';
            }

            if (hasDate) {
                line += '[' + cc.Created_Date__c.format('dd-MM-yy HH:mm a') + '] ';
            }

            line += ': ' + actualComment + '\n';

            summaryMap.put(
                cc.Related_Source__c,
                summaryMap.get(cc.Related_Source__c) + line
            );

            counterMap.put(cc.Related_Source__c, count + 1);
        }

        // Step 4: Update Related Source
        List<Related_Source__c> updates = new List<Related_Source__c>();

        for (Id rsId : summaryMap.keySet()) {
            updates.add(new Related_Source__c(
                Id = rsId,
                Last_Note__c = summaryMap.get(rsId)
            ));

            System.debug(
                'Updating Related_Source__c Id = ' + rsId +
                ' | Last_Note__c length = ' + summaryMap.get(rsId).length()
            );
        }

        if (!updates.isEmpty()) {
            update updates;
            System.debug('Updated ' + updates.size() + ' Related_Source__c records');
        }
    }

    // ================================
    // FINISH
    // ================================
    global void finish(Database.BatchableContext bc) {
        System.debug('RelatedSourceLastNoteBatch completed successfully');
    }
}