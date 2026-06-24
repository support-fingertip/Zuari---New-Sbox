public without sharing class manulaSharingClass {
    public static void manualShareSiteVisit(Map<Id,Id> SVMap){
        List<Site_Visit__Share> SVShareList = new List<Site_Visit__Share>();
        for(Id con : SVMap.keySet()){
            Site_Visit__Share ldShr  = new Site_Visit__Share();
            ldShr.parentId = con;
            ldShr.UserOrGroupId = SVMap.get(con);
            ldShr.AccessLevel = 'Read';
            ldShr.RowCause = Schema.Site_Visit__Share.RowCause.Manual;
            SVShareList.add(ldShr);
        }
        system.debug('SVShareList'+SVShareList);
        if(SVShareList.size()>0){
            List<Database.SaveResult> srList = Database.insert(SVShareList,false);
            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    system.debug('Success');
                }
                else {
                    Database.Error err = sr.getErrors()[0];
                    system.debug('Error Message'+err.getMessage());
                    if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                       err.getMessage().contains('AccessLevel')){
                       }
                    else{
                    }
                }
            }
        }
    }
    
    public static Boolean manualShareLeadVisit(Map<Id,Id> LeadMap){
        Boolean res;
        List<LeadShare> LeadShareList = new List<LeadShare>();
        for(Id con : LeadMap.keySet()){
            LeadShare ldShr  = new LeadShare();
            ldShr.LeadId = con;
            ldShr.UserOrGroupId = LeadMap.get(con);
            ldShr.LeadAccessLevel = 'Read';
            ldShr.RowCause = Schema.LeadShare.RowCause.Manual;
            LeadShareList.add(ldShr);
        }
        system.debug('LeadShareList'+LeadShareList);
        if(LeadShareList.size()>0){
            List<Database.SaveResult> srList = Database.insert(LeadShareList,false);
            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    system.debug('Success');
                    res = true;
                }
                else {
                    Database.Error err = sr.getErrors()[0];
                    system.debug('Error Message'+err.getMessage());
                    if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                       err.getMessage().contains('AccessLevel')){
                       }
                    else{
                    }
                    res = false;
                }
            }
        }
        return res;
    }
    
    /**
     * Manages Lead sharing based on Related Source records
     * - Shares Lead with RS Owner if Is_Locked__c = false
     * - Removes Lead sharing if Is_Locked__c = true
     * - Ensures only unlocked RS owners have access to the Lead
     */
    public static void manageLeadSharingFromRelatedSource(List<Related_Source__c> relatedSourceList) {
        System.debug('================ MANAGE LEAD SHARING FROM RELATED SOURCE =================');
        
        if (relatedSourceList == null || relatedSourceList.isEmpty()) {
            System.debug('No Related Source records to process');
            return;
        }
        
        // Step 1: Collect Lead & User IDs from incoming records
        Set<Id> leadIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        
        for (Related_Source__c rs : relatedSourceList) {
            if (rs.SLead__c != null && rs.OwnerId != null) {
                leadIds.add(rs.SLead__c);
                userIds.add(rs.OwnerId);
            }
        }
        
        if (leadIds.isEmpty()) {
            System.debug('No valid Lead IDs found for sharing');
            return;
        }
        
        System.debug('Processing ' + leadIds.size() + ' Leads and ' + userIds.size() + ' Users');
        
        // Step 2: Get Lead Owners (to avoid sharing Lead with its own owner)
        Map<Id, Id> leadOwnerMap = new Map<Id, Id>();
        for (Lead l : [SELECT Id, OwnerId FROM Lead WHERE Id IN :leadIds]) {
            leadOwnerMap.put(l.Id, l.OwnerId);
        }
        
        // Step 3: Query ALL Related Source records for these Leads
        List<Related_Source__c> allRelatedSources = [
            SELECT Id, SLead__c, OwnerId, Is_Locked__c
            FROM Related_Source__c
            WHERE SLead__c IN :leadIds
            AND OwnerId != null
        ];
        
        // Step 4: Build map of Lead → Users who should have access (unlocked RS only)
        Map<Id, Set<Id>> leadToUnlockedOwners = new Map<Id, Set<Id>>();
        
        for (Related_Source__c rs : allRelatedSources) {
            // Skip if RS Owner is Lead Owner
            if (leadOwnerMap.containsKey(rs.SLead__c) && 
                leadOwnerMap.get(rs.SLead__c) == rs.OwnerId) {
                System.debug('Skipping RS Owner same as Lead Owner: ' + rs.OwnerId);
                continue;
            }
            
            // Only add if Is_Locked__c = false
            if (rs.Is_Locked__c == false) {
                if (!leadToUnlockedOwners.containsKey(rs.SLead__c)) {
                    leadToUnlockedOwners.put(rs.SLead__c, new Set<Id>());
                }
                leadToUnlockedOwners.get(rs.SLead__c).add(rs.OwnerId);
            }
        }
        
        System.debug('Lead to Unlocked Owners Map: ' + leadToUnlockedOwners);
        
        // Step 5: Collect all users involved
        Set<Id> allUsersInvolved = new Set<Id>();
        allUsersInvolved.addAll(userIds);
        for (Set<Id> owners : leadToUnlockedOwners.values()) {
            allUsersInvolved.addAll(owners);
        }
        
        // Step 6: Fetch existing manual shares for these Leads and Users
        Map<String, LeadShare> existingSharesMap = new Map<String, LeadShare>();
        
        for (LeadShare ls : [
            SELECT Id, LeadId, UserOrGroupId
            FROM LeadShare
            WHERE LeadId IN :leadIds
            AND UserOrGroupId IN :allUsersInvolved
            AND RowCause = 'Manual'
        ]) {
            String key = ls.LeadId + '-' + ls.UserOrGroupId;
            existingSharesMap.put(key, ls);
        }
        
        System.debug('Found ' + existingSharesMap.size() + ' existing manual shares');
        
        // Step 7: Determine shares to insert and delete
        List<LeadShare> sharesToInsert = new List<LeadShare>();
        List<LeadShare> sharesToDelete = new List<LeadShare>();
        
        // Process each Lead
        for (Id leadId : leadIds) {
            Set<Id> usersWhoShouldHaveAccess = leadToUnlockedOwners.get(leadId);
            
            if (usersWhoShouldHaveAccess == null) {
                usersWhoShouldHaveAccess = new Set<Id>();
            }
            
            // Check all users involved with this Lead
            for (Id userId : allUsersInvolved) {
                String key = leadId + '-' + userId;
                Boolean shareExists = existingSharesMap.containsKey(key);
                Boolean shouldHaveAccess = usersWhoShouldHaveAccess.contains(userId);
                
                // Skip if user is Lead owner
                if (leadOwnerMap.containsKey(leadId) && leadOwnerMap.get(leadId) == userId) {
                    continue;
                }
                
                // Need to CREATE share
                if (shouldHaveAccess && !shareExists) {
                    LeadShare ls = new LeadShare();
                    ls.LeadId = leadId;
                    ls.UserOrGroupId = userId;
                    ls.LeadAccessLevel = 'Read';
                    ls.RowCause = Schema.LeadShare.RowCause.Manual;
                    sharesToInsert.add(ls);
                    
                    System.debug('SHARE TO CREATE → Lead: ' + leadId + ' | User: ' + userId);
                }
                
                // Need to DELETE share
                if (!shouldHaveAccess && shareExists) {
                    sharesToDelete.add(existingSharesMap.get(key));
                    
                    System.debug('SHARE TO DELETE → Lead: ' + leadId + ' | User: ' + userId);
                }
            }
        }
        
        // Step 8: Execute DML operations
        if (!sharesToInsert.isEmpty()) {
            System.debug('Inserting ' + sharesToInsert.size() + ' Lead shares');
            List<Database.SaveResult> insertResults = Database.insert(sharesToInsert, false);
            
            for (Integer i = 0; i < insertResults.size(); i++) {
                if (insertResults[i].isSuccess()) {
                    System.debug('Successfully shared Lead: ' + sharesToInsert[i].LeadId);
                } else {
                    Database.Error err = insertResults[i].getErrors()[0];
                    System.debug('Error sharing Lead: ' + err.getMessage());
                }
            }
        }
        
        if (!sharesToDelete.isEmpty()) {
            System.debug('Deleting ' + sharesToDelete.size() + ' Lead shares');
            List<Database.DeleteResult> deleteResults = Database.delete(sharesToDelete, false);
            
            for (Integer i = 0; i < deleteResults.size(); i++) {
                if (deleteResults[i].isSuccess()) {
                    System.debug('Successfully removed Lead share');
                } else {
                    Database.Error err = deleteResults[i].getErrors()[0];
                    System.debug('Error removing Lead share: ' + err.getMessage());
                }
            }
        }
        
        System.debug('================ LEAD SHARING MANAGEMENT COMPLETED =================');
    }
    
    public static void shareAnyRecord(List<Lead> leadList,String levelAccess) {
        
        Map<Id,Id> SVMap = new Map<Id,Id>();
        for(Lead ld : leadList){
            SVMap.put(ld.Lead_OwnerSecondary__c,ld.Id);
        }
        if(SVMap.size() >0){
            List<SObject> shareRecords = new List<SObject>();
            for(Id recordId :SVMap.keySet()){
                SObjectType sObjectType = SVMap.get(recordId).getSObjectType();
                system.debug(sObjectType);
                String shareObjectName;
                String parenId;
                String AccessLev;
                if (sObjectType.getDescribe().isCustom()) {
                    String objectApiName = String.valueOf(sObjectType);
                    shareObjectName = objectApiName.removeEndIgnoreCase('__c') + '__Share';
                } else {
                    shareObjectName = sObjectType + 'Share';
                    parenId = sObjectType +'Id';
                    AccessLev = sObjectType + 'AccessLevel';
                }
                Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
                system.debug(shareType);
                if (shareType != null) {
                    SObject shareRecord = shareType.newSObject();
                    if(sObjectType.getDescribe().isCustom()){
                        shareRecord.put('ParentId', SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put('AccessLevel', levelAccess);
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                    else{
                        if(shareObjectName == 'AccountShare'){
                            shareRecord.put('OpportunityAccessLevel', levelAccess); 
                        }
                        shareRecord.put(parenId, SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put(AccessLev, levelAccess);
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                } 
                else {
                    System.debug('Share object not found for ' + sObjectType);
                }
            }
            if(shareRecords.size()>0){
                List<Database.SaveResult> srList = Database.insert(shareRecords,false);
                for(Database.SaveResult sr : srList){
                    if(sr.isSuccess()){
                        system.debug('Lead Shared success');
                    }
                    else {
                        Database.Error err = sr.getErrors()[0];
                        system.debug('Error Message'+err.getMessage());
                        if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                           err.getMessage().contains('AccessLevel')){
                           }
                        else{
                        }
                    }
                }
            }
        }
    }
    
    public static void shareAnyRecordPreSales(List<Lead> leadList,String levelAccess) {
        
        Map<Id,Id> SVMap = new Map<Id,Id>();
        for(Lead ld : leadList){
            SVMap.put(ld.Pre_sales_user__c,ld.Id);
        }
        if(SVMap.size() >0){
            List<SObject> shareRecords = new List<SObject>();
            for(Id recordId :SVMap.keySet()){
                SObjectType sObjectType = SVMap.get(recordId).getSObjectType();
                system.debug(sObjectType);
                String shareObjectName;
                String parenId;
                String AccessLev;
                if (sObjectType.getDescribe().isCustom()) {
                    String objectApiName = String.valueOf(sObjectType);
                    shareObjectName = objectApiName.removeEndIgnoreCase('__c') + '__Share';
                } else {
                    shareObjectName = sObjectType + 'Share';
                    parenId = sObjectType +'Id';
                    AccessLev = sObjectType + 'AccessLevel';
                }
                Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
                system.debug(shareType);
                if (shareType != null) {
                    SObject shareRecord = shareType.newSObject();
                    if(sObjectType.getDescribe().isCustom()){
                        shareRecord.put('ParentId', SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put('AccessLevel', levelAccess);
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                    else{
                        if(shareObjectName == 'AccountShare'){
                            shareRecord.put('OpportunityAccessLevel', levelAccess); 
                        }
                        shareRecord.put(parenId, SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put(AccessLev, levelAccess);
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                } 
                else {
                    System.debug('Share object not found for ' + sObjectType);
                }
            }
            if(shareRecords.size()>0){
                List<Database.SaveResult> srList = Database.insert(shareRecords,false);
                for(Database.SaveResult sr : srList){
                    if(sr.isSuccess()){
                        system.debug('Lead Shared success');
                    }
                    else {
                        Database.Error err = sr.getErrors()[0];
                        system.debug('Error Message'+err.getMessage());
                        if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                           err.getMessage().contains('AccessLevel')){
                           }
                        else{
                        }
                    }
                }
            }
        }
    }
    
    //not using
    public static void checkShared(List<Lead> updateList){
        Map<Id, Id> leadToShare = new Map<Id, Id>();
        Set<Id> leadIdsToRevoke = new Set<Id>();
      
        for (Lead dl : updateList) {
            if (dl.Lead_OwnerSecondary__c != null) {
                leadToShare.put(dl.Lead_OwnerSecondary__c,dl.Id);
            } else {
                leadIdsToRevoke.add(dl.Id); 
            }
        }
        if(leadIdsToRevoke.size() >0){
            List<LeadShare> existingShares = [SELECT Id, LeadId, UserOrGroupId FROM LeadShare WHERE LeadId IN :leadToShare.keySet() and RowCause = 'Manual'];
            
            Map<Id, Set<Id>> leadToExistingShares = new Map<Id, Set<Id>>();
            for (LeadShare share : existingShares) {
                if (!leadToExistingShares.containsKey(share.LeadId)) {
                    leadToExistingShares.put(share.UserOrGroupId, new Set<Id>());
                }
                //leadToExistingShares.get(share.LeadId).add(share.UserOrGroupId);
            }
            
            for (Id leadId : leadIdsToRevoke) {
                if (leadToExistingShares.containsKey(leadId)) {
                    Set<Id> usersWithAccess = leadToExistingShares.get(leadId);
                    system.debug('Called revoke access');
                    revokeAccess(usersWithAccess);
                }
            }
            
        }
        if(leadToShare.size() > 0){
            system.debug('Called the share nay lead');
            //shareAnyRecord(leadToShare, 'Edit');
        }
        
    }
     public static void bookingsToShare(List<Booking__c> bookingsList) {
    system.debug('shareAnyRecord breached ------- ');

    // Step 1: Revoke old manual shares
    Set<Id> bookingIds = new Set<Id>();
    for(Booking__c ld : bookingsList) bookingIds.add(ld.Id);

    List<Booking__Share> oldShares = [
        SELECT Id FROM Booking__Share 
        WHERE ParentId IN :bookingIds 
        AND RowCause = 'Manual'
    ];
    if(!oldShares.isEmpty()) delete oldShares;

    // Step 2: Build corrected map (supports multiple bookings per user)
    Map<Id, List<Id>> SVMap = new Map<Id, List<Id>>();
    for(Booking__c ld : bookingsList){
        if(ld.Sales_User__c != null){
            if(!SVMap.containsKey(ld.Sales_User__c)){
                SVMap.put(ld.Sales_User__c, new List<Id>());
            }
            SVMap.get(ld.Sales_User__c).add(ld.Id);
        }
    }

    // Step 3: Create share records
    if(SVMap.size() > 0){
        List<SObject> shareRecords = new List<SObject>();
        for(Id userId : SVMap.keySet()){
            for(Id bookingId : SVMap.get(userId)){
                SObject shareRecord = Schema.getGlobalDescribe()
                    .get('Booking__Share').newSObject();
                shareRecord.put('ParentId', bookingId);
                shareRecord.put('UserOrGroupId', userId);
                shareRecord.put('AccessLevel', 'Read');
                shareRecord.put('RowCause', 'Manual');
                shareRecords.add(shareRecord);
            }
        }

        if(shareRecords.size() > 0){
            List<Database.SaveResult> srList = Database.insert(shareRecords, false);
            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    system.debug('Booking Shared success');
                } else {
                    system.debug('Error: ' + sr.getErrors()[0].getMessage());
                }
            }
        }
    }
}
 
    @future
    public static void revokeAccess(Set<Id> ldId){
        List<LeadShare> sharesToDelete = [SELECT Id FROM LeadShare WHERE LeadId in: ldId and RowCause = 'Manual'];
        system.debug('Called revoke access lead share '+sharesToDelete);
        if (!sharesToDelete.isEmpty()) {
            delete sharesToDelete;
        }
    }
    
    public static void shareWithPreSalesUser(List<Related_Source__c> newRecords) {

    List<Related_Source__Share> shareList = new List<Related_Source__Share>();

    for(Related_Source__c rs : newRecords) {

        if(rs.Pre_Sales_user__c != null) {

            Related_Source__Share shareRec = new Related_Source__Share();
            shareRec.ParentId = rs.Id;
            shareRec.UserOrGroupId = rs.Pre_Sales_user__c;
            shareRec.AccessLevel = 'Edit';
            shareRec.RowCause = Schema.Related_Source__Share.RowCause.Manual;

            shareList.add(shareRec);
        }
    }

    if(!shareList.isEmpty()) {
        Database.insert(shareList, false);
    }
}
    public static void shareWithSalesUser(List<Related_Source__c> newRecords) {

    List<Related_Source__Share> shareList = new List<Related_Source__Share>();

    for(Related_Source__c rs : newRecords) {

        if(rs.STM2__c != null) {

            Related_Source__Share shareRec = new Related_Source__Share();
            shareRec.ParentId = rs.Id;
            shareRec.UserOrGroupId = rs.STM2__c;
            shareRec.AccessLevel = 'Edit';
            shareRec.RowCause = Schema.Related_Source__Share.RowCause.Manual;

            shareList.add(shareRec);
        }
    }

    if(!shareList.isEmpty()) {
        Database.insert(shareList, false);
    }
}
}