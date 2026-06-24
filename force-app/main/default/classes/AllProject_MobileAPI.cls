/****************************************************************
* Class Name   : AllProject_MobileAPI
* Company      : Fingertipplus
* Created Date : 27-05-2025
*
* @description :
* This Apex REST API exposes the endpoint `/AllProjectAPI/*` and is
* designed for consumption by mobile and external applications.
* It returns a paginated list of all active projects along with
* relevant project metadata and image URLs.
*
* Functional Overview:
* - Accepts a JSON POST request with userId and optional filter parameters.
* - Validates the user against Channel_Partner__c using User_Id__c
*   and ensures the user is active.
* - Dynamically builds SOQL based on provided filters:
*     • Search by project name
*     • City filter
*     • Facing filter (multi-picklist)
*     • Unit Type filter (multi-picklist)
* - Fetches active Project__c records with pagination
*   (15 records per page using OFFSET).
* - Retrieves one project image per project using:
*     • ContentDocumentLink
*     • ContentVersion (filtered by "Project Images")
*     • ContentDistribution for public image URLs
* - Constructs a structured response including:
*     • Project Id
*     • Project Name
*     • Project Status
*     • City
*     • Unit Type
*     • Facing
*     • Available Units
*     • Total Units
*     • Starting Price Range
*     • Ending Price Range
*     • Project Image URL
* - Logs request, response, and errors in Apex_Log__c.
* - Returns consistent JSON responses for both success and error cases.
*
* Key Features:
* - Dynamic SOQL with safe escaping
* - Pagination support for mobile performance
* - One-image-per-project optimization
* - Centralized error handling
* - Detailed API logging
*
* Author       : Praveen Kumar
*
* Change Log:
* --------------------------------------------------------------------------
* Ver | Author         | Date       | Description
* --------------------------------------------------------------------------
* 1.0 | Praveen Kumar  | 27-12-2025 | Initial implementation
* --------------------------------------------------------------------------
**************************************************************/


@RestResource(urlMapping='/AllProjectAPI/*')
global without sharing class AllProject_MobileAPI {
    @HttpPost
    global static void getAllprojectDetail() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AllProject_MobileAPI';
        log.Request__c = requestBody;
        try {
            AllProjectWrapper proj = (AllProjectWrapper) JSON.deserialize(requestBody, AllProjectWrapper.class);
            String userId = proj.userId;
            String search = proj.search;
            String projectStatusId = proj.projectStatusId;
            String facingId = proj.facingId;
            String cityId = proj.cityId;
            String unitTypeId = proj.unitTypeId;
            Integer pageSize = proj.pageSize;
            
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please Send correct userId','AllProject_MobileAPI',requestBody);
                return;
            }
            
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','AllProject_MobileAPI',requestBody);
                return;
            }
            if (!cmList.isEmpty() ) {
                String baseQuery = 'SELECT Id, Name,Project_Id__c,City1__c,Project_Status__c,Unit_Type__c,Facing__c,Starting_Price__c,End_Price_Range__c,Available_Units__c,Total_Units__c FROM Project__c';
                
                List<String> conditions = new List<String>();
                conditions.add('Active__c = TRUE');
                
                if (!String.isBlank(search)) {
                    String escapedSearch = String.escapeSingleQuotes(search.trim());
                    
                    conditions.add(
                        '(Name LIKE \'%' + escapedSearch + '%\' ' +
                        'OR Project_Id__c LIKE \'%' + escapedSearch + '%\' '+
                        'OR Project__c LIKE \'%' + escapedSearch + '%\')'
                    );
                }
                if (!String.isBlank(cityId)) {
                    conditions.add('City1__c = \'' + String.escapeSingleQuotes(cityId.trim()) + '\'');
                }
                if (!String.isBlank(projectStatusId)) {
                    conditions.add('Project_Status__c = \'' + String.escapeSingleQuotes(projectStatusId.trim()) + '\'');
                }
                
                if (!String.isBlank(facingId)) {
                    conditions.add('Facing__c INCLUDES (\'' + String.escapeSingleQuotes(facingId.trim()) + '\')');
                }
                if (!String.isBlank(unitTypeId)) {
                    conditions.add('Unit_Type__c INCLUDES (\'' + String.escapeSingleQuotes(unitTypeId.trim()) + '\')');
                }
                
                if (!conditions.isEmpty()) {
                    baseQuery += ' WHERE ' + String.join(conditions, ' AND ');
                }
                 Integer offsetSize = pageSize != null ? pageSize*15 : 0;
               
                baseQuery += ' ORDER BY CREATEDDATE DESC LIMIT 15 OFFSET ' + offsetSize;
                System.debug(baseQuery);
                List<Project__c> projectList = Database.query(baseQuery);
                
                Set<Id> projectIds = new Set<Id>();
                
                For(Project__c  pr : projectList){
                    projectIds.add(pr.Id);
                }
                Map<Id, String> projectToImageUrl = new Map<Id, String>();
                if (!projectIds.isEmpty()) {
                    
                    List<ContentDocumentLink> docLinks = [ SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :projectIds ];
                    
                    Set<Id> contentDocIds = new Set<Id>();
                    for (ContentDocumentLink link : docLinks) {
                        contentDocIds.add(link.ContentDocumentId);
                    }
                    
                    Map<Id, String> docIdToTitle = new Map<Id, String>();
                    for (ContentVersion cv : [ SELECT ContentDocumentId, Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds AND Title LIKE '%Project Images%']) {
                        docIdToTitle.put(cv.ContentDocumentId, cv.Title);
                    }
                    
                    Map<Id, String> docToDistUrl = new Map<Id, String>();
                    for (ContentDistribution dist : [ SELECT ContentDocumentId, ContentDownloadUrl  FROM ContentDistribution  WHERE ContentDocumentId IN :docIdToTitle.keySet() ]) {
                        String picUrl = dist.ContentDownloadUrl
                            .replace('download/?', 'renditionDownload?rendition=ORIGINAL_Jpg&')
                            .replace('&ids', '&versionId');
                        
                        docToDistUrl.put(dist.ContentDocumentId, picUrl);
                    }
                    
                    // ✅ Project → Image URL (ONE image per project)
                    for (ContentDocumentLink link : docLinks) {
                        if (!projectToImageUrl.containsKey(link.LinkedEntityId)
                            && docToDistUrl.containsKey(link.ContentDocumentId)) {
                                
                                projectToImageUrl.put(
                                    link.LinkedEntityId,
                                    docToDistUrl.get(link.ContentDocumentId)
                                );
                            }
                    }
                }
                
                List<ProjectData> responseList = new List<ProjectData>();
                
                for (Project__c p : projectList) {
                    ProjectData pd = new ProjectData();
                    
                    pd.id = p.Project_Id__c != null
                        ? p.Project_Id__c
                        : null;
                    
                    pd.projectImageUrl = projectToImageUrl.containsKey(p.Id)
                        ? projectToImageUrl.get(p.Id)
                        : null;
                    
                    pd.projectName = p.Name;
                    
                    pd.projectStatusId = p.Project_Status__c != null
                        ? p.Project_Status__c
                        : null;
                    
                    pd.city = p.City1__c;
                    pd.unitType = p.Unit_Type__c;
                    pd.facing = p.Facing__c;
                    
                    pd.availableUnits = String.Valueof(p.Available_Units__c);
                    pd.totalUnits = String.valueOf(p.Total_Units__c);
                    
                    pd.startPriceRange = p.Starting_Price__c;
                    pd.endPriceRange = p.End_Price_Range__c;
                    
                    responseList.add(pd);
                }
                ProjectResponseWrapper response = new ProjectResponseWrapper();
                response.status = true;
                response.message = 'projects data';
                response.data = responseList;
                
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody =
                    Blob.valueOf(JSON.serialize(response));
                
                log.Response__c = 'All Project fetched successfully '+JSON.serialize(response);
                log.Status__c = 'SUCCESS';
                insert log;
                
                
            }
        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse('Error: ' + e.getMessage(),'AllProject_MobileAPI',requestBody);
            
        }
        
    }
    public class AllProjectWrapper {
        public String userId;
        public String search;
        public String projectStatusId;
        public String facingId;
        public String cityId;
        public String unitTypeId;
        public Integer pageSize;
    }
    public class ProjectResponseWrapper {
        public Boolean status;
        public String message;
        public List<ProjectData> data;
    }
    
    public class ProjectData {
        public String id;
        public String projectImageUrl;
        public String projectName;
        public String projectStatusId;
        public String city;
        public String unitType;
        public String facing;
        public String availableUnits;
        public String totalUnits;
        public String startPriceRange;
        public String endPriceRange;
    }
    
    /*
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'status' => false,
                'message' => message
                }));
    }*/
}