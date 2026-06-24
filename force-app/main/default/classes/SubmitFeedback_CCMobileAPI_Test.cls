@isTest
public class SubmitFeedback_CCMobileAPI_Test {
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
        SubmitFeedback_CCMobileAPI.submitFeedback();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        String responseBody = RestContext.response.responseBody.toString();
       }


}