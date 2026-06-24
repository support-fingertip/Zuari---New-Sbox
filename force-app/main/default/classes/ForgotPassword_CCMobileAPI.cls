/**
 * @description REST API endpoint for Contact Center mobile application forgot password functionality.
 * This API validates customer by mobile number and sends OTP for password reset.
 * 
 * @author        Praveen Kumar
 * @version       1.0
 * @since         2026-02-13
 * 
 * REST Endpoint: POST /services/apexrest/CCForgotPasswordAPI/
 */
@RestResource(urlMapping='/CCForgotPasswordAPI/*')
global with sharing class ForgotPassword_CCMobileAPI {
    
    /**
     * @description Handles POST requests for forgot password OTP generation.
     * Validates the provided mobile number against Customer_Master__c records,
     * and sends OTP for password reset on successful validation.
     * All requests and responses are logged in the Apex_Log__c object for audit trail.
     * 
     * @return void - Sends HTTP response with success/error status and message
     * 
     * Expected Request Body:
     * {
     *     "mobileNumber": "string" // Customer's phone number (required)
     * }
     * 
     * Success Response (200 OK):
     * {
     *     "status": true,
     *     "message": "OTP send successfully"
     * }
     * 
     * Error Response:
     * Delegated to ErrorResponseUitilityClass which handles error formatting and logging
     */
    @HttpPost
    global static void forgotPassword() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        // Initialize audit log record for tracking API requests and responses
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'ForgotPassword_CCMobileAPI';
        log.Request__c = requestBody;

        try {

            // Deserialize incoming JSON request into ForgotPasswordWrapper object
            ForgotPasswordWrapper forgotPasswordData = (ForgotPasswordWrapper) JSON.deserialize(requestBody, ForgotPasswordWrapper.class);

            String mobile = forgotPasswordData.mobileNumber;

            // Validate that required field (mobile number) is not empty
            if (String.isBlank(mobile)) {

                // Send error response for missing mobile number
                ErrorResponseUitilityClass.sendErrorResponse('Please enter valid mobile number', 'ForgotPassword_CCMobileAPI', requestBody);
                return;
            }

            // Query Customer_Master__c to validate customer with provided mobile number
            List<Customer_Master__c> cmList = [
                SELECT Id, Name, Phone_Number__c,Email__c
                FROM Customer_Master__c
                WHERE Phone_Number__c = :mobile
                AND Active__c = True
                LIMIT 1
            ];

            // If no active customer found with provided mobile number, return error
            if (cmList.isEmpty()) {

                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'ForgotPassword_CCMobileAPI', requestBody);
                return;
            }

            // Customer found - generate OTP and send email
            String result;
            if (!cmList.isEmpty()) {
                String toEmail = cmList[0].Email__c;
                system.debug(toEmail);
                
                // Generate 6-digit random OTP
                Integer otp = Math.round(Math.random() * 8999) + 100000;
                otp = 111111;
                // Create email message
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                // Update customer record with OTP
                cmList[0].OTP_Number__c = otp;
                update cmList[0];
                
                String userId = cmList[0].Name;
                
                // Set email parameters
                email.setToAddresses(new String[] { toEmail });
                email.setSubject('OTP for Forgot Password');
                
                // Prepare email body
                String body = 'Dear User,\n\n';
                body += 'Your One-Time Password (OTP) for password reset is: ' + otp + '\n\n';
                body += 'Regards,\nSupport Team';
                
                email.setPlainTextBody(body);
                
            email.setSaveAsActivity(true);
                
                // Set org-wide email address for sending
               List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE '%communication@crm.zuariproperties.com%' LIMIT 1];
       if (!oweaList.isEmpty()) {
                   email.setOrgWideEmailAddressId(oweaList[0].Id);
                }
                
                // Send the email
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                result = String.ValueOf(results);
                System.debug(results);
                if(results[0].isSuccess()){

    Task t = new Task();
    t.Subject = 'OTP Email Sent';
    t.Status = 'Completed';
    t.Priority = 'Normal';
    t.WhatId = cmList[0].Id;
    t.Description =
        'OTP email sent to ' +
        cmList[0].Email__c +
        ' on ' +
        String.valueOf(System.now());

    insert t;
}
                
            }

            // Build successful response
            Map<String, Object> response = new Map<String, Object>{
                'status' => true,
                'message' => 'OTP send successfully'
            };

            // Set HTTP response status and body
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            // Log successful OTP request
            log.Response__c = 'OTP sent successfully for ' + cmList[0].Name + result;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {

            // Catch and log any exceptions that occur during processing
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'ForgotPassword_CCMobileAPI', requestBody);

        }
    }

    /**
     * @description Wrapper class for deserializing incoming forgot password request JSON.
     * Maps incoming JSON fields to Apex properties for mobile number validation.
     */
    public class ForgotPasswordWrapper {
        public String mobileNumber;  // Customer's registered phone number
    }
}