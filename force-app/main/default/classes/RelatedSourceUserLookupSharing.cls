/**
 * RelatedSourceUserLookupSharing
 *
 * Related_Source__c has a Private OWD. This helper grants explicit (Apex managed)
 * shares so that the User referenced in each of the object's User lookup fields can
 * see/edit the record.
 *
 *   - shareOnInsert   : called from RelatedSourceTrigger (after insert). Creates a
 *                       Related_Source__Share for every distinct active Standard user
 *                       referenced in a lookup field (skips the record Owner and nulls).
 *   - reshareOnUpdate : called from RelatedSourceTrigger (after update). When the lookup
 *                       fields change, removes shares for users that were dropped from the
 *                       lookups and adds shares for newly referenced users.
 *
 * Shares use RowCause = Manual, consistent with the other sharing classes in this org
 * (manulaSharingClass, ChannelPartnerSharingHelper). To stay safe with the shared Manual
 * row cause, reshareOnUpdate only ever deletes shares for users that were previously
 * referenced by a lookup and are no longer referenced — it never touches shares for users
 * the lookups never granted.
 *
 * Modeled on ChannelPartnerSharingHelper (eligible-user filter, error logging) and the
 * composite-key dedup used in RelatedSourceSharingService.
 */
public without sharing class RelatedSourceUserLookupSharing {

    private static final String ROW_CAUSE = Schema.Related_Source__Share.RowCause.Manual;
    private static final String ACCESS_LEVEL = 'Edit';

    // Every User lookup field on Related_Source__c that should receive a share.
    private static final List<String> USER_LOOKUP_FIELDS = new List<String>{
        'Assign_To__c',
        'Extension_Approver__c',
        'Extension_Requested_By__c',
        'Last_Unqualified_by__c',
        'Lead_OwnerSecondary__c',
        'Pre_Sales_User__c',
        'RM_CP_Name__c',
        'Sales_User__c',
        'SV_User__c',
        'STM2__c',
        'Search_Closing_Manager__c',
        'Search_Sourcing_Manager__c',
        'Transfered_By__c'
    };

    /**
     * Share each record with every active Standard user referenced in a lookup field.
     * Safe to re-run: existing Manual shares are skipped.
     */
    public static void shareOnInsert(List<Related_Source__c> newList) {
        if (newList == null || newList.isEmpty()) return;

        // recordId -> desired set of user ids (Owner excluded)
        Map<Id, Set<Id>> desiredByRecord = new Map<Id, Set<Id>>();
        Set<Id> allUserIds = new Set<Id>();

        for (Related_Source__c rs : newList) {
            Set<Id> users = desiredUsers(rs);
            if (users.isEmpty()) continue;
            desiredByRecord.put(rs.Id, users);
            allUserIds.addAll(users);
        }

        if (desiredByRecord.isEmpty()) return;

        Set<Id> eligibleUserIds = filterEligibleUsers(allUserIds);
        if (eligibleUserIds.isEmpty()) return;

        Set<String> existing = existingShareKeys(desiredByRecord.keySet());

        List<Related_Source__Share> toInsert = new List<Related_Source__Share>();
        for (Id recordId : desiredByRecord.keySet()) {
            for (Id userId : desiredByRecord.get(recordId)) {
                if (!eligibleUserIds.contains(userId)) continue;
                if (existing.contains(recordId + '|' + userId)) continue;
                toInsert.add(buildShare(recordId, userId));
            }
        }

        insertShares(toInsert);
    }

    /**
     * Keep shares in sync when lookup fields change. For each record whose lookup users
     * changed: delete shares for users no longer referenced by any lookup, and insert
     * shares for newly referenced active Standard users. Only users that were previously
     * referenced by a lookup are ever deleted.
     */
    public static void reshareOnUpdate(
        List<Related_Source__c> newList,
        Map<Id, Related_Source__c> oldMap
    ) {
        if (newList == null || newList.isEmpty() || oldMap == null) return;

        Map<Id, Set<Id>> addByRecord = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> removeByRecord = new Map<Id, Set<Id>>();
        Set<Id> usersToAdd = new Set<Id>();
        Set<Id> usersToRemove = new Set<Id>();

        for (Related_Source__c rs : newList) {
            Related_Source__c oldRs = oldMap.get(rs.Id);
            if (oldRs == null) continue;

            Set<Id> newUsers = desiredUsers(rs);
            Set<Id> oldUsers = desiredUsers(oldRs);

            Set<Id> added = new Set<Id>(newUsers);
            added.removeAll(oldUsers);

            Set<Id> removed = new Set<Id>(oldUsers);
            removed.removeAll(newUsers);

            if (!added.isEmpty()) {
                addByRecord.put(rs.Id, added);
                usersToAdd.addAll(added);
            }
            if (!removed.isEmpty()) {
                removeByRecord.put(rs.Id, removed);
                usersToRemove.addAll(removed);
            }
        }

        // ── Delete shares for users dropped from the lookups ─────────────────
        if (!removeByRecord.isEmpty()) {
            List<Related_Source__Share> toDelete = new List<Related_Source__Share>();
            for (Related_Source__Share sh : [
                SELECT Id, ParentId, UserOrGroupId
                FROM Related_Source__Share
                WHERE ParentId IN :removeByRecord.keySet()
                  AND UserOrGroupId IN :usersToRemove
                  AND RowCause = :ROW_CAUSE
            ]) {
                Set<Id> removedForRecord = removeByRecord.get(sh.ParentId);
                if (removedForRecord != null && removedForRecord.contains(sh.UserOrGroupId)) {
                    toDelete.add(sh);
                }
            }
            if (!toDelete.isEmpty()) {
                Database.delete(toDelete, false);
            }
        }

        // ── Insert shares for newly referenced users ─────────────────────────
        if (!addByRecord.isEmpty()) {
            Set<Id> eligibleUserIds = filterEligibleUsers(usersToAdd);
            Set<String> existing = existingShareKeys(addByRecord.keySet());

            List<Related_Source__Share> toInsert = new List<Related_Source__Share>();
            for (Id recordId : addByRecord.keySet()) {
                for (Id userId : addByRecord.get(recordId)) {
                    if (!eligibleUserIds.contains(userId)) continue;
                    if (existing.contains(recordId + '|' + userId)) continue;
                    toInsert.add(buildShare(recordId, userId));
                }
            }
            insertShares(toInsert);
        }
    }

    /** Distinct, non-null user ids referenced by the lookup fields, excluding the record Owner. */
    private static Set<Id> desiredUsers(Related_Source__c rs) {
        Set<Id> users = new Set<Id>();
        for (String fieldName : USER_LOOKUP_FIELDS) {
            Object val = rs.get(fieldName);
            if (val == null) continue;
            Id userId = (Id) val;
            if (userId == rs.OwnerId) continue; // owner already has access
            users.add(userId);
        }
        return users;
    }

    /** Existing share keys (recordId|userId) for our RowCause, used to avoid duplicates on insert. */
    private static Set<String> existingShareKeys(Set<Id> recordIds) {
        Set<String> keys = new Set<String>();
        for (Related_Source__Share s : [
            SELECT ParentId, UserOrGroupId
            FROM Related_Source__Share
            WHERE ParentId IN :recordIds
              AND RowCause = :ROW_CAUSE
        ]) {
            keys.add(s.ParentId + '|' + s.UserOrGroupId);
        }
        return keys;
    }

    private static Related_Source__Share buildShare(Id recordId, Id userId) {
        Related_Source__Share s = new Related_Source__Share();
        s.ParentId = recordId;
        s.UserOrGroupId = userId;
        s.AccessLevel = ACCESS_LEVEL;
        s.RowCause = ROW_CAUSE;
        return s;
    }

    /** Only active Standard users can be granted record shares. */
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

    private static void insertShares(List<Related_Source__Share> shares) {
        if (shares == null || shares.isEmpty()) return;
        List<Database.SaveResult> results = Database.insert(shares, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'Related_Source user-lookup share insert failed for ' + shares[i].ParentId +
                    ' user ' + shares[i].UserOrGroupId + ': ' + results[i].getErrors());
            }
        }
    }
}
