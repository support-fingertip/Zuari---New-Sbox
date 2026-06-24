@RestResource(urlMapping='/ChannelPartnerLeadAPI/*')
global without sharing class ChannelPartnerLead_MobileAPI {
    
    @HttpPost
    global static void getLeadData() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'ChannelPartnerLead_MobileAPI';
        log.Request__c = requestBody;
        
        try {
            
            leadRequest wrapper =  (leadRequest) JSON.deserialize(requestBody, leadRequest.class);
            if (wrapper == null || String.isBlank(wrapper.userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('UserId should not be blank','ChannelPartnerLead_MobileAPI',requestBody);
                return;
            }
            
            String userId = wrapper.userId;
            
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','ChannelPartnerLead_MobileAPI',requestBody);
                return;
            }
              List<Related_Source__c> cpldlst=[select id,Lead_Id__c,Name__c from Related_Source__c where Channel_Partner1__c =:cmList[0].Id and Is_Locked__c = FALSE];
                DashboardResponse response = new DashboardResponse();
            response.status = true;
            response.message = 'leads list';
            response.data = new List<DashboardData>();
            
           //List<Lead> ldlst = [Select id,Name,FirstName,LastName,Lead_ID__c from Lead Where Channel_Partner__c=:cmList[0].Id];
          for (Related_Source__c ld : cpldlst) {
                DashboardData dd = new DashboardData();
                dd.id = ld.Lead_Id__c;
                dd.leadName = ld.Name__c;
                response.data.add(dd);
            }

            // ✅ SEND RESPONSE
            sendResponse(response); 
            
        }catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'ChannelPartnerLead_MobileAPI',requestBody);
        }
    }
    public class leadRequest {
        public String userId;
    } 
    public class DashboardResponse {
        public Boolean status;
        public String message;
        public List<DashboardData> data;
    }

    public class DashboardData {
        public String id;
        public String leadName;
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
}