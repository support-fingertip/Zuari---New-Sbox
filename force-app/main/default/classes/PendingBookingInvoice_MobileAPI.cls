/****************************************************************
* Class Name   : PendingBookingInvoice_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API fetches Pending Booking Invoices
* for a Channel Partner with optional date & project filters.
*
******************************************************************/
@RestResource(urlMapping='/PendingBookingInvoiceAPI/*')
global without sharing class PendingBookingInvoice_MobileAPI {
    
    @HttpPost
    global static void getPendingBookingInvoices() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'PendingBookingInvoice_MobileAPI',
            Request__c = requestBody
        );
         try {
            /* -------------------------------
               Deserialize Request
             ------------------------------- */
            PendingBookingRequest input =  (PendingBookingRequest) JSON.deserialize(requestBody, PendingBookingRequest.class);
            
            if (String.isBlank(input.userId)) {
               // sendError('userId is required', log);
                ErrorResponseUitilityClass.sendErrorResponse('userId is required','PendingBookingInvoice_MobileAPI',requestBody);
                return;
            }
            
            /* -------------------------------
                 Validate Channel Partner
             ------------------------------- */
            Channel_Partner__c cp = [ SELECT Id  FROM Channel_Partner__c WHERE User_Id__c = :input.userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cp == null) {
               // sendError('Channel Partner not found', log);
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','PendingBookingInvoice_MobileAPI',requestBody);
                return;
            }
            
            Id cpId = cp.Id;
            List<Booking__c> bookingList = new List<Booking__c>();
 			 
            /* -------------------------------
               Build Dynamic SOQL
            ------------------------------- */
              Integer offsetSize = input.pageSize != null ? input.pageSize*15 : 0;
              
            String baseQuery =
                'SELECT Id,Name, Booking_Date__c, Agreement_Value_Before_GST__c, ' +
                'Plot__r.Name, Project__c, Invoice__r.Name ' +
                'FROM Booking__c';
            
            List<String> conditions = new List<String>();
           // conditions.add('Invoice_Created__c = FALSE');
            conditions.add('sale_agreement_completed__c = TRUE');
                
            /* Mandatory conditions */
            conditions.add(
                'Channel_Partner__c = \'' +
                String.escapeSingleQuotes(cpId) + '\''
            );
            
            /* Optional project filter */
           
            if (!String.isBlank(input.projectId)) {
                
          
             List<Project__c> project = [ SELECT Id,Project_Id__c,Project__c FROM Project__c WHERE Project__c = :input.projectId LIMIT 1  ];
            String prj = project[0].Project__c;
    conditions.add('Project__c = \'' + String.escapeSingleQuotes(prj) + '\'');
}
            /* Optional booking date filter */
           if (input.bookingDate != null) {
    Date d = Date.ValueOf(input.bookingDate);
    DateTime startDt = DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0));
    DateTime endDt   = startDt.addDays(1);

    conditions.add(
        'Booking_Date__c >= ' + startDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
    );
    conditions.add(
        'Booking_Date__c < ' + endDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
    );
}

if (!String.isBlank(input.invoiceNumber)) {
    conditions.add(
        'Invoice__r.Name = \'' +
        String.escapeSingleQuotes(input.invoiceNumber) + '\''
    );
}
            
            /* Combine query */
            String soql = baseQuery;
           
            if (!conditions.isEmpty()) {
                soql += ' WHERE ' + String.join(conditions, ' AND ');
            }
            
            soql += ' ORDER BY Booking_Date__c DESC LIMIT 15 OFFSET '  + offsetSize;
            
            System.debug('Final SOQL => ' + soql);
                 
                
             bookingList = Database.query(soql);
            
            
            /* Execute */
            
            /* -------------------------------
                  Prepare Response Data
             ------------------------------- */
            List<PendingBookingWrapper> dataList = new List<PendingBookingWrapper>();
            
            for (Booking__c b : bookingList) {
                PendingBookingWrapper w = new PendingBookingWrapper();
                w.id = b.Name;
                w.agreementAmount = b.Agreement_Value_Before_GST__c;
                w.projectName = b.Project__c;
                w.unitNumber = b.Plot__r.Name;
                w.bookingDate = b.Booking_Date__c;
                
                dataList.add(w);
            }
            
            PendingBookingResponse res =  new PendingBookingResponse(true, 'invoice data', dataList);
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
            
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            } catch (Exception e) {
            
            ErrorResponseUitilityClass.sendErrorResponse('Failed to fetch pending booking invoices: ' + e.getMessage(),'PendingBookingInvoice_MobileAPI',requestBody);
        }
        
    }
    
    /* ===============================
      REQUEST WRAPPER
     =============================== */
    public class PendingBookingRequest {
        public String userId;
        public Datetime bookingDate; // Optional
        public String projectId;   
        public Integer pageSize;// Optional
        public String invoiceNumber;// Optional
    }
    
    /* ===============================
      RESPONSE DATA WRAPPER
    =============================== */
    public class PendingBookingWrapper {
        public String id;
        public Decimal agreementAmount;
        public String projectName;
        public String unitNumber;
        public Datetime bookingDate;
    }
    
    /* ===============================
        RESPONSE WRAPPER
    =============================== */
    public class PendingBookingResponse {
        public Boolean status;
        public String message;
        public List<PendingBookingWrapper> data;
        
        public PendingBookingResponse(Boolean s, String m, List<PendingBookingWrapper> d) {
            status = s;
            message = m;
            data = d;
        }
    }
    
    /* ===============================
       ERROR HANDLER
     =============================== */
     /*
    private static void sendError(String msg, Apex_Log__c log) {
        
        PendingBookingResponse res =
            new PendingBookingResponse(false, msg, null);
        
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
        
        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);
        insert log;
    }*/
}