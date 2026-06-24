/**
 * @description REST API endpoint for Contact Center mobile application to submit feedback on a customer query.
 * Validates customer and query, then updates the Customer_Query__c record with feedback details.
 *
 * Request:
 * {
 *   "userId": "CM-0001",
 *   "queryId": "CQ-0024",
 *   "feedbackDescription": "",
 *   "rattingId": 2
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Feedback submit successfully"
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-04-10
 */
@RestResource(urlMapping='/CCSubmitFeedbackAPI/*')
global without sharing class SubmitFeedback_CCMobileAPI {

    /**
     * @description Handles POST requests to submit feedback on a customer query.
     * Validates customer, fetches query by queryId (auto-number Name), and updates feedback fields.
     */
    @HttpPost
    global static void submitFeedback() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'SubmitFeedback_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            FeedbackRequestWrapper requestData = (FeedbackRequestWrapper) JSON.deserialize(requestBody, FeedbackRequestWrapper.class);

            String userId = requestData.userId;
            String queryId = requestData.queryId;

            // Validate that userId is provided
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'SubmitFeedback_CCMobileAPI', requestBody);
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
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'SubmitFeedback_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = cmList[0];

            // Validate that queryId is provided
            if (String.isBlank(queryId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide queryId', 'SubmitFeedback_CCMobileAPI', requestBody);
                return;
            }

            // Fetch the Customer Query by Name (auto-number) and Customer
            List<Customer_Query__c> queryList = [
                SELECT Id, Name
                FROM Customer_Query__c
                WHERE Name = :queryId
                AND Customer_Master__c = :customer.Id
                LIMIT 1
            ];

            if (queryList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Query Not Found', 'SubmitFeedback_CCMobileAPI', requestBody);
                return;
            }

            // Update the Customer Query with feedback details
            Customer_Query__c cq = queryList[0];
            cq.Feedback_Detail__c = String.isNotBlank(requestData.feedbackDescription) ? requestData.feedbackDescription : '';
            cq.Feedback_Rating__c = requestData.rattingId != null ? String.valueOf(requestData.rattingId) : null;
            cq.Feedback_Submitted_Time__c = System.now();
            update cq;

            // Build response
            FeedbackResponse response = new FeedbackResponse();
            response.status = true;
            response.message = 'Feedback submit successfully';

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Feedback submitted for query: ' + cq.Name;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'SubmitFeedback_CCMobileAPI', requestBody);
        }
    }

    // ===== Request Wrapper =====
    /**
     * @description Wrapper class for deserializing feedback request JSON.
     */
    public class FeedbackRequestWrapper {
        public String userId;              // Customer identifier (e.g., "CM-0001")
        public String queryId;             // Query auto-number Name (e.g., "CQ-0024")
        public String feedbackDescription; // Feedback text
        public String rattingId;          // Rating value (e.g., 2)
    }

    // ===== Response Wrapper =====
    /**
     * @description Wrapper class for complete API response.
     */
    public class FeedbackResponse {
        public Boolean status;   // Response status
        public String message;   // Response message
    }

}