/**
 * @description REST API for Receipt Screen in Contact Center Mobile.
 * Performs customer + booking validation and returns:
 * 1) Demand summary (total due, overdue, pending count)
 * 2) Full pending demand list for the booking
 * 3) Latest 5 receipt line item payments with downloadable receipt file URL
 *
 * Request:
 * {
 *   "userId":"CPC001",
 *   "bookingId":"BCC003"
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Receipts List",
 *   "data": {
 *     "totalDue": 280000,
 *     "overDue": 45000,
 *     "pending": 5,
 *     "pendingDemand": [ ... ],
 *     "RecentPayments": [ ... ]
 *   }
 * }
 *
 * @author Praveen Kumar
 */
@RestResource(urlMapping='/CCReceiptScreenAPI/*')
global without sharing class ReceiptScreen_CCMobileAPI {

    /**
     * @description Entry point for receipt screen API.
     * Validates request, resolves booking context, and prepares screen payload.
     */
    @HttpPost
    global static void getReceiptScreenData() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody != null ? req.requestBody.toString() : '';

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'ReceiptScreen_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            ReceiptScreenRequest requestData = (ReceiptScreenRequest) JSON.deserialize(requestBody, ReceiptScreenRequest.class);

            String userId = requestData != null ? requestData.userId : null;
            String bookingId = requestData != null ? requestData.bookingId : null;

            // Validate mandatory userId
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'ReceiptScreen_CCMobileAPI', requestBody);
                return;
            }

            // Resolve active customer by Id or external Name
            List<Customer_Master__c> customerList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = true
                LIMIT 1
            ];

            if (customerList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'ReceiptScreen_CCMobileAPI', requestBody);
                return;
            }

            // Validate mandatory bookingId
            if (String.isBlank(bookingId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide bookingId', 'ReceiptScreen_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = customerList[0];

            // Ensure booking belongs to the validated customer
            List<Booking__c> bookingList = [
                SELECT Id, Name
                FROM Booking__c
                WHERE Name = :bookingId
                AND Customer_Master__c = :customer.Id
                LIMIT 1
            ];

            if (bookingList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Booking not found for customer', 'ReceiptScreen_CCMobileAPI', requestBody);
                return;
            }

            Booking__c booking = bookingList[0];

         // Fetch all raised demands for this booking (no pagination by requirement)
            List<Demand_Raised__c> demandList = [
                SELECT Id, Name, Demand_Status__c, Amount_Demanded__c, Current_Demand_amount__c, Demanded_Date__c,
                       Payment_schedule__r.Name, Payment_schedule__r.Payment_Due_Date__c
                FROM Demand_Raised__c
                WHERE Booking__c = :booking.Id
                ORDER BY CreatedDate DESC
            ];

            Decimal totalDue = 0;
            Decimal overDue = 0;
            Integer pendingCount = 0;
            List<PendingDemandDetail> pendingDemandList = new List<PendingDemandDetail>();

            // Build pending demand details and aggregate summary metrics
            for (Demand_Raised__c demandRec : demandList) {
                PendingDemandDetail pendingItem = new PendingDemandDetail();
                pendingItem.pendingDemandId = demandRec.Name != null ? demandRec.Name : '';
                pendingItem.pendingDemandName = (demandRec.Payment_schedule__r != null && demandRec.Payment_schedule__r.Name != null)
                    ? demandRec.Payment_schedule__r.Name
                    : '';
                pendingItem.pendingDemandDescription = pendingItem.pendingDemandName;

                Date dueDate = (demandRec.Payment_schedule__r != null) ? demandRec.Payment_schedule__r.Payment_Due_Date__c : null;
                if (dueDate != null) {
                    pendingItem.pendingDemandDueDate = Datetime.newInstance(dueDate.year(), dueDate.month(), dueDate.day()).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                } else {
                    pendingItem.pendingDemandDueDate = '';
                }

                pendingItem.pendingDemandStatusId = demandRec.Demand_Status__c != null ? demandRec.Demand_Status__c : '';

                Decimal demandAmount = demandRec.Current_Demand_amount__c != null
                    ? demandRec.Current_Demand_amount__c
                    : (demandRec.Amount_Demanded__c != null ? demandRec.Amount_Demanded__c : 0);
                pendingItem.pendingDemandAmount = demandAmount;

                // Total due = sum of all demand amounts
                totalDue += demandAmount;

                // Overdue = demand amounts where due date has passed
                if (dueDate != null && dueDate < Date.today()) {
                    overDue += demandAmount;
                }

                // Pending count based on commonly used due/pending statuses
                if (pendingItem.pendingDemandStatusId == null || pendingItem.pendingDemandStatusId == '' ||
                    pendingItem.pendingDemandStatusId.equalsIgnoreCase('Due') ||
                    pendingItem.pendingDemandStatusId.equalsIgnoreCase('Pending') ||
                    pendingItem.pendingDemandStatusId.equalsIgnoreCase('Overdue')) {
                    pendingCount++;
                }

                pendingDemandList.add(pendingItem);
            }

            // Fetch latest 5 receipt line items (recent payments section)
            List<Receipt_Line_Item__c> receiptList = [
                SELECT Id, Name, Amount__c, Mode_of_Payment__c, Cheque_no_Transaction_Number__c, Receipt__c,
                       Receipt__r.Receipt_Date__c, Payment_schedule__r.Name
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :booking.Id
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];

            Map<Id, String> receiptToDownloadUrl = new Map<Id, String>();
            Set<Id> receiptIds = new Set<Id>();
            for (Receipt_Line_Item__c receiptLine : receiptList) {
                if (receiptLine.Receipt__c != null) {
                    receiptIds.add(receiptLine.Receipt__c);
                }
            }

            // Resolve each receipt's downloadable file URL from Files (Content objects)
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

                // Pick one matching receipt file version per receipt record
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

                    // Create distribution when it doesn't exist, so API can return download URL
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

            // Build RecentPayments response array
            List<PaymentDetail> recentPayments = new List<PaymentDetail>();
            for (Receipt_Line_Item__c receiptLine : receiptList) {
                PaymentDetail paymentItem = new PaymentDetail();
                paymentItem.paymentId = receiptLine.Name != null ? receiptLine.Name : '';
                paymentItem.paymentName = (receiptLine.Payment_schedule__r != null && receiptLine.Payment_schedule__r.Name != null)
                    ? receiptLine.Payment_schedule__r.Name
                    : '';

                if (receiptLine.Receipt__r != null && receiptLine.Receipt__r.Receipt_Date__c != null) {
                    Date receiptDate = receiptLine.Receipt__r.Receipt_Date__c;
                    paymentItem.paymentDate = Datetime.newInstance(receiptDate.year(), receiptDate.month(), receiptDate.day()).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                } else {
                    paymentItem.paymentDate = '';
                }

                paymentItem.paymentAmount = receiptLine.Amount__c != null ? receiptLine.Amount__c : 0;
                paymentItem.paymentMethod = receiptLine.Mode_of_Payment__c != null ? receiptLine.Mode_of_Payment__c : '';
                paymentItem.paymentFileDownloadURL = receiptLine.Receipt__c != null && receiptToDownloadUrl.containsKey(receiptLine.Receipt__c)
                    ? receiptToDownloadUrl.get(receiptLine.Receipt__c)
                    : '';
                paymentItem.paymentTransactionId = receiptLine.Cheque_no_Transaction_Number__c != null
                    ? receiptLine.Cheque_no_Transaction_Number__c
                    : '';
                recentPayments.add(paymentItem);
            }

            // Compose final response payload
            ReceiptScreenData data = new ReceiptScreenData();
            data.totalDue = totalDue;
            data.overDue = overDue;
            data.pending = pendingCount;
            data.pendingDemand = pendingDemandList;
            data.RecentPayments = recentPayments;

            ReceiptScreenResponse responseData = new ReceiptScreenResponse();
            responseData.status = true;
            responseData.message = 'Receipts List';
            responseData.data = data;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));

            log.Response__c = 'Retrieved receipt screen data for booking';
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'ReceiptScreen_CCMobileAPI', requestBody);
        }
    }

    /**
     * @description Request wrapper for receipt screen API.
     */
    public class ReceiptScreenRequest {
        public String userId;
        public String bookingId;
    }

    /**
     * @description Pending demand detail node used in response.
     */
    public class PendingDemandDetail {
        public String pendingDemandId;
        public String pendingDemandName;
        public String pendingDemandDescription;
        public String pendingDemandDueDate;
        public String pendingDemandStatusId;
        public Decimal pendingDemandAmount;
    }

    /**
     * @description Recent payment detail node used in response.
     */
    public class PaymentDetail {
        public String paymentId;
        public String paymentName;
        public String paymentDate;
        public Decimal paymentAmount;
        public String paymentMethod;
        public String paymentFileDownloadURL;
        public String paymentTransactionId;
    }

    /**
     * @description Data wrapper for receipt screen summary and lists.
     */
    public class ReceiptScreenData {
        public Decimal totalDue;
        public Decimal overDue;
        public Integer pending;
        public List<PendingDemandDetail> pendingDemand;
        public List<PaymentDetail> RecentPayments;
    }

    /**
     * @description Top-level API response wrapper.
     */
    public class ReceiptScreenResponse {
        public Boolean status;
        public String message;
        public ReceiptScreenData data;
    }
}