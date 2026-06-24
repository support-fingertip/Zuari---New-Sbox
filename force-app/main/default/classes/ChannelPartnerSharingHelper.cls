public without sharing class ChannelPartnerSharingHelper {

    private static final String ROW_CAUSE = Schema.Channel_Partner__Share.RowCause.Manual;
    private static final String ACCESS_LEVEL = 'Edit';

    public static void shareWithSourcingRM(List<Channel_Partner__c> newList) {
        if (newList == null || newList.isEmpty()) return;

        Map<Id, Id> cpToUser = new Map<Id, Id>();
        Set<Id> userIds = new Set<Id>();

        for (Channel_Partner__c cp : newList) {
            if (cp.Sourcing_RM__c == null) continue;
            if (cp.Sourcing_RM__c == cp.OwnerId) continue;
            cpToUser.put(cp.Id, cp.Sourcing_RM__c);
            userIds.add(cp.Sourcing_RM__c);
        }

        if (cpToUser.isEmpty()) return;

        Set<Id> eligibleUserIds = filterEligibleUsers(userIds);
        if (eligibleUserIds.isEmpty()) return;

        List<Channel_Partner__Share> toInsert = new List<Channel_Partner__Share>();
        for (Id cpId : cpToUser.keySet()) {
            Id userId = cpToUser.get(cpId);
            if (!eligibleUserIds.contains(userId)) continue;
            toInsert.add(buildShare(cpId, userId));
        }

        insertShares(toInsert);
    }

    public static void reshareOnSourcingRMChange(
        List<Channel_Partner__c> newList,
        Map<Id, Channel_Partner__c> oldMap
    ) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> changedCpIds = new Set<Id>();
        Set<Id> oldUserIds = new Set<Id>();
        Map<Id, Id> cpToNewUser = new Map<Id, Id>();
        Set<Id> newUserIds = new Set<Id>();

        for (Channel_Partner__c cp : newList) {
            Channel_Partner__c oldCp = oldMap.get(cp.Id);
            if (oldCp == null) continue;
            if (cp.Sourcing_RM__c == oldCp.Sourcing_RM__c) continue;

            changedCpIds.add(cp.Id);

            if (oldCp.Sourcing_RM__c != null) {
                oldUserIds.add(oldCp.Sourcing_RM__c);
            }
            if (cp.Sourcing_RM__c != null && cp.Sourcing_RM__c != cp.OwnerId) {
                cpToNewUser.put(cp.Id, cp.Sourcing_RM__c);
                newUserIds.add(cp.Sourcing_RM__c);
            }
        }
System.debug(changedCpIds);
        if (changedCpIds.isEmpty()) return;

        if (!oldUserIds.isEmpty()) {
            List<Channel_Partner__Share> toDelete = [
                SELECT Id
                FROM Channel_Partner__Share
                WHERE ParentId IN :changedCpIds
                AND UserOrGroupId IN :oldUserIds
                AND RowCause = :ROW_CAUSE
            ];
            if (!toDelete.isEmpty()) {
                Database.delete(toDelete, false);
            }
        }

        if (cpToNewUser.isEmpty()) return;

        Set<Id> eligibleUserIds = filterEligibleUsers(newUserIds);
        if (eligibleUserIds.isEmpty()) return;

        List<Channel_Partner__Share> toInsert = new List<Channel_Partner__Share>();
        for (Id cpId : cpToNewUser.keySet()) {
            Id userId = cpToNewUser.get(cpId);
            if (!eligibleUserIds.contains(userId)) continue;
            toInsert.add(buildShare(cpId, userId));
        }

        System.debug(toInsert);
        insertShares(toInsert);
        System.debug(toInsert);
    }

    private static Channel_Partner__Share buildShare(Id cpId, Id userId) {
        Channel_Partner__Share s = new Channel_Partner__Share();
        s.ParentId = cpId;
        s.UserOrGroupId = userId;
        s.AccessLevel = ACCESS_LEVEL;
        s.RowCause = ROW_CAUSE;
        return s;
    }

    private static Set<Id> filterEligibleUsers(Set<Id> userIds) {
        Set<Id> eligible = new Set<Id>();
        if (userIds == null || userIds.isEmpty()) return eligible;
        for (User u : [
            SELECT Id
            FROM User
            WHERE Id IN :userIds
            AND IsActive = true
            AND UserType = 'Standard'
        ]) {
            eligible.add(u.Id);
        }
        return eligible;
    }

    private static void insertShares(List<Channel_Partner__Share> shares) {
        if (shares.isEmpty()) return;
        List<Database.SaveResult> results = Database.insert(shares, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'Sourcing_RM share insert failed for ' + shares[i].ParentId +
                    ' user ' + shares[i].UserOrGroupId + ': ' + results[i].getErrors());
            }
        }
    }
}