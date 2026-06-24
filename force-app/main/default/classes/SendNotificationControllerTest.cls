@IsTest
public class SendNotificationControllerTest {

    @TestSetup
    static void setup() {
        // Create and insert a valid Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Channel Partner',
            Email__c = 'test@example.com', // make sure Email__c is writable in your org
            Active__c = true
        );
        insert cp;
        
        // Create and insert Notification__c record (ensure the fields are writable)
        Notification__c notification = new Notification__c(
           
            Notification_Content__c = 'Test content',
            IsActive__c = true,
            IsNotificationSent__c = false,
           
            Notification_Time__c = System.now(),
            Notification_Category__c = 'User Specific',
            Channel_Partner__c = cp.Id  // Use the actual ID of the created Channel Partner
        );
        insert notification;
    }

    @IsTest
    static void test_sendNotification_withValidRecord() {
        // Get the Notification Id (we will pass this into the controller)
        Notification__c notification = [SELECT Id FROM Notification__c LIMIT 1];

        Test.startTest();
        // Call the sendNotification method with a valid recordId
        SendNotificationController.sendNotification(notification.Id);
        Test.stopTest();

        // If we reached this point without errors, the method executed successfully.
        // You can add further checks as needed (mocking callouts, etc.)
    }

    @IsTest
    static void test_sendNotification_withNullRecordId() {
        // Calling sendNotification with null recordId to see how the method handles it
        Test.startTest();
        SendNotificationController.sendNotification(null);
        Test.stopTest();
        // No exception should be thrown, we are covering this "path"
    }
/*
    @IsTest
    static void test_pushOneSignalNotification() {
        // Mock notification and player IDs
        Notification__c notification = new Notification__c(
           
            IsActive__c = true,
            IsNotificationSent__c = false,
            Notification_Content__c = 'Test content for OneSignal',
           
            Notification_Time__c = System.now(),
            Notification_Category__c = 'User Specific',
            Channel_Partner__c = 'some-channel-partner-id'  // You should use a real Channel Partner Id
        );
        insert notification;

        Set<String> mockPlayerIds = new Set<String>{'mock-player-id-1', 'mock-player-id-2'};

        Test.startTest();
        // Calling the future method (this is where the HTTP callout is made)
        SendNotificationController.pushOneSignalNotification(notification.Id, mockPlayerIds);
        Test.stopTest();

        // If the code reaches here without error, it's an indication the method ran.
        // Further assertions would need to mock the HTTP callout (covered in next part).
    }

    // Mocking the callout using HttpCalloutMock
        @IsTest
    static void test_pushOneSignalNotification_callout() {
        // Implement the HttpCalloutMock to simulate the response from OneSignal
        Test.setMock(HttpCalloutMock.class, new OneSignalMockResponse());

        // Proceed with test like normal
        test_pushOneSignalNotification();
    }

    // Mock response class for OneSignal
    class OneSignalMockResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"mock-id"}');
            res.setStatusCode(200);
            return res;
        }
    }*/
}