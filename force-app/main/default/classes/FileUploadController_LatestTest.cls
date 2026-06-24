@isTest
public class FileUploadController_LatestTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account as parent record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test users for sharing (if needed)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser1 = new User(
            Alias = 'testu1', 
            Email = 'testuser1@test.com',
            EmailEncodingKey = 'UTF-8', 
            LastName = 'TestUser1', 
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', 
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'testuser1@test.com.test'
        );
        insert testUser1;
    }
    
    @isTest
    static void testFileUpload_Success() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        
        Test.startTest();
        String result = FileUploadController_Latest.fileUpload(
            testAccount.Id, 
            'testfile.pdf', 
            'application/pdf', 
            base64Data, 
            'Test Document'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'File should be uploaded successfully');
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testAccount.Id];
        System.assertEquals(1, links.size(), 'One ContentDocumentLink should be created');
    }
 /*   
    @isTest
    static void testFileUpload_EmptyParentId() {
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        
        Test.startTest();
        try {
            FileUploadController_Latest.fileUpload(
                null, 
                'testfile.pdf', 
                'application/pdf', 
                base64Data, 
                'Test Document'
            );
            System.assert(false, 'Should throw exception for empty parentId');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Parent Record ID is required'), 'Correct error message expected');
        }
        Test.stopTest();
    }
    */
    @isTest
    static void testMultifileUpload_Success() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test multi file content'));
        
        Test.startTest();
        String result = FileUploadController_Latest.multifileUpload(
            testAccount.Id, 
            'multifile.pdf', 
            'application/pdf', 
            base64Data, 
            'Multi Test Document', 
            false
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Multi file should be uploaded successfully');
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testAccount.Id];
        System.assert(links.size() > 0, 'ContentDocumentLink should be created');
    }
    
    @isTest
    static void testMultifileUpload_WithPicklist() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test picklist content'));
        
        Test.startTest();
        String result = FileUploadController_Latest.multifileUpload(
            testAccount.Id, 
            'picklistfile.pdf', 
            'application/pdf', 
            base64Data, 
            'Picklist Document', 
            true
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Picklist file should be uploaded successfully');
    }
    
    @isTest
    static void testGetFiles_NoFilter() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        // Upload a test file first
        FileUploadController_Latest.multifileUpload(
            testAccount.Id, 'test.pdf', 'application/pdf', base64Data, 'Test Doc', false
        );
        
        Test.startTest();
        List<FileUploadController_Latest.FileWrapper> files = FileUploadController_Latest.getFiles(testAccount.Id, null, null);
        Test.stopTest();
        
        System.assert(files.size() > 0, 'Files should be returned');
    }
 /*   
    @isTest
    static void testGetFiles_WithFileName() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        FileUploadController_Latest.multifileUpload(
            testAccount.Id, 'specific.pdf', 'application/pdf', base64Data, 'Specific Doc', false
        );
        
        Test.startTest();
        List<FileUploadController_Latest.FileWrapper> files = FileUploadController_Latest.getFiles(testAccount.Id, 'Specific Doc', null);
        Test.stopTest();
        
        System.assertEquals(1, files.size(), 'One file should match the filename filter');
    }
  */  
    @isTest
    static void testGetMultiFiles_WithPartialName() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        FileUploadController_Latest.multifileUpload(
            testAccount.Id, 'partialmatch.pdf', 'application/pdf', base64Data, 'Partial Match', false
        );
        
        Test.startTest();
        List<FileUploadController_Latest.FileWrapper> files = FileUploadController_Latest.getMultiFiles(testAccount.Id, 'Partial');
        Test.stopTest();
        
        System.assertEquals(1, files.size(), 'One file should match partial name');
    }
    
    @isTest
    static void testDeleteFileFromSalesforce_Success() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        // Upload file first
        String docId = FileUploadController_Latest.multifileUpload(
            testAccount.Id, 'delete.pdf', 'application/pdf', base64Data, 'Delete Doc', false
        );
        
        Test.startTest();
        FileUploadController_Latest.deleteFileFromSalesforce(docId);
        Test.stopTest();
        
        List<ContentDocument> remainingDocs = [SELECT Id FROM ContentDocument WHERE Id = :docId];
        System.assertEquals(0, remainingDocs.size(), 'File should be deleted');
    }
    
 /*   @isTest
    static void testDeleteFileFromSalesforce_NonExistentFile() {
        Test.startTest();
        try {
            FileUploadController_Latest.deleteFileFromSalesforce('fakeDocId');
            System.assert(false, 'Should throw exception for non-existent file');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error deleting file'), 'Correct error expected');
        }
        Test.stopTest();
    }
  */  
    @isTest
    static void testGetRelatedFilesByRecordId() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        // Upload files
        FileUploadController_Latest.multifileUpload(
            testAccount.Id, 'related1.pdf', 'application/pdf', base64Data, 'Related Doc 1', false
        );
        FileUploadController_Latest.multifileUpload(
            testAccount.Id, 'related2.pdf', 'application/pdf', base64Data, 'Related Doc 2', false
        );
        
        Test.startTest();
        Map<ID, String> fileMap = FileUploadController_Latest.getRelatedFilesByRecordId(testAccount.Id, null, null);
        Test.stopTest();
        
        System.assert(fileMap.size() > 0, 'Files should be returned in map');
    }
    
    @isTest
    static void testGetRelatedFilesByRecordId_WithFilters() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        FileUploadController_Latest.multifileUpload(
            testAccount.Id, 'filtertest.pdf', 'application/pdf', base64Data, 'Filter Test', false
        );
        
        Test.startTest();
        Map<ID, String> fileMap = FileUploadController_Latest.getRelatedFilesByRecordId(
            testAccount.Id, 'Filter', null
        );
        Test.stopTest();
        
        System.assert(fileMap.size() == 1, 'One file should match filter');
    }
}