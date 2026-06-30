/**
 * RelatedSourceUserLookupSharingBatch
 *
 * One-time (or ad-hoc) backfill that grants user-lookup shares to existing
 * Related_Source__c records, reusing RelatedSourceUserLookupSharing.shareOnInsert.
 *
 * Run after deploy:
 *   Database.executeBatch(new RelatedSourceUserLookupSharingBatch(), 200);
 */
public without sharing class RelatedSourceUserLookupSharingBatch
    implements Database.Batchable<SObject> {

    // Keep in sync with RelatedSourceUserLookupSharing.USER_LOOKUP_FIELDS.
    private static final String QUERY =
        'SELECT Id, OwnerId, ' +
        'Assign_To__c, Extension_Approver__c, Extension_Requested_By__c, ' +
        'Last_Unqualified_by__c, Lead_OwnerSecondary__c, Pre_Sales_User__c, ' +
        'RM_CP_Name__c, Sales_User__c, SV_User__c, STM2__c, ' +
        'Search_Closing_Manager__c, Search_Sourcing_Manager__c, Transfered_By__c ' +
        'FROM Related_Source__c';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<Related_Source__c> scope) {
        RelatedSourceUserLookupSharing.shareOnInsert(scope);
    }

    public void finish(Database.BatchableContext bc) {
        // no-op
    }
}
