@IsTest
private class EOIFormSiteControllerTest {

    private static String buildJson() {
        Map<String, Object> m = new Map<String, Object>{
            'Name__c'                 => 'John Doe',
            'Salutation__c'           => null,
            'Primary_Contact_No__c'   => '9876543210',
            'Email__c'                => 'john.doe@example.com',
            'Permanent_Address__c'    => '123 Test Street',
            'Country_of_Residence__c' => 'India',
            'Date_of_Birth__c'        => '1990-01-15',
            'Project_Name__c'         => 'Codename X',
            'Declaration_Accepted__c' => true,
            'DPDP_Consent_Given__c'   => true
        };
        return JSON.serialize(m);
    }

    private static String filesJsonOneImage() {
        List<Map<String, Object>> files = new List<Map<String, Object>>{
            new Map<String, Object>{
                'fileName' => 'photo.png',
                'title'    => 'Passport Photo',
                'base64'   => EncodingUtil.base64Encode(Blob.valueOf('dummy-image-bytes'))
            }
        };
        return JSON.serialize(files);
    }

    private static Id recordIdFrom(String result) {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(result);
        return (Id) String.valueOf(m.get('recordId'));
    }

    @IsTest
    static void testPicklistGetters() {
        EOIFormSiteController ctrl = new EOIFormSiteController();
        Test.startTest();
        System.assertNotEquals(null, ctrl.getSalutationOptions());
        System.assertNotEquals(null, ctrl.getProfessionOptions());
        System.assertNotEquals(null, ctrl.getQualificationOptions());
        System.assertNotEquals(null, ctrl.getIncomeOptions());
        System.assertNotEquals(null, ctrl.getPurposeOptions());
        System.assertNotEquals(null, ctrl.getHowKnowOptions());
        System.assertNotEquals(null, ctrl.getPlcOptions());
        System.assertNotEquals(null, ctrl.getAreaOptions());
        System.assertNotEquals(null, ctrl.getFacingOptions());
        System.assertNotEquals(null, ctrl.getRoadOptions());
        Test.stopTest();
    }

    @IsTest
    static void testSubmitCreatesEoiAndLead() {
        Test.startTest();
        String result = EOIFormSiteController.submitEOIRemote(buildJson(), null, null);
        Test.stopTest();

        Id recordId = recordIdFrom(result);
        System.assertNotEquals(null, recordId, 'Record Id should be returned');
        System.assertEquals(1, [SELECT COUNT() FROM EOI__c WHERE Id = :recordId], 'EOI created');

        List<Lead> leads = [SELECT Id, EOI_Collected__c FROM Lead WHERE Phone__c = '9876543210'];
        System.assertEquals(1, leads.size(), 'Lead created');
        System.assertEquals(true, leads[0].EOI_Collected__c, 'EOI_Collected__c true');
    }

    @IsTest
    static void testSubmitWithFileAttachesInSameTransaction() {
        Test.startTest();
        String result = EOIFormSiteController.submitEOIRemote(buildJson(), filesJsonOneImage(), leadJson());
        Test.stopTest();

        Id recordId = recordIdFrom(result);
        System.assertEquals(1,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :recordId],
            'File attached to the EOI in the same transaction');
    }

    @IsTest
    static void testDuplicateLeadNotInserted() {
        insert new Lead(LastName = 'Existing', Company = 'Existing Co', Phone__c = '9876543210');

        Test.startTest();
        EOIFormSiteController.submitEOIRemote(buildJson(), null, null);
        Test.stopTest();

        List<Lead> leads = [SELECT Id, EOI_Collected__c FROM Lead WHERE Phone__c = '9876543210'];
        System.assertEquals(1, leads.size(), 'No duplicate Lead');
        System.assertEquals(true, leads[0].EOI_Collected__c, 'Existing Lead flagged');
    }

    @IsTest
    static void testUploadFileRemote() {
        Id recordId = recordIdFrom(EOIFormSiteController.submitEOIRemote(buildJson(), null, null));

        Test.startTest();
        Boolean ok = EOIFormSiteController.uploadFileRemote(
            recordId, 'photo.png', 'Passport Photo',
            EncodingUtil.base64Encode(Blob.valueOf('dummy-image-bytes'))
        );
        Test.stopTest();

        System.assertEquals(true, ok, 'Upload should succeed');
    }

    @IsTest
    static void testUploadFileBlankReturnsFalse() {
        Id recordId = recordIdFrom(EOIFormSiteController.submitEOIRemote(buildJson(), null, null));
        Test.startTest();
        Boolean ok = EOIFormSiteController.uploadFileRemote(recordId, 'x.png', 'X', null);
        Test.stopTest();
        System.assertEquals(false, ok, 'Blank base64 returns false');
    }

    @IsTest
    static void testSubmitBlankThrows() {
        Boolean threw = false;
        Test.startTest();
        try {
            EOIFormSiteController.submitEOIRemote('', null, null);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw, 'Blank JSON should throw');
    }

    @IsTest
    static void testSourceMappingAndNewMethods() {
        Test.startTest();
        EOIFormSiteController.submitEOIRemote(buildJson(), null, leadJson());
        EOIFormSiteController.searchChannelPartners('a');
        EOIFormSiteController.searchChannelPartners(null);
        EOIFormSiteController.getSourceDependencyJson();
        Test.stopTest();
    }

    private static String leadJson() {
        return JSON.serialize(new Map<String, String>{
            'sourceType' => 'Channel Partner',
            'secondary'  => 'Channel Partner',
            'tertiary'   => 'Test CP Name'
        });
    }
}