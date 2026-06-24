/****************************************************************
* Class Name   : CreateInvoice_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API creates an Invoice request
* for a Channel Partner.
*
* Input JSON:
* {
*   "userId": "9",
*   "invoiceNumber": "FD454",
*   "totalAgreementAmount": 1200000,
*   "commissionAmount": 10000,
*   "netInvoiceAmount": 1100000,
*   "cancelledBookingAmount": 110000,
*   "projectName": "Zuari Garden"
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Your invoice request is sent for approval",
*   "data": {
*       "invoiceId": "a0B5g00000XXXXXXX",
*       "invoiceNumber": "INV-000123"
*   }
* }
*
* Author       : Sandeep Kumar
******************************************************************************************/
@RestResource(urlMapping='/CreateInvoiceAPI/*')
global without sharing class CreateInvoice_MobileAPI {
     @HttpPost
    global static void createOrUpdateInvoice() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(Request_Type__c = 'CreateInvoice_MobileAPI',Request__c = requestBody );

        try {
            CreateInvoiceRequestWrapper input =(CreateInvoiceRequestWrapper) JSON.deserialize(requestBody,CreateInvoiceRequestWrapper.class);

            /* ================= VALIDATION ================= */
            if (String.isBlank(input.userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('userId is required','CreateInvoice_MobileAPI',requestBody);
                return;
            }

            if (input.bookingId == null || input.bookingId.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('bookingId list is required','CreateInvoice_MobileAPI',requestBody);
                return;
            }

            /* ================= CHANNEL PARTNER ================= */
            Channel_Partner__c cp = [ SELECT Id   FROM Channel_Partner__c  WHERE Active__c = TRUE    AND User_Id__c = :input.userId  LIMIT 1];

            /* ================= FETCH BOOKINGS ================= */
            List<Booking__c> bookings = [SELECT Id, Name, Invoice__c,Invoice_Created__c FROM Booking__c  WHERE Name IN :input.bookingId AND Channel_Partner__c = :cp.Id ];

            if (bookings.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('No bookings found for this Channel Partner','CreateInvoice_MobileAPI',requestBody);
                return;
            }

            /* ================= FETCH OR CREATE INVOICE ================= */
            Invoice__c invoice;
            Boolean isUpdate = false;

            if (!String.isBlank(input.invoiceId)) {

                List<Invoice__c> invList = [SELECT Id, Name FROM Invoice__c   WHERE Name = :input.invoiceId  LIMIT 1];

                if (invList.isEmpty()) {
                    ErrorResponseUitilityClass.sendErrorResponse('Invoice not found','CreateInvoice_MobileAPI',requestBody);
                    return;
                }

                invoice = invList[0];
                isUpdate = true;

            } else {
                invoice = new Invoice__c();
                invoice.Invoice_Status__c = 'Pending';
                invoice.Channel_Partner__c = cp.Id;
            }

            /* ================= SET INVOICE FIELDS ================= */
            invoice.Project_Name__c = input.projectName;
            invoice.Agreement_Amount__c = input.agreementAmount;
            invoice.Commission_Amount__c = input.commissionAmount;
            invoice.Cancelled_Booking_Amount__c = input.cancelledBookingCommissionAmount;
            invoice.TDS__c = input.tds;
            invoice.GST__c = input.gst;
            invoice.Net_Invoice_Amount__c = input.netInvoiceAmount;
			 invoice.Invoice_Date__c = Date.ValueOf(input.invoiceDate);

            if (isUpdate) {
                update invoice;
            } else {
                insert invoice;
            }

            /* ================= EXISTING LINE ITEMS ================= */
            Map<Id, Invoice_Line_Item__c> existingLineItemByBooking = new Map<Id, Invoice_Line_Item__c>();

            for (Invoice_Line_Item__c li : [ SELECT Id, Booking__c FROM Invoice_Line_Item__c WHERE Invoice__c = :invoice.Id]) {
                existingLineItemByBooking.put(li.Booking__c, li);
            }

            List<Invoice_Line_Item__c> toInsert = new List<Invoice_Line_Item__c>();
            List<Invoice_Line_Item__c> toUpdate = new List<Invoice_Line_Item__c>();

            /* ================= CREATE / UPDATE LINE ITEMS ================= */
            for (Booking__c bk : bookings) {

                if (existingLineItemByBooking.containsKey(bk.Id)) {

                    Invoice_Line_Item__c li = existingLineItemByBooking.get(bk.Id);

                    li.Invoice_Date__c = input.invoiceDate;
                    toUpdate.add(li);

                } else {
                    Invoice_Line_Item__c li = new Invoice_Line_Item__c();
                    li.Invoice__c = invoice.Id;
                    li.Booking__c = bk.Id;
                    li.Invoice_Date__c = input.invoiceDate;
                    toInsert.add(li);
                }

                bk.Invoice__c = invoice.Id;
                bk.Invoice_Created__c= TRUE;
            }

            if (!toInsert.isEmpty()) insert toInsert;
            if (!toUpdate.isEmpty()) update toUpdate;
            update bookings;
            
			Invoice__c invResult = [SELECT Id, Name FROM Invoice__c WHERE Id = :invoice.Id ];
            
            /* ================= RESPONSE ================= */
            CreateInvoiceResponseWrapper res = new CreateInvoiceResponseWrapper(true,isUpdate ? 'Invoice updated successfully': 'Invoice created successfully',invResult.Id, invResult.Name );

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =  Blob.valueOf(JSON.serialize(res));

            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse('Failed to process invoice: ' + e.getMessage(),'CreateInvoice_MobileAPI',requestBody);
            
        }
    }

    /* ================= REQUEST WRAPPER ================= */
    public class CreateInvoiceRequestWrapper {
        public String userId;
        public String invoiceId;
        public Datetime invoiceDate;
        public String projectName;
        public Decimal agreementAmount;
        public Decimal commissionAmount;
        public Decimal cancelledBookingCommissionAmount;
        public Decimal tds;
        public Decimal gst;
        public Decimal netInvoiceAmount;
        public List<String> bookingId;
        public String uploadDocumentURL;
    }

    /* ================= RESPONSE WRAPPER ================= */
    public class CreateInvoiceResponseWrapper {
        public Boolean status;
        public String message;
        public Id invoiceId;
        public String invoiceNumber;

        public CreateInvoiceResponseWrapper(Boolean s,String m,Id id,String num) {
            status = s;
            message = m;
            invoiceId = id;
            invoiceNumber = num;
        }
    }

    /* ================= ERROR HANDLER ================= */
    /*
    private static void sendError(String msg, Apex_Log__c log) {

        CreateInvoiceResponseWrapper res = new CreateInvoiceResponseWrapper(false, msg, null, null);

        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);
        insert log;
    }*/

    
   /* @HttpPost
    global static void createOrUpdateInvoice() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'CreateInvoice_MobileAPI',
            Request__c = requestBody
        );
        Boolean logInserted = false;
        
        try {
            CreateInvoiceRequestWrapper input =(CreateInvoiceRequestWrapper) JSON.deserialize(requestBody, CreateInvoiceRequestWrapper.class);
            
            /* ============ BASIC VALIDATION ============ 
            if (String.isBlank(input.userId)) {
                sendError('userId is required', log, logInserted);
                return;
            }
            
            if (input.bookingId == null || input.bookingId.isEmpty()) {
                sendError('bookingId list is required', log, logInserted);
                return;
            }
            
            /* ============ CHANNEL PARTNER ============ 
            Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Active__c = TRUE  AND User_Id__c = :input.userId LIMIT 1 ];
            
            /* ============ FETCH OR CREATE INVOICE ============ 
            Invoice__c inv;
            Boolean isUpdate = false;
            if (!String.isBlank(input.invoiceId)) {
                List<Invoice__c> invList = [SELECT Id, Name, Invoice_Status__c FROM Invoice__c WHERE Name = :input.invoiceId LIMIT 1];
                if (!invList.isEmpty()) {
                    inv = invList[0];
                    isUpdate = true;
                    
                }
            }
            
            if (inv == null) {
                inv = new Invoice__c();
                inv.Invoice_Status__c = 'Pending';
            } else {
                system.debug('inv is not null');
            }
            
            /* ============ SET INVOICE FIELDS ============ 
            inv.Channel_Partner__c = cp.Id;
            //inv.Invoice_Date__c = input.invoiceDate;
            inv.Project_Name__c = input.projectName;
            inv.Agreement_Amount__c = input.agreementAmount;
            inv.Commission_Amount__c = input.commissionAmount;
            inv.Cancelled_Booking_Amount__c = input.cancelledBookingCommissionAmount;
            inv.TDS__c = input.tds;
            inv.GST__c = input.gst;
            inv.Net_Invoice_Amount__c = input.netInvoiceAmount;
            
            /* ===== HANDLE ISO DATETIME / DATE STRING ===== 
            if (!String.isBlank(input.invoiceDate)) {
                try {
                    if (input.invoiceDate.contains('T')) {
                        Datetime dt = Datetime.valueOfGmt(
                            input.invoiceDate
                            .replace('T', ' ')
                            .replace('Z', '')
                        );
                        inv.Invoice_Date__c = dt.date();
                    } else {
                        inv.Invoice_Date__c = Date.valueOf(input.invoiceDate);
                    }
                } catch (Exception e) {
                    sendError('Invalid invoiceDate format', log, logInserted);
                    return;
                }
            }
            /* ============ INSERT / UPDATE INVOICE ============ 
            if (isUpdate) {
                update inv;
                
            } else {
                insert inv;
             }
            
            /* ============ FETCH BOOKINGS ============ 
            List<Booking__c> bookingList = [SELECT Id, Name, Invoice__c FROM Booking__c WHERE Name IN :input.bookingId];
            
            
            
            if (bookingList.isEmpty()) {
                
                sendError('No valid bookings found', log, logInserted);
                return;
            }
            
            /* ============ MAP BOOKINGS TO INVOICE ============ 
            for (Booking__c b : bookingList) {
                
                b.Invoice__c = inv.Id;
            }
            
            update bookingList;
            
            
            /* ============ SUCCESS RESPONSE ============ 
            Invoice__c invResult = [SELECT Id, Name FROM Invoice__c WHERE Id = :inv.Id ];
            
            
            
            CreateInvoiceResponseWrapper res = new CreateInvoiceResponseWrapper(true, isUpdate ? 'Invoice updated successfully' : 'Invoice created successfully',invResult.Id,invResult.Name );
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =
                Blob.valueOf(JSON.serialize(res));
            
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;
            
            
            
        } catch (DmlException e) {
            
            sendError(
                'DML Error: ' + e.getMessage() +
                ' Fields: ' + String.join(e.getDmlFields(0), ','),
                log,
                logInserted
            );
        } catch (Exception e) {
            
            sendError('Failed to process invoice: ' + e.getMessage(), log, logInserted);
        }
        
        
    }
    
    /* ================= REQUEST WRAPPER ================= 
    public class CreateInvoiceRequestWrapper {
        public String userId;
        public String invoiceId;
        public String invoiceDate;
        public String projectName;
        public Decimal agreementAmount;
        public Decimal commissionAmount;
        public Decimal cancelledBookingCommissionAmount;
        public Decimal tds;
        public Decimal gst;
        public Decimal netInvoiceAmount;
        public List<String> bookingId;
        public String uploadDocumentURL;
    }
    */
    /* ================= RESPONSE WRAPPER ================= 
    public class CreateInvoiceResponseWrapper {
        public Boolean status;
        public String message;
        public Id invoiceId;
        public String invoiceNumber;
        
        public CreateInvoiceResponseWrapper(Boolean s,String m,Id id, String num) {
            status = s;
            message = m;
            invoiceId = id;
            invoiceNumber = num;
        }
    }
    
    /* ================= ERROR HANDLER ================= 
    private static void sendError(String msg,Apex_Log__c log,  Boolean logInserted ) {
        
        
        CreateInvoiceResponseWrapper res =
            new CreateInvoiceResponseWrapper(false, msg, null, null);
        
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
    
    
}