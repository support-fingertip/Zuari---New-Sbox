/**
 * @description REST API endpoint for Contact Center mobile application change password functionality.
 * This API validates customer by user identifier and old password, then updates to the new password.
 *
 * @author        Praveen Kumar
 * @version       1.0
 * @since         2026-02-13
 *
 * REST Endpoint: POST /services/apexrest/CCChangePasswordAPI/
 */
@RestResource(urlMapping='/CCChangePasswordAPI/*')
global with sharing class ChangePassword_CCMobileAPI {

    /**
     * @description Handles POST requests to change customer's password.
     * Validates the provided userId and oldPassword against Customer_Master__c records,
     * and updates the Password__c field to the provided newPassword on success.
     * All requests and responses are logged in the Apex_Log__c object for audit trail.
     *
     * Expected Request Body:
     * {
     *   "userId": "string",       // Customer identifier (Id or User_Id__c)
     *   "oldPassword": "string", // Existing password
     *   "newPassword": "string"  // New password to set
     * }
     */
    @HttpPost
    global static void changePassword() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'ChangePassword_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            ChangePasswordWrapper reqData = (ChangePasswordWrapper) JSON.deserialize(requestBody, ChangePasswordWrapper.class);

            String userId = reqData.userId;
            String oldPassword = reqData.oldPassword;
            String newPassword = reqData.newPassword;

            if (String.isBlank(userId) || String.isBlank(oldPassword) || String.isBlank(newPassword)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId, oldPassword and newPassword', 'ChangePassword_CCMobileAPI', requestBody);
                return;
            }

            // Try to find customer by Salesforce Id or by Name
            List<Customer_Master__c> cmList = [
                SELECT Id, Name, Password__c,Is_Password_Change__c
                FROM Customer_Master__c
                WHERE  Name = :userId
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'ChangePassword_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c cm = cmList[0];

            if (cm.Password__c != oldPassword) {
                ErrorResponseUitilityClass.sendErrorResponse('Old password is incorrect', 'ChangePassword_CCMobileAPI', requestBody);
                return;
            }

            cm.Password__c = newPassword;
            cm.Is_Password_Change__c = true; // Optional: Flag to indicate password has been changed
            update cm;

            Map<String, Object> response = new Map<String, Object>{
                'status' => true,
                'message' => 'Password change successfully'
            };

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Password changed successfully for ' + cm.Name;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'ChangePassword_CCMobileAPI', requestBody);
        }

    }

    public class ChangePasswordWrapper {
        public String userId;
        public String oldPassword;
        public String newPassword;
    }

}