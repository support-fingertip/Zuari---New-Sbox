@isTest
private class MCubeCampaignQueueableTest {

    private class CampaignMock implements HttpCalloutMock {
        Boolean ok;
        CampaignMock(Boolean ok) { this.ok = ok; }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (ok) {
                res.setStatusCode(200);
                res.setBody('{"status":"success"}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error":"server error"}');
            }
            return res;
        }
    }

    private static Related_Source__c buildRecord(String phone, String name, String sourceType) {
        Related_Source__c rs = new Related_Source__c();
        rs.Phone__c       = phone;
        rs.Name__c        = name;
        rs.Customer_Name__c = name;
        rs.Country_Code__c = '+91';
        rs.Source_Type__c  = sourceType;
        rs.Is_Locked__c   = false;
        return rs;
    }

    @isTest
    static void testSuccessScenario() {

        Test.setMock(HttpCalloutMock.class, new CampaignMock(true));

        Test.startTest();
        System.enqueueJob(new MCubeCampaignQueueable(
            new List<Related_Source__c>{ buildRecord('+91 (974) 092-0241', 'Sample', 'Digital Marketing') }
        ));
        Test.stopTest();

        List<Apex_Log__c> logs = [
            SELECT Status__c, Request__c, Response__c
            FROM Apex_Log__c
            WHERE Request_Type__c LIKE 'MCubeCampaign:%'
        ];
        System.assertEquals(1, logs.size(), 'Expected one log per record');
        System.assertEquals('SUCCESS', logs[0].Status__c);
        System.assert(logs[0].Request__c.contains('"number":"9740920241"'),
            'Phone should be sanitized in payload: ' + logs[0].Request__c);
        System.assert(logs[0].Request__c.contains('"source":"Digital Marketing"'),
            'Source_Type__c should appear in payload');
    }

    @isTest
    static void testHttpFailureScenario() {

        Test.setMock(HttpCalloutMock.class, new CampaignMock(false));

        Test.startTest();
        System.enqueueJob(new MCubeCampaignQueueable(
            new List<Related_Source__c>{ buildRecord('9740920241', 'Sample', 'Referral') }
        ));
        Test.stopTest();

        Apex_Log__c log = [
            SELECT Status__c, Error_Message__c
            FROM Apex_Log__c
            WHERE Request_Type__c LIKE 'MCubeCampaign:%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('FAIL', log.Status__c);
        System.assert(log.Error_Message__c != null && log.Error_Message__c.contains('500'),
            'Error message should reference HTTP 500: ' + log.Error_Message__c);
    }

    @isTest
    static void testBlankPhoneSkipped() {

        Test.setMock(HttpCalloutMock.class, new CampaignMock(true));

        Test.startTest();
        System.enqueueJob(new MCubeCampaignQueueable(
            new List<Related_Source__c>{ buildRecord(null, 'NoPhone', 'Hoarding') }
        ));
        Test.stopTest();

        Apex_Log__c log = [
            SELECT Status__c, Error_Message__c
            FROM Apex_Log__c
            WHERE Request_Type__c LIKE 'MCubeCampaign:%'
            LIMIT 1
        ];
        System.assertEquals('SKIP', log.Status__c);
        System.assertEquals('Phone__c is blank', log.Error_Message__c);
    }
}
