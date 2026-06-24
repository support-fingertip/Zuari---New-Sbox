/**
 * RelatedSourceSharingService
 * 
 * Flow passes in a list of Related_Source__c record IDs.
 * The class handles everything else:
 *   - Queries STM2__c and SLead__c on each record
 *   - Skips shares that already exist
 *   - Creates manual shares for:
 *       1. Related_Source__c  → shared with STM2__c user
 *       2. SLead__c (Lead)    → shared with STM2__c user
 */
public with sharing class RelatedSourceSharingService {

    @InvocableMethod(
        label='Share Related Source with STM2 User'
        description='Pass in Related_Source__c record IDs. Shares each record and its related Lead (SLead__c) with the STM2__c user if not already shared.'
        category='Sharing'
    )
    public static void shareWithSTM2User(List<Id> recordIds) {

        if (recordIds == null || recordIds.isEmpty()) return;

        // ── Step 1: Query records ────────────────────────────────────────────
        List<Related_Source__c> records = [
            SELECT Id, STM2__c, SLead__c
            FROM Related_Source__c
            WHERE Id IN :recordIds
              AND STM2__c != null
        ];

        if (records.isEmpty()) return;

        // Collect Lead IDs for share dedup check
        Set<Id> leadIds = new Set<Id>();
        for (Related_Source__c rec : records) {
            if (rec.SLead__c != null) {
                leadIds.add(rec.SLead__c);
            }
        }

        // ── Step 2: Find existing manual shares to avoid duplicates ──────────

        // Related_Source__c existing shares
        Set<String> existingRelatedSourceShares = new Set<String>();
        for (Related_Source__Share s : [
            SELECT ParentId, UserOrGroupId
            FROM Related_Source__Share
            WHERE ParentId IN :recordIds
              AND RowCause = :Schema.Related_Source__Share.RowCause.Manual
        ]) {
            existingRelatedSourceShares.add(s.ParentId + '|' + s.UserOrGroupId);
        }

        // Lead existing shares
        Set<String> existingLeadShares = new Set<String>();
        if (!leadIds.isEmpty()) {
            for (LeadShare s : [
                SELECT LeadId, UserOrGroupId
                FROM LeadShare
                WHERE LeadId IN :leadIds
                  AND RowCause = 'Manual'
            ]) {
                existingLeadShares.add(s.LeadId + '|' + s.UserOrGroupId);
            }
        }

        // ── Step 3: Build new shares ─────────────────────────────────────────
        List<Related_Source__Share> newRelatedSourceShares = new List<Related_Source__Share>();
        List<LeadShare> newLeadShares = new List<LeadShare>();

        for (Related_Source__c rec : records) {

            // Share Related_Source__c
            String rsKey = rec.Id + '|' + rec.STM2__c;
            if (!existingRelatedSourceShares.contains(rsKey)) {
                Related_Source__Share s = new Related_Source__Share();
                s.ParentId      = rec.Id;
                s.UserOrGroupId = rec.STM2__c;
                s.AccessLevel   = 'Edit';
                s.RowCause      = Schema.Related_Source__Share.RowCause.Manual;
                newRelatedSourceShares.add(s);
            }

            // Share related Lead (SLead__c)
            if (rec.SLead__c != null) {
                String leadKey = rec.SLead__c + '|' + rec.STM2__c;
                if (!existingLeadShares.contains(leadKey)) {
                    LeadShare ls = new LeadShare();
                    ls.LeadId         = rec.SLead__c;
                    ls.UserOrGroupId  = rec.STM2__c;
                    ls.LeadAccessLevel = 'Edit';
                    ls.RowCause       = 'Manual';
                    newLeadShares.add(ls);
                }
            }
        }

        // ── Step 4: Insert ───────────────────────────────────────────────────
        if (!newRelatedSourceShares.isEmpty()) {
            Database.insert(newRelatedSourceShares, false);
        }

        if (!newLeadShares.isEmpty()) {
            Database.insert(newLeadShares, false);
        }
    }
}