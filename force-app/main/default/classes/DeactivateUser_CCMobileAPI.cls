/**
 * @description REST API endpoint for Contact Center mobile application to deactivate (delete) a customer account.
 * Validates the customer using supplied `userId` (Salesforce Id or Name) and sets Active__c = False.
 *
 * Request:
 * {
 *   "userId": 9
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Account deleted successfully"
 * }
 *
 * @author Praveen Kumar
 */
@RestResource(urlMapping='/CCDeactivateUserAPI/*')
global with sharing class DeactivateUser_CCMobileAPI {

    @HttpPost
    global static void deactivateUser() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'DeactivateUser_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            DeactivateWrapper data = (DeactivateWrapper) JSON.deserialize(requestBody, DeactivateWrapper.class);
            String userId = data.userId;

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'DeactivateUser_CCMobileAPI', requestBody);
                return;
            }

            // Find the customer by Id or Name
            List<Customer_Master__c> cmList = [
                SELECT Id, Name, Active__c
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'DeactivateUser_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c cm = cmList[0];
            cm.Active__c = False;
            update cm;

            Map<String, Object> response = new Map<String, Object>{
                'status' => true,
                'message' => 'Account deleted successfully'
            };

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Account deactivated for ' + cm.Name;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'DeactivateUser_CCMobileAPI', requestBody);
        }

    }

    public class DeactivateWrapper {
        public String userId;
    }

}