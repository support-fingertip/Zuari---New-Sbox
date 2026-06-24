public with sharing class RelatedSourceBulkOwnerAuraCtrl {

    @AuraEnabled
    public static List<Related_Source__c> fetchRelatedSources(
        Date fromDate,
        Date toDate,
        Id fromUserId,
        String allocatedProjectValue,
        String sourceTypeValue
    ) {
        String query = 'SELECT Id, Name, OwnerId, Owner.Name, Allocated_Project__c, source_type__c, CreatedDate FROM Related_Source__c WHERE Id != null';
        if (fromDate != null)                                            query += ' AND CreatedDate >= :fromDate';
        if (toDate != null)                                              query += ' AND CreatedDate <= :toDate';
        if (fromUserId != null)                                          query += ' AND OwnerId = :fromUserId';
        if (allocatedProjectValue != null && allocatedProjectValue != '') query += ' AND Allocated_Project__c = :allocatedProjectValue';
        if (sourceTypeValue != null && sourceTypeValue != '')            query += ' AND source_type__c = :sourceTypeValue';
        query += ' ORDER BY CreatedDate DESC LIMIT 500';
        return Database.query(query);
    }

    @AuraEnabled
    public static List<Map<String,String>> getUsers() {
        List<Map<String,String>> options = new List<Map<String,String>>();
        for (User u : [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name])
            options.add(new Map<String,String>{ 'label' => u.Name, 'value' => u.Id });
        return options;
    }

    @AuraEnabled
    public static List<String> getAllocatedProjectPicklistValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldDesc = Related_Source__c.Allocated_Project__c.getDescribe();
        for (Schema.PicklistEntry pe : fieldDesc.getPicklistValues())
            values.add(pe.getValue());
        return values;
    }

    @AuraEnabled
    public static List<String> getSourceTypePicklistValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldDesc = Related_Source__c.source_type__c.getDescribe();
        for (Schema.PicklistEntry pe : fieldDesc.getPicklistValues())
            values.add(pe.getValue());
        return values;
    }

    @AuraEnabled
    public static void bulkUpdateOwner(List<Id> recordIds, Id toUserId) {
        if (recordIds == null || recordIds.isEmpty()) throw new AuraHandledException('Select at least one record.');
        if (toUserId == null) throw new AuraHandledException('To User is required.');
        List<Related_Source__c> updateList = new List<Related_Source__c>();
        for (Id recId : recordIds)
            updateList.add(new Related_Source__c(Id = recId, OwnerId = toUserId));
        update updateList;
    }

    @AuraEnabled
    public static void bulkUpdateEmptySTM2(List<Id> recordIds, Id stm2UserId) {
        List<Related_Source__c> recordsToUpdate = [
            SELECT Id, STM2__c FROM Related_Source__c
            WHERE Id IN :recordIds AND STM2__c = null
        ];
        for (Related_Source__c rec : recordsToUpdate)
            rec.STM2__c = stm2UserId;
        update recordsToUpdate;
    }

    @AuraEnabled
    public static void bulkReassignSTM2(List<Id> recordIds, Id fromUserId, Id toUserId) {
        List<Related_Source__c> recordsToUpdate = [
            SELECT Id, STM2__c FROM Related_Source__c
            WHERE Id IN :recordIds AND STM2__c = :fromUserId
        ];
        for (Related_Source__c rec : recordsToUpdate)
            rec.STM2__c = toUserId;
        update recordsToUpdate;
    }
}