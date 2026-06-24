/**
 * -----------------------------------------------------------------------------
 * Class Name  : Payment_MobileAPI
 * Author      : Praveen Kumar
 * API Type    : REST (POST)
 * URL Mapping : /services/apexrest/GetPaymentAPI/*
 *
 * Description :
 * This REST API is used by the mobile application to fetch payment-related
 * information for a logged-in Channel Partner.
 *
 * Key Features:
 * 1. Validates the requesting user using User_Id__c and fetches the active
 *    Channel Partner record.
 *
 * 2. Returns paginated Payment_Line_Item__c records (15 records per page)
 *    based on optional filters:
 *      - Payment Status
 *      - Project
 *
 * 3. Implements progressive (cumulative) totals logic:
 *      - Page 1  → totals of first 15 records
 *      - Page 2  → totals of first 30 records
 *      - Page 3  → totals of first 45 records (or available count)
 *      - Further pages → totals remain constant once records are exhausted
 *
 *    This is achieved by:
 *      - Fetching record Ids up to the cumulative limit
 *      - Running an aggregate query (SUM) on those Ids
 *
 * 4. Formats total amounts in Lakhs (L) for mobile-friendly display.
 *
 * 5. Ensures stateless behavior:
 *      - Totals are calculated dynamically per request
 *      - No dependency on previous API calls
 *
 * 6. Logs every request and response in Apex_Log__c for auditing and debugging.
 *
 * Notes:
 * - OFFSET is used only for page-level data retrieval.
 * - Aggregation avoids unsupported SOQL subqueries.
 * - Designed to be governor-safe and scalable.
 *
 * -----------------------------------------------------------------------------
 */

@RestResource(urlMapping='/GetPaymentAPI/*')
global without sharing class Payment_MobileAPI {

    @HttpPost
    global static void getPayments() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(Request_Type__c = 'Payment_MobileAPI',Request__c = requestBody);

        try {
            // ---------- Deserialize ----------
            PaymentRequestWrapper input = (PaymentRequestWrapper) JSON.deserialize(requestBody, PaymentRequestWrapper.class);

            if (String.isBlank(input.userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('UserId is required','Payment_MobileAPI',requestBody);
                 return;
            }

            // ---------- Channel Partner ----------
            Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c WHERE User_Id__c = :input.userId AND Active__c = TRUE LIMIT 1];
            if (cp == null) {
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found for userId: ' + input.userId,'Payment_MobileAPI',requestBody);

                return;
            }

            // ---------- Build SOQL ----------
             String baseWhere = ' WHERE Channel_Partner__c = \'' + cp.Id + '\'';

            String soql =
                'SELECT Id, Name,Payment_Line_Item__c, Property_Address__c, Payament_Status__c, ' +
                'Commission_Amount__c, Booking_Amount__c, Pending_Amount__c ' +
                'FROM Payment_Line_Item__c ' +
                'WHERE Channel_Partner__c = \'' + cp.Id + '\'';

            if (String.isNotBlank(input.paymentStatusId) && input.paymentStatusId != '0') {
                soql += ' AND Payament_Status__c = \'' +
                        String.escapeSingleQuotes(input.paymentStatusId) + '\'';
            }

            if (String.isNotBlank(input.projectId)) {
                soql += ' AND Project_name__c = \'' +
                        String.escapeSingleQuotes(input.projectId) + '\'';
            }

            Integer offsetSize = input.pageSize != null ? input.pageSize * 15 : 0;
            soql += ' ORDER BY CreatedDate DESC LIMIT 15 OFFSET ' + offsetSize;

            List<Payment_Line_Item__c> payments = Database.query(soql);

            // ---------- Build Response ----------
            PaymentSummary data = new PaymentSummary();
            data.paymentList = new List<PaymentLineItemWrapper>();

            Decimal totalProcessed = 0;
            Decimal totalPending = 0;
            Integer index = 1;

            for (Payment_Line_Item__c li : payments) {

                PaymentLineItemWrapper pw = new PaymentLineItemWrapper();
                pw.id = li.Payment_Line_Item__c;
                pw.personName = li.Name;
                pw.propertyAddress = li.Property_Address__c;
                pw.paymentStatus = li.Payament_Status__c;
                pw.commissionAmount = li.Commission_Amount__c;
                pw.bookingAmount = li.Booking_Amount__c;
                pw.pendingAmount = li.Pending_Amount__c;

                data.paymentList.add(pw);
                    // Commented on 27-01-2026 to optimize total calculation
               // totalProcessed += (li.Commission_Amount__c != null ? li.Commission_Amount__c : 0); 
                //totalPending += (li.Pending_Amount__c != null ? li.Pending_Amount__c : 0);
            }
            //Added on 27-01-2026 to optimize total calculation
            Integer cumulativeLimit = (input.pageSize + 1) * 15;
            List<Payment_Line_Item__c> cumulativeRecords = Database.query(
                                                            'SELECT Id FROM Payment_Line_Item__c ' + baseWhere + ' ORDER BY CreatedDate ASC  LIMIT ' + cumulativeLimit);
            Set<Id> cumulativeIds = new Set<Id>();
            for (Payment_Line_Item__c pli : cumulativeRecords) {
                cumulativeIds.add(pli.Id);
            }

            if (!cumulativeIds.isEmpty()) {
                 AggregateResult ar = [ SELECT  SUM(Commission_Amount__c) totalProcessed, SUM(Pending_Amount__c) totalPending  FROM Payment_Line_Item__c WHERE Id IN :cumulativeIds ];

    totalProcessed = ar.get('totalProcessed') != null  ? (Decimal) ar.get('totalProcessed')  : 0;

    totalPending = ar.get('totalPending') != null   ? (Decimal) ar.get('totalPending') : 0;
}

            data.processedAmount = formatInLakhs(totalProcessed);
            data.pendingAmount = formatInLakhs(totalPending);

            SuccessResponseWrapper res = new SuccessResponseWrapper(true, 'Payment data', data);

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse('Failed to fetch payment data: ' + e.getMessage(),'Payment_MobileAPI',requestBody);
            
        }
    }

    // ================= Helpers =================

    private static String formatInLakhs(Decimal amount) {
        if (amount == null) return '0L';
        Decimal lakhs = amount / 100000;
        return lakhs.setScale(1) + 'L';
    }

    // ================= Request =================
    public class PaymentRequestWrapper {
        public String userId;
        public String paymentStatusId;
        public String projectId;
        public Integer pageSize;
    }

    // ================= Response =================
    public class PaymentSummary {
        public String processedAmount;
        public String pendingAmount;
        public List<PaymentLineItemWrapper> paymentList;
    }

    public class PaymentLineItemWrapper {
        public String id;
        public String personName;
        public String propertyAddress;
        public String paymentStatus;
        public Decimal commissionAmount;
        public Decimal bookingAmount;
        public Decimal pendingAmount;
    }

    public class SuccessResponseWrapper {
        public Boolean status;
        public String message;
        public PaymentSummary data;

        public SuccessResponseWrapper(Boolean status, String message, PaymentSummary data) {
            this.status = status;
            this.message = message;
            this.data = data;
        }
    }

    public class ResponseWrapper {
        public Boolean status;
        public String message;
        public ResponseWrapper(Boolean status, String message) {
            this.status = status;
            this.message = message;
        }
    }
/*
    private static void sendError(String msg, Apex_Log__c log) {

        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(new ResponseWrapper(false, msg)));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        insert log;
    }*/
}