@isTest
public class ProjectNameAutoFillTest {
    @isTest
    static void testProjectInsertAndUpdate() {
       
        List<Schema.PicklistEntry> values = 
            Project__c.Project__c.getDescribe().getPicklistValues();

        // Use the first valid value
        String firstValue = values[0].getValue();

        // Test Insert...
        Project__c proj = new Project__c(
            Project__c = firstValue
        );
        insert proj;

        Project__c insertedProj = [SELECT Id, Name, Project__c FROM Project__c WHERE Id = :proj.Id];
       

        // Test Update ...
        if (values.size() > 1) {
            String secondValue = values[1].getValue();
            insertedProj.Project__c = secondValue;
            update insertedProj;

            Project__c updatedProj = [SELECT Id, Name, Project__c FROM Project__c WHERE Id = :insertedProj.Id];
            
        }
    }
}