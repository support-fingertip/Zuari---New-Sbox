trigger ProjectNameAutoFill on Project__c (before insert, before update) {
    /*for (Project__c proj : Trigger.new) {
        if (Trigger.isBefore && Trigger.isInsert) {
            if (proj.Project__c != null) {
                proj.Name = proj.Project__c;
            }
        }
        
        if (Trigger.isBefore && Trigger.isUpdate) {
            if (proj.Project__c != null && proj.Name != proj.Project__c) {
                proj.Name = proj.Project__c;
            }
        }
    }*/
}