/****************************************************************
* Class Name   : InvoiceList_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API fetches Invoice list
* for a Channel Partner with pagination and booking details.
*
* Author       : Sandeep Kumar
******************************************************************/
@RestResource(urlMapping='/InvoiceListAPI/*')
global without sharing class InvoiceList_MobileAPI {

    @HttpPost
    global static void getInvoiceList() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(Request_Type__c = 'InvoiceList_MobileAPI',  Request__c = requestBody);

        try {
            // Deserialize request
            InvoiceListRequestWrapper input =(InvoiceListRequestWrapper) JSON.deserialize(requestBody, InvoiceListRequestWrapper.class);

            if (String.isBlank(input.userId)) {
                //sendError('userId is required', log);
                ErrorResponseUitilityClass.sendErrorResponse('userId is required','InvoiceList_MobileAPI',requestBody);
                return;
            }
            Integer limitSize = 10;

            Integer offsetSize = input.pageSize == null ? 0 : input.pageSize*limitSize;
            

            // Validate Channel Partner
            Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c WHERE Active__c = TRUE AND User_Id__c = :input.userId  LIMIT 1];

            if (cp == null) {
                //sendError('Channel Partner not found', log);
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','InvoiceList_MobileAPI',requestBody);
                return;
            }

            // Fetch Invoice list
            List<Invoice__c> invoiceList = [
                SELECT Id, Name, Agreement_Amount__c, Commission_Amount__c,Cancelled_Booking_Amount__c, Net_Investment_Amount__c,
                       Commsison_Percentage__c, Invoice_Status__c, Project_Name__c, TDS__c, GST__c, CreatedDate FROM Invoice__c
                WHERE Channel_Partner__c = :cp.Id
                AND Name LIKE :('%' + input.search + '%')
                ORDER BY CreatedDate DESC
                LIMIT :limitSize     OFFSET :offsetSize ];

            // Collect Invoice Ids
            Set<Id> invoiceIds = new Set<Id>();
            for (Invoice__c inv : invoiceList) {
                invoiceIds.add(inv.Id);
            }

            // Fetch Booking details (Lookup to Invoice)
            Map<Id, List<BookingDetailWrapper>> bookingMap = new Map<Id, List<BookingDetailWrapper>>();

            if (!invoiceIds.isEmpty()) {
                List<Booking__c> bookingList = [ SELECT Id,Name, Invoice__c, Plot__c,Plot__r.Name, Agreement_Value_Before_GST__c, Booking_Date__c
                    FROM Booking__c WHERE Invoice__c IN :invoiceIds];

                for (Booking__c b : bookingList) {
                    BookingDetailWrapper bd = new BookingDetailWrapper();
                    bd.unit = b.Plot__r.Name;
                    bd.agreementValue = b.Agreement_Value_Before_GST__c;
                    bd.bookingDate = b.Booking_Date__c;
                    bd.bookingId= b.Name;

                    if (!bookingMap.containsKey(b.Invoice__c)) {
                        bookingMap.put(b.Invoice__c, new List<BookingDetailWrapper>());
                    }
                    bookingMap.get(b.Invoice__c).add(bd);
                }
            }

            // Prepare response data
            List<InvoiceListWrapper> dataList = new List<InvoiceListWrapper>();
System.debug(invoiceList.Size());
            for (Invoice__c inv : invoiceList) {
                InvoiceListWrapper w = new InvoiceListWrapper();
                w.id = inv.Name;
                w.invoiceNumber = inv.Name;
                w.agreementAmount = inv.Agreement_Amount__c;
                w.commissionAmount = inv.Commission_Amount__c;
                w.cancelledBookingAmount = inv.Cancelled_Booking_Amount__c;
                w.netInvestAmount = inv.Net_Investment_Amount__c;
                w.commissionPercentage = inv.Commsison_Percentage__c;
                w.invoiceStatusId = inv.Invoice_Status__c;
                w.projectName = inv.Project_Name__c;
                w.TDS = inv.TDS__c;
                w.GST = inv.GST__c;

                w.bookingDetail = bookingMap.containsKey(inv.Id)
                    ? bookingMap.get(inv.Id)
                    : new List<BookingDetailWrapper>();

                dataList.add(w);
            }

            // Success response
            InvoiceListResponseWrapper res =  new InvoiceListResponseWrapper(true, 'invoice data', dataList);

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res) + '=='+invoiceList.Size();
            insert log;

        } catch (Exception e) {
           
            ErrorResponseUitilityClass.sendErrorResponse('Failed to fetch invoice list: ' + e.getMessage(),'InvoiceList_MobileAPI',requestBody);
            
        }
    }

    // ---------- Request Wrapper ----------
    public class InvoiceListRequestWrapper {
        public String userId;
        public String search;
        public Integer pageSize; // OFFSET
    }

    // ---------- Booking Detail Wrapper ----------
    public class BookingDetailWrapper {
        public String unit;
        public String bookingId;
        public Decimal agreementValue;
        public Datetime bookingDate;
    }

    // ---------- Invoice Wrapper ----------
    public class InvoiceListWrapper {
        public String id;
        public String invoiceNumber;
        public Decimal agreementAmount;
        public Decimal commissionAmount;
        public Decimal cancelledBookingAmount;
        public Decimal netInvestAmount;
        public Decimal commissionPercentage;
        public String invoiceStatusId;
        public String projectName;
        public Decimal TDS;
        public Decimal GST;
        public List<BookingDetailWrapper> bookingDetail;
    }

    // ---------- Response Wrapper ----------
    public class InvoiceListResponseWrapper {
        public Boolean status;
        public String message;
        public List<InvoiceListWrapper> data;

        public InvoiceListResponseWrapper(Boolean s, String m, List<InvoiceListWrapper> d) {
            status = s;
            message = m;
            data = d;
        }
    }

    // ---------- Error Helper ----------
    /*
    private static void sendError(String msg, Apex_Log__c log) {

        InvoiceListResponseWrapper res =
            new InvoiceListResponseWrapper(false, msg, null);

        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);
        insert log;
    }*/
}