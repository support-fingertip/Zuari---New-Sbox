public with sharing class CustomerQueryAssignmentService {

    private static final String CRM_EXECUTIVE_PROFILE = 'CRM Executive';

    public static void assignOwners(List<Customer_Query__c> newList) {
        Set<Id> currentOwnerUserIds = new Set<Id>();
        for (Customer_Query__c cq : newList) {
            if (cq.OwnerId != null && String.valueOf(cq.OwnerId).startsWith('005')) {
                currentOwnerUserIds.add(cq.OwnerId);
            }
        }

        Set<Id> alreadyCrmExecOwners = new Set<Id>();
        if (!currentOwnerUserIds.isEmpty()) {
            for (User u : [
                SELECT Id FROM User
                WHERE Id IN :currentOwnerUserIds
                  AND Profile.Name = :CRM_EXECUTIVE_PROFILE
            ]) {
                alreadyCrmExecOwners.add(u.Id);
            }
        }

        List<User> execs = [
            SELECT Id
            FROM User
            WHERE IsActive = true
              AND Profile.Name = :CRM_EXECUTIVE_PROFILE
            ORDER BY Last_Query_Assigned_Time__c ASC NULLS FIRST, Id ASC
        ];
        if (execs.isEmpty()) {
            return;
        }

        Set<Id> stampUserIds = new Set<Id>();
        Integer pointer = 0;
        for (Customer_Query__c cq : newList) {
            if (cq.OwnerId != null && alreadyCrmExecOwners.contains(cq.OwnerId)) {
                continue;
            }
            Id chosen = execs[pointer].Id;
            cq.OwnerId = chosen;
            stampUserIds.add(chosen);
            pointer = Math.mod(pointer + 1, execs.size());
        }

        if (!stampUserIds.isEmpty() && !System.isQueueable() && !System.isFuture() && !System.isBatch()) {
            System.enqueueJob(new CustomerQueryUserStampQueueable(stampUserIds));
        } else if (!stampUserIds.isEmpty()) {
            CustomerQueryUserStampQueueable.stampNow(stampUserIds);
        }
    }
}