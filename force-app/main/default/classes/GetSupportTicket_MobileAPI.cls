/****************************************************************
* Class Name   : GetSupportTicket_MobileAPI
* Company      : Fingertipplus
* Created Date : 18-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API fetches Support Tickets for a
* Channel Partner using dynamic filters.
*
* Request JSON:
* {
*   "userId": "9",
*   "pageSize": 10,
*   "ticketStatusId": "77",
*   "ticketTypeId": "Payment",
*   "search": "Commission"
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Support ticket data",
*   "data": [ ... ]
* }
*
* Author       : Sandeep Kumar
*****************************************************************/

@RestResource(urlMapping='/GetSupportTicketAPI/*')
global without sharing class GetSupportTicket_MobileAPI {

    @HttpPost
    global static void getTickets() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'GetSupportTicket_MobileAPI',
            Request__c = requestBody
        );

        Boolean logInserted = false;

        try {

            /* ---------------- Deserialize Input ---------------- */
            TicketRequestWrapper input = (TicketRequestWrapper) JSON.deserialize(requestBody, TicketRequestWrapper.class);

            System.debug('Input JSON: ' + JSON.serialize(input));

            /* ---------------- Mandatory Validation ---------------- */
            if (String.isBlank(input.userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('UserId is required','GetSupportTicket_MobileAPI',requestBody);
                return;
            }

            /* ---------------- Fetch Channel Partner ---------------- */
            List<Channel_Partner__c> cpList = [ SELECT Id FROM Channel_Partner__c WHERE User_Id__c = :input.userId AND Active__c = TRUE LIMIT 1];

            if (cpList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','GetSupportTicket_MobileAPI',requestBody);
                return;
            }

            Id cpId = cpList[0].Id;
            String ticketStatusId = input.ticketStatusId;
            String ticketTypeId   = input.ticketTypeId;
            String search      = input.search;

            /* ---------------- Dynamic SOQL ---------------- */
            String baseQuery =
                'SELECT Id, Name, Subject__c, Description__c, Type__c,' +
                ' CreatedDate, Ticket_Status__c, Priority_Status__c ' +
                'FROM Support_Ticket__c';
            
            List<String> conditions = new List<String>();
            conditions.add('Channel_Partner__c = :cpId');
            
            if (String.isNotBlank(ticketStatusId) && ticketStatusId != '0') {
                conditions.add('Ticket_Status__c = :ticketStatusId');
            }
            
            if (String.isNotBlank(ticketTypeId)) {
                conditions.add('Priority_Status__c = :ticketTypeId');
            }
            
/*            if (String.isNotBlank(searchKey)) {
                conditions.add(
                    'Name LIKE \'%' + String.escapeSingleQuotes(searchKey.trim()) + '%\''
                );
            }*/
             if (!String.isBlank(search)) {
                    String escapedSearch = String.escapeSingleQuotes(search.trim());
                    
                    conditions.add(
                        '(' +
                        'Name LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Subject__c LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Type__c LIKE \'%' + escapedSearch + '%\'' +
                        ')'
                    );
                }
                
               
            
            if (!conditions.isEmpty()) {
                baseQuery += ' WHERE ' + String.join(conditions, ' AND ');
            }
            
           // Integer offsetSize = input.pageSize != null ? input.pageSize : 0;
            Integer limitSize  = 15;
             Integer offsetSize = input.pageSize != null ? input.pageSize*15 : 0;
               
            
            baseQuery += ' ORDER BY CreatedDate DESC';
            baseQuery += ' LIMIT ' + limitSize + ' OFFSET ' + offsetSize;
            
            System.debug(baseQuery);
            
            List<Support_Ticket__c> tickets = Database.query(baseQuery);
            
            /* ---------------- No Data Found ---------------- */
            if (tickets.isEmpty()) {
                
                SuccessResponseWrapper res =
                    new SuccessResponseWrapper(
                        false,
                        'No support tickets found for the given filters',
                        new List<TicketResponseWrapper>()
                    );
                
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody =
                    Blob.valueOf(JSON.serialize(res));
                
                log.Status__c = 'SUCCESS';
                log.Response__c = JSON.serialize(res);
                insert log;
                logInserted = true;
                return;
            }
            
            /* ---------------- Prepare Response ---------------- */
            List<TicketResponseWrapper> responseList = new List<TicketResponseWrapper>();
            
            for (Support_Ticket__c st : tickets) {
                responseList.add(new TicketResponseWrapper(st));
            }
            
            SuccessResponseWrapper res =  new SuccessResponseWrapper(true, 'Support ticket data', responseList);


            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =
                Blob.valueOf(JSON.serialize(res));

            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;

        } catch (Exception e) {

            System.debug('Exception: ' + e.getMessage());

            
            ErrorResponseUitilityClass.sendErrorResponse('Failed to fetch support tickets: ' + e.getMessage(),'GetSupportTicket_MobileAPI',requestBody);
            
        }
    }

    /* ====================== REQUEST WRAPPER ====================== */
    public class TicketRequestWrapper {
        public String userId;
        public Integer pageSize;
        public String ticketStatusId;
        public String ticketTypeId;
        public String search;
    }

    /* ====================== RESPONSE ITEM ====================== */
    public class TicketResponseWrapper {
        public String id;
        public String subject;
        public String description;
        public String type;
        public Datetime createdOn;
        public String ticketStatusId;
        public String priorityId;

        public TicketResponseWrapper(Support_Ticket__c st) {
            id = st.Name;
            subject = st.Subject__c;
            description = st.Description__c;
            type = st.Type__c;
            createdOn = st.CreatedDate;
            ticketStatusId = st.Ticket_Status__c;
            priorityId = st.Priority_Status__c;
        }
    }

    /* ====================== SUCCESS RESPONSE ====================== */
    public class SuccessResponseWrapper {
        public Boolean status;
        public String message;
        public List<TicketResponseWrapper> data;

        public SuccessResponseWrapper(Boolean status, String message, List<TicketResponseWrapper> data) {
            this.status = status;
            this.message = message;
            this.data = data;
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
    }
*/
    public class ResponseWrapper {
        public Boolean status;
        public String message;

        public ResponseWrapper(Boolean status, String message) {
            this.status = status;
            this.message = message;
        }
    }
}