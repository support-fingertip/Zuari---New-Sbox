/****************************************************************
* Class Name   : AllLead_MobileAPI
* Company      : Fingertipplus
* Created Date : 17-12-2025
*
* @description :
* This Apex REST API exposes the endpoint `/AllLeadAPI/*` and is
* designed for mobile and external applications to fetch a
* paginated list of Leads associated with a Channel Partner.
*
* Functional Overview:
* - Accepts a JSON POST request containing:
*     • userId (mandatory)
*     • search and multiple optional filter parameters
* - Validates the user against Channel_Partner__c using User_Id__c
*   and ensures the Channel Partner is active.
* - Dynamically builds SOQL to fetch Lead records belonging to the
*   validated Channel Partner.
*
* Supported Filters:
* - Lead Name search
* - Lead Status
* - Allocated Project
* - Rejection Reason
* - Created Date range
* - Booking Date range
* - Site Visit Date range
* - Rejection Date range
*
* Data Handling:
* - Supports pagination (15 records per page using LIMIT & OFFSET)
* - Orders records by CreatedDate (descending)
* - Maps Lead fields into a mobile-friendly response structure:
*     • Lead Id
*     • Lead Name
*     • Phone Number
*     • Project Name
*     • Assigned Owner Name
*     • First Site Visit Date/Time
*     • Last Site Visit Date/Time
*     • Lead Status
*
* Response & Logging:
* - Returns structured JSON responses for both success and failure
* - Logs request, response, and error details in Apex_Log__c
* - Centralized error handling for API consistency
*
* Key Features:
* - Dynamic SOQL with safe escaping
* - Multiple date-range filters
* - Channel Partner–based data security
* - Pagination for mobile performance
* - Detailed API logging
*
* Author       : Praveen Kumar
*
* Change Log:
* --------------------------------------------------------------------------
* Ver | Author         | Date       | Description
* --------------------------------------------------------------------------
* 1.0 | Praveen Kumar  | 17-12-2025 | Initial implementation
* --------------------------------------------------------------------------
**************************************************************/


@RestResource(urlMapping='/AllLeadAPI/*')
global without sharing class AllLead_MobileAPI {
    
    @HttpPost
    global static void getAllLeadDetail() {
        
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AllLead_MobileAPI';
        log.Request__c = requestBody;
        try{
            AllLeadWrapper ld = (AllLeadWrapper) JSON.deserialize(requestBody, AllLeadWrapper.class);
            
            String userId = ld.userId;
            String search = ld.search;
            String leadStatus = ld.leadStatus;
            String projectName = ld.projectName;
            String rejectedReason = ld.rejectedReason;
            
            DateTime toCreatedDate = ld.toCreatedDate;
            DateTime fromCreatedDate = ld.fromCreatedDate;
            DateTime toBookingDate = ld.toBookingDate;
            DateTime fromBookingDate = ld.fromBookingDate;
            DateTime toSVDate = ld.toSVDate;
            DateTime fromSVDate = ld.fromSVDate;
            DateTime fromRejectionDate = ld.fromRejectionDate;
            DateTime toRejectionDate = ld.toRejectionDate;
            
            Date fromrejectDate = Date.Valueof(fromRejectionDate);
            Date torejectDate = Date.Valueof(toRejectionDate);
            
            System.debug(fromrejectDate);
            
            Integer pageSize = ld.pageSize;
            
            if (String.isBlank(userId)) {
                //sendErrorResponse('Please Send correct userId');
                  ErrorResponseUitilityClass.sendErrorResponse('userId is required','AllLead_MobileAPI',requestBody);
              
                return;
            }
            
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                //sendErrorResponse('User Not Found in System');
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','AllLead_MobileAPI',requestBody);
              
                return;
            }
            
            if (!cmList.isEmpty()) {
              //  String baseQuery = 'SELECT Id,Lead_ID__c, LastName,Name, Phone__c, Allocated_Project__c, OwnerId,Owner.Name,Lead_Status__c,First_Site_Visit_Date_Time__c,Last_Site_Visit_Date_Time__c,Rejection_Date__c FROM Lead' ;
                String rsbaseQuery = 'SELECT Id,Name, Name__c, Primary_Phone__c, Allocated_Project__c,Lead_Id__c,Lead_status1__c, OwnerId,Owner.Name,First_Site_Visit_Date_Time__c,Last_Site_Visit_Date_Time__c,Rejection_Date__c FROM Related_Source__c' ;
                
                
                String cpId = cmList[0].Id; 
                System.debug(cpId);
                List<String> conditions = new List<String>();
                
               conditions.add('Channel_Partner1__c = :cpId');
                conditions.add('Is_Locked__c = FALSE');
                
                if (!String.isBlank(search)) {
    String escapedSearch = String.escapeSingleQuotes(search.trim());

    conditions.add(
        '(' +
        'Name__c LIKE \'%' + escapedSearch + '%\' ' +
        'OR Lead_Id__c LIKE \'%' + escapedSearch + '%\' ' +
        'OR Lead_status1__c LIKE \'%' + escapedSearch + '%\' ' +
        'OR Primary_Phone__c LIKE \'%' + escapedSearch + '%\' ' +
        'OR Allocated_Project__c LIKE \'%' + escapedSearch + '%\'' +
        ')'
    );
}

                if (!String.isBlank(leadStatus)) {
                    conditions.add(
                        'Lead_status1__c = \'' + String.escapeSingleQuotes(leadStatus) + '\''
                    );
                }
                
                // 🏗 Project Name
                if (!String.isBlank(projectName)) {
                    conditions.add(
                        'Allocated_Project__c = \'' + String.escapeSingleQuotes(projectName) + '\''
                    );
                }
                
                // ❌ Rejected Reason
                if (!String.isBlank(rejectedReason)) {
                    conditions.add(
                        'Reason_For_Rejection__c = \'' + String.escapeSingleQuotes(rejectedReason) + '\''
                    );
                }
                if (fromCreatedDate != null) {
                    conditions.add('CreatedDate >= :fromCreatedDate');
                }
                if (toCreatedDate != null) {
                    conditions.add('CreatedDate <= :toCreatedDate');
                }
                
                // 📘 Booking Date Range
                if (fromBookingDate != null) {
                    conditions.add('Booking_Date__c >= :fromBookingDate');
                }
                if (toBookingDate != null) {
                    conditions.add('Booking_Date__c <= :toBookingDate');
                }
                
                // 🏠 Site Visit Date Range
                if (fromSVDate != null) {
                    conditions.add('Last_Site_Visit_Date_Time__c >= :fromSVDate');
                }
                if (toSVDate != null) {
                    conditions.add('Last_Site_Visit_Date_Time__c <= :toSVDate');
                }
                // ❌ Rejection Date Range (Date field)
                if (fromrejectDate != null) {
                    conditions.add('Rejection_Date__c >= :fromrejectDate');
                }
                if (torejectDate != null) {
                    conditions.add('Rejection_Date__c <= :torejectDate');
                }
                
                if (!conditions.isEmpty()) {
                    rsbaseQuery += ' WHERE ' + String.join(conditions, ' AND ');
                }
                Integer offsetSize = pageSize != null ? pageSize*15 : 0;
                rsbaseQuery += ' ORDER BY CREATEDDATE DESC LIMIT 15 OFFSET ' + offsetSize;
                System.debug(rsbaseQuery);
               // List<Lead> ldlst = Database.query(baseQuery);
                List<Related_Source__c> Relatedlst = Database.query(rsbaseQuery);
                List<LeadData> responseList = new List<LeadData>();
                System.debug(Relatedlst.size());
             /*   for (Lead l : ldlst) {
                    LeadData ldResp = new LeadData();
                    
                    ldResp.id = l.Lead_ID__c; // or keep String if preferred
                    ldResp.personName = l.Name;
                    ldResp.personPhoneNumber = l.Phone__c;
                    ldResp.projectName = l.Allocated_Project__c;
                    ldResp.assignedPersonName = l.Owner != null ? l.Owner.Name : null;
                    
                    ldResp.firstVisit = l.First_Site_Visit_Date_Time__c;
                    ldResp.lastVisit  = l.Last_Site_Visit_Date_Time__c;
                    
                    // Example mapping – adjust if Lead_Status__c is picklist/text
                    ldResp.leadStatusId = l.Lead_Status__c != null
                        ? l.Lead_Status__c
                        : null;
                    
                    responseList.add(ldResp);
                }
                */
                     for (Related_Source__c l : Relatedlst) {
                    LeadData ldResp = new LeadData();
                    
                    ldResp.id = l.Lead_Id__c; // or keep String if preferred
                    ldResp.personName = l.Name__c;
                    ldResp.personPhoneNumber = l.Primary_Phone__c;
                    ldResp.projectName = l.Allocated_Project__c;
                    ldResp.assignedPersonName = l.Owner != null ? l.Owner.Name : null;
                    
                    ldResp.firstVisit = l.First_Site_Visit_Date_Time__c;
                    ldResp.lastVisit  = l.Last_Site_Visit_Date_Time__c;
                    
                    // Example mapping – adjust if Lead_Status__c is picklist/text
                    ldResp.leadStatusId = l.Lead_status1__c != null
                        ? l.Lead_status1__c
                        : null;
                    
                    responseList.add(ldResp);
                }
                
           
                LeadResponseWrapper response = new LeadResponseWrapper();
                response.status = true;
                response.message = 'leads Data';
                response.data = responseList;
                
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody =
                    Blob.valueOf(JSON.serialize(response));
                
                log.Response__c = 'Leads fetched successfully '+ JSON.serialize(response);
                log.Status__c = 'SUCCESS';
                insert log;
                return;
            }  
            
            
        }
        catch (Exception e) {
           // sendErrorResponse('Error: ' + e.getMessage());
             ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'AllLead_MobileAPI',requestBody);
         
              
        }
        
        
    }
    public class AllLeadWrapper {
        public String userId;
        public String search;
        public String leadStatus;
        public String projectName;
        public String rejectedReason;
        public DateTime toCreatedDate;
        public DateTime fromCreatedDate;
        public DateTime toBookingDate;
        public DateTime fromBookingDate;
        public DateTime toSVDate;
        public DateTime fromSVDate;
        public DateTime fromRejectionDate;
        public DateTime toRejectionDate;
        public Integer pageSize;
    }
    public class LeadResponseWrapper {
        public Boolean status;
        public String message;
        public List<LeadData> data;
    }
    
    public class LeadData {
        public String id;
        public String personName;
        public String personPhoneNumber;
        public String projectName;
        public String assignedPersonName;
        public Datetime firstVisit;
        public Datetime lastVisit;
        public String leadStatusId;
    }
    
    /*
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'status' => false,
                'message' => message
                }));
    }
    */
}