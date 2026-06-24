@isTest
private class ProjectDetail_MobileAPITest {

    private static Integer counter = 0;

    private static void setField(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable())
            sob.put(field, val);
    }

    private static Channel_Partner__c createPartner(Boolean active) {
        counter++;
        String seed = String.valueOf(System.now().getTime()) + '_' + counter;
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = active);
        setField(cp, 'Name', 'CP_' + seed);
        setField(cp, 'Email__c', 'test_' + seed + '@test.com');
        setField(cp, 'User_Id__c', 'UID-PD-' + seed);
        insert cp;
        Channel_Partner__c result = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertNotEquals(null, result.User_Id__c, 'User_Id__c must be populated');
        return result;
    }

    private static Project__c createProject() {
        counter++;
        Project__c proj = new Project__c();
        setField(proj, 'Name', 'PROJ_' + System.now().getTime() + '_' + counter);
        insert proj;
        return [SELECT Id, Project_Id__c, Name FROM Project__c WHERE Id = :proj.Id];
    }

    private static Project__c createFullProject() {
        counter++;
        Project__c proj = new Project__c();
        setField(proj, 'Name', 'PROJ_FULL_' + System.now().getTime() + '_' + counter);
        setField(proj, 'Project_Address__c', '123 Test Street');
        setField(proj, 'RERA_NO__c', 'RERA12345');
        setField(proj, 'Available_Units__c', 50);
        setField(proj, 'Total_Units__c', 100);
        setField(proj, 'Starting_Price__c', '50L');
        setField(proj, 'End_Price_Range__c', '1Cr');
        setField(proj, 'Offer_Precentage__c', 10);
        setField(proj, 'Video_URL__c', 'https://video.test.com/demo');
        setField(proj, 'BHK_Type__c', '1 BHK;2 BHK;3 BHK');
        setField(proj, 'Facing__c', 'East;West;North');
        setField(proj, 'Unit_Type__c', 'Villa');
        setField(proj, 'Amenties__c', 'Private Garden');
        setField(proj, 'Project_Location__Latitude__s', 12.9716);
        setField(proj, 'Project_Location__Longitude__s', 77.5946);
        insert proj;
        return [SELECT Id, Project_Id__c, Name FROM Project__c WHERE Id = :proj.Id];
    }

    private static Commission_Slab__c createSlab(Id projectId, String criteria, Decimal factor) {
        Commission_Slab__c slab = new Commission_Slab__c(Project__c = projectId);
        if (criteria != null) setField(slab, 'Booking_Criteria__c', criteria);
        if (factor != null) setField(slab, 'Commission_Factor__c', factor);
        insert slab;
        return slab;
    }

    private static void createProjectDocuments(Id projectId) {
        List<String> titles = new List<String>{
            'Project Images', 'Project Brochure - Main', 'Floor Plans - Type A', 'Approval Document - RERA'
        };
        List<Id> cvIds = new List<Id>();
        for (String title : titles) {
            ContentVersion cv = new ContentVersion();
            cv.Title = title;
            cv.PathOnClient = title.replaceAll('[^a-zA-Z0-9]', '_') + '.pdf';
            cv.VersionData = Blob.valueOf('Test content for ' + title);
            cv.IsMajorVersion = true;
            insert cv;
            cvIds.add(cv.Id);
        }
        List<ContentVersion> insertedCVs = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id IN :cvIds];
        List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();
        for (ContentVersion cv : insertedCVs) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = projectId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            cdLinks.add(cdl);
        }
        insert cdLinks;
        Set<Id> cvIdSet = new Set<Id>(cvIds);
        Set<Id> coveredCvIds = new Set<Id>();
        for (ContentDistribution ed : [SELECT ContentVersionId FROM ContentDistribution WHERE ContentVersionId IN :cvIdSet]) {
            coveredCvIds.add(ed.ContentVersionId);
        }
        List<ContentDistribution> distsToInsert = new List<ContentDistribution>();
        for (ContentVersion cv : insertedCVs) {
            if (!coveredCvIds.contains(cv.Id)) {
                ContentDistribution dist = new ContentDistribution();
                dist.Name = cv.Title + ' Dist';
                dist.ContentVersionId = cv.Id;
                dist.PreferencesAllowViewInBrowser = true;
                dist.PreferencesLinkLatestVersion = true;
                distsToInsert.add(dist);
            }
        }
        if (!distsToInsert.isEmpty()) insert distsToInsert;
    }

    private static void mockRequest(Object payload) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProjectDetailAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @isTest static void testSuccessWithPartner() {
        Channel_Partner__c cp = createPartner(true);
        Project__c proj = createProject();
        createSlab(proj.Id, 'Test Criteria', 2.5);
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testSuccessUserIdZero() {
        Project__c proj = createProject();
        mockRequest(new Map<String, Object>{'userId' => '0', 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testSuccessFullProjectWithDocuments() {
        Channel_Partner__c cp = createPartner(true);
        Project__c proj = createFullProject();
        createSlab(proj.Id, 'Criteria A', 1.5);
        createProjectDocuments(proj.Id);
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testSuccessUserIdZeroWithDocuments() {
        Project__c proj = createFullProject();
        createProjectDocuments(proj.Id);
        mockRequest(new Map<String, Object>{'userId' => '0', 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testMultipleCommissionSlabs() {
        Channel_Partner__c cp = createPartner(true);
        Project__c proj = createProject();
        createSlab(proj.Id, 'Criteria A', 1.5);
        createSlab(proj.Id, 'Criteria B', 3.0);
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testCommissionSlabNullCriteria() {
        Channel_Partner__c cp = createPartner(true);
        Project__c proj = createProject();
        Commission_Slab__c slab = new Commission_Slab__c(Project__c = proj.Id);
        setField(slab, 'Commission_Factor__c', 2.0);
        insert slab;
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testNoCommissionSlabs() {
        Channel_Partner__c cp = createPartner(true);
        Project__c proj = createProject();
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest static void testMissingUserId() {
        Project__c proj = createProject();
        mockRequest(new Map<String, Object>{'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testMissingProjectId() {
        Channel_Partner__c cp = createPartner(true);
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testBothFieldsBlank() {
        mockRequest(new Map<String, Object>{'userId' => '', 'projectId' => ''});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testInvalidUserId() {
        Project__c proj = createProject();
        mockRequest(new Map<String, Object>{'userId' => 'FAKE123', 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testInactivePartner() {
        Channel_Partner__c cp = createPartner(false);
        Project__c proj = createProject();
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'projectId' => proj.Project_Id__c});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testProjectNotFound() {
        Channel_Partner__c cp = createPartner(true);
        mockRequest(new Map<String, Object>{'userId' => cp.User_Id__c, 'projectId' => 'FAKE_PROJECT_ID'});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testJsonError() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProjectDetailAPI/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{malformed');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testEmptyRequest() {
        mockRequest(new Map<String, Object>());
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testNullFields() {
        mockRequest(new Map<String, Object>{'userId' => null, 'projectId' => null});
        Test.startTest(); ProjectDetail_MobileAPI.getProjectDetail(); Test.stopTest();
    }

    @isTest static void testWrapperClasses() {
        ProjectDetail_MobileAPI.ProjectWrapper pw = new ProjectDetail_MobileAPI.ProjectWrapper();
        pw.userId = 'test'; pw.projectId = 'test';
        ProjectDetail_MobileAPI.ProjectLatLong latlong = new ProjectDetail_MobileAPI.ProjectLatLong();
        latlong.latitude = 12.97; latlong.longitude = 77.59;
        ProjectDetail_MobileAPI.ProjectDocument doc = new ProjectDetail_MobileAPI.ProjectDocument();
        doc.pdfName = 'test.pdf'; doc.pdfUrl = 'https://test.com';
        ProjectDetail_MobileAPI.ProjectDetailData data = new ProjectDetail_MobileAPI.ProjectDetailData();
        data.id = 'PRJ001'; data.projectImageUrl = 'https://img.test.com';
        data.projectName = 'Test Project'; data.projectStatusId = 'Active';
        data.projectAddress = '123 Test St'; data.reraNumber = 'RERA123';
        data.availableUnits = '50'; data.totalUnits = '100';
        data.startPriceRange = '50L'; data.endPriceRange = '1Cr';
        data.offerPercentage = '10'; data.videoURL = 'https://video.test.com';
        data.projectLatLong = latlong;
        data.unitTypes = new List<String>{'Apartment', 'Villa'};
        data.facingOptions = new List<String>{'East', 'West'};
        data.BHKTypes = new List<String>{'1 BHK', '2 BHK'};
        data.amenities = new List<String>{'Pool', 'Gym'};
        data.commissionSlab = new Map<String, Decimal>{'Criteria A' => 2.5};
        data.brochures = new List<ProjectDetail_MobileAPI.ProjectDocument>{doc};
        data.floorPlans = new List<ProjectDetail_MobileAPI.ProjectDocument>{doc};
        data.approvals = new List<ProjectDetail_MobileAPI.ProjectDocument>{doc};
        ProjectDetail_MobileAPI.ProjectDetailResponseWrapper res = new ProjectDetail_MobileAPI.ProjectDetailResponseWrapper();
        res.status = true; res.message = 'test'; res.data = data;
        System.assertNotEquals(null, JSON.serialize(res));
    }
}