/**
 * I use to  HttpCalloutMock in this Test Class:
 * ----------------------------------------------
 * 1. Salesforce blocks real HTTP callouts in tests (CalloutException).
 * 2. WhatsAppBulkSender does callouts, so without a mock → tests fail.
 * 3. Mock lets us fake API replies (200 OK, 500 Error, Bad JSON).
 * 4. This way we test ALL logic branches reliably, without needing the real API.
 *
 * Mock = Fake API reply used only in test classes.
 */

@isTest
public class WhatsAppBulkSenderTest {
    
    // --- Mock for Success case (200 OK) ---
    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message_id":{"messages":[{"id":"MSG123","message_status":"sent"}]}}');
            return res;
        }
    }
    
    // --- Mock for Failure case (500 Error) ---
    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Server Error"}');
            return res;
        }
    }
    
    // --- Mock for Bad JSON case ---
    private class BadJsonMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('INVALID_JSON');
            return res;
        }
    }

    @isTest
    static void testSuccessCase() {
        Lead l = new Lead(LastName = 'Test', Company = 'TestCompany', Phone__c = '9876543210');
        insert l;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        System.enqueueJob(new WhatsAppBulkSender(new List<Lead>{ l }));
        Test.stopTest();

        Lead updatedLead = [SELECT WhatsApp_Message_Id__c, WhatsApp_Message_Status__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals('MSG123', updatedLead.WhatsApp_Message_Id__c);
        System.assertEquals('sent', updatedLead.WhatsApp_Message_Status__c);

        Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('SUCCESS', log.Status__c);
    }

    @isTest
    static void testFailureCase() {
        Lead l = new Lead(LastName = 'Fail', Company = 'TestCompany', Phone__c = '9876543211');
        insert l;

        Test.setMock(HttpCalloutMock.class, new FailureMock());
        Test.startTest();
        System.enqueueJob(new WhatsAppBulkSender(new List<Lead>{ l }));
        Test.stopTest();

        Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('FAIL', log.Status__c);
    }

    @isTest
    static void testBadJsonCase() {
        Lead l = new Lead(LastName = 'BadJson', Company = 'TestCompany', Phone__c = '9876543212');
        insert l;

        Test.setMock(HttpCalloutMock.class, new BadJsonMock());
        Test.startTest();
        System.enqueueJob(new WhatsAppBulkSender(new List<Lead>{ l }));
        Test.stopTest();

        Apex_Log__c log = [SELECT Status__c FROM Apex_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('FAIL', log.Status__c);
    }

    
}