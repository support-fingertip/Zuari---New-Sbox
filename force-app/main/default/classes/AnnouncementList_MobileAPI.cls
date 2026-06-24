@RestResource(urlMapping='/AnnouncementListAPI/*')
global without sharing class AnnouncementList_MobileAPI {
     @HttpPost
    global static void getAllSiteVisitDetail() {
        
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AnnouncementList_MobileAPI';
        log.Request__c = requestBody;
        try{
            AllSiteVisitWrapper ld = (AllSiteVisitWrapper) JSON.deserialize(requestBody, AllSiteVisitWrapper.class);
            
            String userId = ld.userId;
            Integer pageSize = ld.pageSize;
            
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please Send correct userId','AnnouncementList_MobileAPI',requestBody);
                return;
            }
            
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','AnnouncementList_MobileAPI',requestBody);
                
                return;
            }
            
            if (!cmList.isEmpty()) {
                
                List<Lead> cpldlst= [Select id from Lead Where Channel_Partner__c =:cmList[0].Id];
                if(cpldlst.isEmpty()){
                 ErrorResponseUitilityClass.sendErrorResponse('No Lead Found for this CP','AnnouncementList_MobileAPI',requestBody);
                return;
            
                    
                }
                
                List<Announcement__c> annlist = [Select id,Name,Announcement_Type__c,Description__c,Posted_Date__c,Title__c,Valid_Till__c from Announcement__c ];
                 List<LeadData> responseList = new List<LeadData>();
               
                for (Announcement__c l : annlist) {
                    LeadData ldResp = new LeadData();
                    ldResp.id = l.Name;
                    ldResp.announcementTypeId = l.Announcement_Type__c;
                    ldResp.title = l.Title__c;
                    ldResp.description = l.Description__c;
                    ldResp.postedDate = String.ValueOf(l.Posted_Date__c);
                    ldResp.validateTillDate = String.ValueOf(l.Valid_Till__c);
                    
                    responseList.add(ldResp);
                }
                LeadResponseWrapper response = new LeadResponseWrapper();
                response.status = true;
                response.message = 'Announcements Data';
                response.data = responseList;
                
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody =  Blob.valueOf(JSON.serialize(response));
                
                log.Response__c = 'Announcement Data fetched successfully'+ responseList;
                log.Status__c = 'SUCCESS';
                insert log;
                return;
            }  
            
            
        }
        catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse('Error: ' + e.getMessage(),'AnnouncementList_MobileAPI',requestBody);
            
        }
        
        
    }
    public class AllSiteVisitWrapper {
        public String userId;
        public Integer pageSize;
    }
    public class LeadResponseWrapper {
        public Boolean status;
        public String message;
        public List<LeadData> data;
    }
    
    public class LeadData {
        public String id;
        public String announcementTypeId;
        public String title;
        public String description;
        public String postedDate;
        public String validateTillDate;
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