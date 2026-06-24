@RestResource(urlMapping='/GETPROJECTLIST/*')
global without sharing class GetProjectListAPI {
        
   @HttpGet
    global static void getPicklistValues() {
        // Create the response object
        EnumAPIResponse response = new EnumAPIResponse();
        response.success = true;
        response.message = 'Fetched Project Picklist Values Successfully';
        response.data = new EnumData();
        
        
        
        // Fetch Project picklist values
        response.data.projectList = getPicklistValues('Lead', 'Allocated_Project__c');
        
       
        // Send the response
        sendResponse(response);
    }
    
    // Helper: get picklist values
    private static List<PicklistValue> getPicklistValues(String objectName, String fieldName) {
        List<PicklistValue> picklistValues = new List<PicklistValue>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) return picklistValues;
        
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            PicklistValue picklistValue = new PicklistValue();
            picklistValue.id = entry.getValue();  // API Name
            picklistValue.name = entry.getLabel(); // Label
            picklistValues.add(picklistValue);
        }
        return picklistValues;
    }
    
    // Helper method to send response
    private static void sendResponse(EnumAPIResponse response) {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    // Response wrapper
    public class EnumAPIResponse {
        public Boolean success;
        public String message;
        public EnumData data;
    }

    // Data wrapper
    public class EnumData {
        public List<PicklistValue> projectList;
        }

    // Basic picklist wrapper
    public virtual class PicklistValue {
    public String id;
    public String name;
}
    
    // Support Type wrapper (with nested concernList)
    public class SupportTypeValue extends PicklistValue {
        public List<PicklistValue> concernList;
    }




}