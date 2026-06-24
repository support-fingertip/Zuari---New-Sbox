@isTest
public class NotificationRead_CCMobileAPI_Test {

    @testSetup
    static void setupData() {
        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9876543210',
            Email__c = 'test@example.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'Test Customer'
        );
        insert customer;

        Customer_Portal_Notification__c notification = new Customer_Portal_Notification__c(
            Customer_Master__c = customer.Id,
            IsActive__c = true,
            IsNotificationSent__c = true,
            Created_For_CC__c = false,
            Notification_Content__c = 'Test content',
            Notification_Heading__c = 'Test Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'New',
            Notification_Redirect_Id__c = 'TEST-REDIRECT-001',
            Notification_Time__c = System.now()
        );
        insert notification;

        Customer_Portal_Notification_Subscriber__c subscriber = new Customer_Portal_Notification_Subscriber__c(
            Customer_Master__c = customer.Id,
            Customer_Portal_Notification__c = notification.Id,
            isRead__c = false
        );
        insert subscriber;
    }

    static void setupPost(String body) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    static Customer_Master__c getCust() {
        return [SELECT Id, Name FROM Customer_Master__c LIMIT 1];
    }

    @isTest
    static void testSuccess() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","notificationId":["TEST-REDIRECT-001"]}');
        Test.startTest();
        NotificationRead_CCMobileAPI.markNotificationRead();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testEmptyNotificationIds() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","notificationId":[]}');
        Test.startTest();
        NotificationRead_CCMobileAPI.markNotificationRead();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":"","notificationId":["someid"]}');
        Test.startTest();
        NotificationRead_CCMobileAPI.markNotificationRead();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","notificationId":["someid"]}');
        Test.startTest();
        NotificationRead_CCMobileAPI.markNotificationRead();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testNullNotificationIds() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '"}');
        Test.startTest();
        NotificationRead_CCMobileAPI.markNotificationRead();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testAlreadyReadNotification() {
        Customer_Portal_Notification_Subscriber__c sub = [
            SELECT Id, isRead__c FROM Customer_Portal_Notification_Subscriber__c LIMIT 1
        ];
        sub.isRead__c = true;
        update sub;

        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","notificationId":["TEST-REDIRECT-001"]}');
        Test.startTest();
        NotificationRead_CCMobileAPI.markNotificationRead();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testNoMatchingNotifications() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","notificationId":["NON-EXISTENT-ID"]}');
        Test.startTest();
        NotificationRead_CCMobileAPI.markNotificationRead();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}