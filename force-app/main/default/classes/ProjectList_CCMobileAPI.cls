/**
 * @description REST helper to expose picklist values for the mobile app.
 * This class returns the values for the `Allocated_Project__c` picklist on the `Lead` object
 * (used as the projects list in the mobile client).
 *
 * Endpoint: GET /services/apexrest/CCProjectList/
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-23
 */
@RestResource(urlMapping='/CCProjectList/*')
global without sharing class ProjectList_CCMobileAPI {

    /**
     * GET handler — returns picklist values for the configured field.
     * The method builds an `EnumAPIResponse` and serializes it to the REST response.
     */
    @HttpGet
    global static void getPicklistValues() {
        // Create the response object
        EnumAPIResponse response = new EnumAPIResponse();
        response.status = true;
        response.message = 'projects list';

        // Fetch picklist values from Lead.Allocated_Project__c
        response.data = getPicklistValues('Lead', 'Allocated_Project__c');

        // Send the response as JSON
        sendResponse(response);
    }

    /**
     * Retrieves picklist entries for a given object's field and maps them into simple wrappers.
     * @param objectName API name of the sObject (e.g., 'Lead')
     * @param fieldName API name of the picklist field (e.g., 'Allocated_Project__c')
     */
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

    /**
     * Writes the response object to the REST context as JSON with HTTP 200.
     */
    private static void sendResponse(EnumAPIResponse response) {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    // ===== Response wrapper classes =====

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

    // Support Type wrapper (with nested concernList) — extends the basic picklist wrapper
    public class SupportTypeValue extends PicklistValue {
        public List<PicklistValue> concernList;
    }

}