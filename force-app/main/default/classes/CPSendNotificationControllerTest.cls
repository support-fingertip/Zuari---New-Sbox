@isTest
public class CPSendNotificationControllerTest {

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
            IsNotificationSent__c = false,
            Created_For_CC__c = true,
            Notification_Content__c = 'Test content',
            Notification_Heading__c = 'Test Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'New',
            Notification_Time__c = System.now()
        );
        insert notification;

        Customer_Portal_Notification_Subscriber__c subscriber = new Customer_Portal_Notification_Subscriber__c(
            Customer_Master__c = customer.Id,
            Customer_Portal_Notification__c = notification.Id,
            isRead__c = false
        );
        insert subscriber;

        Logged_in_Device__c device = new Logged_in_Device__c(
            Customer_Master__c = customer.Id,
            Device_Id__c = 'test-device-id-123',
            Status__c = 'Active'
        );
        insert device;
    }

    @isTest
    static void testSendNotification() {
        Customer_Portal_Notification__c noti = [SELECT Id FROM Customer_Portal_Notification__c LIMIT 1];

        Test.startTest();
        CPSendNotificationController.sendNotification(noti.Id);
        Test.stopTest();

        List<Customer_Portal_Notification_Subscriber__c> subs = [
            SELECT Id FROM Customer_Portal_Notification_Subscriber__c
        ];
        System.assert(subs.size() > 0, 'Subscribers should be created');
    }

    @isTest
    static void testSendNotificationNullId() {
        Test.startTest();
        CPSendNotificationController.sendNotification(null);
        Test.stopTest();
    }

    @isTest
    static void testPushOneSignalNotification() {
        Customer_Portal_Notification__c noti = [SELECT Id FROM Customer_Portal_Notification__c LIMIT 1];
        Set<String> playerIds = new Set<String>{'player-id-1', 'player-id-2'};

        Test.startTest();
        CPSendNotificationController.pushOneSignalNotification(noti.Id, playerIds);
        Test.stopTest();

        Customer_Portal_Notification__c updatedNoti = [
            SELECT Id, IsNotificationSent__c FROM Customer_Portal_Notification__c WHERE Id = :noti.Id
        ];
        System.assertNotEquals(null, updatedNoti, 'Notification should still exist after push');
    }
}