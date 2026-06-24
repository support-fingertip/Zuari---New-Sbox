/*****************************************************************************************
* Class Name   : DeleteUserAPI_MobileAPI
* Company      : Fingertipplus
* Created Date : 16-12-2025
*
* Description  :
* ---------------------------------------------------------------------------------------
* This Apex class exposes a RESTful POST web service to delete a Channel Partner
* based on their userId.
*
* Input JSON:
* ---------------------------------------------------------------------------------------
* {
*   "userId": "CP-003"
* }
*
* Success Response:
* ---------------------------------------------------------------------------------------
* {
*   "status": true,
*   "message": "User deleted successfully"
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
@RestResource(urlMapping='/DeleteUserAPI/*')
global without sharing class DeleteUserAPI_MobileAPI {

    @HttpPost
    global static void deleteUser() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'DeleteUserAPI',
            Request__c = requestBody
        );

        try {
            // Deserialize input
            DeleteUserWrapper input = (DeleteUserWrapper) JSON.deserialize(requestBody, DeleteUserWrapper.class);

            // Validate input
            if (String.isBlank(input.userId)) {
               // sendError('UserId is required', log, false);
                  ErrorResponseUitilityClass.sendErrorResponse('UserId is required','DeleteUserAPI_MobileAPI',requestBody);
              
                return;
            }

            // Fetch active user
            List<Channel_Partner__c> cpList = [
                SELECT Id, Name, User_Id__c
                FROM Channel_Partner__c
                WHERE User_Id__c = :input.userId
                AND Active__c = TRUE
                LIMIT 1
            ];

            if (cpList.isEmpty()) {
                 ErrorResponseUitilityClass.sendErrorResponse('User not found or already inactive','DeleteUserAPI_MobileAPI',requestBody);
              
                return;
            }

            Channel_Partner__c cp = cpList[0];

            // Delete user
            cp.Active__c = false;
            update cp;
            //delete cp;

            // Success response
            ResponseWrapper response = new ResponseWrapper(true, 'User deleted successfully');
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            // Log success
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(response);
            insert log;

        } catch (Exception e) {
           
            // sendError('User deletion failed. Please try again.', log, false);
             ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'DeleteUserAPI_MobileAPI',requestBody);
         
        }
    }

    // ---------- Input Wrapper ----------
    public class DeleteUserWrapper {
        public String userId;
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