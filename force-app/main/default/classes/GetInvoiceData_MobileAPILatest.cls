@RestResource(urlMapping='/GetInvoiceDataAPIlatest/*')
global without sharing class GetInvoiceData_MobileAPILatest {
    
    
    @HttpPost
    global static void getInvoiceData() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody == null ? null : req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'GetInvoiceData_MobileAPI',
            Request__c = requestBody
        );
        
        try {
            // ================= Deserialize Input =================
            GetInvoiceRequestWrapper input =
                (GetInvoiceRequestWrapper) JSON.deserialize(requestBody, GetInvoiceRequestWrapper.class);
            
            if (input == null || String.isBlank(input.userId)
                || input.bookingId == null || input.bookingId.isEmpty()) {
                    sendError('userId and bookingId are required', log);
                    return;
                }
            
            // ================= Validate Channel Partner =================
            List<Channel_Partner__c> cpList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :input.userId  AND Active__c = TRUE LIMIT 1];
            
            if (cpList.isEmpty()) {
                sendError('Channel Partner not found', log);
                return;
            }
            
            Id cpId = cpList[0].Id;
            System.debug(cpId);
            // ================= Fetch Bookings =================
            List<Booking__c> bookings = [ SELECT Id, Name, Invoice__c, CreatedDate,PLot__r.Name
                                         FROM Booking__c  WHERE Channel_Partner__c = :cpId AND Name IN :input.bookingId
                                         AND Invoice__c != NULL  ORDER BY CreatedDate DESC];
            System.debug(input.bookingId + '---- ' + bookings);
            if (bookings.isEmpty()) {
                sendError('No bookings found', log);
                return;
            }
            
            // ================= Ensure SINGLE Invoice =================
            Id invoiceId = bookings[0].Invoice__c;
            System.debug(invoiceId);
            for (Booking__c bk : bookings) {
                if (bk.Invoice__c != invoiceId) {
                    sendError('Multiple invoices found for given bookings', log);
                    return;
                }
            }
            
            // ================= Fetch Invoice =================
            Invoice__c inv = [ SELECT Id,Project_Name1__c,
                              Agreement_Amount__c, Commission_Amount__c,
                              Cancelled_Booking_Amount__c,TDS__c, GST__c,
                              Net_Invoice_Amount__c  FROM Invoice__c  WHERE Id = :invoiceId LIMIT 1 ];
            System.debug(inv);
            // ================= Build Single Response Object =================
            InvoiceGroupData grp = new InvoiceGroupData();
            grp.projectName = inv.Project_Name1__c;
            grp.agreementAmount = inv.Agreement_Amount__c;
            grp.commissionAmount = inv.Commission_Amount__c;
            grp.cancelledBookingCommissionAmount = inv.Cancelled_Booking_Amount__c;
            grp.tds = inv.TDS__c;
            grp.gst = inv.GST__c;
            grp.netInvoiceAmount = inv.Net_Invoice_Amount__c;
            grp.bookingDetails = new List<BookingDetail>();
            grp.bookingId = new List<String>();
            
            // ================= Add MULTIPLE Booking Details =================
            for (Booking__c bk : bookings) {
                
                BookingDetail bd = new BookingDetail();
                bd.unit = bk.Plot__r.Name;
                bd.agreementAmount = inv.Agreement_Amount__c;
                bd.bookingDate = bk.CreatedDate;
                
                grp.bookingDetails.add(bd);
                grp.bookingId.add(bk.Name);
            }
            
            // ================= Final Response =================
            List<InvoiceGroupData> dataList = new List<InvoiceGroupData>();
            dataList.add(grp); // ✅ ONLY ONE OBJECT
            
            InvoiceResponseWrapper res = new InvoiceResponseWrapper(
                true,
                'Announcement data',
                dataList
            );
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
            
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            
        } catch (Exception e) {
            sendError('Failed to fetch invoice data: ' + e.getMessage(), log);
        }
    }
    
    
    // ================= Input Wrapper =================
    public class GetInvoiceRequestWrapper {
        public String userId;
        public List<String> bookingId;
    }
    
    // ================= Response Wrappers =================
    public class BookingDetail {
        public String unit;
        public Decimal agreementAmount;
        public Datetime bookingDate;
    }
    
    public class InvoiceGroupData {
        public String projectName;
        public Decimal agreementAmount;
        public Decimal commissionAmount;
        public Decimal cancelledBookingCommissionAmount;
        public Decimal tds;
        public Decimal gst;
        public Decimal netInvoiceAmount;
        public List<BookingDetail> bookingDetails;
        public List<String> bookingId;
    }
    
    public class InvoiceResponseWrapper {
        public Boolean status;
        public String message;
        public List<InvoiceGroupData> data;
        
        public InvoiceResponseWrapper(Boolean s, String m, List<InvoiceGroupData> d) {
            status = s;
            message = m;
            data = d;
        }
    }
    
    // ================= Error Helper =================
    private static void sendError(String msg, Apex_Log__c log) {
        
        InvoiceResponseWrapper res =
            new InvoiceResponseWrapper(false, msg, null);
        
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
        
        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);
        insert log;
    }
}