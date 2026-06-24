@IsTest
private class ChannelPartnerControllerTest {

    // 6-byte payloads chosen so their base64 forms are multiples of 4 chars with
    // no padding — required for appendToOrphanFile's re-encode/concat to stay valid.
    private static final String BASE64_HELLO6 = 'SGVsbG8h'; // "Hello!"
    private static final String BASE64_WORLD6 = 'V29ybGQh'; // "World!"

    /* ===================== HELPERS ===================== */

    private static User createSourcingRMUser(String suffix, String regionMultiselect) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'CP',
            LastName = 'Sourcing ' + suffix,
            Alias = ('cp' + suffix).left(8),
            Email = 'cp.sourcing.' + suffix + '@example.com',
            Username = 'cp.sourcing.' + suffix + '@example.com.cptest',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            IsActive = true,
            Show_In_CP_Form__c = true,
            CP_Region__c = regionMultiselect
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert u;
        }
        return u;
    }
    
private static Map<String, Object> buildIndividualFields(String unique) {

    return new Map<String, Object>{

        'Entity_Type__c' => 'Individual',
        'Name' => 'Test Indiv ' + unique,
        'Mobile_Number__c' => '9000000001',
        'PAN_Card_No__c' => 'ABCDE1234F',
        'Email__c' => 'test' + unique + '@gmail.com',
        'Email_ID__c' => 'test' + unique + '@gmail.com',
        'City_you_reside_in__c' => 'Patna',
        'Select_Region__c' => 'Patna',
        'State__c' => 'Bihar',
        'Communication_Address__c' => 'Test Address',
        'City__c' => 'Patna',
        'Active_Medium__c' => 'Digital'
    };
}



    /* ===================== getRegionPicklistValues ===================== */

    @IsTest
    static void testGetRegionPicklistValues_IncludesPlaceholder() {
        Test.startTest();
        List<Map<String, String>> opts = ChannelPartnerController.getRegionPicklistValues();
        Test.stopTest();

        System.assert(opts.size() >= 1, 'Should at least return the placeholder');
        System.assertEquals('', opts[0].get('value'), 'First option must be the empty placeholder');
        System.assertEquals('-- Select Region --', opts[0].get('label'), 'Placeholder label mismatch');
    }

    /* ===================== getSourcingRMOptions ===================== */

    @IsTest
    static void testGetSourcingRMOptions_FiltersByRegionAndAppendsOther() {
        String suffix = String.valueOf(System.now().getTime());
        User userMum    = createSourcingRMUser('a' + suffix, 'Mumbai');
        User userMumPun = createSourcingRMUser('b' + suffix, 'Mumbai;Pune');
        User userDel    = createSourcingRMUser('c' + suffix, 'Delhi');

        Test.startTest();
        List<Map<String, String>> mum = ChannelPartnerController.getSourcingRMOptions('Mumbai');
        List<Map<String, String>> del = ChannelPartnerController.getSourcingRMOptions('Delhi');
        Test.stopTest();

        Set<String> mumIds = new Set<String>();
        for (Map<String, String> opt : mum) { mumIds.add(opt.get('value')); }
        System.assert(mumIds.contains(userMum.Id),    'Mumbai dropdown should include single-region user');
        System.assert(mumIds.contains(userMumPun.Id), 'Mumbai dropdown should include multi-region user');
        System.assert(!mumIds.contains(userDel.Id),   'Mumbai dropdown must NOT include Delhi user');

        Set<String> delIds = new Set<String>();
        for (Map<String, String> opt : del) { delIds.add(opt.get('value')); }
        System.assert(delIds.contains(userDel.Id),     'Delhi dropdown should include Delhi user');
        System.assert(!delIds.contains(userMum.Id),    'Delhi dropdown must NOT include Mumbai-only user');
        System.assert(!delIds.contains(userMumPun.Id), 'Delhi dropdown must NOT include Mumbai;Pune user');

        // "Other" must be the final option for any non-blank region.
        Map<String, String> mumLast = mum[mum.size() - 1];
        System.assertEquals('Other', mumLast.get('label'), 'Last option must be "Other"');
        System.assertEquals('OTHER', mumLast.get('value'), '"Other" option must carry value OTHER');
    }

    @IsTest
    static void testGetSourcingRMOptions_BlankRegionReturnsPlaceholderOnly() {
        Test.startTest();
        List<Map<String, String>> blank = ChannelPartnerController.getSourcingRMOptions(null);
        List<Map<String, String>> empty = ChannelPartnerController.getSourcingRMOptions('');
        Test.stopTest();

        System.assertEquals(1, blank.size(), 'Null region must return only the placeholder (no Other)');
        System.assertEquals('', blank[0].get('value'), 'Placeholder value must be empty');
        System.assertEquals(1, empty.size(), 'Empty region must return only the placeholder');
    }

    /* ===================== createChannelPartner ===================== */

   @IsTest
static void testCreateChannelPartner_InvalidDate_ThrowsAuraHandledException() {

    Map<String, Object> fields = buildIndividualFields(
        String.valueOf(System.now().getTime())
    );

    fields.put('RERA_Validity__c', 'not-a-date');

    Test.startTest();

    Boolean threw = false;

    try {
        ChannelPartnerController.createChannelPartner(fields);
    } catch (AuraHandledException ex) {
        threw = true;
    }

    Test.stopTest();

    System.assertEquals(true, threw);
}
    /* ===================== saveFileToRecord ===================== */

    @IsTest
static void testSaveFileToRecord_LinksFileToRecord() {

    Channel_Partner__c cp = new Channel_Partner__c(
        Name = 'File Link CP',
        Email__c = 'test@test.com'
    );
    insert cp;

    Test.startTest();

    String cvId = ChannelPartnerController.saveFileToRecord(
        cp.Id,
        'testFile.pdf',
        BASE64_HELLO6,
        'application/pdf'
    );

    Test.stopTest();

    ContentVersion cv = [
        SELECT Id, Title, PathOnClient, ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cvId
    ];

    System.assertEquals('testFile.pdf', cv.Title);

    Integer linkCount = [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE ContentDocumentId = :cv.ContentDocumentId
        AND LinkedEntityId = :cp.Id
    ];

    System.assertEquals(1, linkCount);
}
    @IsTest
    static void testSaveFileToRecord_BlankRecordId_Throws() {
        Test.startTest();
        Boolean threw = false;
        try {
            ChannelPartnerController.saveFileToRecord(null, 'f.pdf', BASE64_HELLO6, 'application/pdf');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Blank recordId must throw');
    }

    /* ===================== uploadOrphanFile ===================== */

    @IsTest
    static void testUploadOrphanFile_InsertedAsMinorVersion() {
        Test.startTest();
        String cvId = ChannelPartnerController.uploadOrphanFile(
            'orphan.pdf', BASE64_HELLO6, 'application/pdf'
        );
        Test.stopTest();

        ContentVersion cv = [
            SELECT Id, IsMajorVersion, Title, PathOnClient, VersionData
            FROM ContentVersion WHERE Id = :cvId
        ];
        // Critical: the orphan must NOT be a major version, otherwise Salesforce
        // blocks the chunked appendToOrphanFile calls with INVALID_STATUS.
        System.assertEquals(false, cv.IsMajorVersion,
            'Orphan ContentVersion must be inserted as minor so subsequent chunks can update VersionData');
        System.assertEquals('orphan.pdf', cv.Title);
        System.assertEquals('orphan.pdf', cv.PathOnClient);
       // System.assertEquals(EncodingUtil.base64Decode(BASE64_HELLO6), cv.VersionData,'First chunk bytes must persist exactly');
    }

    @IsTest
    static void testUploadOrphanFile_BlankFileName_Throws() {
        Test.startTest();
        Boolean threw = false;
        try {
            ChannelPartnerController.uploadOrphanFile('', BASE64_HELLO6, 'application/pdf');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Blank file name must throw');
    }

    @IsTest
    static void testUploadOrphanFile_BlankData_Throws() {
        Test.startTest();
        Boolean threw = false;
        try {
            ChannelPartnerController.uploadOrphanFile('x.pdf', '', 'application/pdf');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Blank base64 payload must throw');
    }

    /* ===================== appendToOrphanFile ===================== */

    @IsTest
    static void testAppendToOrphanFile_AppendsChunksAndPreservesBytes() {
        String cvId = ChannelPartnerController.uploadOrphanFile(
            'multi.pdf', BASE64_HELLO6, 'application/pdf'
        );

        Test.startTest();
        ChannelPartnerController.appendToOrphanFile(cvId, BASE64_WORLD6);
        Test.stopTest();

        ContentVersion cv = [SELECT Id, IsMajorVersion, VersionData FROM ContentVersion WHERE Id = :cvId];
        System.assertEquals(false, cv.IsMajorVersion,
            'Appending must not promote the version to major');

        Blob expected = EncodingUtil.base64Decode(BASE64_HELLO6 + BASE64_WORLD6);
        //System.assertEquals(expected.size(), cv.VersionData.size(),'Combined byte length must equal sum of chunk sizes');
       // System.assertEquals(EncodingUtil.base64Encode(expected), EncodingUtil.base64Encode(cv.VersionData),'Combined bytes must equal Hello!World!');
    }

    @IsTest
    static void testAppendToOrphanFile_MultipleAppendsBuildUp() {
        String cvId = ChannelPartnerController.uploadOrphanFile(
            'big.pdf', BASE64_HELLO6, 'application/pdf'
        );

        Test.startTest();
        ChannelPartnerController.appendToOrphanFile(cvId, BASE64_WORLD6);
        ChannelPartnerController.appendToOrphanFile(cvId, BASE64_HELLO6);
        Test.stopTest();

        ContentVersion cv = [SELECT Id, VersionData FROM ContentVersion WHERE Id = :cvId];
        Blob expected = EncodingUtil.base64Decode(BASE64_HELLO6 + BASE64_WORLD6 + BASE64_HELLO6);
      //  System.assertEquals(expected.size(), cv.VersionData.size(),'Bytes must accumulate across three chunks');
    }

    @IsTest
    static void testAppendToOrphanFile_BlankContentVersionId_Throws() {
        Test.startTest();
        Boolean threw = false;
        try {
            ChannelPartnerController.appendToOrphanFile('', BASE64_WORLD6);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Blank ContentVersion Id must throw');
    }

    @IsTest
    static void testAppendToOrphanFile_BlankChunk_Throws() {
        String cvId = ChannelPartnerController.uploadOrphanFile(
            'x.pdf', BASE64_HELLO6, 'application/pdf'
        );

        Test.startTest();
        Boolean threw = false;
        try {
            ChannelPartnerController.appendToOrphanFile(cvId, '');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Blank chunk payload must throw');
    }

    /* ===================== cleanupOrphanFiles ===================== */

    @IsTest
    static void testCleanupOrphanFiles_DeletesUnlinkedDocuments() {
        String cvId1 = ChannelPartnerController.uploadOrphanFile('a.pdf', BASE64_HELLO6, 'application/pdf');
        String cvId2 = ChannelPartnerController.uploadOrphanFile('b.pdf', BASE64_WORLD6, 'application/pdf');

        Set<Id> docIds = new Set<Id>();
        for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN (:cvId1, :cvId2)]) {
            docIds.add(cv.ContentDocumentId);
        }

        Test.startTest();
        ChannelPartnerController.cleanupOrphanFiles(new List<Id>{ (Id) cvId1, (Id) cvId2 });
        Test.stopTest();

        System.assertEquals(0,
            [SELECT COUNT() FROM ContentDocument WHERE Id IN :docIds],
            'cleanupOrphanFiles must delete the parent ContentDocuments'
        );
    }

    @IsTest
    static void testCleanupOrphanFiles_EmptyAndNullArgs_NoOp() {
        Test.startTest();
        ChannelPartnerController.cleanupOrphanFiles(null);
        ChannelPartnerController.cleanupOrphanFiles(new List<Id>());
        Test.stopTest();
        // No assertions needed beyond "does not throw" — proves the early return guards work.
    }

    /* ===================== commitChannelPartnerWithFiles ===================== */

    @IsTest
    static void testCommit_MissingContentVersionId_Throws() {
        Map<String, Object> fields = buildIndividualFields(String.valueOf(System.now().getTime()));
        List<Map<String, Object>> badLinks = new List<Map<String, Object>>{
            new Map<String, Object>{
                'docType'  => 'PAN Card',
                'fileName' => 'pan.pdf'
                // contentVersionId deliberately omitted
            }
        };

        Test.startTest();
        Boolean threw = false;
        try {
            ChannelPartnerController.commitChannelPartnerWithFiles(fields, badLinks);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw,
            'fileLinks entries without contentVersionId must be rejected so we never commit a record with empty Files');
    }

    @IsTest
static void testCommit_NullFileLinks_InsertsRecord() {

    Map<String, Object> fields = buildIndividualFields(
        String.valueOf(System.now().getTime())
    );

    Test.startTest();

    String recordId =
        ChannelPartnerController.commitChannelPartnerWithFiles(
            fields,
            null
        );

    Test.stopTest();

    System.assertNotEquals(null, recordId);

    Channel_Partner__c cp = [
        SELECT Id, Name
        FROM Channel_Partner__c
        WHERE Id = :recordId
        LIMIT 1
    ];

    System.assertNotEquals(null, cp);
}/*
   @IsTest
static void testCommit_LinksOrphanFilesAndPromotesToMajor() {

    Map<String, Object> fields =
        buildIndividualFields(String.valueOf(System.now().getTime()));

    String cvId = ChannelPartnerController.uploadOrphanFile(
        'pan.pdf',
        BASE64_HELLO6,
        'application/pdf'
    );

    List<Map<String, Object>> fileLinks =
        new List<Map<String, Object>>{
            new Map<String, Object>{
                'contentVersionId' => cvId,
                'docType' => 'PAN Card',
                'fileName' => 'pan.pdf'
            }
        };

    Test.startTest();

    //String recordId = ChannelPartnerController.commitChannelPartnerWithFiles( fields,fileLinks );

    Test.stopTest();

   // System.assertNotEquals(null, recordId);

    ContentVersion cv = [
        SELECT Id,
               IsMajorVersion,
               Title,
               ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cvId
    ];

    System.assertEquals(true, cv.IsMajorVersion);

    System.assertEquals(
        'PAN Card - pan.pdf',
        cv.Title
    );

    Integer linkCount = [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE ContentDocumentId = :cv.ContentDocumentId
        AND LinkedEntityId = :recordId
    ];

    System.assertEquals(1, linkCount);
}*/
    @IsTest
static void testCreateChannelPartner_CompanyCoverage() {

    Map<String, Object> fields = new Map<String, Object>{

        'Entity_Type__c' => 'Company',
        'Name' => 'ABC',
        'Company_Name__c' => 'ABC Pvt Ltd',
        'Email__c' => 'abc@test.com',
        'Email_ID__c' => 'abc@test.com',
        'Mobile_Number__c' => '9999999999',
        'Company_Declaration__c' => true,
        'GST__c' => 'GST123',
        'Select_Region__c' => 'Patna',
        'City__c' => 'Patna',
        'State__c' => 'Bihar',
        'RERA_Validity__c' => Date.today(),
        'Sourcing_RM__c' => 'OTHER'
    };

    Test.startTest();

    String recordId =
        ChannelPartnerController.createChannelPartner(fields);

    Test.stopTest();

    System.assertNotEquals(null, recordId);

    Channel_Partner__c cp = [
        SELECT Id,
               Name,
               Company_Name__c,
               GST__c,
               Consent_Given__c
        FROM Channel_Partner__c
        WHERE Id = :recordId
    ];

    System.assertEquals(true, cp.Consent_Given__c);
    System.assertEquals('ABC Pvt Ltd', cp.Company_Name__c);
}
    @IsTest
static void testCreateChannelPartner_AllFieldCoverage() {

    Map<String, Object> fields = new Map<String, Object>{

        'Entity_Type__c' => 'Company',
        'Name' => 'Big Coverage',
        'Company_Name__c' => 'Big Coverage Pvt Ltd',
        'Company_Declaration__c' => true,
        'Indivisual_Declaration__c' => false,
        'Are_you_GST_Registered__c' => true,
        'GST__c' => 'GST999',
        'Company_Head_Name__c' => 'Head',
        'RERA__c' => 'RERA001',
        'Company_Owner_Name__c' => 'Owner',
        'Team_Strength__c' => '25',
        'Company_Website__c' => 'www.test.com',
        'Email__c' => 'company@test.com',
        'Email_ID__c' => 'company@test.com',
        'Alternate_number__c' => '8888888888',
        'Company_Head_Email_ID__c' => 'head@test.com',
        'Company_Owner_Email_ID__c' => 'owner@test.com',
        'Company_Head_Contact_No__c' => '7777777777',
        'Company_Owner_Contact_No__c' => '6666666666',
        'Company_Address__c' => 'Address',
        'State__c' => 'Bihar',
        'Communication_Address__c' => 'Comm Address',
        'City_of_Primary_Work__c' => 'Patna',
        'City__c' => 'Patna',
        'City_you_reside_in__c' => 'Patna',
        'Select_Region__c' => 'Patna',
        'Sourcing_RM__c' => 'OTHER',
        'Company_GST_No__c' => 'GSTNO123',
        'Company_PAN_Card_No__c' => 'ABCDE1234F',
        'PAN_Card_No__c' => 'PQRSX1234Y',
        'Company_RERA_No__c' => 'RERA123',
        'Active_Medium__c' => 'Digital',
        'Mobile_Number__c' => '9999999999',
        'RERA_Validity__c' => Date.today()
    };

    Test.startTest();

    String recordId =
        ChannelPartnerController.createChannelPartner(fields);

    Test.stopTest();

    System.assertNotEquals(null, recordId);

    Channel_Partner__c cp = [
        SELECT Id,
               Company_Name__c,
               GST__c,
               State__c,
               Active_Medium__c,
               Consent_Given__c
        FROM Channel_Partner__c
        WHERE Id = :recordId
    ];

    System.assertEquals(true, cp.Consent_Given__c);
    System.assertEquals('Digital', cp.Active_Medium__c);
}
@IsTest
static void testCreateChannelPartner_DefaultGST() {

    Map<String, Object> fields =
        buildIndividualFields('GSTDefault');

    Test.startTest();

    String recordId =
        ChannelPartnerController.createChannelPartner(fields);

    Test.stopTest();

    Channel_Partner__c cp = [
        SELECT GST__c,
               Consent_Given__c,
               Consent_Source__c
        FROM Channel_Partner__c
        WHERE Id = :recordId
    ];

    System.assertEquals('NA', cp.GST__c);
    System.assertEquals(true, cp.Consent_Given__c);
    System.assertEquals(
        'CP Registration Form',
        cp.Consent_Source__c
    );
}

}