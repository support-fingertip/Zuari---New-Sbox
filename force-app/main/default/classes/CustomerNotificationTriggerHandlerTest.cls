@isTest
public class CustomerNotificationTriggerHandlerTest {

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
    }

    @isTest
    static void testHandleAfterInsert() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];

        Test.startTest();
        Customer_Portal_Notification__c noti = new Customer_Portal_Notification__c(
            Customer_Master__c = customer.Id,
            IsActive__c = true,
            IsNotificationSent__c = false,
            Created_For_CC__c = true,
            Notification_Content__c = 'Insert test',
            Notification_Heading__c = 'Insert Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'Inserted',
            Notification_Time__c = System.now()
        );
        insert noti;
        Test.stopTest();

        List<Customer_Portal_Notification__c> notifications = [
            SELECT Id FROM Customer_Portal_Notification__c WHERE Id = :noti.Id
        ];
        System.assertEquals(1, notifications.size(), 'Notification should be inserted');
    }

    @isTest
    static void testHandleAfterInsertInactive() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];

        Test.startTest();
        Customer_Portal_Notification__c noti = new Customer_Portal_Notification__c(
            Customer_Master__c = customer.Id,
            IsActive__c = false,
            IsNotificationSent__c = false,
            Created_For_CC__c = true,
            Notification_Content__c = 'Inactive test',
            Notification_Heading__c = 'Inactive Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'Inactive',
            Notification_Time__c = System.now()
        );
        insert noti;
        Test.stopTest();

        System.assertNotEquals(null, noti.Id, 'Notification should be inserted even if inactive');
    }

    @isTest
    static void testHandleAfterInsertNotCC() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];

        Test.startTest();
        Customer_Portal_Notification__c noti = new Customer_Portal_Notification__c(
            Customer_Master__c = customer.Id,
            IsActive__c = true,
            IsNotificationSent__c = false,
            Created_For_CC__c = false,
            Notification_Content__c = 'Not CC test',
            Notification_Heading__c = 'Not CC Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'NotCC',
            Notification_Time__c = System.now()
        );
        insert noti;
        Test.stopTest();

        System.assertNotEquals(null, noti.Id, 'Notification should be inserted even if not CC');
    }

    @isTest
    static void testHandleAfterUpdate() {
        Customer_Portal_Notification__c noti = [
            SELECT Id, Updated_Status__c, IsActive__c
            FROM Customer_Portal_Notification__c LIMIT 1
        ];

        Test.startTest();
        noti.Updated_Status__c = 'Updated';
        update noti;
        Test.stopTest();

        Customer_Portal_Notification__c updatedNoti = [
            SELECT Id, Updated_Status__c FROM Customer_Portal_Notification__c WHERE Id = :noti.Id
        ];
        System.assertEquals('Updated', updatedNoti.Updated_Status__c, 'Status should be updated');
    }

    @isTest
    static void testHandleAfterUpdateNoStatusChange() {
        Customer_Portal_Notification__c noti = [
            SELECT Id, Notification_Content__c
            FROM Customer_Portal_Notification__c LIMIT 1
        ];

        Test.startTest();
        noti.Notification_Content__c = 'Modified content';
        update noti;
        Test.stopTest();

        Customer_Portal_Notification__c updatedNoti = [
            SELECT Id, Notification_Content__c FROM Customer_Portal_Notification__c WHERE Id = :noti.Id
        ];
        System.assertEquals('Modified content', updatedNoti.Notification_Content__c);
    }
}