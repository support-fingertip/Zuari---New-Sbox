/**
 * @description REST API endpoint for Contact Center mobile application password reset functionality.
 * This API validates customer by mobile number and updates their password.
 * 
 * @author        Praveen Kumar
 * @version       1.0
 * @since         2026-02-13
 * 
 * REST Endpoint: POST /services/apexrest/CCResetPasswordAPI/
 */
@RestResource(urlMapping='/CCResetPasswordAPI/*')
global with sharing class RestPassword_CCMobileAPI {
    
    /**
     * @description Handles POST requests for password reset.
     * Validates the provided mobile number against Customer_Master__c records,
     * and updates the password upon successful validation.
     * All requests and responses are logged in the Apex_Log__c object for audit trail.
     * 
     * @return void - Sends HTTP response with success/error status and message
     * 
     * Expected Request Body:
     * {
     *     "mobileNumber": "string", // Customer's phone number (required)
     *     "password": "string"      // New password (required)
     * }
     * 
     * Success Response (200 OK):
     * {
     *     "status": true,
     *     "message": "Password updated successfully"
     * }
     * 
     * Error Response:
     * Delegated to ErrorResponseUitilityClass which handles error formatting and logging
     */
    @HttpPost
    global static void resetPassword() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        // Initialize audit log record for tracking API requests and responses
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'RestPassword_CCMobileAPI';
        log.Request__c = requestBody;

        try {

            // Deserialize incoming JSON request into ResetPasswordWrapper object
            ResetPasswordWrapper resetPasswordData = (ResetPasswordWrapper) JSON.deserialize(requestBody, ResetPasswordWrapper.class);

            String mobile = resetPasswordData.mobileNumber;
            String newPassword = resetPasswordData.password;

            // Validate that required fields (mobile number and password) are not empty
            if (String.isBlank(mobile) || String.isBlank(newPassword)) {

                // Send error response for missing fields
                ErrorResponseUitilityClass.sendErrorResponse('Please enter valid mobile number and password', 'RestPassword_CCMobileAPI', requestBody);
                return;
            }

            // Query Customer_Master__c to validate customer with provided mobile number
            List<Customer_Master__c> cmList = [
                SELECT Id, Name, Phone_Number__c, Password__c
                FROM Customer_Master__c
                WHERE Phone_Number__c = :mobile
                AND Active__c = True
                LIMIT 1
            ];

            // If no active customer found with provided mobile number, return error
            if (cmList.isEmpty()) {

                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'RestPassword_CCMobileAPI', requestBody);
                return;
            }

            // Customer found - update password
            if (!cmList.isEmpty()) {
                
                // Update customer password
                cmList[0].Password__c = newPassword;
                update cmList[0];
                
                system.debug('Password updated for customer: ' + cmList[0].Name);
            }

            // Build successful response
            Map<String, Object> response = new Map<String, Object>{
                'status' => true,
                'message' => 'Password updated successfully'
            };

            // Set HTTP response status and body
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            // Log successful password reset
            log.Response__c = 'Password updated successfully for ' + cmList[0].Name;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {

            // Catch and log any exceptions that occur during processing
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'RestPassword_CCMobileAPI', requestBody);

        }
    }

    /**
     * @description Wrapper class for deserializing incoming password reset request JSON.
     * Maps incoming JSON fields to Apex properties for password reset operation.
     */
    public class ResetPasswordWrapper {
        public String mobileNumber;  // Customer's registered phone number
        public String password;      // New password for the customer account
    }
}