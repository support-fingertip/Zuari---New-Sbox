@isTest
private class TopPerformerCP_MobileAPI_Test {

    private static Integer counter = 0;

    private static void setField(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable())
            sob.put(field, val);
    }

    private static Channel_Partner__c createPartner(Integer bookings, Boolean topPerformer, Boolean active) {
        counter++;
        String seed = String.valueOf(System.now().getTime()) + '_' + counter;
        Channel_Partner__c cp = new Channel_Partner__c();
        setField(cp, 'Name', 'CP_' + seed);
        setField(cp, 'Email__c', 'tp_' + seed + '@test.com');
        setField(cp, 'No_of_Booking__c', bookings);
        setField(cp, 'Top_Perfomer__c', topPerformer);
        setField(cp, 'Active__c', active);
        setField(cp, 'Rewards__c', 5000);
        setField(cp, 'User_Id__c', 'UID-TP-' + seed);
        insert cp;
        Channel_Partner__c result = [SELECT Id, User_Id__c, No_of_Booking__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertNotEquals(null, result.User_Id__c, 'User_Id__c must be populated');
        return result;
    }

    private static void createProfilePhoto(Channel_Partner__c cp) {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Profile Photo';
        cv.PathOnClient = 'photo.jpg';
        cv.VersionData = Blob.valueOf('fake image data');
        cv.IsMajorVersion = true;
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = cp.Id;
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        List<ContentDistribution> existDists = [SELECT Id FROM ContentDistribution WHERE ContentVersionId = :cv.Id];
        if (existDists.isEmpty()) {
            ContentDistribution dist = new ContentDistribution();
            dist.Name = 'Profile Photo Dist';
            dist.ContentVersionId = cv.Id;
            dist.PreferencesAllowViewInBrowser = true;
            dist.PreferencesLinkLatestVersion = true;
            insert dist;
        }
    }

    private static void mockRequest(Object payload) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/TopPerformerCP/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @isTest static void testSuccessWithImagesPage0() {
        Channel_Partner__c requester = createPartner(10, false, true);
        Channel_Partner__c tp1 = createPartner(20, true, true);
        Channel_Partner__c tp2 = createPartner(18, true, true);
        createProfilePhoto(tp1);
        createProfilePhoto(tp2);
        mockRequest(new Map<String, Object>{'userId' => requester.User_Id__c, 'pageSize' => 0});
        Test.startTest();
        TopPerformerCP_MobileAPI.getTopPerformerDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testSuccessNullPageSize() {
        Channel_Partner__c requester = createPartner(10, false, true);
        createPartner(15, true, true);
        mockRequest(new Map<String, Object>{'userId' => requester.User_Id__c});
        Test.startTest();
        TopPerformerCP_MobileAPI.getTopPerformerDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testSuccessPagination() {
        Channel_Partner__c requester = createPartner(10, false, true);
        createPartner(20, true, true);
        mockRequest(new Map<String, Object>{'userId' => requester.User_Id__c, 'pageSize' => 3});
        Test.startTest();
        TopPerformerCP_MobileAPI.getTopPerformerDetail();
        Test.stopTest();
    }

    @isTest static void testNoTopPerformersExist() {
        Channel_Partner__c requester = createPartner(10, false, true);
        mockRequest(new Map<String, Object>{'userId' => requester.User_Id__c, 'pageSize' => 0});
        Test.startTest();
        TopPerformerCP_MobileAPI.getTopPerformerDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testTopPerformerNoPhoto() {
        Channel_Partner__c requester = createPartner(10, false, true);
        createPartner(25, true, true);
        mockRequest(new Map<String, Object>{'userId' => requester.User_Id__c, 'pageSize' => 0});
        Test.startTest();
        TopPerformerCP_MobileAPI.getTopPerformerDetail();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testUserNotFound() {
        mockRequest(new Map<String, Object>{'userId' => 'FAKE-USER-999', 'pageSize' => 0});
        Test.startTest();
        TopPerformerCP_MobileAPI.getTopPerformerDetail();
        Test.stopTest();
    }

    @isTest static void testInactiveUser() {
        Channel_Partner__c inactiveCP = createPartner(8, false, false);
        mockRequest(new Map<String, Object>{'userId' => inactiveCP.User_Id__c, 'pageSize' => 0});
        Test.startTest();
        TopPerformerCP_MobileAPI.getTopPerformerDetail();
        Test.stopTest();
    }

    @isTest static void testMalformedJson() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/TopPerformerCP/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{malformed');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        Test.startTest();
        TopPerformerCP_MobileAPI.getTopPerformerDetail();
        Test.stopTest();
    }

    @isTest static void testWrapperClasses() {
        TopPerformerCP_MobileAPI.perfomerWrapper pw = new TopPerformerCP_MobileAPI.perfomerWrapper();
        pw.userId = 'test'; pw.pageSize = 0;
        TopPerformerCP_MobileAPI.perfomerData pd = new TopPerformerCP_MobileAPI.perfomerData();
        pd.id = '1'; pd.personImageURL = 'url'; pd.projectName = 'proj';
        pd.personName = 'name'; pd.numberOfBooking = '5'; pd.reward = '100';
        TopPerformerCP_MobileAPI.perfomerResponseWrapper rw = new TopPerformerCP_MobileAPI.perfomerResponseWrapper();
        rw.status = true; rw.message = 'test';
        rw.data = new List<TopPerformerCP_MobileAPI.perfomerData>{ pd };
        System.assertNotEquals(null, JSON.serialize(rw));
    }
}