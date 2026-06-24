/****************************************************************
* Class Name   : AllFollowUP_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* @description :
* This Apex REST API exposes the endpoint `/AllFollowUpAPI/*` and is
* designed for mobile and external applications to retrieve a
* paginated list of Follow-up records associated with a Channel
* Partner’s Leads.
*
* Functional Overview:
* - Accepts a JSON POST request containing:
*     • userId (mandatory)
*     • optional search and filter parameters
* - Validates the user against Channel_Partner__c using User_Id__c
*   and ensures the Channel Partner is active.
* - Fetches all Leads mapped to the Channel Partner.
* - Retrieves Follow_up__c records related to those Leads.
* - Dynamically builds SOQL based on provided filters.
*
* Supported Filters:
* - Follow-up Name search
* - Lead Status
* - Project Name
* - Follow-up Scheduled Date range
* - Follow-up Completed Date range
*
* Data Handling:
* - Supports pagination (15 records per page using LIMIT & OFFSET)
* - Orders records by CreatedDate (descending)
* - Fetches related Lead and Owner data for response enrichment
*
* Response Mapping:
* - Constructs a mobile-friendly response including:
*     • Follow-up Id / Name
*     • Lead Name
*     • Lead Phone Number
*     • Executive Phone Number
*     • Follow-up Status
*     • Follow-up Type
*     • Feedback / Comments
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
* - Cross-object data mapping
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


@RestResource(urlMapping='/AllFollowUpAPI/*')
global without sharing class AllFollowUP_MobileAPI {
    
    @HttpPost
    global static void getAllSiteVisitDetail() {
        
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AllFollowUP_MobileAPI';
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
            
            
            
            Integer pageSize = ld.pageSize;
            
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('userId is required','AllFollowUP_MobileAPI',requestBody);
         
                return;
            }
            
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','AllFollowUP_MobileAPI',requestBody);
                return;
            }
            
            if (!cmList.isEmpty()) {
                
               // List<Lead> cpldlst= [Select id from Lead Where Channel_Partner__c =:cmList[0].Id];
                 List<Related_Source__c> cpldlst=[select id from Related_Source__c where Channel_Partner1__c =:cmList[0].Id and Is_Locked__c = FALSE];
               

                if(cpldlst.isEmpty()){
                    ErrorResponseUitilityClass.sendErrorResponse('No Lead Found for this CP','AllFollowUP_MobileAPI',requestBody);
                    return;
                    
                    
                }
                
                Set<Id> cpldId= new Set<Id>();
                
                for(Related_Source__c ldd : cpldlst){
                    cpldId.add(ldd.Id);
                    
                }
                
                String baseQuery = 'SELECT Id,Name,Comments__c,Subject__c,Status__c,Owner.Phone,SLead__r.Phone__c,SLead__r.Name FROM Follow_up__c' ;
                
                
                List<String> conditions = new List<String>();
                conditions.add('Related_Source__c = :cpldId');
                if (!String.isBlank(search)) {
                    String escapedSearch = String.escapeSingleQuotes(search.trim());
                    
                    conditions.add(
                        '(' +
                        'Name LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Status__c LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Lead_Name__c  LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Subject__c  LIKE \'%' + escapedSearch + '%\' ' +
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
                    conditions.add('Scheduled_Date__c >= :fromScheduleDate');
                }
                if (toScheduleDate != null) {
                    conditions.add('Scheduled_Date__c <= :toScheduleDate');
                }
                
                if (fromCompletedDate != null) {
                    conditions.add('Completed_Date__c >= :fromCompletedDate');
                }
                if (toCompletedDate != null) {
                    conditions.add('Completed_Date__c <= :toCompletedDate');
                }
                
                
                
                if (!conditions.isEmpty()) {
                    baseQuery += ' WHERE ' + String.join(conditions, ' AND ');
                }
                Integer offsetSize = pageSize != null ? pageSize*15 : 0;
                baseQuery += ' ORDER BY CREATEDDATE DESC LIMIT 15 OFFSET ' + offsetSize;
                System.debug(baseQuery);
                List<Follow_up__c> ldlst = Database.query(baseQuery);
                List<LeadData> responseList = new List<LeadData>();
                
                for (Follow_up__c l : ldlst) {
                    LeadData ldResp = new LeadData();
                    
                    ldResp.id = l.Name; // or keep String if preferred
                    ldResp.personName = l.SLead__r.Name;
                    ldResp.personPhoneNumber = l.SLead__r.Phone__c;
                    ldResp.executivePhoneNumber = String.Valueof(l.Owner.Phone );
                    
                    ldResp.followUpStatusId = l.Status__c;
                    ldResp.feedback =l.Comments__c;
                    ldResp.followUpType =l.Subject__c;
                    
                    responseList.add(ldResp);
                }
                LeadResponseWrapper response = new LeadResponseWrapper();
                response.status = true;
                response.message = 'Follow-ups Data';
                response.data = responseList;
                
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody =
                    Blob.valueOf(JSON.serialize(response));
                
                log.Response__c = 'Follow Up fetched successfully';
                log.Status__c = 'SUCCESS';
                insert log;
                return;
            }  
            
            
        }
        catch (Exception e) {
             ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'AllFollowUP_MobileAPI',requestBody);
         
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
        public String executivePhoneNumber;
        public String followUpStatusId;
        public String feedback;
        public String followUpType;
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