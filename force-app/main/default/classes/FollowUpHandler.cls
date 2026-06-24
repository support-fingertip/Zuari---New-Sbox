public class FollowUpHandler {

    public static void updateRelatedSourceDates(List<Follow_up__c> newList) {

        Set<Id> relatedSourceIds = new Set<Id>();

        for (Follow_up__c fu : newList) {
            if (fu.Related_Source__c != null && fu.Scheduled_Date__c != null) {
                relatedSourceIds.add(fu.Related_Source__c);
            }
        }

        if (relatedSourceIds.isEmpty()) return;

        Map<Id, List<Follow_up__c>> rsFollowups = new Map<Id, List<Follow_up__c>>();

        for (Follow_up__c fu : [
            SELECT Scheduled_Date__c, Related_Source__c, CreatedDate
            FROM Follow_up__c
            WHERE Related_Source__c IN :relatedSourceIds
            AND Scheduled_Date__c != null
            ORDER BY CreatedDate DESC, Scheduled_Date__c DESC
        ]) {

            if (!rsFollowups.containsKey(fu.Related_Source__c)) {
                rsFollowups.put(fu.Related_Source__c, new List<Follow_up__c>());
            }
            rsFollowups.get(fu.Related_Source__c).add(fu);
        }

        List<Related_Source__c> rsUpdateList = new List<Related_Source__c>();

        for (Id rsId : rsFollowups.keySet()) {

            List<Follow_up__c> fuList = rsFollowups.get(rsId);

            Related_Source__c rs = new Related_Source__c(Id = rsId);

            // Newly created followup
            rs.Latest_FollowUp_Date__c = fuList[0].Scheduled_Date__c;

            // Previous followup
            rs.Last_Follow_Up_Date__c =
                (fuList.size() > 1) ? fuList[1].Scheduled_Date__c : null;

            rsUpdateList.add(rs);
        }

        if (!rsUpdateList.isEmpty()) {
            update rsUpdateList;
        }
    }
}