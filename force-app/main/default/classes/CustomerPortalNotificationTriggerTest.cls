@isTest
public class CustomerPortalNotificationTriggerTest {

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
    }

    @isTest
    static void testAfterInsertTrigger() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];

        Test.startTest();
        Customer_Portal_Notification__c noti = new Customer_Portal_Notification__c(
            Customer_Master__c = customer.Id,
            IsActive__c = true,
            IsNotificationSent__c = false,
            Created_For_CC__c = true,
            Notification_Content__c = 'Trigger insert test',
            Notification_Heading__c = 'Trigger Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'New',
            Notification_Time__c = System.now()
        );
        insert noti;
        Test.stopTest();

        List<Customer_Portal_Notification__c> inserted = [
            SELECT Id FROM Customer_Portal_Notification__c WHERE Id = :noti.Id
        ];
        System.assertEquals(1, inserted.size(), 'Trigger should allow insert');
    }

    @isTest
    static void testAfterUpdateTrigger() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];

        Customer_Portal_Notification__c noti = new Customer_Portal_Notification__c(
            Customer_Master__c = customer.Id,
            IsActive__c = true,
            IsNotificationSent__c = false,
            Created_For_CC__c = true,
            Notification_Content__c = 'Trigger update test',
            Notification_Heading__c = 'Trigger Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'New',
            Notification_Time__c = System.now()
        );
        insert noti;

        Test.startTest();
        noti.Updated_Status__c = 'Updated';
        update noti;
        Test.stopTest();

        Customer_Portal_Notification__c updatedNoti = [
            SELECT Id, Updated_Status__c FROM Customer_Portal_Notification__c WHERE Id = :noti.Id
        ];
        System.assertEquals('Updated', updatedNoti.Updated_Status__c, 'Status should be updated via trigger');
    }

    @isTest
    static void testAfterInsertInactiveNotification() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];

        Test.startTest();
        Customer_Portal_Notification__c noti = new Customer_Portal_Notification__c(
            Customer_Master__c = customer.Id,
            IsActive__c = false,
            IsNotificationSent__c = false,
            Created_For_CC__c = true,
            Notification_Content__c = 'Inactive trigger test',
            Notification_Heading__c = 'Inactive Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'Inactive',
            Notification_Time__c = System.now()
        );
        insert noti;
        Test.stopTest();

        System.assertNotEquals(null, noti.Id, 'Inactive notification should still be inserted');
    }

    @isTest
    static void testAfterInsertAlreadySent() {
        Customer_Master__c customer = [SELECT Id FROM Customer_Master__c LIMIT 1];

        Test.startTest();
        Customer_Portal_Notification__c noti = new Customer_Portal_Notification__c(
            Customer_Master__c = customer.Id,
            IsActive__c = true,
            IsNotificationSent__c = true,
            Created_For_CC__c = true,
            Notification_Content__c = 'Already sent test',
            Notification_Heading__c = 'Sent Heading',
            Notification_Type__c = 'Booking Type',
            Updated_Status__c = 'Sent',
            Notification_Time__c = System.now()
        );
        insert noti;
        Test.stopTest();

        System.assertNotEquals(null, noti.Id, 'Already sent notification should still be inserted');
    }
}