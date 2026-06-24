/**
 * @description REST API endpoint for Contact Center mobile application to verify OTP.
 * Validates the customer using mobile number and verifies the provided OTP against the stored OTP_Number__c field.
 *
 * Request:
 * {
 *   "mobileNumber": "8160419222",
 *   "otp": "859856"
 * }
 *
 * Response (Success):
 * {
 *   "status": true,
 *   "message": "OTP verified successfully"
 * }
 *
 * Response (Error):
 * Delegated to ErrorResponseUitilityClass which handles error formatting
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-18
 */
@RestResource(urlMapping='/CCVerifyOTPAPI/*')
global with sharing class VerifyOTP_CCMobileAPI {

    /**
     * @description Handles POST requests to verify OTP for password reset.
     * Validates customer by mobile number and compares provided OTP with stored OTP_Number__c.
     * Returns success if OTP matches, error if OTP does not match or customer not found.
     * All requests and responses are logged to Apex_Log__c for audit trail.
     */
    @HttpPost
    global static void verifyOTP() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'VerifyOTP_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            VerifyOTPWrapper otpData = (VerifyOTPWrapper) JSON.deserialize(requestBody, VerifyOTPWrapper.class);

            String mobile = otpData.mobileNumber;
            String otp = otpData.otp;

             // Validate that required fields are not empty

            // Validate that required fields are not empty
            if (String.isBlank(mobile) || String.isBlank(otp)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide valid mobile number and OTP', 'VerifyOTP_CCMobileAPI', requestBody);
                return;
            }

            // Query customer by mobile number
            List<Customer_Master__c> cmList = [
                SELECT Id, Name, Phone_Number__c, OTP_Number__c
                FROM Customer_Master__c
                WHERE Phone_Number__c = :mobile
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'VerifyOTP_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c cm = cmList[0];
            String storedOTP = String.valueOf(cm.OTP_Number__c);

            // Verify if provided OTP matches stored OTP
            if (storedOTP != otp) {
                ErrorResponseUitilityClass.sendErrorResponse('OTP does not match', 'VerifyOTP_CCMobileAPI', requestBody);
                return;
            }

            // OTP verified successfully
            Map<String, Object> response = new Map<String, Object>{
                'status' => true,
                'message' => 'OTP verified successfully'
            };

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'OTP verified successfully for ' + cm.Name;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'VerifyOTP_CCMobileAPI', requestBody);
        }
    }

    /**
     * @description Wrapper class for deserializing OTP verification request JSON.
     */
    public class VerifyOTPWrapper {
        public String mobileNumber;  // Customer's registered phone number
        public String otp;            // OTP provided by customer
    }

}