/**
 * @description REST API endpoint for Contact Center mobile application to fetch customer queries.
 * Validates customer and retrieves all associated queries with dynamic filtering and pagination.
 *
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "pageSize": 0,
 *   "projectId": "CPP001",
 *   "search": "",
 *   "ticketStatusId": "",
 *   "ticketTypeId": ""
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Support Queries",
 *   "data": [
 *     {
 *       "queryId": "qr01",
 *       "queryName": "Payment receipt not received",
 *       "queryDescription": "I made a payment...",
 *       "queryType": "Payment",
 *       "queryDate": "2025-12-02T12:34:56Z",
 *       "queryPriorityId": "High",
 *       "queryStatusId": "InProgress"
 *     }
 *   ]
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-23
 */
@RestResource(urlMapping='/CCAllCustomerQueriesAPI/*')
global without sharing class AllCustomerQuery_CCMobileAPI {

    /**
     * @description Handles POST requests to fetch customer queries with dynamic filtering.
     * Validates customer and builds dynamic query based on provided filters.
     */
    @HttpPost
    global static void getAllCustomerQueries() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AllCustomerQuery_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            AllQueriesRequestWrapper requestData = (AllQueriesRequestWrapper) JSON.deserialize(requestBody, AllQueriesRequestWrapper.class);

            String userId = requestData.userId;
            Integer pageSize = requestData.pageSize != null ? requestData.pageSize : 0;
            String projectId = requestData.projectId;
            String search = requestData.search;
            String ticketStatusId = requestData.ticketStatusId;
            String ticketTypeId = requestData.ticketTypeId;

            // Validate that userId is provided
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'AllCustomerQuery_CCMobileAPI', requestBody);
                return;
            }

            // Validate customer exists
            List<Customer_Master__c> cmList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'AllCustomerQuery_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = cmList[0];

            // Build dynamic query with filters (using conditions list + bind map)
            String baseQuery = 'SELECT Id,Name, Subject__c, Description__c, Query_Type__c, CreatedDate, Priority__c, Query_Status__c FROM Customer_Query__c';

            List<String> conditions = new List<String>();
            String cmid =customer.Id;
            conditions.add('Customer_Master__c = :cmid');



            // Optional filters (inline escaped values)
            if (!String.isBlank(projectId)) {
                 conditions.add(
                        'Project__c = \'' + String.escapeSingleQuotes(projectId) + '\''
                    );
            }

            if (!String.isBlank(search)) {
                String escapedSearch = String.escapeSingleQuotes(search.trim());
                 conditions.add(
        '(' +
        'Name LIKE \'%' + escapedSearch + '%\' ' +
        'OR Subject__c LIKE \'%' + escapedSearch + '%\' ' +
        'OR Query_Type__c LIKE \'%' + escapedSearch + '%\' ' +
        'OR Priority__c LIKE \'%' + escapedSearch + '%\' ' +
        'OR Query_Status__c LIKE \'%' + escapedSearch + '%\'' +
        ')'
    );
              }

            if (!String.isBlank(ticketStatusId)) {
                conditions.add(
                        'Query_Status__c = \'' + String.escapeSingleQuotes(ticketStatusId) + '\''
                    );
               }

            if (!String.isBlank(ticketTypeId)) {
                conditions.add(
                        'Query_Type__c = \'' + String.escapeSingleQuotes(ticketTypeId) + '\''
                    );
               }
               

            // Attach WHERE clause if we have conditions
            String queryString = baseQuery;
            if (!conditions.isEmpty()) {
                queryString += ' WHERE ' + String.join(conditions, ' AND ');
            }

            // Add ordering and pagination
            queryString += ' ORDER BY CreatedDate DESC';

            // Calculate offset based on pageSize (pageSize * 15 records per page)
            Integer offset = pageSize * 15;
            Integer recordLimit = 15;

             Integer offsetSize = pageSize != null ? pageSize*15 : 0;
                queryString += ' LIMIT 15 OFFSET ' + offsetSize;
            // Execute dynamic query
            System.debug('Dynamic Query: ' + queryString);
            List<Customer_Query__c> queryList = Database.query(queryString);

            // If no queries found, return empty response
            if (queryList.isEmpty()) {
                AllQueriesResponse response = new AllQueriesResponse();
                response.status = true;
                response.message = 'Support Queries';
                response.data = new List<QueryDetail>();

                RestContext.response.statusCode = 200;
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

                log.Response__c = 'No queries found for customer';
                log.Status__c = 'SUCCESS';
                insert log;
                return;
            }

            // Build response data
            List<QueryDetail> queryDetailList = new List<QueryDetail>();

            for (Customer_Query__c cq : queryList) {
                QueryDetail queryDetail = new QueryDetail();
                queryDetail.queryId = cq.Name;
                queryDetail.queryName = cq.Subject__c != null ? cq.Subject__c : '';
                queryDetail.queryDescription = cq.Description__c != null ? cq.Description__c : '';
                queryDetail.queryType = cq.Query_Type__c != null ? cq.Query_Type__c : '';
                queryDetail.queryDate = cq.CreatedDate != null ? cq.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : '';
                queryDetail.queryPriorityId = cq.Priority__c != null ? cq.Priority__c : '';
                String qStatus = (String)cq.get('Query_Status__c');
                queryDetail.queryStatusId = qStatus != null ? qStatus : '';
                queryDetailList.add(queryDetail);
            }

            // Build response
            AllQueriesResponse response = new AllQueriesResponse();
            response.status = true;
            response.message = 'Support Queries';
            response.data = queryDetailList;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Retrieved ' + queryList.size() + ' queries for customer';
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'AllCustomerQuery_CCMobileAPI', requestBody);
        }
    }

    // ===== Request Wrapper =====
    /**
     * @description Wrapper class for deserializing all queries request JSON.
     */
    public class AllQueriesRequestWrapper {
        public String userId;           // Customer identifier
        public Integer pageSize;        // Page number (0 = first 15 records, 1 = next 15, etc.)
        public String projectId;        // Project filter (optional)
        public String search;           // Search term for Subject or Description (optional)
        public String ticketStatusId;   // Status filter (optional)
        public String ticketTypeId;     // Query type filter (optional)
    }

    // ===== Response Wrapper Classes =====
    /**
     * @description Wrapper class for individual query detail in response.
     */
    public class QueryDetail {
        public String queryId;          // Query record Id
        public String queryName;        // Subject
        public String queryDescription; // Description
        public String queryType;        // Query type
        public String queryDate;        // Created date
        public String queryPriorityId;  // Priority
        public String queryStatusId;    // Status
    }

    /**
     * @description Wrapper class for complete API response.
     */
    public class AllQueriesResponse {
        public Boolean status;              // Response status
        public String message;              // Response message
        public List<QueryDetail> data;      // Array of query details
    }

}