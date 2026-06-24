@RestResource(urlMapping='/NotificationReadAPI/*')
global without sharing  class NotificationRead_MobileAPI {
    
    @HttpPost
    global static void updateNotificationRead() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString(); // Get the JSON body
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c ='Notification_read_MobileAPI';
        log.Request__c =requestBody;
        try{
            
            notificationReqWrapper ntdata = (notificationReqWrapper) JSON.deserialize(requestBody, notificationReqWrapper.class);
            String userId = ntdata.userId;
            List<String> NotifcationIds = ntdata.notificationId; 
            
            if (String.isBlank(userId)) {
                
                ErrorResponseUitilityClass.sendErrorResponse('User Id Should not be blank.','NotificationRead_MobileAPI',requestBody);
                return;
            }
          //  List<Customer_Master__c> cmList = [ SELECT Id, Email__c, Password__c, First_Name__c, Last_Name__c, Phone__c, Name, Loyality__c/*, CRM_Executive__c, CRM_Executive__r.LastName, CRM_Executive__r.Phone, CRM_Executive__r.Email */ FROM Customer_Master__c WHERE Name = :userId AND isActive__c = TRUE LIMIT 1 ];
            List<Channel_Partner__c> cmList = [ SELECT Id FROM Channel_Partner__c  WHERE User_Id__c = :userId AND Active__c = TRUE LIMIT 1 ];
            
            if (cmList.isEmpty()) {
                
                ErrorResponseUitilityClass.sendErrorResponse('User Not Found in System','NotificationRead_MobileAPI',requestBody);
                return;
            }
            List<Notification__c> notificationlist = new List<Notification__c>();
            notificationlist = [SELECT Id,Name FROM Notification__c WHERE Notification_Redirect_Id__c =:NotifcationIds];
            set<string> notficationRecIds = new set<string>();
            for(Notification__c nc : notificationlist){
                notficationRecIds.add(nc.Id);
            }
            System.debug(notficationRecIds);
           List<Notification_Subscriber__c> notReadCust = new List<Notification_Subscriber__c>();
            List<Notification_Subscriber__c> updateReadCust = new List<Notification_Subscriber__c>();
            notReadCust = [SELECT Id, isRead__c, Channel_Partner__c, Notification__c FROM Notification_Subscriber__c WHERE Notification__c IN :notficationRecIds AND Channel_Partner__c=:cmList[0].Id];
            
            system.debug(notReadCust.size());
           
            for (Notification_Subscriber__c ntr : notReadCust) {
                Notification_Subscriber__c nr = new Notification_Subscriber__c();
                nr.Id = ntr.Id;
                nr.isRead__c = true;
               updateReadCust.add(nr);
            }
			update updateReadCust;
           
            // Send the response back using a wrapper class
            OfferResponseWrapper response = new OfferResponseWrapper();
            response.status = true;
            response.message = 'Notification read successfully';
           
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
            RestContext.response.statusCode = 200;
            
            log.Status__c = 'SUCCESS';
            log.Response__c= 'Notification read successfully';
            insert log;
            
        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse('Login failed: ' + e.getMessage(),'NotificationRead_MobileAPI',requestBody);
        }
    }
    
    

    // Wrapper class for the entire response
    public class OfferResponseWrapper {
        public Boolean status;
        public String message;
    }

    public class notificationReqWrapper {
        public String userId;
        public List<String> notificationId;
    }
    /*
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 400;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
            'status' => false,
            'message' => message
        }));
    }
*/
 

}