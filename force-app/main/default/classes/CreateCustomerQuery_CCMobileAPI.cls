/**
 * @description REST API endpoint for Contact Center mobile application to create customer queries.
 * Validates customer and booking, verifies project/unit match, then creates Customer_Query__c record.
 *
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "projectId": "CPP001",
 *   "unitNumberId": "",
 *   "subject": "",
 *   "queryTypeId": "",
 *   "subTypeId": "",
 *   "description": ""
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Query created successfully",
 *   "data": {
 *     "queryId": "CQ001"
 *   }
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-23
 */
@RestResource(urlMapping='/CCCreateCustomerQueryAPI/*')
global without sharing class CreateCustomerQuery_CCMobileAPI {

    /**
     * @description Handles POST requests to create customer queries.
     * Validates customer, fetches bookings, verifies project/unit match,
     * and creates Customer_Query__c record.
     */
    @HttpPost
    global static void createCustomerQuery() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'CreateCustomerQuery_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            CreateQueryRequestWrapper requestData = (CreateQueryRequestWrapper) JSON.deserialize(requestBody, CreateQueryRequestWrapper.class);

            String userId = requestData.userId;
            String projectId = requestData.projectId;
            String unitNumberId = requestData.unitNumberId;
            String subject = requestData.subject;
            String queryTypeId = requestData.queryTypeId;
            String subTypeId = requestData.subTypeId;
            String description = requestData.description;
            String otherQueryDescription = requestData.otherQueryDescription;

            // Validate that required fields are not empty
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'CreateCustomerQuery_CCMobileAPI', requestBody);
                return;
            }

            // Validate customer exists
            List<Customer_Master__c> cmList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'CreateCustomerQuery_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = cmList[0];

            // Fetch all bookings for this customer
            List<Booking__c> bookingList = [
                SELECT Id, Name, Plot__c, Plot__r.Name, Plot__r.Project__c, Plot__r.Project__r.Name,PLot__r.Project__r.Project__c,PLot__r.Project__r.Project_Id__c
                FROM Booking__c
                WHERE Customer_Master__c = :customer.Id
                LIMIT 15
            ];

            if (bookingList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('No bookings found for this customer', 'CreateCustomerQuery_CCMobileAPI', requestBody);
                return;
            }

            // Verify project and unit match for at least one booking
            Booking__c matchedBooking = null;

            for (Booking__c booking : bookingList) {
                // Check if project matches
                if (booking.Plot__r.Project__c != null && booking.Plot__r.Project__r.Project_Id__c == projectId) {
                    // If unitNumberId is provided, also check unit match
                    if (String.isBlank(unitNumberId) || (booking.Plot__c != null && booking.Plot__r.Name == unitNumberId)) {
                        matchedBooking = booking;
                        break;
                    }
                }
            }

            // If no matching booking found
            if (matchedBooking == null) {
                ErrorResponseUitilityClass.sendErrorResponse('There is no purchased unit for this project', 'CreateCustomerQuery_CCMobileAPI', requestBody);
                return;
            }

            // Check for duplicate query
            List<Customer_Query__c> existingQueries = [
                SELECT Id
                FROM Customer_Query__c
                WHERE Customer_Master__c = :customer.Id
                  AND Booking__c = :matchedBooking.Id
                  AND Query_Type__c = :queryTypeId
                  AND Query_Sub_Type__c = :subTypeId
                  AND Lapse_Email_Sent__c = false
                  AND Query_Status__c != 'Closed'
                LIMIT 1
            ];

            if (!existingQueries.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('For this Booking already query is submitted', 'CreateCustomerQuery_CCMobileAPI', requestBody);
                return;
            }

            // Create Customer Query
            Customer_Query__c customerQuery = new Customer_Query__c();
            customerQuery.Customer_Master__c = customer.Id;
            customerQuery.Booking__c = matchedBooking.Id;
            customerQuery.Project__c = matchedBooking.PLot__r.Project__r.Project__c;
            customerQuery.Unit__c = String.isBlank(unitNumberId) ? null : matchedBooking.Plot__c;
            customerQuery.Subject__c = String.isBlank(subject) ? '' : subject;
            customerQuery.Query_Type__c = String.isBlank(queryTypeId) ? '' : queryTypeId;
            customerQuery.Query_Sub_Type__c = String.isBlank(subTypeId) ? '' : subTypeId;
            customerQuery.Description__c = String.isBlank(description) ? '' : description;
            customerQuery.Query_Status__c = 'New';
            customerQuery.Other_Query__c = String.isBlank(otherQueryDescription) ? '' : otherQueryDescription;
            
            insert customerQuery;

            // Build response data
            CreateQueryResponseData responseData = new CreateQueryResponseData();
            responseData.queryId = customerQuery.Id;

            // Build response
            CreateQueryResponse response = new CreateQueryResponse();
            response.status = true;
            response.message = 'Customer Query created successfully';
            response.data = responseData;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Customer query created successfully: ' + customerQuery.Id;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'CreateCustomerQuery_CCMobileAPI', requestBody);
        }
    }

    // ===== Request Wrapper =====
    /**
     * @description Wrapper class for deserializing create query request JSON.
     */
    public class CreateQueryRequestWrapper {
        public String userId;        // Customer identifier
        public String projectId;     // Project identifier
        public String unitNumberId;  // Unit/Plot identifier (optional)
        public String subject;       // Query subject
        public String queryTypeId;   // Query type
        public String subTypeId;     // Query sub-type
        public String description;   // Query description
        public String otherQueryDescription;   // Query description
    }

    // ===== Response Wrapper Classes =====
    /**
     * @description Wrapper class for query ID in response.
     */
    public class CreateQueryResponseData {
        public String queryId;  // Created Customer_Query__c record Id
    }

    /**
     * @description Wrapper class for complete API response.
     */
    public class CreateQueryResponse {
        public Boolean status;                  // Response status
        public String message;                  // Response message
        public CreateQueryResponseData data;    // Response data
    }

}