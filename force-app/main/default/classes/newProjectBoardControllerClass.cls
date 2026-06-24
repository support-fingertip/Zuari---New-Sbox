/****************************************************************
* Class Name : newProjectBoardControllerClass
* Company : Fingertipplus
* Created Date : 1-04-2025
* @description : This class is responsible for showing the data in Custom Tab Inventory Managment.
* @author : Praveen Kumar
* Used By : newInventoryManagment Aura Component
* 
*
* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author | Date | Description
* -----------------------------------------------------------------------------
* 1.0 | Praveen Kumar | 1-04-2025 | Initial version
* -----------------------------------------------------------------------------
**************************************************************/
public class newProjectBoardControllerClass {
     @auraEnabled
    Public static List<Project__c> getProjects(){
        return [SELECT Id,Name,Project__c,Project_Address__c,Total_Units__c,Available_Units__c,Booked_Units__c,Not_Released_Units__c,Blocked_Units__c, Sold_Units__c FROM Project__c];
    }
    @auraEnabled
    Public static List<Plot__c> getPlots(string Project){
        return [SELECT Id,Name,Project__c, BHK_Type__c,  Unit_Facing_Direction__c, Plot_Type__c, Status__c,Super_Built_up_Area__c,Rate_per_sqft__c,
                Block_Name__c,Wing__c FROM Plot__c WHERE Project__c=:project order by Name Asc];
    }
 @AuraEnabled
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        
        // Get the describe result for the object
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        
        // Get the field describe result
        Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
        
        // Get the picklist values
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) { // Only include active values
                picklistValues.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }
        
        return picklistValues;
    }
	
     @AuraEnabled(cacheable=true)
    public static List<String> getBlockNames(String projectId) {
        List<Block__c> blocks = [SELECT Name FROM Block__c WHERE Project__c = :projectId];
        List<String> blockNames = new List<String>();
        for (Block__c block : blocks) {
            blockNames.add(block.Name);
        }
        return blockNames;
    }
}