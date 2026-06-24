/*****************************************************************************************
* Class Name   : ChangePasswordAPI_MobileAPI
* Company      : Fingertipplus
* Created Date : 16-12-2025
*
* Description  :
* ---------------------------------------------------------------------------------------
* This Apex class exposes a RESTful POST web service for changing the password
* of a Channel Partner based on their userId and old password.
*
* Input JSON:
* ---------------------------------------------------------------------------------------
* {
*   "userId": "CP-003",
*   "oldPassword": "Test@123",
*   "newPassword": "Test@1234"
* }
*
* Success Response:
* ---------------------------------------------------------------------------------------
* {
*   "status": true,
*   "message": "Password changed successfully"
* }
*
* Failure Response:
* ---------------------------------------------------------------------------------------
* {
*   "status": false,
*   "message": "Error message"
* }
* Author       : Sandeep Kumar
*
* Change Log:
* ---------------------------------------------------------------------------------------
* Version | Author         | Date       | Description
* ---------------------------------------------------------------------------------------
* 1.0     | Sandeep Kumar  | 16-12-2025 | Initial version
******************************************************************************************/
@RestResource(urlMapping='/ChangePasswordAPI/*')
global without sharing class ChangePasswordAPI_MobileAPI {

    @HttpPost
    global static void changePassword() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'ChangePasswordAPI',
            Request__c = requestBody
        );

        try {
            // Deserialize input
            ChangePasswordWrapper input = (ChangePasswordWrapper) JSON.deserialize(requestBody, ChangePasswordWrapper.class);

            // Validate input
            if (String.isBlank(input.userId) || String.isBlank(input.oldPassword) || String.isBlank(input.newPassword)) {
               // sendError('All fields (userId, oldPassword, newPassword) are required', log, false);
                 ErrorResponseUitilityClass.sendErrorResponse('All fields (userId, oldPassword, newPassword) are required','ChangePasswordAPI_MobileAPI',requestBody);
              
                return;
            }

            // Fetch active user
            List<Channel_Partner__c> cpList = [SELECT Id, Name, Password__c, Is_Password_Change__c, User_Id__c
                								FROM Channel_Partner__c  WHERE User_Id__c = :input.userId  AND Active__c = TRUE LIMIT 1];

            if (cpList.isEmpty()) {
              //  sendError('User not found', log, false);
                 ErrorResponseUitilityClass.sendErrorResponse('User not found','ChangePasswordAPI_MobileAPI',requestBody);
              
                return;
            }

            Channel_Partner__c cp = cpList[0];

            // Check old password
           if (cp.Password__c != input.oldPassword) {
                //  sendError('Old password is incorrect', log, false);
                 ErrorResponseUitilityClass.sendErrorResponse('Old password is incorrect','ChangePasswordAPI_MobileAPI',requestBody);
              
                return;
            }

            // Update password
            cp.Password__c = input.newPassword;
            cp.Is_Password_Change__c = true;
          //  System.debug(cp + cp.Password__c +'=='+ input.newPassword);
            update cp;
			//System.debug(cp);
            // Success response
            ResponseWrapper response = new ResponseWrapper(true, 'Password changed successfully');
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            // Log success
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(response);
            insert log;

        } catch (Exception e) {
          
          //  sendError('Password change failed. Please try again.', log, false);
             ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'ChangePassword_MobileAPI',requestBody);
          
        }
    }

    // ---------- Input Wrapper ----------
    public class ChangePasswordWrapper {
        public String userId;
        public String oldPassword;
        public String newPassword;
    }

    // ---------- Response Wrapper ----------
    public class ResponseWrapper {
        public Boolean status;
        public String message;

        public ResponseWrapper(Boolean st, String msg) {
            status = st;
            message = msg;
        }
    }
/*
    // ---------- Helper ----------
    private static void sendError(String msg, Apex_Log__c log, Boolean logInserted) {
        ResponseWrapper response = new ResponseWrapper(false, msg);
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(response);

        if (logInserted) {
            update log;
        } else {
            insert log;
        }
    }*/
}