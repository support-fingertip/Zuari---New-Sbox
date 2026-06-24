/****************************************************************
* Class Name   : NotificationDetail_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API fetches Notifications for a
* Channel Partner using userId.
*
* Input JSON:
* {
*   "userId": "CH-0003",
*   "pageSize": 0
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Notification data",
*   "data": [
*     {
*       "notificationId": 998,
*       "id": 10,
*       "notificationTypeId": 85,
*       "title": "Notification Title",
*       "description": "Notification description",
*       "notificationDate": "2025-12-03T12:34:56Z",
*       "isRead": false
*     }
*   ]
* }
*
* Author       : Sandeep Kumar
******************************************************************************************/
@RestResource(urlMapping='/NotificationDetailAPI/*')
global without sharing class NotificationDetail_MobileAPI {
    
    @HttpPost
    global static void getNotifications() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'NotificationDetail_MobileAPI',
            Request__c = requestBody
        );
        Boolean logInserted = false;
        
        try {
            NotificationRequestWrapper input = (NotificationRequestWrapper) JSON.deserialize(requestBody, NotificationRequestWrapper.class);
            
            if (String.isBlank(input.userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('userId is required','NotificationDetail_MobileAPI',requestBody);
                return;
            }
            
            Integer offsetVal = input.pageSize != null ? input.pageSize : 0;
            Integer limitVal = 10;
            
            // Validate Channel Partner
            Channel_Partner__c cp = [SELECT Id, User_Id__c FROM Channel_Partner__c 
                                     WHERE Active__c = TRUE AND User_Id__c = :input.userId
                                     LIMIT 1];
            
            if (cp == null) {
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found for userId: ' + input.userId,'NotificationDetail_MobileAPI',requestBody);

                return;
            }
            
            List<Notification_Subscriber__c> ntsub = [Select id,Notification__c,isRead__c from Notification_Subscriber__c where Channel_Partner__c =:cp.Id AND Notification__r.isActive__c=true];
            Map<Id, Boolean> readMap = new Map<Id, Boolean>();
            
            set<Id> notiIds = new  set<Id>();
            For(Notification_Subscriber__c nfs : ntsub){
                if(nfs.Notification__c != null){
                    
                    notiIds.add(nfs.Notification__c);
                    
                    readMap.put(nfs.Notification__c, nfs.isRead__c);
                }
            }
            System.debug(notiIds);
            
            // Fetch notifications
            List<Notification__c> notifications = [
                SELECT Id, Name,Notification_Time__c,Notification_Redirect_Id__c,Notification_Heading__c,Updated_Status__c, Notification_Category__c,Id__c,Title__c,Notification_Type__c, Notification_Content__c, isRead__c, Notification_Date__c
                FROM Notification__c
                WHERE IsActive__c = TRUE AND Channel_Partner__c = :cp.Id AND ID IN :notiIds
                ORDER BY CreatedDate DESC
                LIMIT :limitVal OFFSET :offsetVal
            ];
            
            List<NotificationDataWrapper> dataList = new List<NotificationDataWrapper>();
            for (Notification__c n : notifications) {
                NotificationDataWrapper nd = new NotificationDataWrapper();
                nd.notificationId = n.Name;
                nd.notificationTypeId = n.Notification_Type__c;
                nd.statuscode = n.Updated_Status__c;
                nd.id = n.Notification_Redirect_Id__c;// optional navigation ID
                nd.title = n.Notification_Heading__c;
                
                nd.description = n.Notification_Content__c;
                nd.notificationDate = n.Notification_Time__c;
                nd.isRead = readMap.get(n.Id);
                
                dataList.add(nd);
            }
            
            NotificationResponseWrapper res = new NotificationResponseWrapper(true, 'Notification data', dataList);
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
            
            // Log success
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;
            
        } catch (Exception e) {
            System.debug('Error fetching notifications: ' + e);
           
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'NotificationDetail_MobileAPI',requestBody);
        }
    }
    
    // ---------- Input Wrapper ----------
    public class NotificationRequestWrapper {
        public String userId;
        public Integer pageSize;
    }
    
    // ---------- Notification Data ----------
    public class NotificationDataWrapper {
        public String notificationId;
        public String id;
        public String notificationTypeId;
        public String title;
        public String statuscode;
        public String description;
        public Datetime notificationDate;
        public Boolean isRead;
    }
    
    // ---------- Response Wrapper ----------
    public class NotificationResponseWrapper {
        public Boolean status;
        public String message;
        public List<NotificationDataWrapper> data;
        public NotificationResponseWrapper(Boolean s, String m, List<NotificationDataWrapper> d) {
            status = s;
            message = m;
            data = d;
        }
    }
    
    // ---------- Error Helper ----------
    /*
    private static void sendError(String msg, Apex_Log__c log, Boolean logInserted) {
        NotificationResponseWrapper res = new NotificationResponseWrapper(false, msg, null);
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));
        
        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);
        
        if (logInserted) {
            update log;
        } else {
            insert log;
        }
    }*/
}