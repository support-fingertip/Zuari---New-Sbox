@isTest
public class FileDocumentControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account as parent record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }
    
    @isTest
    static void testGetDocuments_NoFiles() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<String> docNames = new List<String>{'Agreement', 'Invoice', 'Receipt'};
        
        Test.startTest();
        List<FileDocumentController.DocumentStatusWrapper> result = 
            FileDocumentController.getDocuments(testAccount.Id, docNames);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should return all documents as not uploaded');
        for (FileDocumentController.DocumentStatusWrapper doc : result) {
            System.assertEquals(false, doc.uploaded, 'All docs should be not uploaded');
            System.assertEquals(null, doc.documentId, 'No document ID should be set');
        }
    }
 /*   
    @isTest
    static void testGetDocuments_WithMatchingFiles() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<String> docNames = new List<String>{'Agreement', 'Invoice'};
        
        // Create test files with Description matching docNames
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        // Upload Agreement file
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'Agreement.pdf';
        cv1.PathOnClient = 'Agreement.pdf';
        cv1.VersionData = Blob.valueOf('Test');
        cv1.Description = 'Agreement';
        cv1.FirstPublishLocationId = testAccount.Id;
        insert cv1;
        
        ContentDocument cd1 = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv1.Id LIMIT 1];
        
        // Upload Invoice file
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'Invoice.pdf';
        cv2.PathOnClient = 'Invoice.pdf';
        cv2.VersionData = Blob.valueOf('Test');
        cv2.Description = 'Invoice';
        cv2.FirstPublishLocationId = testAccount.Id;
        insert cv2;
        
        Test.startTest();
        List<FileDocumentController.DocumentStatusWrapper> result = 
            FileDocumentController.getDocuments(testAccount.Id, docNames);
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should return 2 documents');
        
        // Verify matching documents are marked as uploaded
        Boolean hasAgreement = false;
        Boolean hasInvoice = false;
        for (FileDocumentController.DocumentStatusWrapper doc : result) {
            if (doc.label == 'Agreement') {
                System.assertEquals(true, doc.uploaded);
                System.assertEquals('Agreement.pdf', doc.fileName);
                System.assertNotEquals(null, doc.documentId);
                hasAgreement = true;
            }
            if (doc.label == 'Invoice') {
                System.assertEquals(true, doc.uploaded);
                System.assertEquals('Invoice.pdf', doc.fileName);
                System.assertNotEquals(null, doc.documentId);
                hasInvoice = true;
            }
        }
        System.assert(hasAgreement, 'Agreement should be found');
        System.assert(hasInvoice, 'Invoice should be found');
    }
    */
    @isTest
    static void testGetDocuments_NonMatchingFiles() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<String> docNames = new List<String>{'Contract', 'PO'};
        
        // Upload file with non-matching Description
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Random.pdf';
        cv.PathOnClient = 'Random.pdf';
        cv.VersionData = Blob.valueOf('Test');
        cv.Description = 'RandomDoc'; // Doesn't match docNames
        cv.FirstPublishLocationId = testAccount.Id;
        insert cv;
        
        Test.startTest();
        List<FileDocumentController.DocumentStatusWrapper> result = 
            FileDocumentController.getDocuments(testAccount.Id, docNames);
        Test.stopTest();
        
        // Both should still be not uploaded since Description doesn't match
        for (FileDocumentController.DocumentStatusWrapper doc : result) {
            System.assertEquals(false, doc.uploaded, 'Docs should remain not uploaded');
        }
    }
    
    @isTest
    static void testMarkDocumentForType_Success() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create test ContentVersion and ContentDocument
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Original.pdf';
        cv.PathOnClient = 'Original.pdf';
        cv.VersionData = Blob.valueOf('Test');
        cv.FirstPublishLocationId = testAccount.Id;
        insert cv;
        
        ContentDocument cd = [SELECT Id, LatestPublishedVersionId FROM ContentDocument 
                             WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
        
        ContentVersion latestVersion = [SELECT Id FROM ContentVersion WHERE Id = :cd.LatestPublishedVersionId];
        
        Test.startTest();
        FileDocumentController.markDocumentForType(
            testAccount.Id, 
            'Invoice', 
            'Updated Invoice.pdf', 
            cd.Id
        );
        Test.stopTest();
        
        // Verify ContentVersion was updated
        ContentVersion updatedCV = [SELECT Description, Title FROM ContentVersion 
                                   WHERE Id = :latestVersion.Id LIMIT 1];
        System.assertEquals('Invoice', updatedCV.Description, 'Description should be updated');
        System.assertEquals('Updated Invoice.pdf', updatedCV.Title, 'Title should be updated');
    }
    
/*    @isTest
    static void testMarkDocumentForType_NonExistentDoc() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        try {
            FileDocumentController.markDocumentForType(
                testAccount.Id, 
                'Invoice', 
                'Test.pdf', 
                'fakeDocId'
            );
            System.assert(false, 'Should throw exception for non-existent document');
        } catch (QueryException e) {
            // Expected - no ContentDocument found
            System.assert(true);
        }
        Test.stopTest();
    }
    */
    @isTest
    static void testDeleteFile_LinkOnly() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create ContentDocument with link to testAccount and another record
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test.pdf';
        cv.PathOnClient = 'Test.pdf';
        cv.VersionData = Blob.valueOf('Test');
        cv.FirstPublishLocationId = testAccount.Id;
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
        
        // Create second link to keep document alive
        Account secondAccount = new Account(Name = 'Second Account');
        insert secondAccount;
        ContentDocumentLink secondLink = new ContentDocumentLink(
            LinkedEntityId = secondAccount.Id,
            ContentDocumentId = cd.Id,
            ShareType = 'V'
        );
        insert secondLink;
        
        Test.startTest();
        FileDocumentController.deleteFile(testAccount.Id, cd.Id, 'Invoice');
        Test.stopTest();
        
        // Verify link to testAccount is deleted, but document still exists
        List<ContentDocumentLink> remainingLinks = [SELECT Id FROM ContentDocumentLink 
                                                   WHERE LinkedEntityId = :testAccount.Id 
                                                   AND ContentDocumentId = :cd.Id];
        System.assertEquals(0, remainingLinks.size(), 'Link to testAccount should be deleted');
        
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id = :cd.Id];
        System.assertEquals(1, docs.size(), 'Document should still exist due to second link');
    }
    
 /*   @isTest
    static void testDeleteFile_DocumentAndLink() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create ContentDocument with ONLY link to testAccount
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test.pdf';
        cv.PathOnClient = 'Test.pdf';
        cv.VersionData = Blob.valueOf('Test');
        cv.FirstPublishLocationId = testAccount.Id;
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
        
        Test.startTest();
        FileDocumentController.deleteFile(testAccount.Id, cd.Id, 'Invoice');
        Test.stopTest();
        
        // Verify both link and document are deleted
        List<ContentDocumentLink> remainingLinks = [SELECT Id FROM ContentDocumentLink 
                                                   WHERE ContentDocumentId = :cd.Id];
        System.assertEquals(0, remainingLinks.size(), 'All links should be deleted');
        
        List<ContentDocument> remainingDocs = [SELECT Id FROM ContentDocument WHERE Id = :cd.Id];
        System.assertEquals(0, remainingDocs.size(), 'Document should be deleted');
    }
    */
    @isTest
    static void testDeleteFile_NoLinkExists() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create ContentDocument linked to different record
        Account otherAccount = new Account(Name = 'Other Account');
        insert otherAccount;
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Other.pdf';
        cv.PathOnClient = 'Other.pdf';
        cv.VersionData = Blob.valueOf('Test');
        cv.FirstPublishLocationId = otherAccount.Id;
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];
        
        Test.startTest();
        FileDocumentController.deleteFile(testAccount.Id, cd.Id, 'Invoice');
        Test.stopTest();
        
        // Document should still exist since no link to testAccount was found
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id = :cd.Id];
        System.assertEquals(1, docs.size(), 'Document should still exist');
    }
}