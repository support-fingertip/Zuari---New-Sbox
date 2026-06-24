/****************************************************************
* Class Name   : AddFollowUp_MobileAPI
* Company      : Fingertipplus
* Created Date : 18-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API adds a Follow-Up record
* for a specific Lead using userId.
*
* Input JSON:
* {
*   "userId": "CP-009",
*   "leadId": "ld-08751",
*   "scheduleDate": "2025-12-10T12:34:56Z",
*   "subject": "This is subject.",
*   "notes": "This is a note."
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Follow-up slot added successfully."
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

@RestResource(urlMapping='/AddFollowUpAPI/*')
global without sharing class AddFollowUp_MobileAPI {

    @HttpPost
    global static void addFollowUp() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'AddFollowUp_MobileAPI',
            Request__c = requestBody
        );

        Boolean logInserted = false;

        try {
            /* ---------------- Deserialize Input ---------------- */
            AddFollowUpWrapper input =
                (AddFollowUpWrapper) JSON.deserialize(requestBody, AddFollowUpWrapper.class);
            System.debug('Input JSON: ' + JSON.serialize(input));

            /* ---------------- Mandatory Validation ---------------- */
            if (String.isBlank(input.userId) ||
                String.isBlank(input.leadId) ||
                input.scheduleDate == null ||
                String.isBlank(input.subject)) {

               // sendError('Required fields are missing', log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Required fields are missing','AddFollowUp_MobileAPI',requestBody);
                return;
            }

            /* ---------------- Validate Channel Partner ---------------- */
            List<Channel_Partner__c> cpList = [
                SELECT Id
                FROM Channel_Partner__c
                WHERE User_Id__c = :input.userId
                AND Active__c = TRUE
                LIMIT 1
            ];

            if (cpList.isEmpty()) {
               // sendError('Channel Partner not found', log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','AddSiteVisit_MobileAPI',requestBody);
                return;
            }

            /* ---------------- Validate Lead ---------------- */
            Lead leadRec;
          /*  try {
                leadRec = [
                    SELECT Id, Lead_ID__c
                    FROM Lead
                    WHERE Lead_ID__c = :input.leadId AND Channel_Partner__r.User_Id__c = :input.userId
                    LIMIT 1
                ];
            } catch (Exception e) {
                sendError('Invalid Lead Id', log, logInserted);
                return;
            }*/
            // 2. Fetch latest related source
            Related_Source__c latestSource;
            
            List<Related_Source__c> sourceList = [
                SELECT Id,CreatedDate,SLead__c
                FROM Related_Source__c
                WHERE Lead_Id__c = :input.leadId AND Is_Locked__c = FALSE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (!sourceList.isEmpty()) {
                latestSource = sourceList[0];
            }

            /* ---------------- Create Follow-Up ----------------*/
            Follow_Up__c fu = new Follow_Up__c();
            fu.SLead__c = latestSource.SLead__c;
            fu.Related_Source__c = latestSource.Id;
            fu.Scheduled_Date__c = input.scheduleDate;
            fu.Subject__c = input.subject;
            fu.Comments__c = input.notes;
            //fu.Source_Type__c = 'Channel partner';

            insert fu;
            System.debug('Follow-up created successfully: ' + fu.Id);


            /* ---------------- Success Response ---------------- */
            ResponseWrapper res =
                new ResponseWrapper(true, 'Follow-up slot added successfully.');

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =
                Blob.valueOf(JSON.serialize(res));

            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;

        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());

           
            //sendError('Follow-up creation failed: ' + e.getMessage(), log, logInserted);
             ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'AddFollowUp_MobileAPI',requestBody);
        }
    }

    /* ====================== INPUT WRAPPER ====================== */
    public class AddFollowUpWrapper {
        public String userId;
        public String leadId;
        public Datetime scheduleDate;
        public String subject;
        public String notes;
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