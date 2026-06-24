@IsTest(SeeAllData=false)
private class PortalLeadInsertAPIControllerTest {

    // Setup a basic valid request body with all fields
    private static String getValidRequestBody(String source, Boolean consentStatus) {
        PortalLeadInsertAPIController.leadWrapper wrapper = new PortalLeadInsertAPIController.leadWrapper();
        wrapper.lastName = 'Test Lead';
        wrapper.source = source;
        wrapper.subSource = 'Website';
        wrapper.mobile = '9876543210';
        wrapper.email = 'test@example.com';
        wrapper.project = 'Project X';
        wrapper.campaign = 'Campaign A';
        wrapper.description = 'Test description';
        wrapper.utmSource = 'google';
        wrapper.utmMedium = 'cpc';
        wrapper.utmCampaign = 'spring_sale';
        wrapper.utmAdgroup = 'group1';
        wrapper.utmTerm = 'apartment';
        wrapper.utmPlacment = 'banner';
        wrapper.utmDevice = 'mobile';
        wrapper.chatConversation = 'Chat log';
        wrapper.sourceOfConsent = 'Website Form';
        wrapper.consetStatus = consentStatus;
        return JSON.serialize(wrapper);
    }

    // Helper to set up RestContext before calling the method
    private static void setRestContext(String jsonBody) {
        RestRequest req = new RestRequest();
        req.requestUri = '/portalLead/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void testCreateLeadSuccessAllFields() {
        String jsonBody = getValidRequestBody('OtherPortal', true);
        setRestContext(jsonBody);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();

    }

    @IsTest
    static void testCreateLeadSuccessDigitalMarketingSource() {
        // Test with MagicBricks (same logic applies to 99 Acres and Housing.com)
        String jsonBody = getValidRequestBody('MagicBricks', false);
        setRestContext(jsonBody);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();

    }

    @IsTest
    static void testCreateLeadSuccess99Acres() {
        String jsonBody = getValidRequestBody('99 Acres', false);
        setRestContext(jsonBody);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();
    }

    @IsTest
    static void testCreateLeadSuccessHousingDotCom() {
        String jsonBody = getValidRequestBody('Housing.com', false);
        setRestContext(jsonBody);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();

    }

    @IsTest
    static void testCreateLeadSuccessConsentTrue() {
        String jsonBody = getValidRequestBody('OtherPortal', true);
        setRestContext(jsonBody);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();

    }

    @IsTest
    static void testCreateLeadSuccessConsentFalse() {
        String jsonBody = getValidRequestBody('OtherPortal', false);
        setRestContext(jsonBody);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();

    }

    @IsTest
    static void testCreateLeadSuccessConsentNull() {
        // When consentStatus is null (omitted), should default to false
        PortalLeadInsertAPIController.leadWrapper wrapper = new PortalLeadInsertAPIController.leadWrapper();
        wrapper.lastName = 'Test';
        wrapper.email = 'test@test.com';
        wrapper.source = 'SomeSource';
        wrapper.consetStatus = null; // explicit null
        String jsonBody = JSON.serialize(wrapper);
        setRestContext(jsonBody);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();

    }

    @IsTest
    static void testCreateLeadMissingLastName() {
        // Missing lastName will cause a DML exception (required field)
        PortalLeadInsertAPIController.leadWrapper wrapper = new PortalLeadInsertAPIController.leadWrapper();
        wrapper.lastName = null; // no last name
        wrapper.email = 'test@test.com';
        wrapper.source = 'Portal';
        String jsonBody = JSON.serialize(wrapper);
        setRestContext(jsonBody);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();

    }

    @IsTest
    static void testCreateLeadInvalidJson() {
        // Invalid JSON format triggers JSONException
        String invalidJson = '{"lastName": "Test", "source": "Portal", "email": "test@test.com",}'; // trailing comma
        setRestContext(invalidJson);

        Test.startTest();
        PortalLeadInsertAPIController.createTaskForLead();
        Test.stopTest();

    }
}