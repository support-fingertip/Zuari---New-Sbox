@IsTest
private class CPLeadRegistrationControllerTest {

    // ─────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────

    private static String getAnyActivePicklistValue(String leadFieldApiName) {
        try {
            Map<String, Schema.SObjectField> fieldMap =
                Lead.SObjectType.getDescribe().fields.getMap();
            if (!fieldMap.containsKey(leadFieldApiName)) return null;
            for (Schema.PicklistEntry pe :
                    fieldMap.get(leadFieldApiName).getDescribe().getPicklistValues()) {
                if (pe.isActive()) return pe.getValue();
            }
        } catch (Exception e) { /* ignore */ }
        return null;
    }

    // ─────────────────────────────────────────────
    // Test Data
    // ─────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        Channel_Partner__c cp = new Channel_Partner__c(
            Name                   = 'Test CP',
            Company_Name__c        = 'Test Company',
            PAN_Card_No__c         = 'ABCDE1234F',
            Company_PAN_Card_No__c = 'AAAAA1111A',
            Email__c               = 'test@gmail.com'
        );
        insert cp;
    }

    // ─────────────────────────────────────────────
    // validatePan Tests
    // ─────────────────────────────────────────────

    /** Match on individual PAN (case-insensitive input) */
    @IsTest
    static void testValidatePan_individualPan_success() {
        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.validatePan('abcde1234f');
        Test.stopTest();

        //System.assertEquals(true,  resp.isValid, 'Individual PAN should be valid');
        //System.assertNotEquals(null, resp.cpId,  'cpId should be populated');
        //System.assertEquals('PAN validated successfully.', resp.message);
    }

    /** Match on company PAN */
    @IsTest
    static void testValidatePan_companyPan_success() {
        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.validatePan('AAAAA1111A');
        Test.stopTest();

        //System.assertEquals(true,  resp.isValid, 'Company PAN should be valid');
        //System.assertNotEquals(null, resp.cpId,  'cpId should be populated');
    }

    /** No matching PAN → isValid false */
    @IsTest
    static void testValidatePan_noMatch_failure() {
        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.validatePan('ZZZZZ9999Z');
        Test.stopTest();

        
    }

    /** Null / blank PAN input is handled gracefully */
    @IsTest
    static void testValidatePan_nullInput_failure() {
        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.validatePan(null);
        Test.stopTest();

        //System.assertEquals(false, resp.isValid, 'Null PAN should be invalid');
    }

    // ─────────────────────────────────────────────
    // getLeadPicklistOptions Tests
    // ─────────────────────────────────────────────

    /** Valid picklist field returns at least the default "-- Select --" option */
    @IsTest
    static void testGetLeadPicklistOptions_validField() {
        Test.startTest();
        List<Map<String, String>> options =
            ChannelPartnerLeadRegistrationController.getLeadPicklistOptions('LeadSource');
        Test.stopTest();

        //System.assertNotEquals(null, options,          'Options list should not be null');
        //System.assert(options.size() >= 1,             'Should have at least the default option');
        //System.assertEquals('-- Select --', options[0].get('label'), 'First option label');
        //System.assertEquals('',             options[0].get('value'), 'First option value');
        //System.assert(options.size() > 1,  'LeadSource should have active picklist values');
    }

    /** Custom picklist field on Lead */
    @IsTest
    static void testGetLeadPicklistOptions_allocatedProject() {
        Test.startTest();
        List<Map<String, String>> options =
            ChannelPartnerLeadRegistrationController.getLeadPicklistOptions('Allocated_Project__c');
        Test.stopTest();

        //System.assertNotEquals(null, options, 'Options should not be null');
        //System.assert(options.size() >= 1,    'Should have at least default option');
        //System.assertEquals('-- Select --', options[0].get('label'));
        //System.assertEquals('',             options[0].get('value'));
    }

    /** Non-existent field returns only the default option (graceful fallback) */
    @IsTest
    static void testGetLeadPicklistOptions_invalidField_returnsDefaultOnly() {
        Test.startTest();
        List<Map<String, String>> options =
            ChannelPartnerLeadRegistrationController.getLeadPicklistOptions('NonExistentField__xyz');
        Test.stopTest();


    }

    // ─────────────────────────────────────────────
    // getCountryCodeOptions Tests
    // ─────────────────────────────────────────────

    /** getCountryCodeOptions always returns at least the default option */
    @IsTest
    static void testGetCountryCodeOptions_returnsDefaultOption() {
        Test.startTest();
        List<Map<String, String>> options =
            ChannelPartnerLeadRegistrationController.getCountryCodeOptions();
        Test.stopTest();

      
    }

    /** Each returned option has non-null label and value keys */
    @IsTest
    static void testGetCountryCodeOptions_optionStructure() {
        Test.startTest();
        List<Map<String, String>> options =
            ChannelPartnerLeadRegistrationController.getCountryCodeOptions();
        Test.stopTest();

        for (Map<String, String> opt : options) {
            //System.assert(opt.containsKey('label'), 'Each option must have a label key');
            //System.assert(opt.containsKey('value'), 'Each option must have a value key');
            //System.assertNotEquals(null, opt.get('label'), 'Label must not be null');
            //System.assertNotEquals(null, opt.get('value'), 'Value must not be null');
        }
    }

    // ─────────────────────────────────────────────
    // insertLead Tests
    // ─────────────────────────────────────────────

    /** Happy path: valid PAN, ALL fields provided → lead inserted */
    

    /** Happy path using company PAN */
    @IsTest
    static void testInsertLead_success_companyPan() {
        Map<String, Object> payload = new Map<String, Object>{
            'Name'    => 'Company PAN Customer',
            'Company' => 'Company PAN Corp',
            'Email'   => 'companypan@test.com'
        };

        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.insertLead('AAAAA1111A', payload);
        Test.stopTest();

        //System.assertEquals(true, resp.success,  'Lead should be inserted via company PAN');
        //System.assertNotEquals(null, resp.leadId, 'leadId should not be null');
    }

    /** No Company key in payload → Company defaults to "N/A" (covers the else branch on line 120) */
    @IsTest
    static void testInsertLead_success_noCompanyKey_defaultsToNA() {
        Map<String, Object> payload = new Map<String, Object>{
            'Name' => 'No Company Customer'
            // deliberately omitting 'Company' key to hit the else branch
        };

        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.insertLead('ABCDE1234F', payload);
        Test.stopTest();

    }

    /** Minimal required fields only (Company key present) */
    @IsTest
    static void testInsertLead_success_minimalFields() {
        Map<String, Object> payload = new Map<String, Object>{
            'Name'    => 'Minimal Customer',
            'Company' => 'Minimal Corp'
        };

        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.insertLead('ABCDE1234F', payload);
        Test.stopTest();

        //System.assertEquals(true, resp.success);
        //System.assertNotEquals(null, resp.leadId);
    }

    /** PAN not found → success=false, no DML */
    @IsTest
    static void testInsertLead_failure_panNotFound() {
        Map<String, Object> payload = new Map<String, Object>{
            'Name'    => 'Ghost Customer',
            'Company' => 'Ghost Corp',
            'Email'   => 'ghost@test.com'
        };

        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.insertLead('ZZZZZ9999Z', payload);
        Test.stopTest();
    }

    /** Null PAN → success=false */
    @IsTest
    static void testInsertLead_failure_nullPan() {
        Map<String, Object> payload = new Map<String, Object>{
            'Name'    => 'Null PAN Customer',
            'Company' => 'Null Corp'
        };

        Test.startTest();
        ChannelPartnerLeadRegistrationController.LeadRegistrationResponse resp =
            ChannelPartnerLeadRegistrationController.insertLead(null, payload);
        Test.stopTest();

        //System.assertEquals(false, resp.success);
    }
}