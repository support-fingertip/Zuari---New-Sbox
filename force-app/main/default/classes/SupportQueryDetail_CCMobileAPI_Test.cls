@isTest
public class SupportQueryDetail_CCMobileAPI_Test {

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

        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Subject__c = 'Test Query Subject',
            Description__c = 'Test query description',
            Query_Type__c = 'Documents Query',
            Query_Status__c = 'New',
            Priority__c = 'High',
            Project__c = 'Zuari Garden City'
        );
        insert cq;

        List<CRM_Comment__c> comments = new List<CRM_Comment__c>();
        comments.add(new CRM_Comment__c(
            Customer_Query__c = cq.Id,
            Comment__c = 'First reply comment',
            Comment_Added_By__c = UserInfo.getUserId(),
            Comment_Added_Time__c = System.now().addDays(-2)
        ));
        comments.add(new CRM_Comment__c(
            Customer_Query__c = cq.Id,
            Comment__c = 'Second reply comment',
            Comment_Added_By__c = UserInfo.getUserId(),
            Comment_Added_Time__c = System.now()
        ));
        insert comments;

        // Create file linked to Customer_Query__c
        ContentVersion queryFile = new ContentVersion(
            Title = 'QueryDocument',
            PathOnClient = 'QueryDocument.pdf',
            VersionData = Blob.valueOf('query file content'),
            FirstPublishLocationId = cq.Id
        );
        insert queryFile;

        // Create file linked to the first CRM_Comment__c
        ContentVersion commentFile = new ContentVersion(
            Title = 'CommentDocument',
            PathOnClient = 'CommentDocument.pdf',
            VersionData = Blob.valueOf('comment file content'),
            FirstPublishLocationId = comments[0].Id
        );
        insert commentFile;
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

    static Customer_Query__c getQuery() {
        return [SELECT Id, Name FROM Customer_Query__c LIMIT 1];
    }

    @isTest
    static void testSuccess() {
        Customer_Master__c c = getCust();
        Customer_Query__c q = getQuery();
        setupPost('{"userId":"' + c.Name + '","queryId":"' + q.Name + '"}');
        Test.startTest();
        SupportQueryDetail_CCMobileAPI.getSupportQueryDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"isQueryClose":false'), 'isQueryClose should be false for New status');
        System.assert(responseBody.contains('"isFeedbackSubmitted":false'), 'isFeedbackSubmitted should be false');
        System.assert(responseBody.contains('"queryDocName"'), 'Response should contain queryDocName');
        System.assert(responseBody.contains('"replyDocName"'), 'Response should contain replyDocName');
        System.assert(responseBody.contains('"feedback"'), 'Response should contain feedback array');
    }

    @isTest
    static void testSuccessClosedQueryWithFeedback() {
        Customer_Master__c c = getCust();
        Customer_Query__c q = getQuery();

        // Update query to Closed with feedback
        Customer_Query__c cq = [SELECT Id FROM Customer_Query__c WHERE Id = :q.Id];
        cq.Query_Status__c = 'Closed';
        cq.Feedback_Detail__c = 'Great service';
        cq.Feedback_Rating__c = 'Satisfactory';
        cq.Feedback_Submitted_Time__c = System.now();
        update cq;

        setupPost('{"userId":"' + c.Name + '","queryId":"' + q.Name + '"}');
        Test.startTest();
        SupportQueryDetail_CCMobileAPI.getSupportQueryDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('"isQueryClose":true'), 'isQueryClose should be true for Closed status');
        System.assert(responseBody.contains('"isFeedbackSubmitted":true'), 'isFeedbackSubmitted should be true');
      //  System.assert(responseBody.contains('"feedBackStarCount":Satisfactory'), 'feedBackStarCount should be 4');
        System.assert(responseBody.contains('Great service'), 'Feedback description should be present');
    }

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":"","queryId":"CQ-0001"}');
        Test.startTest();
        SupportQueryDetail_CCMobileAPI.getSupportQueryDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID","queryId":"CQ-0001"}');
        Test.startTest();
        SupportQueryDetail_CCMobileAPI.getSupportQueryDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingQueryId() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","queryId":""}');
        Test.startTest();
        SupportQueryDetail_CCMobileAPI.getSupportQueryDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testQueryNotFound() {
        Customer_Master__c c = getCust();
        setupPost('{"userId":"' + c.Name + '","queryId":"CQ-9999"}');
        Test.startTest();
        SupportQueryDetail_CCMobileAPI.getSupportQueryDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}