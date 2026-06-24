/****************************************************************
* Class Name   : AddCallHistory_MobileAPI
* Company      : Fingertipplus
* Created Date : 18-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API adds a Call History record
* for a specific Lead using userId.
*
* Input JSON:
* {
*   "userId": "CP-009",
*   "leadId": "ld-08751",
*   "callDate": "2025-12-10T12:34:56Z",
*   "callTypeId": "Inbound",
*   "callStatusId": "ANSWER",
*   "callDuration": 190,
*   "description": "This is a description."
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Call history added successfully."
* }
*
* Author       : Sandeep Kumar
*
* Change Log:
* ---------------------------------------------------------------------------------------
* Version | Author         | Date       | Description
* ---------------------------------------------------------------------------------------
* 1.0     | Sandeep Kumar  | 18-12-2025 | Initial version
******************************************************************************************/

@RestResource(urlMapping='/AddCallHistoryAPI/*')
global without sharing class AddCallHistory_MobileAPI {
    
    @HttpPost
    global static void addCallHistory() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'AddCallHistory_MobileAPI',
            Request__c = requestBody
        );
        
        Boolean logInserted = false;
        
        try {
            /* ---------------- Deserialize Input ---------------- */
            AddCallWrapper input = (AddCallWrapper) JSON.deserialize(requestBody, AddCallWrapper.class);
            System.debug('Input JSON: ' + JSON.serialize(input));
            
            /* ---------------- Mandatory Validation ---------------- */
            if (String.isBlank(input.userId) ||
                String.isBlank(input.leadId) ||
                input.callDate == null ||
                String.isBlank(input.callTypeId) ||
                String.isBlank(input.callStatusId)) {
                    
                   // sendError('Required fields are missing', log, logInserted);
                    ErrorResponseUitilityClass.sendErrorResponse('Required fields are missing','AddCallHistory_MobileAPI',requestBody);
                    return;
                }
            
            /* ---------------- Validate Channel Partner ---------------- */
            List<Channel_Partner__c> cpList = [SELECT Id FROM Channel_Partner__c WHERE User_Id__c = :input.userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cpList.isEmpty()) {
               // sendError('Channel Partner not found', log, logInserted);
                    ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','AddCallHistory_MobileAPI',requestBody);
                return;
            }
            
            /* ---------------- Validate Lead ---------------- */
            /* Lead leadRec;
try {
leadRec = [
SELECT Id,Lead_ID__c
FROM Lead
WHERE Lead_ID__c = :input.leadId  AND Channel_Partner__r.User_Id__c = :input.userId
LIMIT 1
];
} catch (Exception e) {
sendError('Invalid Lead Id', log, logInserted);
return;
}*/
            // 2. Fetch latest related source
            Related_Source__c latestSource;
            
            List<Related_Source__c> sourceList = [SELECT Id,CreatedDate,SLead__c FROM Related_Source__c WHERE Lead_Id__c = :input.leadId AND Is_Locked__c = FALSE
               										 ORDER BY CreatedDate DESC  LIMIT 1 ];
            
            if (!sourceList.isEmpty()) {
                latestSource = sourceList[0];
            }
            
            
            /* ---------------- Create Call History ---------------- */
            Call_Detail__c cd = new Call_Detail__c();
            cd.Lead__c = latestSource.SLead__c;
            cd.Start_Time__c = input.callDate; 
            cd.Call_Type__c = input.callTypeId;
            cd.Status__c = input.callStatusId;
            cd.Call_ID__c = input.description;
            cd.Related_Source__c = latestSource.Id;
            cd.Discription__c = input.description;
            cd.Duration__c = input.callDuration;
            cd.Created_By_CP_Mobile_APP__c = true;
            
            insert cd;
            System.debug('Call history created successfully: ' + cd.Id);
            
            /* ---------------- Success Response ---------------- */
            ResponseWrapper res =   new ResponseWrapper(true, 'Call history added successfully.');
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =
                Blob.valueOf(JSON.serialize(res));
            
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;
            
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'AddCallHistory_MobileAPI',requestBody);
        }
    }
    
    /* ====================== INPUT WRAPPER ====================== */
    public class AddCallWrapper {
        public String userId;
        public String leadId;
        public Datetime callDate;
        public String callTypeId;
        public String callStatusId;
        public Integer callDuration;
        public String description;
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
    
    /* ====================== ERROR HANDLER ====================== *//*
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