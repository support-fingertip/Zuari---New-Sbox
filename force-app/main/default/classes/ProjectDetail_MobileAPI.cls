/****************************************************************
* Class Name   : ProjectDetail_MobileAPI
* Company      : Fingertipplus
* Created Date : 27-05-2025
* @description :
* This Apex REST class exposes the `/ProjectDetailAPI/*` endpoint,allowing mobile apps to retrieve detailed information about a specific project. The API requires a valid `userId` and `projectId`,
* validates the customer, fetches associated project and amenity data,and returns a structured JSON response with all relevant details.
*
* Functional Flow:
* - Accepts a JSON request body containing `userId` and `projectId`.
* - Validates that both fields are provided and user is active.
* - Retrieves a single matching `Project__c` record based on `Project_Id__c`.
* - Gathers key project details: images, area, BHK types, pricing, location,
*   progress status, and description.
* - Extracts related `Amenity__c` records and maps them to a custom list.
* - Logs both request and response for monitoring and debugging.
*
* Author       : Praveen Kumar
*
* Change Log:
* --------------------------------------------------------------------------
* Ver | Author         | Date       | Description
* --------------------------------------------------------------------------
* 1.0 | Praveen Kumar  | 27-05-2025 | Initial version
* --------------------------------------------------------------------------
**************************************************************/

@RestResource(urlMapping='/ProjectDetailAPI/*')
global without sharing class ProjectDetail_MobileAPI {
    
    @HttpPost
    global static void getProjectDetail() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString(); // Get the JSON body
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c ='ProjectDetail_MobileAPI';
        log.Request__c =requestBody;
        
        try{
            ProjectWrapper proj = (ProjectWrapper) JSON.deserialize(requestBody, ProjectWrapper.class);
            String userId = proj.userId;
            String prjId = proj.projectId;
            
            if (String.isBlank(userId) || String.isBlank(prjId)) {
                ErrorResponseUitilityClass.sendErrorResponse('UserId or ProjectId Should not be Null.','ProjectDetail_MobileAPI',requestBody);
                return;
            }
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty() && userId!= '0') {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found','ProjectDetail_MobileAPI',requestBody);
                return;
            }
            
            Project__c project = [ SELECT Id,Project_Id__c,Project__c, Project_Status__c,Name,Project_Address__c,RERA_NO__c,Available_Units__c,Total_Units__c,Starting_Price__c,BHK_Type__c,
                                  End_Price_Range__c,Offer_Precentage__c,Video_URL__c,Project_Location__c,Unit_Type__c,Facing__c,Amenties__c,Project_Location__Latitude__s,Project_Location__Longitude__s FROM Project__c WHERE Project_Id__c = :prjId LIMIT 1  ];
            
            if (project == null) {
                ErrorResponseUitilityClass.sendErrorResponse('Project Not Found','ProjectDetail_MobileAPI',requestBody);
                return;
            }
            Map<String, Decimal> commissionSlabMap = new Map<String, Decimal>();
            
            for (Commission_Slab__c slab : [ SELECT Booking_Criteria__c, Commission_Factor__c FROM Commission_Slab__c WHERE Project__c = :project.Id]) {
                if (slab.Booking_Criteria__c != null && slab.Commission_Factor__c != null) {
                    commissionSlabMap.put( slab.Booking_Criteria__c,  slab.Commission_Factor__c  );
                }
            }
            
            
            
            String subImageUrl = '';
            List<ContentDocumentLink>  projLinks = [  SELECT ContentDocumentId FROM ContentDocumentLink  WHERE LinkedEntityId = :project.Id ];
            
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink link : projLinks) {
                docIds.add(link.ContentDocumentId);
            }
            Map<Id, String> docIdToTitle = new Map<Id, String>();
            
            
            List<ContentVersion> versions = [ SELECT Id, Title, FileExtension, ContentDocumentId  FROM ContentVersion  WHERE IsLatest = true AND ContentDocumentId IN :docIds];
            Set<id> cdid = new Set<id>();
            
            for (ContentVersion cv : versions) {
                cdid.add(cv.id);
                docIdToTitle.put(cv.id, cv.Title);
            }
            List<ProjectDocument> brochureList = new List<ProjectDocument>();
            List<ProjectDocument> florplanlst = new List<ProjectDocument>();
            List<ProjectDocument> approvallist = new List<ProjectDocument>();
            for (ContentDistribution cd : [SELECT ContentDocumentId, DistributionPublicUrl,ContentVersion.FileExtension,ContentVersion.Title,ContentVersionId,ContentDownloadUrl FROM ContentDistribution WHERE ContentVersionId IN:docIdToTitle.keySet()]) {
                //  String title = docIdToTitle.get(cd.ContentVersionId).toLowerCase();
                if (cd.ContentVersion.Title.contains('Project Images')) {
                    String picUrl = '';
                    picUrl =  cd.ContentDownloadUrl.replace('download/?' , 'renditionDownload?rendition=ORIGINAL_Jpg&');
                    picUrl = picUrl.replace('&ids' , '&versionId');
                    
                    subImageUrl =picUrl;
                }
                if (cd.ContentVersion.Title != null && cd.ContentVersion.Title.contains('Project Brochure')) {
                    System.debug('Hello');
                    ProjectDocument pd = new ProjectDocument();
                    pd.pdfName = cd.ContentVersion.Title /*+ '.' + cd.ContentVersion.FileExtension*/;
                    pd.pdfUrl  = cd.ContentDownloadUrl;
                    
                    brochureList.add(pd);
                }
                
                if (cd.ContentVersion.Title != null && cd.ContentVersion.Title.contains('Floor Plans')) {
                    System.debug('Hello');
                    ProjectDocument pd = new ProjectDocument();
                    pd.pdfName = cd.ContentVersion.Title /*+ '.' + cd.ContentVersion.FileExtension*/;
                    pd.pdfUrl  = cd.ContentDownloadUrl;
                    
                    florplanlst.add(pd);
                }
                
                if (cd.ContentVersion.Title != null && cd.ContentVersion.Title.contains('Approval Document')) {
                    System.debug('Hello');
                    ProjectDocument pd = new ProjectDocument();
                   // pd.pdfName = cd.ContentVersion.Title + '.' + cd.ContentVersion.FileExtension;
                   pd.pdfName = cd.ContentVersion.Title;
                    pd.pdfUrl  = cd.ContentDownloadUrl;
                    
                    approvallist.add(pd);
                }
                
            }
            System.debug(brochureList);
            
            ProjectDetailData data = new ProjectDetailData();
            data.brochures = brochureList;
            
            // Basic info
            data.id = project.Project_Id__c != null
                ? project.Project_Id__c
                : null;
            
            data.projectName = project.Name;
            data.projectStatusId = project.Project_Status__c != null
                ? project.Project_Status__c
                : null;
            
            data.projectAddress = project.Project_Address__c;
            data.reraNumber = project.RERA_NO__c;
            
            // Units & pricing
            data.availableUnits = String.ValueOf(project.Available_Units__c);
            data.totalUnits = String.Valueof(project.Total_Units__c);
            
            data.startPriceRange = project.Starting_Price__c;
            data.endPriceRange = project.End_Price_Range__c;
            
            // Offers & media
            data.offerPercentage = String.ValueOf(project.Offer_Precentage__c);
            data.videoURL = project.Video_URL__c;
            data.projectImageUrl =subImageUrl;
            ProjectLatLong latLong = new ProjectLatLong();
            latLong.latitude  = project.Project_Location__Latitude__s;
            latLong.longitude = project.Project_Location__Longitude__s;
            
            data.projectLatLong = latLong;
            
            data.unitTypes     = parseMultiPicklist(project.Unit_Type__c);
            data.facingOptions = parseMultiPicklist(project.Facing__c);
            data.amenities     = parseMultiPicklist(project.Amenties__c);
            
            // If BHKTypes is same as Unit_Type__c or another field
            data.BHKTypes = parseMultiPicklist(project.BHK_Type__c);
            
            // data.brochures  = new List<ProjectDocument>();
            data.floorPlans = florplanlst;
            data.approvals  = approvallist;
            
            
            data.commissionSlab = commissionSlabMap;
            ProjectDetailResponseWrapper response = new ProjectDetailResponseWrapper();
            response.status = true;
            response.message = 'projects data';
            response.data = data;
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody =  Blob.valueOf(JSON.serialize(response));
            
            log.Response__c = JSON.serialize(response);
            log.Status__c = 'SUCCESS';
            insert log;
            
            
            
        }
        Catch (Exception e){
            System.debug(e.getMessage());
            ErrorResponseUitilityClass.sendErrorResponse('Error: ' + e.getMessage(),'ProjectDetail_MobileAPI',requestBody);
            

            
        }
        
    }
    public class ProjectWrapper {
        public String userId;
        public String projectId;
        
    }
    private static List<String> parseMultiPicklist(String multiPicklistStr) {
        List<String> result = new List<String>();
        if (String.isNotBlank(multiPicklistStr)) {
            result = multiPicklistStr.split(';');
            for (Integer i = 0; i < result.size(); i++) {
                result[i] = result[i].trim();
            }
        }
        return result;
    }
    public class ProjectDetailResponseWrapper {
        public Boolean status;
        public String message;
        public ProjectDetailData data;
    }
    public class ProjectDetailData {
        public String id;
        public String projectImageUrl;
        public String projectName;
        public String projectStatusId;
        public String projectAddress;
        public String reraNumber;
        
        public String availableUnits;
        public String totalUnits;
        
        public String startPriceRange;
        public String endPriceRange;
        
        public String offerPercentage;
        public String videoURL;
        
        public ProjectLatLong projectLatLong;
        
        public List<String> unitTypes;
        public List<String> facingOptions;
        public List<String> BHKTypes;
        public List<String> amenities;
        
        public Map<String, Decimal> commissionSlab;
        
        public List<ProjectDocument> brochures;
        public List<ProjectDocument> floorPlans;
        public List<ProjectDocument> approvals;
        
    }
    public class ProjectLatLong {
        public Decimal latitude;
        public Decimal longitude;
    }
    public class ProjectDocument {
        public String pdfName;
        public String pdfUrl;
    }
    
    /*
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'status' => false,
                'message' => message
                }));
    } */
}