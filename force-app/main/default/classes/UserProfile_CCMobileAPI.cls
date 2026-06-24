/**
 * @description REST API endpoint for Contact Center mobile application to retrieve user profile information.
 * Validates the customer using supplied `userId` (Salesforce Id or Name) and returns complete profile details.
 *
 * Request:
 * {
 *   "userId": 9
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "User profile",
 *   "data": {
 *     "name": "Rohan Jani",
 *     "mobileNumber": "8160419555",
 *     "emailAddress": "rohan@gmail.com",
 *     "address": "123 Main Street, Goa 403802",
 *     "aadharNumber": "1525 1252 5452 6563",
 *     "pan": "DYDGH7645S",
 *     "passportNumber": "",
 *     "iocnumber": ""
 *   }
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-18
 */
@RestResource(urlMapping='/CCUserProfileAPI/*')
global with sharing class UserProfile_CCMobileAPI {

    /**
     * @description Handles POST requests to fetch user profile details.
     * Validates the provided userId and retrieves all customer profile information.
     */
    @HttpPost
    global static void getUserProfile() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'UserProfile_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            ProfileWrapper data = (ProfileWrapper) JSON.deserialize(requestBody, ProfileWrapper.class);
            String userId = data.userId;

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'UserProfile_CCMobileAPI', requestBody);
                return;
            }

            // Query customer profile by Id or Name
            List<Customer_Master__c> cmList = [
                SELECT Id, Name,Customer_Name__c, Phone_Number__c, Email__c, Address__c, Aadhaar_Number__c, PAN_Number__c, Passport_No__c, IOC_No__c,
                Bank_Name__c,Account_Number__c,Branch__c,IFSC_Code__c
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'UserProfile_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c cm = cmList[0];

            // Build profile data map
            Map<String, Object> profileData = new Map<String, Object>{
                'name' => cm.Customer_Name__c,
                'mobileNumber' => cm.Phone_Number__c != null ? cm.Phone_Number__c : '',
                'emailAddress' => cm.Email__c != null ? cm.Email__c : '',
                'address' => cm.Address__c != null ? cm.Address__c : '',
                'aadharNumber' => cm.Aadhaar_Number__c != null ? cm.Aadhaar_Number__c : '',
                'pan' => cm.PAN_Number__c != null ? cm.PAN_Number__c : '',
                'passportNumber' => cm.Passport_No__c != null ? cm.Passport_No__c : '',
                'iocNumber' => cm.IOC_No__c != null ? cm.IOC_No__c : '',
                'bankName' => cm.Bank_Name__c != null ? cm.Bank_Name__c : '',
                'accountNumber' => cm.Account_Number__c != null ? String.valueOf(cm.Account_Number__c) : '',
                'branch' => cm.Branch__c != null ? cm.Branch__c : '',
                'ifscCode' => cm.IFSC_Code__c != null ? cm.IFSC_Code__c : '',
                'userId' => cm.Name
            };

            Map<String, Object> response = new Map<String, Object>{
                'status' => true,
                'message' => 'User profile',
                'data' => profileData
            };

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'User profile retrieved for ' + cm.Name;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'UserProfile_CCMobileAPI', requestBody);
        }
    }

    /**
     * @description Wrapper class for deserializing profile request JSON.
     */
    public class ProfileWrapper {
        public String userId;
    }

}