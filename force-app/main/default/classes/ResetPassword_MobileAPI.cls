/****************************************************************
* Class Name   : ResetPassword_MobileAPI
* Company      : Fingertipplus
* Created Date : 15-12-2025 
*
* @description :
* This Apex REST API handles the "Reset Password" functionality
* for the mobile application.
*
* Flow:
*  - Accepts mobile number and new password as input
*  - Validates mobile number and password for null/blank
*  - Checks for active Customer_Master__c record matching the mobile number
*  - Updates the Password__c field for the user
*  - Returns structured JSON response indicating success or failure
*  - Logs request and response using Apex_Log__c
*
* Input JSON:
* {
*   "mobileNumber": "999999999",
*   "password": "NewPassword123"
* }
*
* Output (Success):
* {
*   "status": true,
*   "message": "Password updated successfully"
* }
*
* Output (Failure):
* {
*   "status": false,
*   "message": "Error message"
* }
*
* Author       : Sandeep Kumar
*
* Change Log:
* ---------------------------------------------------------------------------------------
* Version | Author         | Date       | Description
* ---------------------------------------------------------------------------------------
* 1.0     | Sandeep Kumar  | 15-12-2025 | Initial version
******************************************************************************************/

@RestResource(urlMapping='/ResetPasswordAPI/*')
global without sharing class ResetPassword_MobileAPI {

    @HttpPost
    global static void resetPasswordMethod() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        // Logging
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'ResetPassword_MobileAPI';
        log.Request__c = requestBody;

        try {
            // Deserialize input JSON
            ResetPasswordWrapper inputData = (ResetPasswordWrapper) JSON.deserialize(requestBody, ResetPasswordWrapper.class);
            String mobile = inputData.mobileNumber;
            String newPassword = inputData.password;

            // Validate input
            if (String.isBlank(mobile) || String.isBlank(newPassword)) {
                  ErrorResponseUitilityClass.sendErrorResponse('Mobile number or password should not be blank','ResetPassword_MobileAPI',requestBody);
              
                return;
            }

            // Query customer by mobile number and active status
            List<Channel_Partner__c> cmList = [
                SELECT Id, Password__c, Name,Mobile_Number__c,Email__c
                FROM Channel_Partner__c
                WHERE Mobile_Number__c = :mobile
                  AND Active__c = TRUE
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found','ResetPassword_MobileAPI',requestBody);
                return;
            }

            Channel_Partner__c cm = cmList[0];

            // Update password
            cm.Password__c = newPassword;
             //cm.Is_Password_Change__c = true;
            update cm;

            // Log success
            log.Response__c = 'Password updated successfully for ' + cm.Name;
            log.Status__c = 'SUCCESS';
            insert log;

            // Send success response
            sendSuccessResponse();

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'ResetPassword_MobileAPI',requestBody);
           }
    }

    // Input wrapper
    public class ResetPasswordWrapper {
        public String mobileNumber;
        public String password;
    }

    // Response wrapper
    public class ResponseWrapper {
        public Boolean status;
        public String message;
    }

    // Error response
    /*
    private static void sendErrorResponse(String message) {
        ResponseWrapper response = new ResponseWrapper();
        response.status = false;
        response.message = message;

        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }*/

    // Success response
    private static void sendSuccessResponse() {
        ResponseWrapper response = new ResponseWrapper();
        response.status = true;
        response.message = 'Password updated successfully';

        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }
}