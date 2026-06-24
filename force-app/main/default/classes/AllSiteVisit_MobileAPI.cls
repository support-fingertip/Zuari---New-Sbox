/****************************************************************
* Class Name   : AllSiteVisit_MobileAPI
* Company      : Fingertipplus
* Created Date : 20-12-2025
*
* @description :
* This Apex REST API exposes the endpoint `/AllSiteVisitAPI/*` and is
* designed for mobile and external applications to fetch a paginated
* list of Site Visit records associated with a Channel Partner’s Leads.
*
* Functional Overview:
* - Accepts a JSON POST request containing:
*     • userId (mandatory)
*     • optional search and filter parameters
* - Validates the user against Channel_Partner__c using User_Id__c
*   and ensures the Channel Partner is active.
* - Fetches all Leads mapped to the Channel Partner.
* - Retrieves Site_Visit__c records linked to those Leads.
* - Dynamically builds SOQL based on provided filters.
*
* Supported Filters:
* - Site Visit Name search
* - Lead Status
* - Project Name
* - Site Visit Schedule Date range
* - Site Visit Completion Date range
* - Revisit / Reschedule Date range
*
* Data Handling:
* - Supports pagination (15 records per page using LIMIT & OFFSET)
* - Orders records by CreatedDate (descending)
* - Enriches response data using related objects:
*     • Lead (First & Last Site Visit dates)
*     • Project (Project Address)
*     • Call_Comments__c (Additional Notes)
*     • Lead Owner (Relationship Manager)
*
* Response Mapping:
* - Constructs a mobile-friendly response including:
*     • Site Visit Id / Name
*     • Lead Name
*     • Lead Phone Number
*     • Project Name
*     • Project Location
*     • First Site Visit Date/Time
*     • Revisit Date/Time
*     • Site Visit Status
*     • Additional Notes
*     • Relationship Manager Name
*
* Response & Logging:
* - Returns structured JSON responses for success and error scenarios
* - Logs request, response, and error details in Apex_Log__c
* - Centralized error handling for API consistency
*
* Key Features:
* - Channel Partner–based data isolation
* - Dynamic SOQL with safe escaping
* - Multiple date-range filters
* - Pagination optimized for mobile performance
* - Cross-object data enrichment
* - Detailed API logging
*
* Author       : Praveen Kumar
*
* Change Log:
* --------------------------------------------------------------------------
* Ver | Author         | Date       | Description
* --------------------------------------------------------------------------
* 1.0 | Praveen Kumar  | 20-12-2025 | Initial implementation
* --------------------------------------------------------------------------
**************************************************************/


@RestResource(urlMapping='/AllSiteVisitAPI/*')
global without sharing class AllSiteVisit_MobileAPI {
    
    @HttpPost
    global static void getAllSiteVisitDetail() {
        
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AllSiteVisit_MobileAPI';
        log.Request__c = requestBody;
        try{
            AllSiteVisitWrapper ld = (AllSiteVisitWrapper) JSON.deserialize(requestBody, AllSiteVisitWrapper.class);
            
            String userId = ld.userId;
            String search = ld.search;
            String leadStatus = ld.leadStatus;
            String projectName = ld.projectName;
            
            DateTime toScheduleDate = ld.toScheduleDate;
            DateTime fromScheduleDate = ld.fromScheduleDate;
            DateTime toCompletedDate = ld.toCompletedDate;
            DateTime fromCompletedDate = ld.fromCompletedDate;
            DateTime toRevisitDate = ld.toRevisitDate;
            DateTime fromRevisitDate = ld.fromRevisitDate;
            
            System.debug(toCompletedDate +'== '+ fromCompletedDate);
            
            Integer pageSize = ld.pageSize;
            
            if (String.isBlank(userId)) {
                //  sendErrorResponse('Please Send correct userId');
                ErrorResponseUitilityClass.sendErrorResponse('userId is required','AllSiteVisit_MobileAPI',requestBody);
                
                return;
            }
            
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                //sendErrorResponse('User Not Found in System');
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','AllSiteVisit_MobileAPI',requestBody);
                
                return;
            }
            
            if (!cmList.isEmpty()) {
                //  List<Lead> cpldlst= [Select id from Lead Where Channel_Partner__c =:cmList[0].Id];
                List<Related_Source__c> cpldlst=[select id from Related_Source__c where Channel_Partner1__c =:cmList[0].Id and Is_Locked__c = FALSE];
                if(cpldlst.isEmpty()){
                    //  sendErrorResponse('No Lead Found for this CP');
                    ErrorResponseUitilityClass.sendErrorResponse('No Lead Found for this CP','AllSiteVisit_MobileAPI',requestBody);
                    
                    return;
                    
                    
                }
                Set<Id> cpldId= new Set<Id>();
                
                for(Related_Source__c ldd : cpldlst){
                    cpldId.add(ldd.Id);
                    
                }
                System.debug(cpldId);
                String baseQuery = 'SELECT Id,Name,Lead_Name__c,Date__c, Related_Source__r.SLead__c,Lead_Phone_Number__c,SLead__c,Status__c,Related_Source__r.SLead__r.Owner.LastName,Project_Name__c,Related_Source__r.SLead__r.First_Site_Visit_Date_Time__c,Related_Source__r.SLead__r.Last_Site_Visit_Date_Time__c FROM Site_Visit__c' ;
                
                
                List<String> conditions = new List<String>();
                conditions.add('Related_Source__c = :cpldId');
                
                
                if (!String.isBlank(search)) {
                    String escapedSearch = String.escapeSingleQuotes(search.trim());
                    
                    conditions.add(
                        '(' +
                        'Name LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Status__c LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Lead_Name__c LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Project_Name__c LIKE \'%' + escapedSearch + '%\'' +
                        ')'
                    );
                }
                if (!String.isBlank(leadStatus)) {
                    conditions.add(
                        'Status__c = \'' + String.escapeSingleQuotes(leadStatus) + '\''
                    );
                }
                
                if (!String.isBlank(projectName)) {
                    conditions.add(
                        'Project_Name__c = \'' + String.escapeSingleQuotes(projectName) + '\''
                    );
                }
                
                if (fromScheduleDate != null) {
                    conditions.add('Date__c >= :fromScheduleDate');
                }
                if (toScheduleDate != null) {
                    conditions.add('Date__c <= :toScheduleDate');
                }
                
                if (fromCompletedDate != null) {
                    conditions.add('SV_Completed_Date_Time__c >= :fromCompletedDate');
                }
                if (toCompletedDate != null) {
                    conditions.add('SV_Completed_Date_Time__c <= :toCompletedDate');
                }
                
                if (fromRevisitDate != null) {
                    conditions.add('Reschedule_Date__c >= :fromRevisitDate');
                }
                if (toRevisitDate != null) {
                    conditions.add('Reschedule_Date__c <= :toRevisitDate');
                }
                
                
                if (!conditions.isEmpty()) {
                    baseQuery += ' WHERE ' + String.join(conditions, ' AND ');
                }
                Integer offsetSize = pageSize != null ? pageSize*15 : 0;
                baseQuery += ' ORDER BY CREATEDDATE DESC LIMIT 15 OFFSET ' + offsetSize;
                System.debug(baseQuery);
                List<Site_Visit__c> svlst = Database.query(baseQuery);
                System.debug(svlst.size());
                List<LeadData> responseList = new List<LeadData>();
                Set<Id> ldId = new Set<Id>();
                
                For(Site_Visit__c sv : svlst){
                    System.debug(sv.Related_Source__r.SLead__c +'-- '+ sv.Id);
                    ldId.add(sv.Related_Source__r.SLead__c );
                }
                List<Call_Comments__c> listaddnot =[Select id,Lead__c,Comments__c,Related_Source__c from Call_Comments__c where Lead__c IN : ldId];
                Map<Id, String> mpapcomet = new Map<id,String>();
                For(Call_Comments__c cp : listaddnot){
                    mpapcomet.put(cp.Related_Source__c,cp.Comments__c);
                }
                Map<String, String> projectAddress = new Map<String, String>();
                For(Project__c Pc : [Select id,Project_Address__c,Project__c from Project__c]){
                    projectAddress.put(Pc.Project__c,pc.Project_Address__c);
                }
                
                for (Site_Visit__c l : svlst) {
                    LeadData ldResp = new LeadData();
                    System.debug(l.Name);
                    ldResp.id = l.Name; // or keep String if preferred
                    ldResp.personName = l.Lead_Name__c;
                    ldResp.personPhoneNumber = l.Lead_Phone_Number__c;
                    ldResp.projectName = l.Project_Name__c;
                    ldResp.projectLocation= projectAddress.get(l.Project_Name__c);
                    ldResp.firstVisit = l.Date__c;
                    ldResp.reVisit =l.Related_Source__r.SLead__r.Last_Site_Visit_Date_Time__c;
                    ldResp.siteVisitStatusId = l.Status__c;
                    ldResp.additionalNotes = mpapcomet.get(l.Related_Source__c);
                    ldResp.relationShipManager = l.Related_Source__r.SLead__r.Owner.LastName;
                    responseList.add(ldResp);
                }
                LeadResponseWrapper response = new LeadResponseWrapper();
                response.status = true;
                response.message = 'Site Visit Data';
                response.data = responseList;
                
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody =
                    Blob.valueOf(JSON.serialize(response));
                
                log.Response__c = 'Site Visit fetched successfully '+ svlst.Size();
                log.Status__c = 'SUCCESS';
                insert log;
                return;
            }  
            
            
        }
        catch (Exception e) {
            // sendErrorResponse('Error: ' + e.getMessage());
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'AllSiteVisit_MobileAPI',requestBody);
            
        }
        
        
    }
    public class AllSiteVisitWrapper {
        public String userId;
        public String search;
        public String leadStatus;
        public String projectName;
        public DateTime toScheduleDate;
        public DateTime fromScheduleDate;
        public DateTime toCompletedDate;
        public DateTime fromCompletedDate;
        public DateTime toRevisitDate;
        public DateTime fromRevisitDate;
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
        public String projectLocation;
        public Datetime firstVisit;
        public Datetime reVisit;
        public String siteVisitStatusId;
        public String additionalNotes;
        public String relationShipManager;
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