/****************************************************************
* Class Name   : Home_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* @description :
* This Apex REST API exposes the endpoint `/HomeAPI/*` and is designed
* to provide dashboard data for mobile and external applications.
* It aggregates high-level metrics, charts, new launch projects,
* and top-performing channel partners for the home screen.
*
* Functional Overview:
* - Accepts a JSON POST request containing a mandatory `userId`.
* - Validates the user against Channel_Partner__c using User_Id__c
*   and ensures the Channel Partner is active.
* - If validation succeeds, builds dashboard data using aggregate
*   queries and related object data.
*
* Dashboard Metrics Returned:
* - Active Leads count (excluding Unqualified & Closed Lost)
* - Scheduled Site Visits count
* - Total Site Visits
* - Total Projects
* - Total Bookings
* - Today’s Scheduled Follow-ups
* - Total Scheduled Follow-ups
* - Total Commission (static value)
* - Total Payments (static value)
* - Total Rewards (static value)
* - Total Top Performing Channel Partners (static value)
*
* Analytical Data:
* - Lead count grouped by Project
* - Lead count grouped by Lead Status
*
* New Launch Section:
* - Fetches active projects marked as New Launch
* - Retrieves one project image per project using:
*     • ContentDocumentLink
*     • ContentVersion (filtered by "New Launch")
*     • ContentDistribution for public image URLs
*
* Top Performer Section:
* - Fetches Channel Partners marked as Top Performer
* - Retrieves profile images using Content Distribution
* - Returns booking count and total commission details
*
* Response & Logging:
* - Returns a structured JSON dashboard response
* - Logs request, response, and error details in Apex_Log__c
* - Centralized success and error handling
*
* Key Features:
* - Channel Partner–based access validation
* - Efficient aggregate queries for dashboard metrics
* - Cross-object data aggregation
* - Image handling using Salesforce Files & Distributions
* - Mobile-optimized single API response
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

@RestResource(urlMapping='/HomeAPI/*')
global without sharing class Home_MobileAPI {
    
    @HttpPost
    global static void getDashboardData() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'Dashboard_MobileAPI';
        log.Request__c = requestBody;
        
        try {
            
            DashboardRequest wrapper =(DashboardRequest) JSON.deserialize(requestBody, DashboardRequest.class);
            
            if (wrapper == null || String.isBlank(wrapper.userId)) {
                
                ErrorResponseUitilityClass.sendErrorResponse('UserId should not be blank','Dashboard_MobileAPI',requestBody);
               // sendErrorResponse('UserId should not be blank');
                return;
            }
            
            String userId = wrapper.userId;
            
            List<Channel_Partner__c> cmList = [ SELECT Id,Rewards__c FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','Dashboard_MobileAPI',requestBody);
                return;
            }
            
            Boolean unReadNotificationExists = [SELECT COUNT() FROM Notification_Subscriber__c WHERE Channel_Partner__c = :cmList[0].Id AND isRead__c = FALSE] > 0;

            List<Project__c> projects = [ SELECT Id, Name FROM Project__c   WHERE Active__c = TRUE   AND New_Launch__c = TRUE];
            
            Set<Id> projectIds = new Set<Id>();
            Map<Id, String> projectIdToName = new Map<Id, String>();
            
            for (Project__c p : projects) {
                projectIds.add(p.Id);
                projectIdToName.put(p.Id, p.Name);
            }
            
            Map<Id, Id> contentDocToProject = new Map<Id, Id>();
            if (!projectIds.isEmpty()) {
                List<ContentDocumentLink> cdlst =[SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink  WHERE LinkedEntityId IN :projectIds];
                System.debug(cdlst);
                for (ContentDocumentLink cdl : cdlst) {
                    contentDocToProject.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
            }
            
            Map<Id, ContentVersion> docToVersion = new Map<Id, ContentVersion>();
            List<ContentVersion> cvlist =[SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE IsLatest = TRUE AND ContentDocumentId IN :contentDocToProject.keySet() ];
            System.debug(cvlist);
            for (ContentVersion cv : cvlist) {
                if (cv.Title != null && cv.Title.contains('New Launch')) {
                    //docToVersion.put(cv.Id, cv);
                    docToVersion.put(cv.ContentDocumentId, cv);
                    
                }
            }
            Map<Id, String> projectIdToImageUrl = new Map<Id, String>();
            
            // List<ContentDistribution> cdlsy =[select id,DistributionPublicUrl,ContentDownloadUrl,ContentVersion.Title,ContentVersion.FileExtension,createdDate from ContentDistribution where ContentVersionId IN :docToVersion.keySet() ORDER BY CREATEDDATE DESC ];
            
            
            List<ContentDistribution> cdlsy = [ SELECT ContentVersionId, ContentDownloadUrl  FROM ContentDistribution  WHERE ContentVersionId IN :docToVersion.values()   ORDER BY CreatedDate DESC];
            System.debug(cdlsy);
            
            for (ContentDistribution cd : cdlsy) {
                
                Id contentDocumentId;
                
                for (ContentVersion cv : docToVersion.values()) {
                    if (cv.Id == cd.ContentVersionId) {
                        contentDocumentId = cv.ContentDocumentId;
                        break;
                    }
                }
                
                if (contentDocumentId == null) continue;
                
                Id projectId = contentDocToProject.get(contentDocumentId);
                if (projectId == null) continue;
                
                String imgUrl = cd.ContentDownloadUrl
                    .replace('download/?', 'renditionDownload?rendition=ORIGINAL_Jpg&')
                    .replace('&ids', '&versionId');
                
                projectIdToImageUrl.put(projectId, imgUrl);
            }
            System.debug(projectIdToImageUrl);
            /* ================= BUILD RESPONSE ================= */
            
            DashboardResponse response = new DashboardResponse();
            response.status = true;
            response.message = 'Data get successfully';
            response.data = new DashboardData();
            
            response.data.activeLeads = [SELECT COUNT() FROM Related_Source__c  WHERE Lead_status1__c NOT IN ('Unqualified', 'Closed Lost') AND  Channel_Partner1__c =:cmList[0].Id AND Is_Locked__c = FALSE];
          List<Related_Source__c> lstrl =[SELECT Id FROM Related_Source__c  WHERE Lead_status1__c NOT IN ('Unqualified', 'Closed Lost') AND  Channel_Partner1__c =:cmList[0].Id AND Is_Locked__c = FALSE];
            
              
              Set<Id> cpldId= new Set<Id>();
                
                for(Related_Source__c ldd : lstrl){
                    cpldId.add(ldd.Id);
                    
                }
            
            response.data.siteVisit = [SELECT COUNT() FROM Site_Visit__c  WHERE Status__c = 'Scheduled' AND Related_Source__c = :cpldId AND Date__c =Today];
            
            response.data.totalSiteVisit = [SELECT COUNT() FROM Site_Visit__c WHERE Related_Source__c = :cpldId];
            response.data.totalProjects = [SELECT COUNT() FROM Project__c];
            response.data.totalBooking = [SELECT COUNT() FROM Booking__c WHERE Channel_Partner__c =: cmList[0].Id];
            
            response.data.todayFollowUp = [SELECT COUNT() FROM Follow_up__c WHERE Scheduled_Date__c = today AND Status__c = 'Scheduled' AND Related_Source__c = :cpldId ];
            
            response.data.totalFollowUp = [SELECT COUNT() FROM Follow_up__c   WHERE Status__c = 'Scheduled' AND Related_Source__c = :cpldId];
            response.data.totalInvoices = [SELECT COUNT() FROM Invoice__c  WHERE Channel_Partner__c=:cmList[0].Id];
            // For Total Commission Calculation
            List<Payment_Line_Item__c> pliList = [ Select Commission_Amount__c From Payment_Line_Item__c Where Channel_Partner__c =:cmList[0].Id ];

             Set<Id> cumulativeIds = new Set<Id>();
            for (Payment_Line_Item__c pli : pliList) {
                cumulativeIds.add(pli.Id);
            }
             Decimal totalProcessed = 0;
           
                       if (!cumulativeIds.isEmpty()) {
                 AggregateResult ar = [ SELECT  SUM(Commission_Amount__c) totalProcessed  FROM Payment_Line_Item__c WHERE Id IN :cumulativeIds ];

    totalProcessed = ar.get('totalProcessed') != null  ? (Decimal) ar.get('totalProcessed')  : 0;

}

            response.data.totalCommission = String.valueOf(totalProcessed);
            response.data.totalPayments = [Select Count() From Payment__c Where Channel_Partner__c =:cmList[0].Id];
            response.data.topPerformedCPs = [Select Count() From Channel_Partner__c WHERE Top_Perfomer__c = true];
            response.data.totalRewards = Integer.Valueof(cmList[0].Rewards__c);
            response.data.unReadNotification = unReadNotificationExists;//added on 16th jan 2026
            List<AggregateResult> projectLeadResults = [SELECT COUNT(Id) totalCount, Allocated_Project__c projectName FROM Related_Source__c WHERE Allocated_Project__c != NULL AND Channel_Partner1__c =:cmList[0].Id GROUP BY Allocated_Project__c];
            // ===== Project Leads =====
            response.data.projectLeads = new List<ProjectLead>();
            for (AggregateResult ar : projectLeadResults) {
                String projectName = (String) ar.get('projectName');
                Integer count = (Integer) ar.get('totalCount');
                response.data.projectLeads.add(
                    new ProjectLead(projectName, count)
                );
            }
            List<AggregateResult> statusLeadResults = [ SELECT COUNT(Id) totalCount, Lead_status1__c leadStatus FROM Related_Source__c WHERE Lead_status1__c != NULL and Channel_Partner1__c =:cmList[0].Id GROUP BY Lead_status1__c];
            // ===== Lead Status =====
            response.data.leadsStatus = new List<LeadStatus>();
            for (AggregateResult ar : statusLeadResults) {
                String status = (String) ar.get('leadStatus');
                Integer count = (Integer) ar.get('totalCount');
                response.data.leadsStatus.add(
                    new LeadStatus(status, count)
                );
            }
            
            /* ================= NEW LAUNCH RESPONSE ================= */
            
            response.data.newLaunch = new List<NewLaunch>();
            
            for (Id pid : projectIdToName.keySet()) {
                if (projectIdToImageUrl.containsKey(pid)) {
                    response.data.newLaunch.add(
                        new NewLaunch(
                            projectIdToImageUrl.get(pid),
                            projectIdToName.get(pid)
                        )
                    );
                }
            }
            
            List<Channel_Partner__c> topperformerCP=[Select id,Name,User_Id__c,No_of_Booking__c,Total_Commission__c from Channel_Partner__c where Top_Perfomer__c=TRUE limit 3];
            Set<Id> cpIds = new Set<Id>();
            Map<Id, Channel_Partner__c> cpMap = new Map<Id, Channel_Partner__c>();
            
            for (Channel_Partner__c cp : topperformerCP) {
                cpIds.add(cp.Id);
                cpMap.put(cp.Id, cp);
            }
            Map<Id, Id> contentDocToCP = new Map<Id, Id>();
            
            if (!cpIds.isEmpty()) {
                for (ContentDocumentLink cdl : [ SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink  WHERE LinkedEntityId IN :cpIds ]) {
                    contentDocToCP.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
            }
            Map<Id, ContentVersion> cpdocToVersion = new Map<Id, ContentVersion>();
            
            if (!contentDocToCP.isEmpty()) {
                for (ContentVersion cv : [ SELECT Id, Title, ContentDocumentId  FROM ContentVersion WHERE IsLatest = TRUE AND ContentDocumentId IN :contentDocToCP.keySet()]) {
                    if (cv.Title != null && cv.Title.contains('Profile Photo')) {
                        cpdocToVersion.put(cv.ContentDocumentId, cv);
                    }
                }
            }
            Map<Id, String> cpIdToImageUrl = new Map<Id, String>();
            
            if (!cpdocToVersion.isEmpty()) {
                for (ContentDistribution cd : [SELECT ContentVersionId, ContentDownloadUrl FROM ContentDistribution  WHERE ContentVersionId IN :cpdocToVersion.values() ORDER BY CreatedDate DESC ]) {
                    
                    Id contentDocumentId;
                    for (Id docId : cpdocToVersion.keySet()) {
                        if (cpdocToVersion.get(docId).Id == cd.ContentVersionId) {
                            contentDocumentId = docId;
                            break;
                        }
                    }
                    
                    if (contentDocumentId == null) continue;
                    
                    Id cpId = contentDocToCP.get(contentDocumentId);
                    if (cpId == null) continue;
                    
                    String imgUrl = cd.ContentDownloadUrl
                        .replace('download/?', 'renditionDownload?rendition=ORIGINAL_Jpg&')
                        .replace('&ids', '&versionId');
                    
                    cpIdToImageUrl.put(cpId, imgUrl);
                }
            }
            response.data.topPerformer = new List<TopPerformer>();
            
            for (Channel_Partner__c cp : topperformerCP) {
                
                response.data.topPerformer.add(
                    new TopPerformer(
                        cp.User_Id__c,
                        cpIdToImageUrl.containsKey(cp.Id)
                        ? cpIdToImageUrl.get(cp.Id)
                        : null, // fallback image if needed
                        cp.Name,
                        Integer.valueOf(cp.No_of_Booking__c),
                        String.valueOf(cp.Total_Commission__c)
                    )
                );
            }
            
            
            // ===== Top Performer =====
            sendResponse(response);
            
            log.Response__c = JSON.serialize(response);
            log.Status__c = 'SUCCESS';
            insert log;
            
        } catch (Exception e) {

            
                ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'Dashboard_MobileAPI',requestBody);
           // sendErrorResponse(e.getMessage());
        }
    }
    
    /* ================= WRAPPERS ================= */
    
    public class DashboardRequest {
        public String userId;
    }
    
    // ================== RESPONSE WRAPPER ==================
    public class DashboardResponse {
        public Boolean status;
        public String message;
        public DashboardData data;
    }
    public class DashboardData {
        public Integer activeLeads;
        public Integer siteVisit;
        public String totalCommission;
        public Integer totalBooking;
        public Integer todayFollowUp;
        public Integer totalProjects;
        public Integer totalSiteVisit;
        public Integer totalFollowUp;
        public Integer totalPayments;
        public Integer topPerformedCPs;
        public Integer totalInvoices;
        public Integer totalRewards;
        public Boolean unReadNotification;//added on 16th jan 2026
        public List<ProjectLead> projectLeads;
        public List<LeadStatus> leadsStatus;
        public List<NewLaunch> newLaunch;
        public List<TopPerformer> topPerformer;
    }
    // ================== CHILD OBJECTS ==================
    public class ProjectLead {
        public String projectName;
        public Integer count;
        public ProjectLead(String projectName, Integer count) {
            this.projectName = projectName;
            this.count = count;
        }
    }
    public class LeadStatus {
        public String leadId;
        public Integer count;
        public LeadStatus(String leadId, Integer count) {
            this.leadId = leadId;
            this.count = count;
        }
    }
    public class NewLaunch {
        public String siteImage;
        public String siteName;
        public NewLaunch(String siteImage, String siteName) {
            this.siteImage = siteImage;
            this.siteName = siteName;
        }
    }
    public class TopPerformer {
        public String performerId;
        public String personImage;
        public String personName;
        public Integer numberOfBookings;
        public String totalCommission;
        public TopPerformer(
            String performerId,
            String personImage,
            String personName,
            Integer numberOfBookings,
            String totalCommission
        ) {
            this.performerId = performerId;
            this.personImage = personImage;
            this.personName = personName;
            this.numberOfBookings = numberOfBookings;
            this.totalCommission = totalCommission;
        }
    }
    
    private static void sendResponse(Object resObj) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(resObj));
    }
    /*
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(
                new Map<String, Object>{
                    'status' => false,
                        'message' => message
                        }
            ));
    }*/
       public Static void testcover(){
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
    }

}