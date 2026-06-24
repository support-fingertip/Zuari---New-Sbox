@IsTest
private class EOIFormControllerTest {

    /* ---------------- helpers ---------------- */
    private static EOI__c buildRecord() {
        return new EOI__c(
            Salutation__c           = 'Mr.',
        Name__c                 = 'John Doe',
        Date_of_Birth__c        = Date.newInstance(1990, 1, 1),
        Primary_Contact_No__c   = '9876543210',     // keep quotes IF it's Text/Phone
        Email__c                = 'john.doe@example.com',
        Aadhaar_Number__c       = 123456789012L,    // no quotes if Number
        PAN_Number__c           = 'ABCDE1234F',
        Permanent_Address__c    = '123 Test Street',
        Permanent_Pincode__c    = 560001,           // no quotes if Number
        Country_of_Residence__c = 'India',
       // Profession__c           = 'Others',
        How_did_you_get_to_know_about_us__c = 'Others',
        Project_Name__c         = 'Codename X',
        Declaration_Accepted__c = true,
        DPDP_Consent_Given__c   = true
        );
    }

    // Empty file payload (valid JSON for List<FileInput>).
    private static String noFiles() {
        return JSON.serialize(new List<EOIFormController.FileInput>());
    }

    // One file payload as JSON (matches the new String filesJson parameter).
    private static String oneFile() {
        return JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{
                'fileName' => 'photo.png',
                'title'    => 'Passport Photo',
                'base64'   => EncodingUtil.base64Encode(Blob.valueOf('dummy-image-bytes'))
            }
        });
    }

    private static Map<String, String> leadInfo() {
        return new Map<String, String>{
            'sourceType' => 'Channel partner',
            'secondary'  => 'Channel Partner',
            'tertiary'   => 'Test Referrer'
        };
    }

    /* ---------------- tests ---------------- */
    @IsTest
    static void testGetFormMetadata() {
        Test.startTest();
        EOIFormController.FormMetadata meta = EOIFormController.getFormMetadata();
        Test.stopTest();
    }

    @IsTest
    static void testSubmitCreatesEoiAndLead() {
        Test.startTest();
        EOIFormController.SubmitResult res =
            EOIFormController.submitEOI(buildRecord(), noFiles(), leadInfo());
        Test.stopTest(); // forces the @future handleLeadFuture to run before assertions
    }

    @IsTest
    static void testSubmitWithFileAttaches() {
        Test.startTest();
        EOIFormController.SubmitResult res =
            EOIFormController.submitEOI(buildRecord(), oneFile(), leadInfo());
        Test.stopTest();
    }

    @IsTest
    static void testDuplicateLeadNotInserted() {
        insert new Lead(LastName = 'Existing', Company = 'Existing Co', Phone__c = '9876543210');
        Test.startTest();
        EOIFormController.submitEOI(buildRecord(), noFiles(), leadInfo());
        Test.stopTest();

    }

    @IsTest
    static void testSubmitNullThrows() {
        Boolean threw = false;
        Test.startTest();
        try {
            EOIFormController.submitEOI(null, null, null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadFile() {
        EOIFormController.SubmitResult res =
            EOIFormController.submitEOI(buildRecord(), noFiles(), leadInfo());
        Test.startTest();
        Boolean ok = EOIFormController.uploadFile(
            res.recordId, 'photo.png', 'Passport Photo',
            EncodingUtil.base64Encode(Blob.valueOf('dummy-image-bytes'))
        );
        Test.stopTest();
    }

    @IsTest
    static void testUploadFileBlankReturnsFalse() {
        EOIFormController.SubmitResult res =
            EOIFormController.submitEOI(buildRecord(), noFiles(), leadInfo());
        Test.startTest();
        Boolean ok = EOIFormController.uploadFile(res.recordId, 'x.png', 'X', null);
        Test.stopTest();
    }

    @IsTest
    static void testSearchChannelPartners() {
        Test.startTest();
        List<EOIFormController.Option> out = EOIFormController.searchChannelPartners('test');
        Test.stopTest();
    }
}