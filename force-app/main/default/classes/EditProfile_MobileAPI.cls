/****************************************************************
* Class Name   : EditProfile_MobileAPI
* Company      : Fingertipplus
* Created Date : 18-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API updates Channel Partner profile details
* using userId. Editable fields: Name, Email, Mobile Number.
*
* Request JSON:
* {
*   "userId": "9",
*   "fullName": "John Roas",
*   "email": "john.roas@test.com",
*   "mobile": "9876543210"
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Profile has been updated successfully"
* }
*
* Author       : Sandeep Kumar
*****************************************************************/

@RestResource(urlMapping='/EditProfileAPI/*')
global without sharing class EditProfile_MobileAPI {

    @HttpPost
    global static void editProfile() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'EditProfile_MobileAPI',
            Request__c = requestBody
        );

        Boolean logInserted = false;

        try {
            /* ---------------- Deserialize Input ---------------- */
            EditProfileWrapper input =  (EditProfileWrapper) JSON.deserialize(requestBody, EditProfileWrapper.class);
            System.debug('Input JSON: ' + JSON.serialize(input));

            /* ---------------- Mandatory Validation ---------------- */
            if (String.isBlank(input.userId) || String.isBlank(input.fullName) || String.isBlank(input.email) 
                ||String.isBlank(input.tlPhoneNumber) ||String.isBlank(input.tlName) ||String.isBlank(input.rmPhoneNumber) ||
                String.isBlank(input.rmName) || String.isBlank(input.address)) {

               // sendError('Required fields are missing', log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Required fields are missing','EditProfile_MobileAPI',requestBody);
                return;
            }

            /* ---------------- Fetch Channel Partner ---------------- */
            List<Channel_Partner__c> cpList = [
                SELECT Id, Name, Email__c, Mobile_Number__c,Company_Address__c, Team_Leader1__c,Team_Leader_Mobile__c,Regional_Manager1__c,Regional_Manager_Mobile__c
               FROM Channel_Partner__c  WHERE User_Id__c = :input.userId  AND Active__c = TRUE  LIMIT 1 ];

            if (cpList.isEmpty()) {
                //sendError('Channel Partner not found', log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','EditProfile_MobileAPI',requestBody);
                return;
            }

            Channel_Partner__c cp = cpList[0];

            /* ---------------- Update Profile ---------------- */
            cp.Name = input.fullName;
            cp.Email__c = input.email;
            cp.Company_Address__c = input.address;
            cp.Team_Leader_Mobile__c = input.tlPhoneNumber;
            cp.Team_Leader1__c = input.tlName;
            cp.Regional_Manager_Mobile__c = input.rmPhoneNumber;
            cp.Regional_Manager1__c = input.rmName;

            update cp;
            System.debug('Profile updated successfully: ' + cp.Id);

            /* ---------------- Success Response ---------------- */
            ResponseWrapper res =   new ResponseWrapper(true, 'Profile has been updated successfully');

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =
                Blob.valueOf(JSON.serialize(res));

            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;

        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());

            
            ErrorResponseUitilityClass.sendErrorResponse('Profile update failed: ' + e.getMessage(),'EditProfile_MobileAPI',requestBody);
            
        }
    }

    /* ====================== INPUT WRAPPER ====================== */
    public class EditProfileWrapper {
        public String userId;
        public String fullName;
        public String email;
        public String address;
        public String rmName;
        public String rmPhoneNumber;
        public String tlName;
        public String tlPhoneNumber;
    }

    /* ====================== RESPONSE WRAPPER ====================== */
    public class ResponseWrapper {
        public Boolean status;
        public String message;

        public ResponseWrapper(Boolean status, String message) {
            this.status = status;
            this.message = message;
        }
    }

    /* ====================== ERROR HANDLER ====================== */
    /*
    private static void sendError(String msg, Apex_Log__c log, Boolean logInserted) {

        ResponseWrapper res = new ResponseWrapper(false, msg);

        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(res));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);

        if (logInserted) {
            update log;
        } else {
            insert log;
        }
    }*/
}