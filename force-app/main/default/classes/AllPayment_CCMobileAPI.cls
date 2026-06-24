/**
 * @description REST API to fetch all payments (receipts) related to a booking for Contact Center mobile app.
 * Validates customer -> booking, supports optional payment status filter and pagination.
 *
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "bookingId": "CPP001",
 *   "paymentStatusId": "",
 *   "pageSize": 0
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "All Payments",
 *   "data": [
 *     {
 *       "paymentId": "001",
 *       "paymentName": "5th Floor Structure",
 *       "paymentDate": "2025-12-02T12:34:56Z",
 *       "paymentAmount": 281000,
 *       "paymentMethod": "UPI",
 *       "paymentFileDownloadURL": "",
 *       "paymentTransactionId": "RCP-2024-156-001"
 *     }
 *   ]
 * }
 */
@RestResource(urlMapping='/CCAllPaymentsAPI/*')
global without sharing class AllPayment_CCMobileAPI {

    @HttpPost
    global static void getAllPayments() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody != null ? req.requestBody.toString() : '';

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AllPayment_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            AllPaymentRequest requestData = (AllPaymentRequest) JSON.deserialize(requestBody, AllPaymentRequest.class);

            String userId = requestData != null ? requestData.userId : null;
            String bookingId = requestData != null ? requestData.bookingId : null;
            String paymentStatusId = requestData != null ? requestData.paymentStatusId : null;
            Integer pageSize = (requestData != null && requestData.pageSize != null) ? requestData.pageSize : 0;

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'AllPayment_CCMobileAPI', requestBody);
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
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'AllPayment_CCMobileAPI', requestBody);
                return;
            }

            if (String.isBlank(bookingId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide bookingId', 'AllPayment_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = customerList[0];
            List<Booking__c> bookingList = [
                SELECT Id, Name
                FROM Booking__c
                WHERE Name = :bookingId
                AND Customer_Master__c = :customer.Id
                LIMIT 1
            ];

            if (bookingList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Booking not found for customer', 'AllPayment_CCMobileAPI', requestBody);
                return;
            }

            Booking__c booking = bookingList[0];

            List<String> conditions = new List<String>();
            conditions.add('Booking__c = \'' + String.escapeSingleQuotes(String.valueOf(booking.Id)) + '\'');

            if (!String.isBlank(paymentStatusId)) {
                conditions.add('Approval_Status__c = \'' + String.escapeSingleQuotes(paymentStatusId) + '\'');
            }
                if (requestData.fromDate != null) {
                    conditions.add('CreatedDate >= ' + requestData.fromDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                }
                if (requestData.toDate != null) {
                    conditions.add('CreatedDate <= ' + requestData.toDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                }

            Integer recLimit = 15;
            Integer offsetVal = pageSize * recLimit;

            String queryString =
                'SELECT Id, Name, Amount__c, Mode_of_Payment__c, Cheque_no_Transaction_Number__c, Receipt__c, ' +
                'Receipt__r.Receipt_Date__c, Payment_schedule__r.Name ' +
                'FROM Receipt_Line_Item__c ' +
                'WHERE ' + String.join(conditions, ' AND ') + ' ' +
                'ORDER BY CreatedDate DESC ' +
                'LIMIT ' + String.valueOf(recLimit) + ' OFFSET ' + String.valueOf(offsetVal);

            List<Receipt_Line_Item__c> receiptList = Database.query(queryString);

            Map<Id, String> receiptToDownloadUrl = new Map<Id, String>();
            Set<Id> receiptIds = new Set<Id>();
            for (Receipt_Line_Item__c receiptLine : receiptList) {
                if (receiptLine.Receipt__c != null) {
                    receiptIds.add(receiptLine.Receipt__c);
                }
            }

            if (!receiptIds.isEmpty()) {
                List<ContentDocumentLink> receiptFileLinks = [
                    SELECT LinkedEntityId, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :receiptIds
                ];

                Set<Id> contentDocIds = new Set<Id>();
                Map<Id, Set<Id>> receiptToDocIds = new Map<Id, Set<Id>>();
                for (ContentDocumentLink linkRec : receiptFileLinks) {
                    contentDocIds.add(linkRec.ContentDocumentId);
                    if (!receiptToDocIds.containsKey(linkRec.LinkedEntityId)) {
                        receiptToDocIds.put(linkRec.LinkedEntityId, new Set<Id>());
                    }
                    receiptToDocIds.get(linkRec.LinkedEntityId).add(linkRec.ContentDocumentId);
                }

                Map<Id, ContentVersion> docToVersionMap = new Map<Id, ContentVersion>();
                if (!contentDocIds.isEmpty()) {
                    for (ContentVersion cv : [
                        SELECT Id, ContentDocumentId, Title, CreatedDate
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :contentDocIds
                        AND IsLatest = true
                        ORDER BY CreatedDate DESC
                    ]) {
                        if (cv.Title != null && cv.Title.toLowerCase().contains('receipt')) {
                            docToVersionMap.put(cv.ContentDocumentId, cv);
                        }
                    }
                }

                Map<Id, Id> receiptToVersionId = new Map<Id, Id>();
                Set<Id> versionIds = new Set<Id>();
                for (Id recId : receiptToDocIds.keySet()) {
                    for (Id docId : receiptToDocIds.get(recId)) {
                        if (docToVersionMap.containsKey(docId)) {
                            Id versionId = docToVersionMap.get(docId).Id;
                            receiptToVersionId.put(recId, versionId);
                            versionIds.add(versionId);
                            break;
                        }
                    }
                }

                if (!versionIds.isEmpty()) {
                    Map<Id, ContentDistribution> versionToDistribution = new Map<Id, ContentDistribution>();
                    for (ContentDistribution dist : [
                        SELECT Id, ContentVersionId, ContentDownloadUrl
                        FROM ContentDistribution
                        WHERE ContentVersionId IN :versionIds
                    ]) {
                        if (!versionToDistribution.containsKey(dist.ContentVersionId)) {
                            versionToDistribution.put(dist.ContentVersionId, dist);
                        }
                    }

                    List<ContentDistribution> distributionsToInsert = new List<ContentDistribution>();
                    for (Id versionId : versionIds) {
                        if (!versionToDistribution.containsKey(versionId)) {
                            ContentDistribution newDist = new ContentDistribution();
                            newDist.Name = 'Receipt File';
                            newDist.ContentVersionId = versionId;
                            newDist.PreferencesAllowViewInBrowser = true;
                            newDist.PreferencesLinkLatestVersion = true;
                            distributionsToInsert.add(newDist);
                        }
                    }

                    if (!distributionsToInsert.isEmpty()) {
                        insert distributionsToInsert;
                        for (ContentDistribution dist : [
                            SELECT Id, ContentVersionId, ContentDownloadUrl
                            FROM ContentDistribution
                            WHERE ContentVersionId IN :versionIds
                        ]) {
                            if (!versionToDistribution.containsKey(dist.ContentVersionId)) {
                                versionToDistribution.put(dist.ContentVersionId, dist);
                            }
                        }
                    }

                    for (Id recId : receiptToVersionId.keySet()) {
                        Id versionId = receiptToVersionId.get(recId);
                        if (versionToDistribution.containsKey(versionId)) {
                            String downloadUrl = versionToDistribution.get(versionId).ContentDownloadUrl;
                            receiptToDownloadUrl.put(recId, downloadUrl != null ? downloadUrl : '');
                        }
                    }
                }
            }

            List<PaymentDetail> paymentData = new List<PaymentDetail>();
            for (Receipt_Line_Item__c receiptLine : receiptList) {
                PaymentDetail detail = new PaymentDetail();
                detail.paymentId = receiptLine.Name != null ? receiptLine.Name : '';
                detail.paymentName = receiptLine.Payment_schedule__r != null && receiptLine.Payment_schedule__r.Name != null
                    ? receiptLine.Payment_schedule__r.Name
                    : '';

                if (receiptLine.Receipt__r != null && receiptLine.Receipt__r.Receipt_Date__c != null) {
                    Date receiptDate = receiptLine.Receipt__r.Receipt_Date__c;
                    detail.paymentDate = Datetime.newInstance(receiptDate.year(), receiptDate.month(), receiptDate.day()).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                } else {
                    detail.paymentDate = '';
                }

                detail.paymentAmount = receiptLine.Amount__c != null ? receiptLine.Amount__c : 0;
                detail.paymentMethod = receiptLine.Mode_of_Payment__c != null ? receiptLine.Mode_of_Payment__c : '';
                detail.paymentFileDownloadURL = receiptLine.Receipt__c != null && receiptToDownloadUrl.containsKey(receiptLine.Receipt__c)
                    ? receiptToDownloadUrl.get(receiptLine.Receipt__c)
                    : '';
                detail.paymentTransactionId = receiptLine.Cheque_no_Transaction_Number__c != null
                    ? receiptLine.Cheque_no_Transaction_Number__c
                    : '';

                paymentData.add(detail);
            }

            AllPaymentResponse responseData = new AllPaymentResponse();
            responseData.status = true;
            responseData.message = 'All Payments';
            responseData.data = paymentData;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));

            log.Response__c = 'Retrieved ' + paymentData.size() + ' payments for booking';
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'AllPayment_CCMobileAPI', requestBody);
        }
    }

    public class AllPaymentRequest {
        public String userId;
        public String bookingId;
        public String paymentStatusId;
        public Integer pageSize;
        public Datetime fromDate;
        public Datetime toDate;
    }

    public class PaymentDetail {
        public String paymentId;
        public String paymentName;
        public String paymentDate;
        public Decimal paymentAmount;
        public String paymentMethod;
        public String paymentFileDownloadURL;
        public String paymentTransactionId;
    }

    public class AllPaymentResponse {
        public Boolean status;
        public String message;
        public List<PaymentDetail> data;
    }
}