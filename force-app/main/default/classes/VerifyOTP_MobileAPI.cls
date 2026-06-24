/****************************************************************
* Class Name   : VerifyOTP_MobileAPI
* Company      : Fingertipplus
* Created Date : 15-12-2025 
*
* @description :
* This Apex REST API handles the "OTP Verification" functionality
* for the mobile application.
*
* Flow:
*  - Accepts mobile number and OTP as input
*  - Validates mobile number and OTP for null/blank
*  - Checks for active Customer_Master__c record matching the mobile number
*  - Verifies the OTP against the stored OTP for the user
*  - Returns structured JSON response indicating success or failure
*  - Logs request and response using Apex_Log__c
*
* Input JSON:
* {
*   "mobileNumber": "8160419555",
*   "otp": "859856"
* }
*
* Output (Success):
* {
*   "status": true,
*   "message": "OTP verified successfully"
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

@RestResource(urlMapping='/VerifyOTPAPI/*')
global without sharing class VerifyOTP_MobileAPI {

    @HttpPost
    global static void verifyOTPMethod() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        // Logging
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'VerifyOTP_MobileAPI';
        log.Request__c = requestBody;

        try {
            // Deserialize input JSON
            OTPWrapper inputData = (OTPWrapper) JSON.deserialize(requestBody, OTPWrapper.class);
            String mobile = inputData.mobileNumber;
            String otpInput = inputData.otp;

            // Validate input
            if (String.isBlank(mobile) || String.isBlank(otpInput)) {
                 ErrorResponseUitilityClass.sendErrorResponse('Mobile number or OTP should not be blank','VerifyOTP_MobileAPI',requestBody);
              
                return;
            }

            // Query customer by mobile number and active status
            List<Channel_Partner__c> cmList = [
                SELECT Id, OTP_Number__c, Name
                FROM Channel_Partner__c
                WHERE Mobile_Number__c = :mobile
                  AND Active__c = TRUE
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                 ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found','VerifyOTP_MobileAPI',requestBody);
              
                return;
            }

            Channel_Partner__c cm = cmList[0];

            // Verify OTP
            if (String.valueOf(cm.OTP_Number__c) != otpInput) {
                ErrorResponseUitilityClass.sendErrorResponse('Invalid OTP','VerifyOTP_MobileAPI',requestBody);
                return;
            }

            // OTP verified successfully
            log.Response__c = 'OTP verified successfully for ' + cm.Name;
            log.Status__c = 'SUCCESS';
            insert log;
            sendSuccessResponse();

        } catch (Exception e) {
         ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'VerifyOTP_MobileAPI',requestBody);
             
        }
    }

    // Input wrapper
    public class OTPWrapper {
        public String mobileNumber;
        public String otp;
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
        response.message = 'OTP verified successfully';

        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }
}