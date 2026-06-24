/**
 * @description REST API to delete notification subscriber records for Contact Center mobile app.
 * Validates customer using userId, resolves notifications using notificationId list,
 * deletes related Notification_Subscriber__c records for that customer,
 * and returns standard success response.
 *
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "notificationId": ["CPP001"]
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Notification delete successfully"
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-27
 */
@RestResource(urlMapping='/CCNotificationDeleteAPI/*')
global without sharing class NotificationDelete_CCMobileAPI {

    @HttpPost
    global static void deleteNotificationSubscriber() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody != null ? req.requestBody.toString() : '';

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'NotificationDelete_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            NotificationDeleteRequest requestData =
                (NotificationDeleteRequest) JSON.deserialize(requestBody, NotificationDeleteRequest.class);

            String userId = requestData != null ? requestData.userId : null;
            List<String> notificationIdList = requestData != null ? requestData.notificationId : null;

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse(
                    'Please provide userId',
                    'NotificationDelete_CCMobileAPI',
                    requestBody
                );
                return;
            }

            if (notificationIdList == null || notificationIdList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse(
                    'Please provide notificationId',
                    'NotificationDelete_CCMobileAPI',
                    requestBody
                );
                return;
            }

            List<Customer_Master__c> customerList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = true
                LIMIT 1
            ];

            if (customerList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse(
                    'Customer Not Found',
                    'NotificationDelete_CCMobileAPI',
                    requestBody
                );
                return;
            }

            Id customerId = customerList[0].Id;

            Set<Id> notificationIds = new Set<Id>();
            for (Customer_Portal_Notification__c notificationRec : [
                SELECT Id
                FROM Customer_Portal_Notification__c
                WHERE Customer_Master__c = :customerId
                AND Notification_Redirect_Id__c IN :notificationIdList
            ]) {
                notificationIds.add(notificationRec.Id);
            }

            List<Customer_Portal_Notification_Subscriber__c> subscriberToDelete = new List<Customer_Portal_Notification_Subscriber__c>();
            if (!notificationIds.isEmpty()) {
                subscriberToDelete = [
                    SELECT Id
                    FROM Customer_Portal_Notification_Subscriber__c
                    WHERE Customer_Master__c = :customerId
                    AND Customer_Portal_Notification__c IN :notificationIds
                ];
            }

            if (!subscriberToDelete.isEmpty()) {
                delete subscriberToDelete;
            }

            NotificationDeleteResponse responseData = new NotificationDeleteResponse();
            responseData.status = true;
            responseData.message = 'Notification delete successfully';

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));

            log.Response__c = 'Deleted subscribers: ' + subscriberToDelete.size();
            log.Status__c = 'SUCCESS';
            insert log;
        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(
                e.getStackTraceString() + ' - ' + e.getMessage(),
                'NotificationDelete_CCMobileAPI',
                requestBody
            );
        }
    }

    public class NotificationDeleteRequest {
        public String userId;
        public List<String> notificationId;
    }

    public class NotificationDeleteResponse {
        public Boolean status;
        public String message;
    }
}