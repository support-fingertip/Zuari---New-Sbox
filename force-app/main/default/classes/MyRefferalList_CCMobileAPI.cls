/**
 * @description REST API to fetch referral list for Contact Center mobile app.
 * Validates customer master and returns referrals for the customer with pagination
 * and optional status filter.
 *
 * Request:
 * {
 *   "userId": "CPC001",
 *   "bookingId": "CB005",
 *   "projectId": "BCC003",
 *   "pageSize": 0,
 *   "referralStatusId": "SITE",
 *   "fromDate": "2026-01-01T00:00:00Z",
 *   "toDate": "2026-01-31T23:59:59Z"
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Referral list fetched successfully",
 *   "data": [
 *     {
 *       "referralId": "REF-2024-001",
 *       "customerName": "Rajesh Kumar",
 *       "contactNumber": "+919876543210",
 *       "city": "Bangalore",
 *       "projectName": "Skyline Residency",
 *       "leadRating": 9,
 *       "rewardAmount": 5000,
 *       "rewardCurrency": "INR",
 *       "rewardDate": "2025-12-02T12:34:56Z",
 *       "status": "REWARDED"
 *     }
 *   ]
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-24
 */
@RestResource(urlMapping='/CCMyRefferalListAPI/*')
global without sharing class MyRefferalList_CCMobileAPI {

    @HttpPost
    global static void getMyRefferalList() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody != null ? req.requestBody.toString() : '';

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'MyRefferalList_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            MyRefferalListRequest requestData = (MyRefferalListRequest) JSON.deserialize(requestBody, MyRefferalListRequest.class);

            String userId = requestData != null ? requestData.userId : null;
            String referralStatusId = requestData != null ? requestData.referralStatusId : null;
            Datetime fromDate = requestData != null ? requestData.fromDate : null;
            Datetime toDate = requestData != null ? requestData.toDate : null;
            Integer pageSize = (requestData != null && requestData.pageSize != null) ? requestData.pageSize : 0;

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'MyRefferalList_CCMobileAPI', requestBody);
                return;
            }

            List<Customer_Master__c> customerList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = true
                LIMIT 1
            ];

            if (customerList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'MyRefferalList_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = customerList[0];

            Integer recLimit = 15;
            Integer offsetVal = pageSize * recLimit;
            String statusFilter = String.isBlank(referralStatusId) ? null : referralStatusId;
            List<String> whereConditions = new List<String>();
            whereConditions.add('Customer_Master__c = \'' + String.escapeSingleQuotes(String.valueOf(customer.Id)) + '\'');

            if (statusFilter != null) {
                whereConditions.add('Status__c = \'' + String.escapeSingleQuotes(statusFilter) + '\'');
            }

            if (fromDate != null) {
                whereConditions.add('CreatedDate >= ' + fromDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            }

            if (toDate != null) {
                whereConditions.add('CreatedDate <= ' + toDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            }
               String projectId = requestData != null ? requestData.projectId : null;
               if (!String.isBlank(projectId)) {
                   whereConditions.add('Project_Name__c = \'' + String.escapeSingleQuotes(projectId) + '\'');
               }

            String queryString = 'SELECT Name, Referrer_Name__c, Contact_Number__c, City__c, Project_Name__c, Lead__r.Lead_Score__c, Reward_Amount__c, Reward_Currency__c, CreatedDate, Status__c '
                + 'FROM Referral__c WHERE ' + String.join(whereConditions, ' AND ')
                + ' ORDER BY CreatedDate DESC LIMIT ' + String.valueOf(recLimit)
                + ' OFFSET ' + String.valueOf(offsetVal);

            List<Referral__c> referralRecords = (List<Referral__c>) Database.query(queryString);

            List<ReferralDetail> data = new List<ReferralDetail>();
            for (Referral__c referralRec : referralRecords) {
                ReferralDetail detail = new ReferralDetail();

                detail.referralId = referralRec.Name != null ? referralRec.Name : '';
                detail.customerName = referralRec.Referrer_Name__c != null ? referralRec.Referrer_Name__c : '';
                detail.contactNumber = referralRec.Contact_Number__c != null ? referralRec.Contact_Number__c : '';
                detail.city = referralRec.City__c != null ? referralRec.City__c : '';
                detail.projectName = referralRec.Project_Name__c != null ? referralRec.Project_Name__c : '';
                detail.leadRating = referralRec.Lead__r != null && referralRec.Lead__r.Lead_Score__c != null ? referralRec.Lead__r.Lead_Score__c : 0;
                detail.rewardAmount = referralRec.Reward_Amount__c != null ? referralRec.Reward_Amount__c : 0;
                detail.rewardCurrency = referralRec.Reward_Currency__c != null ? referralRec.Reward_Currency__c : 'INR';
                detail.rewardDate = referralRec.CreatedDate != null
                    ? referralRec.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
                    : '';
                detail.status = referralRec.Status__c != null ? referralRec.Status__c : '';

                data.add(detail);
            }

            MyRefferalListResponse responseData = new MyRefferalListResponse();
            responseData.status = true;
            responseData.message = 'Referral list fetched successfully';
            responseData.data = data;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));

            log.Response__c = 'Retrieved ' + data.size() + ' referrals for customer';
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'MyRefferalList_CCMobileAPI', requestBody);
        }
    }

    public class MyRefferalListRequest {
        public String userId;
        public String bookingId;
        public String projectId;
        public Integer pageSize;
        public String referralStatusId;
        public Datetime fromDate;
        public Datetime toDate;
    }

    public class ReferralDetail {
        public String referralId;
        public String customerName;
        public String contactNumber;
        public String city;
        public String projectName;
        public Decimal leadRating;
        public Decimal rewardAmount;
        public String rewardCurrency;
        public String rewardDate;
        public String status;
    }

    public class MyRefferalListResponse {
        public Boolean status;
        public String message;
        public List<ReferralDetail> data;
    }
}