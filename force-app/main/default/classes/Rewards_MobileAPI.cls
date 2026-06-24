/****************************************************************
* Class Name   : Rewards_MobileAPI
* Company      : Fingertipplus
* Created Date : 27-12-2025
*
* @description :
* This Apex REST API exposes the endpoint `/Rewards/*` and is designed
* to provide reward-related information for top-performing Channel
* Partners to mobile and external applications.
*
* The API validates the requesting user and returns a paginated list
* of Channel Partners marked as top performers, including reward
* details, booking counts, descriptions, and profile images.
*
* Functional Overview:
* - Accepts a JSON POST request containing:
*     • userId (mandatory)
*     • pageSize (optional, for pagination)
* - Validates the user against Channel_Partner__c using User_Id__c
*   and ensures the Channel Partner is active.
* - Retrieves Channel Partners where Top_Perfomer__c = true.
* - Sorts results by No_of_Booking__c in descending order.
* - Applies pagination using LIMIT and OFFSET (15 records per page).
*
* Image Handling:
* - Fetches Channel Partner profile images using:
*     • ContentDocumentLink
*     • ContentVersion (filtered by "Profile Photo")
*     • ContentDistribution for public image URLs
* - Ensures one profile image per Channel Partner.
*
* Response Mapping:
* - Returns a mobile-friendly response containing:
*     • Performer Id (User Id)
*     • Performer Name
*     • Profile Image URL
*     • Number of Bookings
*     • Reward Value
*     • Reward Description
*
* Response & Logging:
* - Returns structured JSON success or error responses.
* - Logs request, response, and error details in Apex_Log__c.
*
* Key Features:
* - Channel Partner validation
* - Rewards-focused top performer listing
* - Pagination optimized for mobile performance
* - Public image access via Salesforce Files
* - Consistent API response structure
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

@RestResource(urlMapping='/Rewards/*')
global without sharing class Rewards_MobileAPI {
     @HttpPost
    global static void getTopPerformerDetail() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'Rewards_MobileAPI';
        log.Request__c = requestBody;
        
        try {
            perfomerWrapper proj = (perfomerWrapper) JSON.deserialize(requestBody, perfomerWrapper.class);
            String userId = proj.userId;
            Integer pageSize = proj.pageSize;
            
            List<Channel_Partner__c> cmList = [ SELECT Id,User_Id__c,Name,No_of_Booking__c,Rewards__c FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','Rewards_MobileAPI',requestBody);
                
                return;
            }
            
            if (!cmList.isEmpty() ) {
                Integer LIMIT_SIZE = 15;
                Integer OFFSET_SIZE = (pageSize != null && pageSize >= 0) ? pageSize*LIMIT_SIZE : 0;
                
                List<Channel_Partner__c> toppercplist = [  SELECT Id, Description__c,User_Id__c, Name, No_of_Booking__c, Rewards__c  FROM Channel_Partner__c WHERE Top_Perfomer__c = true  ORDER BY No_of_Booking__c DESC  LIMIT :LIMIT_SIZE OFFSET :OFFSET_SIZE];
                Set<Id> cpIds = new Set<Id>();
                
                For(Channel_Partner__c cp : toppercplist){
                    cpIds.add(cp.Id);
                    
                }
                Map<Id, String> projectToImageUrl = new Map<Id, String>();
                if (!cpIds.isEmpty()) {
                    System.debug(cpIds);
                    List<ContentDocumentLink> docLinks = [ SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :cpIds ];
                    
                    Set<Id> contentDocIds = new Set<Id>();
                    for (ContentDocumentLink link : docLinks) {
                        contentDocIds.add(link.ContentDocumentId);
                    }
                    
                    Map<Id, String> docIdToTitle = new Map<Id, String>();
                    for (ContentVersion cv : [ SELECT ContentDocumentId, Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds AND Title LIKE '%Profile Photo%']) {
                        docIdToTitle.put(cv.ContentDocumentId, cv.Title);
                    }
                    
                    Map<Id, String> docToDistUrl = new Map<Id, String>();
                    for (ContentDistribution dist : [ SELECT ContentDocumentId, ContentDownloadUrl  FROM ContentDistribution  WHERE ContentDocumentId IN :docIdToTitle.keySet() ]) {
                        String picUrl = dist.ContentDownloadUrl
                            .replace('download/?', 'renditionDownload?rendition=ORIGINAL_Jpg&')
                            .replace('&ids', '&versionId');
                        
                        docToDistUrl.put(dist.ContentDocumentId, picUrl);
                    }
                    
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
                System.debug(projectToImageUrl);
                List<perfomerData> responseList = new List<perfomerData>();
                for (Channel_Partner__c p : toppercplist) {
                    System.debug('Jell');
                    perfomerData pd = new perfomerData();
                    pd.personImageURL = projectToImageUrl.containsKey(p.Id)? projectToImageUrl.get(p.Id) : null;
                    pd.Id = p.User_Id__c;
                    pd.personName = p.Name;
                    pd.numberOfBooking = String.ValueOf(p.No_of_Booking__c);
                    pd.reward = String.ValueOf(p.Rewards__c);
                    pd.description=p.Description__c;
                    responseList.add(pd);
                    
                }
                System.debug(toppercplist);
                perfomerResponseWrapper response = new perfomerResponseWrapper();
                response.status = true;
                response.message = 'top Performed data';
                response.data = responseList;
                
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody =     Blob.valueOf(JSON.serialize(response));
                
                
                log.Response__c = 'All Top Performed fetched successfully '+JSON.serialize(response);
                log.Status__c = 'SUCCESS';
                insert log;
                
            }
        } 
        catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse('Error: ' + e.getMessage(),'Rewards_MobileAPI',requestBody);
            
        }
        
        
    }
    public class perfomerWrapper {
        public String userId;
        public Integer pageSize;
    }
    public class perfomerResponseWrapper {
        public Boolean status;
        public String message;
        public List<perfomerData> data;
    }
    
    public class perfomerData {
        public String id;
        public String personImageURL;
        public String projectName;
        public String personName;
        public String numberOfBooking;
        public String reward;
        public String description;
    }
    
    /*
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 400;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'success' => false,
                'message' => message
                }));
    }
   */

}