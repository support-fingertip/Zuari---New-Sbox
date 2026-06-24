/**
 * @description REST API to fetch all demands related to a booking for Contact Center mobile app.
 * Validates customer -> booking, supports filtering by demand status and pagination.
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "bookingId": "BBK001",
 *   "projectId": "PRJ001",
 *   "demandStatusId": "Pending",
 *   "pageSize": 0
 * }
 *
 * Response:
 * {
 *  "status": true,
 *  "message": "All Demands",
 *  "data": [ { demand objects... } ]
 * }
 */
@RestResource(urlMapping='/CCAllDemandsAPI/*')
global without sharing class AllDemand_CCMobileAPI {

    @HttpPost
    global static void getAllDemands() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        String normalizedRequestBody = requestBody
            .replace('"raiseFromDate":""', '"raiseFromDate":null')
            .replace('"raiseToDate":""', '"raiseToDate":null')
            .replace('"dueFromDate":""', '"dueFromDate":null')
            .replace('"dueToDate":""', '"dueToDate":null')
            .replace('"raiseFromDate": ""', '"raiseFromDate": null')
            .replace('"raiseToDate": ""', '"raiseToDate": null')
            .replace('"dueFromDate": ""', '"dueFromDate": null')
            .replace('"dueToDate": ""', '"dueToDate": null');

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AllDemand_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            AllDemandRequest requestData = (AllDemandRequest) JSON.deserialize(normalizedRequestBody, AllDemandRequest.class);

            String userId = requestData.userId;
            String bookingId = requestData.bookingId;
            String projectId = requestData.projectId;
            String demandStatusId = requestData.demandStatusId;
            Datetime raiseFromDate = requestData.raiseFromDate;
            Datetime raiseToDate = requestData.raiseToDate;
            Datetime dueFromDate = requestData.dueFromDate;
            Datetime dueToDate = requestData.dueToDate;
            Integer pageSize = requestData.pageSize != null ? requestData.pageSize : 0;

            if (raiseFromDate != null && raiseToDate != null && raiseFromDate > raiseToDate) {
                ErrorResponseUitilityClass.sendErrorResponse('raiseFromDate should be less than or equal to raiseToDate', 'AllDemand_CCMobileAPI', requestBody);
                return;
            }
            if (dueFromDate != null && dueToDate != null && dueFromDate > dueToDate) {
                ErrorResponseUitilityClass.sendErrorResponse('dueFromDate should be less than or equal to dueToDate', 'AllDemand_CCMobileAPI', requestBody);
                return;
            }

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'AllDemand_CCMobileAPI', requestBody);
                return;
            }

            // Validate customer
            List<Customer_Master__c> cmList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'AllDemand_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = cmList[0];

            // Validate booking belongs to customer
            if (String.isBlank(bookingId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide bookingId', 'AllDemand_CCMobileAPI', requestBody);
                return;
            }

            List<Booking__c> bkList = [
                SELECT Id, Name, Project1__c
                FROM Booking__c
                WHERE Name = :bookingId
                AND Customer_Master__c = :customer.Id
                LIMIT 1
            ];

            if (bkList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Booking not found for customer', 'AllDemand_CCMobileAPI', requestBody);
                return;
            }

            Booking__c booking = bkList[0];

            // Build dynamic SOQL directly on Demand_Raised__c for this booking
            List<String> conditions = new List<String>();
            conditions.add('Booking__c = \'' + String.escapeSingleQuotes(String.valueOf(booking.Id)) + '\'');

            if (!String.isBlank(demandStatusId)) {
                conditions.add('Demand_Status__c = \'' + String.escapeSingleQuotes(demandStatusId) + '\'');
            }
            if (raiseFromDate != null) {
                conditions.add('DAY_ONLY(Demanded_Date__c) >= ' + String.valueOf(raiseFromDate.dateGmt()));
            }
            if (raiseToDate != null) {
                conditions.add('DAY_ONLY(Demanded_Date__c) <= ' + String.valueOf(raiseToDate.dateGmt()));
            }
            if (dueFromDate != null) {
                conditions.add('Due_Date_Payment_Schedule__c >= ' + String.valueOf(dueFromDate.dateGmt()));
            }
            if (dueToDate != null) {
                conditions.add('Due_Date_Payment_Schedule__c <= ' + String.valueOf(dueToDate.dateGmt()));
            }

            Integer offset = pageSize * 15;
            Integer recLimit = 15;

            String queryString =
                'SELECT Id, Name, Demanded_Date__c, Amount_Demanded__c, Current_Demand_amount__c, Demand_Status__c, ' +
                'Payment_schedule__r.Name, Payment_schedule__r.PaymentDueDate__c, Payment_schedule__r.Received_Amount1__c, ' +
                'Payment_schedule__r.Interest_Amount__c, Payment_schedule__r.Payment_Date__c ' +
                'FROM Demand_Raised__c WHERE ' + String.join(conditions, ' AND ') + ' ' +
                'ORDER BY CreatedDate ASC LIMIT ' + String.valueOf(recLimit) + ' OFFSET ' + String.valueOf(offset);

            System.debug('queryString: ' + queryString);
            List<Demand_Raised__c> demandList = Database.query(queryString);

            List<DemandDetail> data = new List<DemandDetail>();
            for (Demand_Raised__c demandRec : demandList) {
                DemandDetail det = new DemandDetail();
                det.demandId = demandRec.Name != null ? demandRec.Name : '';
                det.demandName = (demandRec.Payment_schedule__r != null && demandRec.Payment_schedule__r.Name != null)
                    ? demandRec.Payment_schedule__r.Name
                    : '';

                String demandRaisedStr = '';
                if (demandRec.Demanded_Date__c != null) {
                    demandRaisedStr = String.valueOf(demandRec.Demanded_Date__c.dateGmt());
                }
                det.demandRaisedDate = demandRaisedStr;

                String demandDueStr = '';
                if (demandRec.Payment_schedule__r != null && demandRec.Payment_schedule__r.PaymentDueDate__c != null) {
                    Date dueDate = demandRec.Payment_schedule__r.PaymentDueDate__c;
                    demandDueStr = String.valueOf(dueDate);
                }
                det.demandDueDate = demandDueStr;

                Decimal demandedAmount = demandRec.Current_Demand_amount__c != null
                    ? demandRec.Current_Demand_amount__c
                    : (demandRec.Amount_Demanded__c != null ? demandRec.Amount_Demanded__c : 0);
                det.demandAmount = demandedAmount;

                Decimal paidAmount = (demandRec.Payment_schedule__r != null && demandRec.Payment_schedule__r.Received_Amount1__c != null)
                    ? demandRec.Payment_schedule__r.Received_Amount1__c
                    : 0;
                det.paidAmount = paidAmount;
                det.balance = demandedAmount - paidAmount;

                det.interest = (demandRec.Payment_schedule__r != null && demandRec.Payment_schedule__r.Interest_Amount__c != null)
                    ? demandRec.Payment_schedule__r.Interest_Amount__c
                    : 0;
                det.demandStatusId = demandRec.Demand_Status__c != null ? demandRec.Demand_Status__c : '';

                if (demandRec.Payment_schedule__r != null && demandRec.Payment_schedule__r.Payment_Date__c != null) {
                    Datetime lastPayDate = demandRec.Payment_schedule__r.Payment_Date__c;
                    Date d = Date.newInstance(lastPayDate.year(), lastPayDate.month(), lastPayDate.day());
                    det.paidOnDate = String.valueOf(d);
                } else {
                    det.paidOnDate = '';
                }

                data.add(det);
            }

            AllDemandResponse resp = new AllDemandResponse();
            resp.status = true;
            resp.message = 'All Demands';
            resp.data = data;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));

            log.Response__c = 'Retrieved ' + demandList.size() + ' demands for booking ' + JSON.serialize(resp);
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'AllDemand_CCMobileAPI', RestContext.request.requestBody.toString());
        }
    }

    // ===== Request / Response wrappers =====
    public class AllDemandRequest {
        public String userId;
        public String bookingId;
        public String projectId;
        public String demandStatusId;
        public Datetime raiseToDate;
        public Datetime raiseFromDate;
        public Datetime dueFromDate;
        public Datetime dueToDate;
        public Integer pageSize;
    }

    public class DemandDetail {
        public String demandId;
        public String demandName;
        public String demandRaisedDate;
        public String demandDueDate;
        public Decimal demandAmount;
        public Decimal paidAmount;
        public Decimal balance;
        public Decimal interest;
        public String demandStatusId;
        public String paidOnDate;
    }

    public class AllDemandResponse {
        public Boolean status;
        public String message;
        public List<DemandDetail> data;
    }

}