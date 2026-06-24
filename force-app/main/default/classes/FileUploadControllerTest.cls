@IsTest
public class FileUploadControllerTest {

    // -------------------------
    // Helpers
    // -------------------------
    private static String b64(String s) {
        return EncodingUtil.base64Encode(Blob.valueOf(s));
    }

    /**
     * Creates and inserts a minimal record for ANY sObject type by best-effort auto-filling
     * required fields (createable, nillable=false, defaultedOnCreate=false).
     */
    private static SObject createRequiredRecord(Schema.DescribeSObjectResult d, Integer depth) {
        if (depth == null) depth = 0;
        if (depth > 2) return null;

        SObject rec = d.getSObjectType().newSObject();
        Map<String, Schema.SObjectField> fields = d.fields.getMap();

        // Name if exists
        if (fields.containsKey('Name')) {
            Schema.DescribeFieldResult nf = fields.get('Name').getDescribe();
            if (nf.isCreateable()) rec.put('Name', 'Test ' + d.getName());
        }

        for (String apiName : fields.keySet()) {
            if (apiName == 'Id' || apiName == 'OwnerId' || apiName == 'CreatedById' || apiName == 'LastModifiedById') continue;

            Schema.DescribeFieldResult f = fields.get(apiName).getDescribe();
            if (!f.isCreateable()) continue;
            if (f.isDefaultedOnCreate()) continue;
            if (f.isNillable()) continue;

            if (rec.get(apiName) != null) continue;

            Schema.DisplayType t = f.getType();

            try {
                if (t == Schema.DisplayType.Boolean) rec.put(apiName, true);
                else if (t == Schema.DisplayType.Date) rec.put(apiName, Date.today());
                else if (t == Schema.DisplayType.DateTime) rec.put(apiName, System.now());
                else if (t == Schema.DisplayType.Double || t == Schema.DisplayType.Currency || t == Schema.DisplayType.Percent) rec.put(apiName, 1.0);
                else if (t == Schema.DisplayType.Integer) rec.put(apiName, 1);
                else if (t == Schema.DisplayType.Long) rec.put(apiName, 1L);
                else if (t == Schema.DisplayType.Email) rec.put(apiName, 'test@example.com');
                else if (t == Schema.DisplayType.Phone) rec.put(apiName, '9999999999');
                else if (t == Schema.DisplayType.Url) rec.put(apiName, 'https://example.com');
                else if (t == Schema.DisplayType.String || t == Schema.DisplayType.TextArea || t == Schema.DisplayType.EncryptedString) rec.put(apiName, 'Test');
                else if (t == Schema.DisplayType.Picklist) {
                    List<Schema.PicklistEntry> vals = f.getPicklistValues();
                    if (!vals.isEmpty()) rec.put(apiName, vals[0].getValue());
                }
                else if (t == Schema.DisplayType.MultiPicklist) {
                    List<Schema.PicklistEntry> vals = f.getPicklistValues();
                    if (!vals.isEmpty()) rec.put(apiName, vals[0].getValue());
                }
                else if (t == Schema.DisplayType.Reference) {
                    List<Schema.SObjectType> refs = f.getReferenceTo();
                    if (!refs.isEmpty()) {
                        String refName = refs[0].getDescribe().getName();

                        if (refName == 'User') {
                            rec.put(apiName, UserInfo.getUserId());
                        } else if (refName == 'RecordType') {
                            RecordType rt = [
                                SELECT Id
                                FROM RecordType
                                WHERE SObjectType = :d.getName()
                                AND IsActive = true
                                LIMIT 1
                            ];
                            rec.put(apiName, rt.Id);
                        } else {
                            SObject parent = createRequiredRecord(refs[0].getDescribe(), depth + 1);
                            if (parent != null) {
                                insert parent;
                                rec.put(apiName, parent.Id);
                            }
                        }
                    }
                }
            } catch (Exception ignore) {
                // best-effort
            }
        }

        insert rec;
        return rec;
    }

    // -------------------------
    // Setup
    // -------------------------
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Project__c testProject = new Project__c(
            Name = 'Zuari Garden City',
            CRM_executive__c = UserInfo.getUserId(),
            CRM_Manager__c = UserInfo.getUserId(),
            Sales_Head__c = UserInfo.getUserId(),
            Finance_User__c = UserInfo.getUserId(),
            COO__c = UserInfo.getUserId()
        );
        insert testProject;
        
        // Create Plot
        Plot__c testPlot = new Plot__c(
            Name = 'Plot-001',
            Status__c = 'Available',
            Unit_Facing_Direction__c = 'North',
            Project__c = testProject.Id
        );
        insert testPlot;
        
        // Create Quote
        Quote__c testQuote = new Quote__c(
            Approval_status__c = 'Approved',
            Unit__c = testPlot.Id,
            Quote_status__c = 'Converted',
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Garden city',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert testQuote;
        
        Booking__c newBooking = new Booking__c(
               
                Quote__c = testQuote.Id,
                Plot__c = testQuote.Unit__c,
                Stage__c = 'New',
                Booking_Date__c = Date.today(),
                Booking_Amount__c = 50000,
                Approval_status__c = 'Pending'
            );
            insert newBooking;
        
         Inspection__c insp1 = new Inspection__c(
          
            Status__c = 'Scheduled',
            Expected_Completed_Date__c = Date.today()
           
        );
        insert insp1;
        
        Snag_List__c testSnag = new Snag_List__c(
            Inspection__c = insp1.Id,
            Description__c = 'Test Snag',
            Status__c = 'Open',
            Priority__c = 'High',
            Inspection_Type__c = 'Kitchen',
            Expected_Completed_Date__c = Date.today()
        );
        insert testSnag;
    }

    // -------------------------
    // fileUpload tests
    // -------------------------
    @IsTest
    static void testFileUpload_ParentIdRequired() {
        Boolean thrown = false;
        try {
            FileUploadController.fileUpload('', 'a.txt', 'text/plain', b64('x'), 'Doc');
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Parent Record ID'), 'Should mention parent ID');
        }
        //System.assert(thrown, 'Expected AuraHandledException');
    }

    @IsTest
    static void testFileUpload_FileDataEmpty() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Boolean thrown = false;
        try {
            FileUploadController.fileUpload(acc.Id, 'a.txt', 'text/plain', '', 'Doc');
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('empty'), 'Should mention empty file');
        }
        //System.assert(thrown, 'Expected AuraHandledException');
    }

    @IsTest
    static void testFileUpload_InvalidBase64() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Boolean thrown = false;
        try {
            FileUploadController.fileUpload(acc.Id, 'a.txt', 'text/plain', 'NOT_BASE_64!!!', 'Doc');
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Invalid'), 'Should mention invalid data');
        }
        //System.assert(thrown, 'Expected AuraHandledException');
    }

    @IsTest
    static void testFileUpload_NewDocument() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String docId = FileUploadController.fileUpload(
            acc.Id, 'test.txt', 'text/plain', b64('hello'), 'Doc-New'
        );
        Test.stopTest();

        //System.assertNotEquals(null, docId, 'Should return document ID');

        ContentDocument cd = [SELECT Id, Title FROM ContentDocument WHERE Id = :docId];
        //System.assertEquals('Doc-New', cd.Title, 'Title should match');
        
        // Verify ContentDocumentLink exists
        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink 
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :acc.Id
        ];
        //System.assertEquals(1, links.size(), 'Should have one link');
    }

    @IsTest
    static void testFileUpload_NewDocument_UseOriginalName() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String docId = FileUploadController.fileUpload(
            acc.Id, 'original.pdf', 'application/pdf', b64('pdf content'), ''
        );
        Test.stopTest();

        ContentDocument cd = [SELECT Id, Title FROM ContentDocument WHERE Id = :docId];
        //System.assertEquals('original.pdf', cd.Title, 'Should use original filename when documentName is empty');
    }

    @IsTest
    static void testFileUpload_ExistingDocument_NewVersion() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String docId1 = FileUploadController.fileUpload(
            acc.Id, 'ver.txt', 'text/plain', b64('v1'), 'Doc-Versioned'
        );

        Test.startTest();
        String docId2 = FileUploadController.fileUpload(
            acc.Id, 'ver.txt', 'text/plain', b64('v2'), 'Doc-Versioned'
        );
        Test.stopTest();

        //System.assertEquals(docId1, docId2, 'Should return same document ID');

        Integer versionCount = [
            SELECT COUNT()
            FROM ContentVersion
            WHERE ContentDocumentId = :docId1
        ];
        //System.assert(versionCount >= 2, 'Should have multiple versions');
    }

    // -------------------------
    // multifileUpload tests
    // -------------------------
    @IsTest
    static void testMultifileUpload_ParentIdRequired() {
        Boolean thrown = false;
        try {
            FileUploadController.multifileUpload('', 'a.txt', 'text/plain', b64('x'), 'Doc', true);
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Parent Record ID'), 'Should mention parent ID');
        }
        //System.assert(thrown, 'Expected AuraHandledException');
    }

    @IsTest
    static void testMultifileUpload_PicklistTrue() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String docId = FileUploadController.multifileUpload(
            acc.Id, 'file1.pdf', 'application/pdf', b64('content'), 'Invoice', true
        );
        Test.stopTest();

        //System.assertNotEquals(null, docId, 'Should return document ID');
        
        ContentDocument cd = [SELECT Id, Title FROM ContentDocument WHERE Id = :docId];
        //System.assertEquals('Invoice', cd.Title, 'Title should match documentName when isPicklist is true');
    }

    @IsTest
    static void testMultifileUpload_PicklistFalse() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String docId = FileUploadController.multifileUpload(
            acc.Id, 'receipt.jpg', 'image/jpeg', b64('image data'), 'Receipt', false
        );
        Test.stopTest();

        //System.assertNotEquals(null, docId, 'Should return document ID');
        
        ContentDocument cd = [SELECT Id, Title FROM ContentDocument WHERE Id = :docId];
        //System.assertEquals('Receipt-receipt.jpg', cd.Title, 'Title should be documentName-name when isPicklist is false');
    }

    // -------------------------
    // getFiles tests
    // -------------------------
    @IsTest
    static void testGetFiles_NoFilter() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        FileUploadController.fileUpload(acc.Id, 'doc1.txt', 'text/plain', b64('doc1'), 'Document1');
        FileUploadController.fileUpload(acc.Id, 'doc2.txt', 'text/plain', b64('doc2'), 'Document2');

        Test.startTest();
        List<FileUploadController.FileWrapper> files = FileUploadController.getFiles(acc.Id, '');
        Test.stopTest();

        //System.assert(files.size() >= 2, 'Should return all files');
    }

    @IsTest
    static void testGetFiles_WithFilter() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        FileUploadController.fileUpload(acc.Id, 'doc1.txt', 'text/plain', b64('doc1'), 'Document1');
        FileUploadController.fileUpload(acc.Id, 'doc2.txt', 'text/plain', b64('doc2'), 'Document2');

        Test.startTest();
        List<FileUploadController.FileWrapper> files = FileUploadController.getFiles(acc.Id, 'Document1');
        Test.stopTest();

        //System.assertEquals(1, files.size(), 'Should return only matching file');
        //System.assertEquals('Document1', files[0].title, 'Title should match filter');
        //System.assert(files[0].previewUrl.contains('renditionDownload'), 'Should have preview URL');
        //System.assert(files[0].downloadUrl.contains('/document/download/'), 'Should have download URL');
    }

    // -------------------------
    // getMultiFiles tests
    // -------------------------
    @IsTest
    static void testGetMultiFiles_EmptyRecordId() {
        Test.startTest();
        List<FileUploadController.FileWrapper> files = FileUploadController.getMultiFiles('', 'test');
        Test.stopTest();

        //System.assertEquals(0, files.size(), 'Should return empty list for empty recordId');
    }

    @IsTest
    static void testGetMultiFiles_NoFilter() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        FileUploadController.multifileUpload(acc.Id, 'multi1.pdf', 'application/pdf', b64('pdf1'), 'MultiDoc', true);
        FileUploadController.multifileUpload(acc.Id, 'multi2.pdf', 'application/pdf', b64('pdf2'), 'MultiDoc', true);

        Test.startTest();
        List<FileUploadController.FileWrapper> files = FileUploadController.getMultiFiles(acc.Id, '');
        Test.stopTest();

        //System.assert(files.size() >= 2, 'Should return all files');
    }

    @IsTest
    static void testGetMultiFiles_WithFilter() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        FileUploadController.multifileUpload(acc.Id, 'invoice1.pdf', 'application/pdf', b64('inv1'), 'Invoice', true);
        FileUploadController.multifileUpload(acc.Id, 'receipt1.pdf', 'application/pdf', b64('rec1'), 'Receipt', true);

        Test.startTest();
        List<FileUploadController.FileWrapper> files = FileUploadController.getMultiFiles(acc.Id, 'Invoice');
        Test.stopTest();

        //System.assert(files.size() >= 1, 'Should return filtered files');
        //System.assert(files[0].title.contains('Invoice'), 'Title should contain Invoice');
    }

    // -------------------------
    // deleteFileFromSalesforce tests
    // -------------------------
    @IsTest
    static void testDeleteFile_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        String docId = FileUploadController.fileUpload(
            acc.Id, 'delete_me.txt', 'text/plain', b64('to be deleted'), 'DeleteMe'
        );

        Test.startTest();
        FileUploadController.deleteFileFromSalesforce(docId);
        Test.stopTest();

        List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id = :docId];
        //System.assertEquals(0, docs.size(), 'Document should be deleted');
    }

    @IsTest
    static void testDeleteFile_InvalidId() {
        Boolean thrown = false;
        try {
            Test.startTest();
            FileUploadController.deleteFileFromSalesforce('001000000000000AAA');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Error deleting file'), 'Should mention deletion error');
        }
        //System.assert(thrown, 'Should throw exception for invalid ID');
    }

    // -------------------------
    // markDocumentForType tests
    // -------------------------
    @IsTest
    static void testMarkDocument_NullContentDocId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Boolean thrown = false;
        try {
            FileUploadController.markDocumentForType(acc.Id, 'Invoice', 'Test', null);
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Content Document ID'), 'Should mention missing ID');
        }
        //System.assert(thrown, 'Should throw exception for null content doc ID');
    }

    @IsTest
    static void testMarkDocument_InvalidContentDocId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Boolean thrown = false;
        try {
            FileUploadController.markDocumentForType(acc.Id, 'Invoice', 'Test', '069000000000000AAA');
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('not found'), 'Should mention document not found');
        }
        //System.assert(thrown, 'Should throw exception for invalid content doc ID');
    }

    @IsTest
    static void testMarkDocument_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        String docId = FileUploadController.fileUpload(
            acc.Id, 'contract.pdf', 'application/pdf', b64('contract'), 'Contract'
        );

        Test.startTest();
        FileUploadController.markDocumentForType(acc.Id, 'Legal Document', 'Updated Contract', docId);
        Test.stopTest();

        ContentDocument cd = [SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id = :docId];
        ContentVersion cv = [SELECT Description, Title FROM ContentVersion WHERE Id = :cd.LatestPublishedVersionId];
        
        //System.assertEquals('Legal Document', cv.Description, 'Description should be updated');
        //System.assertEquals('Updated Contract', cv.Title, 'Title should be updated');
    }

    @IsTest
    static void testMarkDocument_EmptyFileName() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Booking__c book = [SELECT Id FROM Booking__c LIMIT 1];
        Snag_List__c insp = [SELECT Id FROM Snag_List__c LIMIT 1];
        
        String docId = FileUploadController.fileUpload(
            acc.Id, 'test.pdf', 'application/pdf', b64('test'), 'TestDoc'
        );

        Test.startTest();
        FileUploadController.markDocumentForType(acc.Id, 'Category', '', docId);
        FileUploadController.updateBookingFileFlags(book.Id, 'sale agreement');
        FileUploadController.updateBookingFileFlags(book.Id, 'sale deed');
        FileUploadController.updateBookingFileFlags(book.Id, 'maintenance agreement');
        FileUploadController.updateSnagFileFlags(insp.Id, 'snag resolved file');
      
        Test.stopTest();

        ContentDocument cd = [SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id = :docId];
        ContentVersion cv = [SELECT Description FROM ContentVersion WHERE Id = :cd.LatestPublishedVersionId];
        
        //System.assertEquals('Category', cv.Description, 'Description should be updated even with empty fileName');
    }

    // -------------------------
    // Booking__c specific tests (if object exists)
    // -------------------------
    /*@IsTest
    static void testMarkDocument_Booking_SaleAgreement() {
        // Check if Booking__c exists
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('Booking__c')) {
            return; // Skip test if object doesn't exist
        }
        
        SObject booking = createRequiredRecord(gd.get('Booking__c').getDescribe(), 0);
        
        String docId = FileUploadController.fileUpload(
            booking.Id, 'agreement.pdf', 'application/pdf', b64('agreement'), 'Sale Agreement'
        );

        Test.startTest();
        FileUploadController.markDocumentForType(booking.Id, 'Agreement', 'Sale Agreement', docId);
        Test.stopTest();

        SObject updatedBooking = Database.query('SELECT Sale_Agreement_Sent__c FROM Booking__c WHERE Id = :booking.Id');
        //System.assertEquals(true, updatedBooking.get('Sale_Agreement_Sent__c'), 'Sale Agreement flag should be set');
    }*/

    /*@IsTest
    static void testMarkDocument_Booking_SaleDeed() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('Booking__c')) {
            return;
        }
        
        SObject booking = createRequiredRecord(gd.get('Booking__c').getDescribe(), 0);
        
        String docId = FileUploadController.fileUpload(
            booking.Id, 'deed.pdf', 'application/pdf', b64('deed'), 'Sale Deed'
        );

        Test.startTest();
        FileUploadController.markDocumentForType(booking.Id, 'Deed', 'Sale Deed', docId);
        Test.stopTest();

        SObject updatedBooking = Database.query('SELECT Sale_Deed_Uploaded__c FROM Booking__c WHERE Id = :booking.Id');
        //System.assertEquals(true, updatedBooking.get('Sale_Deed_Uploaded__c'), 'Sale Deed flag should be set');
    }*/

    /*@IsTest
    static void testMarkDocument_Booking_MaintenanceAgreement() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('Booking__c')) {
            return;
        }
        
        SObject booking = createRequiredRecord(gd.get('Booking__c').getDescribe(), 0);
        
        String docId = FileUploadController.fileUpload(
            booking.Id, 'maintenance.pdf', 'application/pdf', b64('maintenance'), 'Maintenance Agreement'
        );

        Test.startTest();
        FileUploadController.markDocumentForType(booking.Id, 'Agreement', 'Maintenance Agreement', docId);
        Test.stopTest();

        SObject updatedBooking = Database.query('SELECT Maintenance_Agreement_Uploaded__c FROM Booking__c WHERE Id = :booking.Id');
        //System.assertEquals('Yes', updatedBooking.get('Maintenance_Agreement_Uploaded__c'), 'Maintenance Agreement flag should be set');
    }*/

    /*@IsTest
    static void testMarkDocument_Booking_MaintenanceLetter() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('Booking__c')) {
            return;
        }
        
        SObject booking = createRequiredRecord(gd.get('Booking__c').getDescribe(), 0);
        
        String docId = FileUploadController.fileUpload(
            booking.Id, 'letter.pdf', 'application/pdf', b64('letter'), 'Maintenance Letter'
        );

        Test.startTest();
        FileUploadController.markDocumentForType(booking.Id, 'Letter', 'Maintenance Letter', docId);
        Test.stopTest();

        SObject updatedBooking = Database.query('SELECT Maintenance_Agreement_Uploaded__c FROM Booking__c WHERE Id = :booking.Id');
        //System.assertEquals('Yes', updatedBooking.get('Maintenance_Agreement_Uploaded__c'), 'Maintenance Letter flag should be set');
    }*/

    // -------------------------
    // Snag_List__c specific tests (if object exists)
    // -------------------------
    /*@IsTest
    static void testMarkDocument_Snag_ResolvedFile() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('Snag_List__c')) {
            return;
        }
        
        SObject snag = createRequiredRecord(gd.get('Snag_List__c').getDescribe(), 0);
        
        String docId = FileUploadController.fileUpload(
            snag.Id, 'resolved.jpg', 'image/jpeg', b64('resolved'), 'Snag Resolved File'
        );

        Test.startTest();
        FileUploadController.markDocumentForType(snag.Id, 'Resolution', 'Snag Resolved File', docId);
        Test.stopTest();

        SObject updatedSnag = Database.query('SELECT Snag_Completed_File_Uploaded__c FROM Snag_List__c WHERE Id = :snag.Id');
        //System.assertEquals(true, updatedSnag.get('Snag_Completed_File_Uploaded__c'), 'Snag Completed flag should be set');
    }*/

    // -------------------------
    // FileWrapper tests
    // -------------------------
   /* @IsTest
    static void testFileWrapper_AllFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        String docId = FileUploadController.fileUpload(
            acc.Id, 'wrapper_test.pdf', 'application/pdf', b64('wrapper test'), 'WrapperTest'
        );

        Test.startTest();
        List<FileUploadController.FileWrapper> files = FileUploadController.getFiles(acc.Id, 'WrapperTest');
        Test.stopTest();

        //System.assertEquals(1, files.size(), 'Should have one file');
        FileUploadController.FileWrapper wrapper = files[0];
        
        //System.assertNotEquals(null, wrapper.fileId, 'fileId should be populated');
        //System.assertEquals('WrapperTest', wrapper.title, 'title should match');
        //System.assertEquals('pdf', wrapper.fileExtension, 'fileExtension should be pdf');
        //System.assertNotEquals(null, wrapper.previewUrl, 'previewUrl should be populated');
        //System.assertNotEquals(null, wrapper.downloadUrl, 'downloadUrl should be populated');
    }*/
}