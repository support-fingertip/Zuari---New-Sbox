/****************************************************************
* Class Name   : PaymentDetail_MobileAPI
* Company      : Fingertipplus
* Created Date : 23-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API fetches Payment Line Item details for a
* Channel Partner using payment line item Id.
*
* Request JSON:
* {
*   "userId": "9",
*   "paymentId": "2"
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Payment data",
*   "data": {
*     "paymentId": 2,
*     "personName": "Rajesh Kumar",
*     "projectName": "Zuari Gardens",
*     "flatNumber": "A-101",
*     "bookingDate": "2025-12-02T12:34:56Z",
*     "paymentStatus": 33,
*     "bookingAmount": 5000000,
*     "commissionRate": 2,
*     "commissionAmount": 10000,
*     "processedAmount": 200000,
*     "pendingAmount": 300000,
*     "transactionNumber": "TXN001234567",
*     "paymentMethod": "Bank Transfer",
*     "processingDate": "2025-12-02T12:34:56Z",
*     "invoiceUrl": "",
*     "contractFile": ""
*   }
* }
*
* Author       : Sandeep Kumar
*****************************************************************/

@RestResource(urlMapping='/PaymentDetailAPI/*')
global without sharing class PaymentDetail_MobileAPI {
    
    @HttpPost
    global static void getPaymentDetail() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'PaymentDetailAPI',
            Request__c = requestBody
        );
        
        try {   
            
            PaymentDetailRequest input =  (PaymentDetailRequest) JSON.deserialize(requestBody, PaymentDetailRequest.class);
            
            if (String.isBlank(input.userId)) {
                //sendError('UserId is required', log);
                ErrorResponseUitilityClass.sendErrorResponse('UserId is required','PaymentDetailAPI',requestBody);
                return;
            }
            if (String.isBlank(input.paymentId)) {
                ErrorResponseUitilityClass.sendErrorResponse('PaymentId is required','PaymentDetailAPI',requestBody);
                return;
            }
            
            // Validate Channel Partner
            List<Channel_Partner__c> lstcp = [SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :input.userId  AND Active__c = TRUE    LIMIT 1];
            if (lstcp.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found','PaymentDetailAPI',requestBody);
                return;
            }
            Channel_Partner__c cp = lstcp[0];
            System.debug(cp);
            // Fetch Payment Line Item
            List<Payment_Line_Item__c> lstpli = [SELECT Id, Name, Payment_Line_Item__c, Project_name__c, Flat_Number__c,
                                                 Booking_Date__c, Payament_Status__c, Booking_Amount__c,
                                                 Comminsion_Rate__c, Commission_Amount__c, Pending_Amount__c,
                                                 Transcantion_Number__c, Payment_Method__c, Processing_Date__c
                                                 FROM Payment_Line_Item__c  WHERE Payment_Line_Item__c = :input.paymentId AND Payment__r.Channel_Partner__c = :cp.Id   LIMIT 1];
            if (lstpli.isEmpty()) {
                //sendError('Payment Line Item not found', log);

                ErrorResponseUitilityClass.sendErrorResponse('Payment Line Item not found','PaymentDetailAPI',requestBody);
                return;
            }
            // ================= FILE URL LOGIC (SAME AS PROJECT API) =================
            Payment_Line_Item__c pli = lstpli[0];
            String invoiceUrl = '';
            String contractUrl = '';
            if(pli.Id != null){
                System.debug('Inside the pli');
                
                List<ContentDocumentLink> links = [SELECT ContentDocumentId   FROM ContentDocumentLink   WHERE LinkedEntityId = :pli.Id];
                
                Set<Id> docIds = new Set<Id>();
                for (ContentDocumentLink cdl : links) {
                    docIds.add(cdl.ContentDocumentId);
                }
                
                if (!docIds.isEmpty()) {
                    System.debug('Inside the doc');
                    List<ContentVersion> versions = [ SELECT Id, Title, FileExtension, ContentDocumentId  FROM ContentVersion WHERE IsLatest = TRUE  AND ContentDocumentId IN :docIds];
                    
                    Map<Id, String> versionTitleMap = new Map<Id, String>();
                    for (ContentVersion cv : versions) {
                        versionTitleMap.put(cv.Id, cv.Title);
                    }
                    
                    List<ContentDistribution> dists = [SELECT ContentVersionId, ContentDownloadUrl,DistributionPublicUrl FROM ContentDistribution   WHERE ContentVersionId IN :versionTitleMap.keySet()];
                    
                    for (ContentDistribution cd : dists) {
                        String title = versionTitleMap.get(cd.ContentVersionId);
                        
                        if (title != null && title.containsIgnoreCase('Invoice')) {
                            invoiceUrl = cd.ContentDownloadUrl;
                        }
                        if (title != null && title.containsIgnoreCase('Contract')) {
                            contractUrl = cd.DistributionPublicUrl;
                        }
                    }
                }
            }
            // ================= BUILD RESPONSE =================
            Decimal bookingAmount  = pli.Booking_Amount__c != null ? pli.Booking_Amount__c : 0;
            Decimal pendingAmount  = pli.Pending_Amount__c != null ? pli.Pending_Amount__c : 0;
            Decimal commissionRate = pli.Comminsion_Rate__c != null ? pli.Comminsion_Rate__c : 0;
            Decimal commissionAmt  = pli.Commission_Amount__c != null ? pli.Commission_Amount__c : 0;
            
            PaymentDetailResponse data = new PaymentDetailResponse();
            
            data.paymentId        = pli.Payment_Line_Item__c;
            data.personName       = pli.Name;
            data.projectName      = pli.Project_name__c;
            data.flatNumber       = pli.Flat_Number__c;
            data.bookingDate      = pli.Booking_Date__c;      // null is OK
            data.paymentStatus    = pli.Payament_Status__c;
            
            data.bookingAmount    = bookingAmount;
            data.commissionRate  = commissionRate;
            data.commissionAmount= commissionAmt;
            
            // ✅ SAFE calculation
            data.processedAmount = bookingAmount - pendingAmount;
            data.pendingAmount   = pendingAmount;
            
            data.transactionNumber = pli.Transcantion_Number__c;
            data.paymentMethod     = pli.Payment_Method__c;
            data.processingDate    = pli.Processing_Date__c;
            
            // ✅ URLs (null-safe by default)
            data.invoiceUrl   = invoiceUrl;
            data.contractFile = contractUrl;
            
            returnSuccess(data, 'Payment data', log);
        } catch (Exception e) {
           // sendError('Failed to fetch payment detail: ' + e.getMessage(), log);

            ErrorResponseUitilityClass.sendErrorResponse('Failed to fetch payment detail: ' + e.getMessage(),'PaymentDetailAPI',requestBody);
        }
        
    }
    
    // ================= REQUEST =================
    public class PaymentDetailRequest {
        public String userId;
        public String paymentId;
    }
    
    // ================= RESPONSE =================
    public class PaymentDetailResponse {
        public String paymentId;
        public String personName;
        public String projectName;
        public String flatNumber;
        public Datetime bookingDate;
        public String paymentStatus;
        public Decimal bookingAmount;
        public Decimal commissionRate;
        public Decimal commissionAmount;
        public Decimal processedAmount;
        public Decimal pendingAmount;
        public String transactionNumber;
        public String paymentMethod;
        public Datetime processingDate;
        public String invoiceUrl;
        public String contractFile;
    }
    
    // ================= SUCCESS =================
    private static void returnSuccess(PaymentDetailResponse data, String message, Apex_Log__c log) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(new SuccessResponseWrapper(true, message, data)));
        
        log.Status__c = 'SUCCESS';
        log.Response__c = JSON.serialize(RestContext.response.responseBody);
        insert log;
    }
    
    // ================= ERROR =================
    /*
    private static void sendError(String msg, Apex_Log__c log) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(new ResponseWrapper(false, msg)));
        
        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        insert log;
    }*/
    
    public class SuccessResponseWrapper {
        public Boolean status;
        public String message;
        public PaymentDetailResponse data;
        
        public SuccessResponseWrapper(Boolean status, String message, PaymentDetailResponse data) {
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
}