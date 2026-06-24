/**
 * @description REST API to fetch notification list for Contact Center mobile app.
 * Validates customer by userId, retrieves active notifications subscribed by the customer,
 * and returns paginated response data in a standard wrapper format.
 *
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "projectId": "CPP001",
 *   "pageSize": 0
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Notification List",
 *   "data": [
 *     {
 *       "notificationId": "",
 *       "notificationTitle": "",
 *       "notificationDescription": "",
 *       "notificationDate": "",
 *       "notificationTypeId": "",
 *       "notificationIsRead": false
 *     }
 *   ]
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-24
 */
@RestResource(urlMapping='/CCNotificationListAPI/*')
global without sharing class NotificationList_CCMobileAPI {

    /**
     * @description Handles POST requests for notification listing.
     * Validates request payload and customer, fetches subscribed active notifications,
     * applies pagination, and returns data in `NotificationListResponse`.
     * Errors are handled through ErrorResponseUitilityClass.
     */
    @HttpPost
    global static void getNotificationList() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody != null ? req.requestBody.toString() : '';

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'NotificationList_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            NotificationListRequest requestData = (NotificationListRequest) JSON.deserialize(requestBody, NotificationListRequest.class);

            String userId = requestData != null ? requestData.userId : null;
            Integer pageSize = (requestData != null && requestData.pageSize != null) ? requestData.pageSize : 0;

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'NotificationList_CCMobileAPI', requestBody);
                return;
            }

            List<Customer_Master__c> cmList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'NotificationList_CCMobileAPI', requestBody);
                return;
            }
            Integer limitVal = 10;
            Integer offsetVal = pageSize * limitVal;
            List<Customer_Portal_Notification_Subscriber__c> ntsub = [
                SELECT Id, Customer_Portal_Notification__c, isRead__c
                FROM Customer_Portal_Notification_Subscriber__c
                WHERE Customer_Master__c = :cmList[0].Id
                AND Customer_Portal_Notification__r.isActive__c = true
            ];
            System.debug(ntsub.size());
            Map<Id, Boolean> readMap = new Map<Id, Boolean>();
            
            Set<Id> notiIds = new Set<Id>();
            for (Customer_Portal_Notification_Subscriber__c nfs : ntsub) {
                if (nfs.Customer_Portal_Notification__c != null) {
                    notiIds.add(nfs.Customer_Portal_Notification__c);
                    readMap.put(nfs.Customer_Portal_Notification__c, nfs.isRead__c);
                }
            }
            System.debug(notiIds.size());
            List<Customer_Portal_Notification__c> notifications = new List<Customer_Portal_Notification__c>();
            if (!notiIds.isEmpty()) {
                notifications = [
                    SELECT Id, Name, Notification_Time__c, Notification_Redirect_Id__c,
                           Updated_Status__c, Notification_Heading__c, Notification_Type__c,
                           Notification_Content__c, isRead__c
                    FROM Customer_Portal_Notification__c
                    WHERE IsActive__c = TRUE
                    AND Customer_Master__c = :cmList[0].Id
                    AND Id IN :notiIds
                    ORDER BY CreatedDate DESC
                    LIMIT :limitVal OFFSET :offsetVal
                ];
            }
            System.debug(notifications.size());
            List<NotificationDetail> data = new List<NotificationDetail>();
            for (Customer_Portal_Notification__c notificationRec : notifications) {
                NotificationDetail det = new NotificationDetail();
                det.notificationId = notificationRec.Name != null ? notificationRec.Name : String.valueOf(notificationRec.Name);
                det.notificationTitle = notificationRec.Notification_Heading__c != null ? notificationRec.Notification_Heading__c : '';
                det.notificationDescription = notificationRec.Notification_Content__c != null ? notificationRec.Notification_Content__c : '';
                det.notificationDate = notificationRec.Notification_Time__c;
              
                det.notificationTypeId = notificationRec.Notification_Type__c != null ? notificationRec.Notification_Type__c : '';
                det.notificationIsRead = readMap.containsKey(notificationRec.Id) ? readMap.get(notificationRec.Id) : (notificationRec.isRead__c != null ? notificationRec.isRead__c : false);
                data.add(det);
            }

            NotificationListResponse responseData = new NotificationListResponse();
            responseData.status = true;
            responseData.message = 'Notification List';
            responseData.data = data;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));

            log.Response__c = 'Retrieved ' + data.size() + ' notifications, pageSize=' + pageSize;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'NotificationList_CCMobileAPI', requestBody);
        }
    }

    /**
     * @description Request wrapper for notification list API.
     */
    public class NotificationListRequest {
        public String userId;
        public String projectId;
        public Integer pageSize;
    }

    /**
     * @description Notification detail wrapper returned for each notification record.
     */
    public class NotificationDetail {
        public String notificationId;
        public String notificationTitle;
        public String notificationDescription;
        public DateTime notificationDate;
        public String notificationTypeId;
        public Boolean notificationIsRead;
    }

    /**
     * @description Standard API response wrapper for notification list endpoint.
     */
    public class NotificationListResponse {
        public Boolean status;
        public String message;
        public List<NotificationDetail> data;
    }
}