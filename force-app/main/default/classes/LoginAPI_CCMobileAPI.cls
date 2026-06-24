/**
 * @description REST API endpoint for Contact Center mobile application login authentication.
 * This API validates customer credentials (mobile number and password) against the Customer_Master__c object
 * and returns an authentication token upon successful login. It also maintains audit logs for all login attempts.
 * 
 * @author        Praveen Kumar
 * @version       1.0
 * @since         2026-02-13
 * 
 * REST Endpoint: POST /services/apexrest/CCLoginAPI/
 */
@RestResource(urlMapping='/CCLoginAPI/*')
global with sharing class LoginAPI_CCMobileAPI {
    
    /**
     * @description Handles POST requests for customer login authentication.
     * Validates the provided mobile number and password against the Customer_Master__c records,
     * verifies the customer is active, and returns an authentication token on success.
     * All requests and responses are logged in the Apex_Log__c object for audit trail.
     * 
     * @return void - Sends HTTP response with success/error status and data
     * 
     * Expected Request Body:
     * {
     *     "mobileNumber": "string", // Customer's phone number (required)
     *     "password": "string",     // Customer's password (required)
     *     "deviceId": "string"      // Mobile device identifier
     * }
     * 
     * Success Response (200 OK):
     * {
     *     "status": true,
     *     "message": "Login successful",
     *     "data": {
     *         "token": "AUTHENTICATION TOKEN",
     *         "userId": "Customer Name"
     *     }
     * }
     * 
     * Error Response:
     * Delegated to ErrorResponseUitilityClass which handles error formatting and logging
     */
     @HttpPost
    global static void checkLogin() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        // Initialize audit log record for tracking API requests and responses
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'LoginAPI_CCMobileAPI';
        log.Request__c = requestBody;

        try {

            // Deserialize incoming JSON request into LoginWrapper object
            LoginWrapper loginData =(LoginWrapper) JSON.deserialize(requestBody, LoginWrapper.class);

            String mobile = loginData.mobileNumber;
            String password = loginData.password;
            String deviceId = logindata.deviceId;
           

            // Validate that required fields (mobile number and password) are not empty
            if (String.isBlank(mobile) || String.isBlank(password)) {

                // Send error response for missing credentials
                ErrorResponseUitilityClass.sendErrorResponse('Please enter valid mobile number and password','LoginAPI_CCMobileAPI',requestBody);
              //  sendErrorResponse('Please enter valid mobile number and password');
                return;
            }

            // Query Customer_Master__c to find active customer matching provided mobile number
            List<Customer_Master__c> cmList = [
                SELECT Id,Name,Password__c, Phone_Number__c,Is_Password_Change__c
                FROM Customer_Master__c
                WHERE Phone_Number__c = :mobile
                AND Active__c = True
               LIMIT 1
            ];

            // If no active customer found with provided mobile number, return error
            if (cmList.isEmpty()) {

                 ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found','LoginAPI_CCMobileAPI',requestBody);
              
              //  sendErrorResponse('Customer Not Found');
                return;
            }

            Customer_Master__c cm = cmList[0];
            
            List<Logged_in_Device__c> dvlst = [select id,Status__c,Last_Logged_Out__c from Logged_in_Device__c where Device_Id__c =: deviceId AND Customer_Master__c =:cmList[0].Id limit 1]; 
            if(dvlst.Size()==0){
                
                Logged_in_Device__c lgd = new Logged_in_Device__c();
                lgd.Customer_Master__c =cmList[0].Id;
                lgd.Last_Logged_In__c = System.Now();
                lgd.Status__c ='Active';
                lgd.Device_Id__c =deviceId;
                insert lgd;
            }
            else if(dvlst.Size()==1){
                dvlst[0].Status__c = 'Active';
                dvlst[0].Last_Logged_In__c = System.Now();
                update dvlst[0];
                
            }
            
            // Verify that provided password matches the stored customer password
            if (cm.Password__c != password) {
                 ErrorResponseUitilityClass.sendErrorResponse('Invalid Password','LoginAPI_CCMobileAPI',requestBody + cm.Password__c);
              
               // sendErrorResponse('Invalid password');
                return;
            }

       

            // Build successful authentication response with token and user information
            Map<String, Object> data = new Map<String, Object>{
                 'token' => 'AUTHENTICATION TOKEN',
                'userId' => cm.Name,
                'isPasswordChange' => cm.Is_Password_Change__c
                
            };

            Map<String, Object> response = new Map<String, Object>{
                'status' => true,
                'message' => 'Login successful',
                'data' => data
            };

            // Set HTTP response status and body
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            // Log successful login attempt
            log.Response__c = 'Login success for ' + cm.Name;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {

            // Catch and log any exceptions that occur during processing
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'LoginAPI_CCMobileAPI',requestBody);
          
            //sendErrorResponse('Login failed. Please try again.');
        }
    }

    /**
     * @description Wrapper class for deserializing incoming login request JSON.
     * Maps incoming JSON fields to Apex properties for login authentication.
     */
    public class LoginWrapper {
        public String mobileNumber;  // Customer's registered phone number
        public String password;      // Customer's account password
        public String deviceId;      // Unique device identifier for the mobile client
    }

}