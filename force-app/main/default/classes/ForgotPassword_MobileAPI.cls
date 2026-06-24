/****************************************************************
* Class Name   : ForgotPassword_MobileAPI
* Company      : Fingertipplus
* Created Date : 15-12-2025 
*
* @description :
* This Apex REST API handles the "Forgot Password" functionality
* for the mobile application.
*
* Flow:
*  - Accepts mobile number as input
*  - Validates mobile number
*  - Checks for active Channel Partner record
*  - Generates a 4-digit OTP
*  - Saves OTP against the user record
*  - Sends OTP via email using Org-Wide Email Address
*  - Returns structured JSON response
*  - Logs request and response using Apex_Log__c
*
* Input JSON:
* {
*   "mobileNumber": "9999999999"
* }
*
* Output (Success):
* {
*   "success": true,
*   "message": "OTP send successfully"
* }
*
* Output (Failure):
* {
*   "success": false,
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
@RestResource(urlMapping='/ForgotPasswordAPI/*')
global without sharing class ForgotPassword_MobileAPI {
    
    @HttpPost
    global static void changePasswordMethod() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString(); // Get the JSON body
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c ='ForgotPassword_MobileAPI';
        
        log.Request__c =requestBody;
        
        try{
            changedPassowrdWrapper newleaddata = (changedPassowrdWrapper) JSON.deserialize(requestBody, changedPassowrdWrapper.class);
            String phoneNumber = newleaddata.mobileNumber;
            
            system.debug(phoneNumber +'==');
            if (String.isBlank(phoneNumber)) {
                //sendErrorResponse('Phone Number should not be blank');
                  
                ErrorResponseUitilityClass.sendErrorResponse('Phone Number should not be blank','ForgotPassword_MobileAPI',requestBody);
              
                return;
            }
            List<Channel_Partner__c> cmList = [ SELECT Id, Email__c,User_Id__c, Password__c, Name,OTP_Number__c  FROM Channel_Partner__c  WHERE Mobile_Number__c=:phoneNumber AND Active__c = TRUE LIMIT 1 ];
            // ==================================================
            //  MOBILE NUMBER WRONG (ONLY THIS CASE → HTTP 200)
            // ==================================================
            if (cmList.isEmpty()) {
                  ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found','ForgotPassword_MobileAPI',requestBody);
              
                return;
            }
            
            // ==================================================
            // MOBILE NUMBER FOUND
            // ==================================================            
            if (!cmList.isEmpty()) {
                String toEmail= cmList[0].Email__c;
                system.debug(toEmail);
                Integer otp = Math.round(Math.random() * 8999) + 100000;
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                cmList[0].OTP_Number__c=otp;
                //commented this linefor testing will change one required
                update cmList;
                ////
                String userId = cmList[0].User_Id__c;
                // Set email parameters
                email.setToAddresses(new String[] { toEmail });
                email.setSubject('OTP for Forgot Password');
                
                String body = 'Dear User,\n\n';
                body += 'Your One-Time Password (OTP) for password reset is: ' + otp + '\n\n';
                
                body += 'Regards,\nSupport Team';
                
                email.setPlainTextBody(body);
                //need to give org wide email 
                List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE '%@crm.zuariproperties.com%' LIMIT 1];
                if (!oweaList.isEmpty()) {
                    email.setOrgWideEmailAddressId(oweaList[0].Id);
                }
                
                // Send the email
                Messaging.SendEmailResult[] results =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                
                
                log.response__c = 'OTP send successfully '+ results;
                log.Status__c = 'SUCCESS';
                insert log;
                
                sendSuccessResponse(toEmail);
                
            }
            
            
        }
        Catch(Exception e){
             ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'ForgotPassword_MobileAPI',requestBody);
          
        }
    }
    
    public class changedPassowrdWrapper {
        
        public string mobileNumber;
    }
    public class ResponseWrapper {
        public Boolean status;
        public String message;
        
    }
    private static void sendSuccessResponse( String toEmail) {
        ResponseWrapper response = new ResponseWrapper();
        response.status = true;
        response.message = 'OTP sent successfully to '+ toEmail;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }
    
}