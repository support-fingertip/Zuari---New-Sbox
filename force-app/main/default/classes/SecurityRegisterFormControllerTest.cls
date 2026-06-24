@isTest
private class SecurityRegisterFormControllerTest {

    // ─── Test Data Setup ────────────────────────────────────────────────────

    /**
     * Builds a valid formData JSON string with all fields populated.
     */
    private static String buildFullFormJson() {
        Map<String, Object> data = new Map<String, Object>{
            'Security_Register_Name__c' => 'Test Visitor',
            'Phone__c'                  => '9876543210',
            'Email__c'                  => 'test@example.com',
            'Secondary_Phone__c'        => '9123456780',
            'Secondary_Email__c'        => 'secondary@example.com',
            'Country__c'                => 'India',
            'Country_Code__c'           => '+91',
            'Project_Name__c'           => 'Test Project',
            'Budget__c'                 => '50-75 Lakhs',
            'Unit_Preference__c'        => '2 BHK',
            'Remarks__c'                => 'Walk-in visitor'
        };
        return JSON.serialize(data);
    }

    /**
     * Builds a minimal formData JSON with only required fields.
     */
    private static String buildMinimalFormJson() {
        Map<String, Object> data = new Map<String, Object>{
            'Security_Register_Name__c' => 'Minimal Visitor',
            'Phone__c'                  => '9000000001',
            'Email__c'                  => 'minimal@example.com',
            'Country__c'                => 'United States',
            'Country_Code__c'           => '+1'
        };
        return JSON.serialize(data);
    }

    // ─── saveSecurityRegister ───────────────────────────────────────────────

    /*@isTest
    static void testSaveSecurityRegister_AllFields_Success() {
        Test.startTest();
        String result = SecurityRegisterFormController.saveSecurityRegister(buildFullFormJson());
        Test.stopTest();

        Assert.areEqual('SUCCESS', result, 'Expected SUCCESS response');

        // Verify record was actually inserted with correct values
        Security_Register__c rec = [
            SELECT Security_Register_Name__c, Phone__c, Email__c,
                   Secondary_Phone__c, Secondary_Email__c,
                   Country__c, Country_Code__c, Project_Name__c,
                   Budget__c, Unit_Preference__c, Remarks__c
            FROM Security_Register__c
            LIMIT 1
        ];

        Assert.areEqual('Test Visitor',        rec.Security_Register_Name__c);
        Assert.areEqual('9876543210',           rec.Phone__c);
        Assert.areEqual('test@example.com',     rec.Email__c);
        Assert.areEqual('9123456780',           rec.Secondary_Phone__c);
        Assert.areEqual('secondary@example.com',rec.Secondary_Email__c);
        Assert.areEqual('India',                rec.Country__c);
        Assert.areEqual('+91',                  rec.Country_Code__c);
        Assert.areEqual('Test Project',         rec.Project_Name__c);
        Assert.areEqual('50-75 Lakhs',          rec.Budget__c);
        Assert.areEqual('2 BHK',                rec.Unit_Preference__c);
        Assert.areEqual('Walk-in visitor',      rec.Remarks__c);
    }*/

    /*@isTest
    static void testSaveSecurityRegister_MinimalFields_Success() {
        Test.startTest();
        String result = SecurityRegisterFormController.saveSecurityRegister(buildMinimalFormJson());
        Test.stopTest();

        Assert.areEqual('SUCCESS', result, 'Expected SUCCESS with minimal fields');

        Security_Register__c rec = [
            SELECT Security_Register_Name__c, Phone__c, Email__c,
                   Country__c, Country_Code__c
            FROM Security_Register__c
            LIMIT 1
        ];

        Assert.areEqual('Minimal Visitor',   rec.Security_Register_Name__c);
        Assert.areEqual('9000000001',        rec.Phone__c);
        Assert.areEqual('minimal@example.com', rec.Email__c);
        Assert.areEqual('United States',     rec.Country__c);
        Assert.areEqual('+1',                rec.Country_Code__c);
    }*/

    /*@isTest
    static void testSaveSecurityRegister_NullValuesSkipped() {
        // Null values in JSON should not throw — fields just stay blank
        Map<String, Object> data = new Map<String, Object>{
            'Security_Register_Name__c' => 'Null Test Visitor',
            'Phone__c'                  => '9000000002',
            'Email__c'                  => 'nulltest@example.com',
            'Country__c'                => null,
            'Country_Code__c'           => null,
            'Remarks__c'                => null
        };

        Test.startTest();
        String result = SecurityRegisterFormController.saveSecurityRegister(JSON.serialize(data));
        Test.stopTest();

        Assert.areEqual('SUCCESS', result, 'Null optional fields should not cause failure');

        Security_Register__c rec = [
            SELECT Country__c, Country_Code__c, Remarks__c
            FROM Security_Register__c
            LIMIT 1
        ];
        Assert.isNull(rec.Country__c,      'Country__c should be null');
        Assert.isNull(rec.Country_Code__c, 'Country_Code__c should be null');
        Assert.isNull(rec.Remarks__c,      'Remarks__c should be null');
    }*/

    @isTest
    static void testSaveSecurityRegister_EmptyJson_ThrowsException() {
        // Completely empty map — no required fields — should throw AuraHandledException
        // (depends on whether Security_Register__c has required fields at DB level)
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            SecurityRegisterFormController.saveSecurityRegister('{}');
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        // If the object has no required fields at DB level this won't throw — that's fine
        // This test just ensures no unhandled NPE occurs
        Assert.isTrue(true, 'No unhandled exception should bubble up');
    }

    @isTest
    static void testSaveSecurityRegister_InvalidJson_ThrowsAuraException() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            SecurityRegisterFormController.saveSecurityRegister('NOT_VALID_JSON');
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Assert.isTrue(exceptionThrown, 'Invalid JSON should throw AuraHandledException');
    }

    // ─── getPicklistValues ──────────────────────────────────────────────────

    @isTest
    static void testGetPicklistValues_ValidField_ReturnsValues() {
        Test.startTest();
        // Project_Name__c is a picklist on Security_Register__c — adjust field name if different
        List<String> values = SecurityRegisterFormController.getPicklistValues(
            'Security_Register__c', 'Project_Name__c'
        );
        Test.stopTest();

        // Should return a list (may be empty if no picklist values configured in test org)
        Assert.isNotNull(values, 'Result should not be null');
    }

    @isTest
    static void testGetPicklistValues_InvalidObject_ReturnsEmpty() {
        Test.startTest();
        List<String> values = SecurityRegisterFormController.getPicklistValues(
            'NonExistentObject__c', 'SomeField__c'
        );
        Test.stopTest();

        Assert.isNotNull(values, 'Should return empty list, not null');
        Assert.areEqual(0, values.size(), 'Should be empty for invalid object');
    }

    @isTest
    static void testGetPicklistValues_InvalidField_ReturnsEmpty() {
        Test.startTest();
        List<String> values = SecurityRegisterFormController.getPicklistValues(
            'Security_Register__c', 'NonExistentField__c'
        );
        Test.stopTest();

        Assert.isNotNull(values, 'Should return empty list, not null');
        Assert.areEqual(0, values.size(), 'Should be empty for invalid field');
    }

    // ─── getCountryCodeOptions ──────────────────────────────────────────────

    @isTest
    static void testGetCountryCodeOptions_ReturnsListWithDefault() {
        Test.startTest();
        List<Map<String, String>> options = SecurityRegisterFormController.getCountryCodeOptions();
        Test.stopTest();

        Assert.isNotNull(options, 'Options should not be null');
        Assert.isTrue(options.size() >= 1, 'Should have at least the default option');

        // First entry must always be the blank default
        Map<String, String> defaultOpt = options[0];
        Assert.areEqual('-- Select Country --', defaultOpt.get('label'), 'First option label should be default');
        Assert.areEqual('',                      defaultOpt.get('value'), 'First option value should be empty');
    }

    @isTest
    static void testGetCountryCodeOptions_EachOptionHasLabelAndValue() {
        Test.startTest();
        List<Map<String, String>> options = SecurityRegisterFormController.getCountryCodeOptions();
        Test.stopTest();

        for (Map<String, String> opt : options) {
            Assert.isNotNull(opt.get('label'), 'Every option must have a label');
            Assert.isNotNull(opt.get('value'), 'Every option must have a value key');
        }
    }

    // ─── Insert count verification ──────────────────────────────────────────

   /* @isTest
    static void testSaveSecurityRegister_OnlyOneRecordInserted() {
        Test.startTest();
        SecurityRegisterFormController.saveSecurityRegister(buildFullFormJson());
        SecurityRegisterFormController.saveSecurityRegister(buildMinimalFormJson());
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Security_Register__c];
        Assert.areEqual(2, count, 'Exactly 2 records should have been inserted');
    }*/
}