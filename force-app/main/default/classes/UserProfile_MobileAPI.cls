/****************************************************************
* Class Name   : UserProfile_MobileAPI
* Company      : Fingertipplus
* Created Date : 16-12-2025 
*
* @description :
* This Apex REST API handles the "User Profile" functionality
* for the mobile application.
*
* Flow:
*  - Accepts User Id as input
*  - Validates User Id for null
*  - Fetches active Channel Partner record based on User Id
*  - Retrieves User (Owner) profile details
*  - Retrieves hierarchy details (Regional Manager, Team Leader,
*    Zuari Regional Manager, Zuari Team Leader)
*  - Retrieves Bank and Tax information
*  - Returns structured JSON response indicating success or failure
*  - Logs request and response using Apex_Log__c
*
* Input JSON:
* {
*   "userId": "cp-00001"
* }
*
* Output (Success):
* {
*   "status": true,
*   "message": "User profile",
*   "data": {
*     "userProfile": {
*       "name": "Rohan Jani",
*       "mobileNumber": "8160419555",
*       "emailAddress": "rohan@gmail.com"
*     },
*     "regionalManager": {
*       "name": "Rohan Jani",
*       "mobileNumber": "8160419555"
*     },
*     "teamLeader": {
*       "name": "Rohan Jani",
*       "mobileNumber": "8160419555"
*     },
*     "regionalManagerZuari": {
*       "name": "Rohan Jani",
*       "mobileNumber": "8160419555"
*     },
*     "teamLeaderZuari": {
*       "name": "Rohan Jani",
*       "mobileNumber": "8160419555"
*     },
*     "bankDetail": {
*       "bankName": "HDFC Bank",
*       "accountNumber": "23568956235689",
*       "ifscCode": "HDFC01237JUN",
*       "branchAddress": "Goa Main Branch"
*     },
*     "taxInformation": {
*       "panNumber": "DEFSD5956E",
*       "gstnumber": "78DS78454587SDSDE96"
*     }
*   }
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
* 1.0     | Sandeep Kumar  | 16-12-2025 | Initial version
******************************************************************************************/
@RestResource(urlMapping='/UserProfileAPI/*')
global without sharing class UserProfile_MobileAPI {
    
    @HttpPost
    global static void getUserProfile() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody == null ? null : req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'UserProfile_MobileAPI',
            Request__c = requestBody
        );
        
        try {
            // ---------- Deserialize request ----------
            RequestWrapper input = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);
            
            if (input == null || String.isBlank(input.userId)) {
             //   sendError('UserId is required', log);
                 ErrorResponseUitilityClass.sendErrorResponse('UserId is required','UserProfile_MobileAPI',requestBody);
              
                return;
            }
            
            // ---------- Fetch Channel Partner ----------
            Channel_Partner__c cp = [
                SELECT Id, User_Id__c, Name, PAN__c, GST__c, Email__c,
                Bank_Address__c,
                Regional_Manager__r.Name, Regional_Manager__r.MobilePhone,
                Team_Leader__r.Name, Team_Leader__r.MobilePhone,
                Reginol_Manager_Zuari__r.Name, Reginol_Manager_Zuari__r.MobilePhone,
                Team_Leader_Zuari__r.Name, Team_Leader_Zuari__r.MobilePhone,
                Account_Number__c, Bank_Name__c, Mobile_Number__c,
                IFSC_CODE__c, Active__c,Pin_Code__c,Company_Address__c,City__c,
                Team_Leader1__c,Team_Leader_Mobile__c,Regional_Manager1__c,Regional_Manager_Mobile__c
                FROM Channel_Partner__c
                WHERE User_Id__c = :input.userId
                AND Active__c = TRUE
                LIMIT 1
            ];
            if (cp == null) {
                
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','UserProfile_MobileAPI',requestBody);
                return;
            }
            // ---------- Build Response ----------
            UserProfileResponse res = new UserProfileResponse();
            res.status = true;
            res.message = 'User profile';
            res.data = new UserProfileData();
            
            // User profile
            res.data.userProfile = new UserProfile();
            res.data.userProfile.name = cp.Name;
            res.data.userProfile.userId = cp.User_Id__c;
            res.data.userProfile.mobileNumber = cp.Mobile_Number__c;
            res.data.userProfile.emailAddress = cp.Email__c;
            //  String cpaddress = cp.Select_Region__c+' '+ cp.City__c + ' '+ cp.Pin_Code__c;
            res.data.userProfile.address = cp.Company_Address__c;
            
            // Regional Manager
            // res.data.regionalManager = buildSimpleUser(cp.Regional_Manager__r);
            res.data.regionalManager = new SimpleUser();
            res.data.regionalManager.name = cp.Regional_Manager1__c;
            res.data.regionalManager.mobileNumber = cp.Regional_Manager_Mobile__c;
            // Team Leader
            //res.data.teamLeader = buildSimpleUser(cp.Team_Leader__r);
            
            res.data.teamLeader = new SimpleUser();
            res.data.teamLeader.name = cp.Team_Leader1__c;
            res.data.teamLeader.mobileNumber = cp.Team_Leader_Mobile__c;  
            // Zuari Regional Manager
            res.data.regionalManagerZuari = buildSimpleUser(cp.Reginol_Manager_Zuari__r);
            
            // Zuari Team Leader
            res.data.teamLeaderZuari = buildSimpleUser(cp.Team_Leader_Zuari__r);
            
            // Bank Details
            res.data.bankDetail = new BankDetail();
            res.data.bankDetail.bankName = cp.Bank_Name__c;
            res.data.bankDetail.accountNumber = cp.Account_Number__c;
            res.data.bankDetail.ifscCode = cp.IFSC_CODE__c;
            res.data.bankDetail.branchAddress = cp.Bank_Address__c;
            
            // Tax Info
            res.data.taxInformation = new TaxInformation();
            res.data.taxInformation.panNumber = cp.PAN__c;
            res.data.taxInformation.gstnumber = cp.GST__c;
            
            // ---------- Send Response ----------
            String jsonOutput = JSON.serialize(res);
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(jsonOutput);
            
            log.Status__c = 'SUCCESS';
            log.Response__c = jsonOutput;
            insert log;
            
        } catch (Exception e) {
             ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'UserProfile_MobileAPI',requestBody);
          
           // sendError(e.getMessage(), log);
        }
    }
    
    // ---------- Helper: Build Simple User ----------
    private static SimpleUser buildSimpleUser(User u) {
        SimpleUser su = new SimpleUser();
        if (u != null) {
            su.name = u.Name;
            su.mobileNumber = u.MobilePhone;
        }
        return su;
    }
    
    // ---------- Error Response ----------
    /*
    private static void sendError(String msg, Apex_Log__c log) {
        UserProfileResponse res = new UserProfileResponse();
        res.status = false;
        res.message = msg;
        
        String jsonOutput = JSON.serialize(res);
        
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(jsonOutput);
        
        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = jsonOutput;
        insert log;
    }*/
    
    // ---------- Request Wrapper ----------
    public class RequestWrapper {
        public String userId;
    }
    
    // ---------- Response Wrappers ----------
    public class UserProfileResponse {
        public Boolean status;
        public String message;
        public UserProfileData data;
    }
    
    public class UserProfileData {
        public UserProfile userProfile;
        public SimpleUser regionalManager;
        public SimpleUser teamLeader;
        public SimpleUser regionalManagerZuari;
        public SimpleUser teamLeaderZuari;
        public BankDetail bankDetail;
        public TaxInformation taxInformation;
    }
    
    public class UserProfile {
        public String name;
        public String userId;
        public String mobileNumber;
        public String emailAddress;
        public String address;
    }
    
    public class SimpleUser {
        public String name;
        public String mobileNumber;
    }
    
    public class BankDetail {
        public String bankName;
        public String accountNumber;
        public String ifscCode;
        public String branchAddress;
    }
    
    public class TaxInformation {
        public String panNumber;
        public String gstnumber;
    }
}