/**
 * @description REST API to mark notifications as read for Contact Center mobile app.
 * Validates customer using userId, resolves notifications from provided notificationId list,
 * then updates Notification_Subscriber__c records for that customer.
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
 *   "message": "Notification read successfully"
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-27
 */
@RestResource(urlMapping='/CCNotificationReadAPI/*')
global without sharing class NotificationRead_CCMobileAPI {

    @HttpPost
    global static void markNotificationRead() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody != null ? req.requestBody.toString() : '';

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'NotificationRead_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            NotificationReadRequest requestData =
                (NotificationReadRequest) JSON.deserialize(requestBody, NotificationReadRequest.class);

            String userId = requestData != null ? requestData.userId : null;
            List<String> notificationIdList = requestData != null ? requestData.notificationId : null;

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse(
                    'Please provide userId',
                    'NotificationRead_CCMobileAPI',
                    requestBody
                );
                return;
            }

            if (notificationIdList == null || notificationIdList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse(
                    'Please provide notificationId',
                    'NotificationRead_CCMobileAPI',
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
                    'NotificationRead_CCMobileAPI',
                    requestBody
                );
                return;
            }

            Id customerId = customerList[0].Id;


            Set<Id> notificationIds = new Set<Id>();
                for (Customer_Portal_Notification__c notificationRec : [
                    SELECT Id, Name
                    FROM Customer_Portal_Notification__c
                    WHERE Customer_Master__c = :customerId
                    AND ( Notification_Redirect_Id__c IN :notificationIdList)
                ]) {
                    notificationIds.add(notificationRec.Id);
                }
            

            List<Customer_Portal_Notification_Subscriber__c> subscriberToUpdate = new List<Customer_Portal_Notification_Subscriber__c>();
            if (!notificationIds.isEmpty()) {
                for (Customer_Portal_Notification_Subscriber__c subscriberRec : [
                    SELECT Id, isRead__c
                    FROM Customer_Portal_Notification_Subscriber__c
                    WHERE Customer_Master__c = :customerId
                    AND Customer_Portal_Notification__c IN :notificationIds
                ]) {
                    if (subscriberRec.isRead__c != true) {
                        subscriberRec.isRead__c = true;
                        subscriberToUpdate.add(subscriberRec);
                    }
                }
            }

            if (!subscriberToUpdate.isEmpty()) {
                update subscriberToUpdate;
            }

            NotificationReadResponse responseData = new NotificationReadResponse();
            responseData.status = true;
            responseData.message = 'Notification read successfully';

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));

            log.Response__c = 'Updated subscribers: ' + subscriberToUpdate.size();
            log.Status__c = 'SUCCESS';
            insert log;
        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(
                e.getStackTraceString() + ' - ' + e.getMessage(),
                'NotificationRead_CCMobileAPI',
                requestBody
            );
        }
    }

    public class NotificationReadRequest {
        public String userId;
        public List<String> notificationId;
    }

    public class NotificationReadResponse {
        public Boolean status;
        public String message;
    }
}