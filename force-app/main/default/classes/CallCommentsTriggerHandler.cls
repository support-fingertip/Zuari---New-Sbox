public class CallCommentsTriggerHandler {

    private static Boolean isExecuting = false;

    public static void afterInsert(List<Call_Comments__c> newList) {

        if (isExecuting) return;
        isExecuting = true;

        Set<Id> relatedSourceIds = new Set<Id>();

        for (Call_Comments__c cc : newList) {
            if (cc.Related_Source__c != null) {
                relatedSourceIds.add(cc.Related_Source__c);
            }
        }

        if (!relatedSourceIds.isEmpty()) {
            System.debug('>>> Processing Related Source IDs: ' + relatedSourceIds);
            AddRelatedSourceNoteController.completeRelatedSourceFollowups(relatedSourceIds);
        }

        isExecuting = false;
    }
}