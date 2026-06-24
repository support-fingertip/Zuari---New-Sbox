/****************************************************************
* Class Name   : GetInvoiceData_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API fetches Invoice details
* for a Channel Partner using bookingId list.
*
* Input JSON:
* {
*   "userId": "9",
*   "bookingId": ["INV2345", "INV2346"]
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Invoice data",
*   "data": [ ... ]
* }
*
* Author       : Sandeep Kumar
******************************************************************************************/
@RestResource(urlMapping='/GetInvoiceDataAPI/*')
global without sharing class GetInvoiceData_MobileAPI {
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
        GetInvoiceRequestWrapper input = (GetInvoiceRequestWrapper) JSON.deserialize(requestBody, GetInvoiceRequestWrapper.class);
        
        if (input == null || String.isBlank(input.userId)
            || input.bookingId == null || input.bookingId.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('userId and bookingId are required','GetInvoiceData_MobileAPI',requestBody);
                return;
            }
        
        // ================= Validate Channel Partner =================
        List<Channel_Partner__c> cpList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :input.userId  AND Active__c = TRUE LIMIT 1];
        
        if (cpList.isEmpty()) {
            ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','GetInvoiceData_MobileAPI',requestBody);
            return;
        }
        
        Id cpId = cpList[0].Id;
        System.debug(cpId);
            Set<Id> bkIds= new Set<Id>();
        String docName,docUrl;
        Date invoicedate ;
        //added recently for testing
        Decimal NetInvoiceAmount=0;
       Decimal CancelledBookingAmount=0;
        //ended here

        if(!String.isBlank(input.invoiceNumber)){
            List<Invoice__c> invList = [SELECT Id, Name,Net_Invoice_Amount__c,Cancelled_Booking_Amount__c,Invoice_Date__c FROM Invoice__c WHERE Name = :input.invoiceNumber AND Channel_Partner__c = :cpId LIMIT 1];
            invoicedate =invList[0].Invoice_Date__c;
            //added newly
            CancelledBookingAmount =invList[0].Cancelled_Booking_Amount__c;
            NetInvoiceAmount = invList[0].Net_Invoice_Amount__c;
                //ended
            System.debug('invList----'+invList);
            List<Booking__c> bklst = [ SELECT Id, Name, Invoice__c FROM Booking__c WHERE Invoice__c IN :invList AND Channel_Partner__c = :cpId  ];
            System.debug('invList----'+bklst.Size());
            For(Booking__c bk : bklst){
                bkIds.add(bk.Id);
            }
            if(!invList.isEmpty()){
                    List<ContentDocumentLink> links = [SELECT ContentDocumentId   FROM ContentDocumentLink   WHERE LinkedEntityId = :invList[0].Id];
            
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
                
                List<ContentDistribution> dists = [SELECT ContentVersionId,ContentVersion.Title, ContentVersion.FileExtension,ContentDownloadUrl,DistributionPublicUrl FROM ContentDistribution   WHERE ContentVersionId IN :versionTitleMap.keySet()  ORDER BY CreatedDate DESC limit 1];
            for(ContentDistribution cd : dists){

                docName = cd.ContentVersion.Title + '.' + cd.ContentVersion.FileExtension;
            docUrl  = cd.ContentDownloadUrl;
                    

            }

        }
    }
}
        // ================= Fetch Bookings =================
        List<Booking__c> bookings = [ SELECT Id, Name, Invoice__c, CreatedDate,PLot__r.Name,Project__c ,Agreement_Value_Before_GST__c  FROM Booking__c  WHERE (ID IN :bkIds) OR (sale_agreement_completed__c = TRUE AND Channel_Partner__c = :cpId AND Name IN :input.bookingId ) ORDER BY CreatedDate DESC];
        
        
        System.debug(input.bookingId + '---- ' + bookings);
        
        if (bookings.isEmpty()) {
            ErrorResponseUitilityClass.sendErrorResponse('No bookings found','GetInvoiceData_MobileAPI',requestBody);
            return;
        }
        
        // ================= Ensure SINGLE Invoice =================
        String ProjectName;
        Decimal bkagreementAmount=0;
        Decimal bkcommissionAmount=0;
        Decimal canbookingam=0;
        Decimal tdsamount =0;
        Decimal gstamount =0;
        
        
        
        for (Booking__c bk : bookings) {
            ProjectName = bk.Project__c;
            bkagreementAmount = bkagreementAmount+ bk.Agreement_Value_Before_GST__c;
            bkIds.add(bk.Id);
            
        }
        System.debug(bkIds.size());
        List<AggregateResult> aggResults = [SELECT  SUM(Commission_Amount__c) cmam,SUM(TDS_Amount__c) tdsam, SUM(GST_Amount__c) gstam FROM Commission_earned__c
                                            WHERE Booking__c IN :bkIds
                                            GROUP BY Booking__c];
        for (AggregateResult ar : aggResults) {
            bkcommissionAmount += (Decimal) ar.get('cmam');
            tdsamount          += (Decimal) ar.get('tdsam');
            gstamount          += (Decimal) ar.get('gstam');
        }
        
        InvoiceGroupData grp = new InvoiceGroupData();
        grp.projectName = ProjectName;
        grp.agreementAmount = bkagreementAmount; // Summation of all Booking's Aggreement Amount
        grp.commissionAmount = bkcommissionAmount;// Commission amount of all Booking's 
        // grp.cancelledBookingCommissionAmount = 0;//
        grp.cancelledBookingCommissionAmount = CancelledBookingAmount!= 0? CancelledBookingAmount:0;//
        grp.tds = tdsamount;
        grp.gst =gstamount;
        grp.invoiceDate =  invoicedate != null ? invoicedate : System.Today();
        grp.invoiceId = '';
        grp.uploadDocumentURL= docUrl;
        grp.documentName = docName;
        grp.netInvoiceAmount =NetInvoiceAmount!=0 ? NetInvoiceAmount :0;
      //   grp.netInvoiceAmount =0;
        grp.bookingDetails = new List<BookingDetail>();
        grp.bookingId = new List<String>();
        
        // ================= Add MULTIPLE Booking Details =================
        for (Booking__c bk : bookings) {
            
            BookingDetail bd = new BookingDetail();
            bd.unit = bk.Plot__r.Name;
            bd.agreementAmount = bk.Agreement_Value_Before_GST__c;
            bd.bookingDate = bk.CreatedDate;
            
            grp.bookingDetails.add(bd);
            grp.bookingId.add(bk.Name);
        }
        
        // ================= Final Response =================
        List<InvoiceGroupData> dataList = new List<InvoiceGroupData>();
        // grp; // ✅ ONLY ONE OBJECT
        
        InvoiceResponseWrapper res = new InvoiceResponseWrapper( true,'Invoice data',grp);
        
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
        
        log.Status__c = 'SUCCESS';
        log.Response__c = JSON.serialize(res);
        insert log;
        } catch (Exception e) {
        
        ErrorResponseUitilityClass.sendErrorResponse('Error: ' + e.getMessage(),'GetInvoiceData_MobileAPI',requestBody);
        
        // sendError('Failed to fetch invoice data: ' + e.getMessage(), log);
    }
    
}


// ================= Input Wrapper =================
public class GetInvoiceRequestWrapper {
    public String userId;
    public List<String> bookingId;
    public String invoiceNumber;
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
    public Date invoiceDate ;
    Public String invoiceId ;
    public String uploadDocumentURL;
    public String documentName;
    public List<BookingDetail> bookingDetails;
    public List<String> bookingId;
}

public class InvoiceResponseWrapper {
    public Boolean status;
    public String message;
    public InvoiceGroupData data;
    
    public InvoiceResponseWrapper(Boolean s, String m, InvoiceGroupData d) {
        status = s;
        message = m;
        data = d;
    }
}

// ================= Error Helper =================


private static void sendErrorResponse(String message) {
    RestContext.response.statusCode = 200;
    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
        'status' => false,
            'message' => message
            }));
}
/*
@HttpPost
global static void getInvoiceData() {

RestRequest req = RestContext.request;
String requestBody = req.requestBody.toString();

Apex_Log__c log = new Apex_Log__c(
Request_Type__c = 'GetInvoiceData_MobileAPI',
Request__c = requestBody
);
Boolean logInserted = false;

try {
GetInvoiceRequestWrapper input = (GetInvoiceRequestWrapper) JSON.deserialize(requestBody, GetInvoiceRequestWrapper.class);

if (String.isBlank(input.userId) || input.bookingId == null || input.bookingId.isEmpty()) {
sendError('userId and bookingId are required', log, logInserted);
return;
}

// Validate Channel Partner
Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c WHERE Active__c = TRUE AND User_Id__c = :input.userId LIMIT 1];

if (cp == null) {
sendError('Channel Partner not found', log, logInserted);
return;
}

// Fetch Invoices (SAMPLE FIELDS)
System.debug(input.bookingId + ' === '+ cp.Id);
List<Booking__c> lstbooking = [Select id,Invoice__c,Name from Booking__c Where Channel_Partner__c = :cp.Id    AND Name IN :input.bookingId];
System.debug(lstbooking);
Set<Id> invoid = new Set<Id>();

for(Booking__c bk :  lstbooking){
invoid.add(bk.Invoice__c);

}
System.debug(invoid);
List<Invoice__c> invoiceList = [SELECT Id, Name, Agreement_Amount__c, Commission_Amount__c, Cancelled_Booking_Amount__c, TDS__c, GST__c, Project_Name__c, Invoice_Status__c,
Commsison_Percentage__c, Net_Investment_Amount__c,Channel_Partner__c, Net_Invoice_Amount__c,CreatedDate
FROM Invoice__c
WHERE Channel_Partner__c = :cp.Id AND ID IN :invoid];

List<InvoiceDataWrapper> dataList = new List<InvoiceDataWrapper>();

for (Invoice__c inv : invoiceList) {
InvoiceDataWrapper d = new InvoiceDataWrapper();
d.bookingId = inv.Name;
d.projectName = inv.Project_Name__c;
d.totalAgreementAmount = inv.Agreement_Amount__c;
d.commissionAmount = inv.Commission_Amount__c;
d.netInvoiceAmount = inv.Net_Invoice_Amount__c;
d.cancelledBookingAmount = inv.Cancelled_Booking_Amount__c;
d.invoiceStatus = inv.Invoice_Status__c;
d.createdDate = inv.CreatedDate;
d.TDS = inv.TDS__c;
d.GST = inv.GST__c;

dataList.add(d);
}

InvoiceResponseWrapper res =  new InvoiceResponseWrapper(true, 'Invoice data', dataList);

RestContext.response.statusCode = 200;
RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

// Log success
log.Status__c = 'SUCCESS';
log.Response__c = JSON.serialize(res);
insert log;
logInserted = true;

} catch (Exception e) {
log.Status__c = 'FAIL';
log.Error_Message__c = e.getMessage();
log.Response__c = e.getStackTraceString();
insert log;
logInserted = true;

sendError('Failed to fetch invoice data: ' + e.getMessage(), log, logInserted);
}
}

// ---------- Input Wrapper ----------
public class GetInvoiceRequestWrapper {
public String userId;
public List<String> bookingId;
}

// ---------- Invoice Data Wrapper ----------
public class InvoiceDataWrapper {
public String bookingId;
public String projectName;
public Decimal totalAgreementAmount;
public Decimal commissionAmount;
public Decimal netInvoiceAmount;
public Decimal cancelledBookingAmount;
public String invoiceStatus;
public Datetime createdDate;
public Decimal GST;
public Decimal TDS;
}

// ---------- Response Wrapper ----------
public class InvoiceResponseWrapper {
public Boolean status;
public String message;
public List<InvoiceDataWrapper> data;

public InvoiceResponseWrapper(Boolean s, String m, List<InvoiceDataWrapper> d) {
status = s;
message = m;
data = d;
}
}

// ---------- Error Helper ----------
private static void sendError(String msg, Apex_Log__c log, Boolean logInserted) {

InvoiceResponseWrapper res =
new InvoiceResponseWrapper(false, msg, null);

RestContext.response.statusCode = 200;
RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

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