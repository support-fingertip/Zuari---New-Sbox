@isTest
private class MarketingCloudOTTSenderTest {

    private class MultiMock implements HttpCalloutMock {

        Boolean tokenOk;
        Boolean sendOk;

        MultiMock(Boolean tokenOk, Boolean sendOk) {
            this.tokenOk = tokenOk;
            this.sendOk = sendOk;
        }

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('auth')) {

                if (tokenOk) {
                    res.setStatusCode(200);
                    res.setBody(
                        '{"access_token":"test-token",' +
                        '"rest_instance_url":"https://test.rest.marketingcloudapis.com/"}'
                    );
                } else {
                    res.setStatusCode(401);
                    res.setBody('{"error":"unauthorized"}');
                }

            } else {

                if (sendOk) {
                    res.setStatusCode(202);
                    res.setBody('{"requestId":"abc-123"}');
                } else {
                    res.setStatusCode(400);
                    res.setBody('{"error":"bad request"}');
                }
            }

            return res;
        }
    }

    private static User createUser() {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        Long ts = DateTime.now().getTime();

        User u = new User(
            FirstName='Test',
            LastName='Owner',
            Alias='town',
            Email='owner@test.com',
            Username='owner'+ts+'@test.com',
            CommunityNickname='owner'+ts,
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            ProfileId=p.Id,
            MobilePhone='9876543210'
        );

        insert u;
        return u;
    }

    private static Related_Source__c buildRecord(Id ownerId) {

        Related_Source__c rs = new Related_Source__c();

        rs.OwnerId = ownerId;
        rs.Phone__c = '9875747213';
        rs.Country_Code__c = '+91';
        rs.Name__c = 'DJ';
        rs.Customer_Name__c = 'DJ';

        return rs;
    }

    @isTest
    static void testSuccessScenario() {

        User ownerUser = createUser();

        Test.setMock(
            HttpCalloutMock.class,
            new MultiMock(true, true)
        );

        Test.startTest();

        System.enqueueJob(
            new MarketingCloudOTTSender(
                new List<Related_Source__c>{
                    buildRecord(ownerUser.Id)
                }
            )
        );

        Test.stopTest();

        List<Apex_Log__c> logs = [
            SELECT Status__c, Request_Type__c
            FROM Apex_Log__c
            WHERE Request_Type__c LIKE 'MarketingCloudOTTSender%'
        ];

        System.assertEquals(2, logs.size());
    }

    @isTest
    static void testTokenFailureScenario() {

        User ownerUser = createUser();

        Test.setMock(
            HttpCalloutMock.class,
            new MultiMock(false, true)
        );

        Test.startTest();

        System.enqueueJob(
            new MarketingCloudOTTSender(
                new List<Related_Source__c>{
                    buildRecord(ownerUser.Id)
                }
            )
        );

        Test.stopTest();

        Apex_Log__c log = [
            SELECT Status__c, Request_Type__c
            FROM Apex_Log__c
            WHERE Request_Type__c =
                  'MarketingCloudOTTSender:Token'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals('FAIL', log.Status__c);
    }

    @isTest
    static void testSendFailureScenario() {

        User ownerUser = createUser();

        Test.setMock(
            HttpCalloutMock.class,
            new MultiMock(true, false)
        );

        Test.startTest();

        System.enqueueJob(
            new MarketingCloudOTTSender(
                new List<Related_Source__c>{
                    buildRecord(ownerUser.Id)
                }
            )
        );

        Test.stopTest();

        Apex_Log__c log = [
            SELECT Status__c, Request_Type__c
            FROM Apex_Log__c
            WHERE Request_Type__c =
                  'MarketingCloudOTTSender:Send'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals('FAIL', log.Status__c);
    }

    @isTest
    static void testNullOwnerScenario() {

        Test.setMock(
            HttpCalloutMock.class,
            new MultiMock(true, true)
        );

        Test.startTest();

        System.enqueueJob(
            new MarketingCloudOTTSender(
                new List<Related_Source__c>{
                    buildRecord(null)
                }
            )
        );

        Test.stopTest();

        Integer countLogs = [
            SELECT COUNT()
            FROM Apex_Log__c
            WHERE Request_Type__c
            LIKE 'MarketingCloudOTTSender%'
        ];

        System.assert(countLogs > 0);
    }
}