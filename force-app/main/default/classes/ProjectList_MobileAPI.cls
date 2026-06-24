/****************************************************************
* Class Name   : ProjectList_MobileAPI
* Company      : Fingertipplus
* Created Date : 27-05-2025
*
* @description :
* This Apex REST API exposes the endpoint `/ProjectList/*` and is
* designed to provide a list of project names for mobile and
* external applications.
*
* The API fetches project values dynamically from the
* `Allocated_Project__c` picklist field on the Lead object and
* returns them in a simple, mobile-friendly format.
*
* Functional Overview:
* - Exposes a GET endpoint to retrieve project picklist values.
* - Uses Salesforce Schema Describe to dynamically fetch
*   picklist metadata.
* - Returns both API values and user-facing labels.
* - Eliminates the need for hardcoded project lists on frontend.
*
* Response Structure:
* - status   : Indicates API execution result
* - message  : Response message
* - data     : List of project values (id & name)
*
* Key Features:
* - Centralized project list API
* - Schema-driven picklist retrieval
* - Lightweight response for dropdown usage
* - Easy to extend to other picklists if required
*
* Author       : Praveen Kumar
*
* Change Log:
* --------------------------------------------------------------------------
* Ver | Author         | Date       | Description
* --------------------------------------------------------------------------
* 1.0 | Praveen Kumar  | 27-12-2025 | Initial implementation
* --------------------------------------------------------------------------
**************************************************************/

@RestResource(urlMapping='/ProjectList/*')
global without sharing class ProjectList_MobileAPI {
        
   @HttpGet
    global static void getPicklistValues() {
        // Create the response object
        EnumAPIResponse response = new EnumAPIResponse();
        response.status = true;
        response.message = 'projects list';
        
        
        // Fetch Priority picklist values
        response.data = getPicklistValues('Lead', 'Allocated_Project__c');
        
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
        public Boolean status;
        public String message;
        
        public List<PicklistValue> data;
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