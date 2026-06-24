/****************************************************************
* Class Name   : CreateSupportTicket_MobileAPI
* Company      : Fingertipplus
* Created Date : 18-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API creates a Support Ticket record
* using numeric userId.
*
* Request JSON:
* {
*   "userId": "9",
*   "ticketTypeId": "0",
*   "subject": "Issue subject",
*   "priorityId": "0",
*   "description": "Issue description"
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Support ticket added successfully"
* }
*
* Author       : Sandeep Kumar
*****************************************************************/

@RestResource(urlMapping='/CreateSupportTicketAPI/*')
global without sharing class CreateSupportTicket_MobileAPI {

    @HttpPost
    global static void createTicket() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'CreateSupportTicket_MobileAPI',
            Request__c = requestBody
        );

        Boolean logInserted = false;

        try {
            /* ---------------- Deserialize Input ---------------- */
            SupportTicketWrapper input =
                (SupportTicketWrapper) JSON.deserialize(requestBody, SupportTicketWrapper.class);
            System.debug('Input JSON: ' + JSON.serialize(input));

            /* ---------------- Mandatory Validation ---------------- */
            if (String.isBlank(input.userId) ||
                String.isBlank(input.ticketTypeId) ||
                String.isBlank(input.subject) ||
                String.isBlank(input.priorityId) ||
                String.isBlank(input.description)) {

                //sendError('Required fields are missing', log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Required fields are missing','CreateSupportTicket_MobileAPI',requestBody);
                return;
            }

            /* ---------------- Validate Channel Partner ---------------- */
            List<Channel_Partner__c> cpList = [
                SELECT Id,Reginol_Manager_Zuari__c,Team_Leader_Zuari__c
                FROM Channel_Partner__c
                WHERE User_Id__c = :input.userId
                AND Active__c = TRUE
                LIMIT 1
            ];

            if (cpList.isEmpty()) {
               // sendError('Channel Partner not found', log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','CreateSupportTicket_MobileAPI',requestBody);
                return;
            }

            User u = [SELECT Id, Name FROM User WHERE Profile.Name = :'Sourcing RM' LIMIT 1];
            User cphhead = [SELECT Id, Name FROM User WHERE Profile.Name = :'CP Head' LIMIT 1];
            User hod = [SELECT Id, Name FROM User WHERE Profile.Name = :'HOD' LIMIT 1];


            Channel_Partner__c cp = cpList[0];
            

            /* ---------------- Create Support Ticket ---------------- */
            Support_Ticket__c st = new Support_Ticket__c();
            st.Type__c = input.ticketTypeId;
            //st.Name = input.subject;
            st.Subject__c = input.subject;
            st.Priority_Status__c = input.priorityId;
            st.Description__c = input.description;
           // st.Ticket_Status__c = 'New';
            st.Channel_Partner__c = cp.Id;
            st.Sourcing_RM__c = u.Id;
            st.ownerId = u.Id; // Set initial owner to RM
            st.escalation_Level__c = 'RM'; // Initial escalation level
            st.Sourcing_Head__c = cphhead.Id;
            st.Head_of_Sales_and_Marketing__c = hod.Id;

            insert st;
            System.debug('Support ticket created successfully: ' + st.Id);

            /* ---------------- Success Response ---------------- */
            ResponseWrapper res =
                new ResponseWrapper(true, 'Support ticket added successfully');

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =
                Blob.valueOf(JSON.serialize(res));

            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;

        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());

            
            ErrorResponseUitilityClass.sendErrorResponse('Support ticket creation failed: ' + e.getMessage(),'CreateSupportTicket_MobileAPI',requestBody);
            
        }
    }

    /* ====================== INPUT WRAPPER ====================== */
    public class SupportTicketWrapper {
        public String userId;
        public String ticketTypeId;
        public String subject;
        public String priorityId;
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