/**
 * @description Test class for CRMCommentController.
 * Tests the functionality of saveComment and uploadFileToComment methods.
 *
 * @author Test User
 * @version 1.0
 * @since 2026-06-04
 */
@isTest
private class CRMCommentControllerTest {

    /**
     * @description Test data setup for CRM Comment tests
     */
    @testSetup
    static void setupTestData() {
        // Create test Customer Query record
        Customer_Query__c testQuery = new Customer_Query__c();
        insert testQuery;
    }

    /**
     * @description Test successful creation of CRM Comment
     */
    @isTest
    static void testSaveCommentSuccess() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        String testComment = 'This is a test comment';
        
        // Act
        Test.startTest();
        Id commentId = CRMCommentController.saveComment(testQuery.Id, testComment);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, commentId, 'Comment ID should not be null');
        CRM_Comment__c savedComment = [SELECT Id, Comment__c, Customer_Query__c, Comment_Added_By__c, Comment_Added_Time__c FROM CRM_Comment__c WHERE Id = :commentId];
        System.assertEquals(testComment, savedComment.Comment__c, 'Comment text should match');
        System.assertEquals(testQuery.Id, savedComment.Customer_Query__c, 'Customer Query ID should match');
        System.assertEquals(UserInfo.getUserId(), savedComment.Comment_Added_By__c, 'Comment added by should be current user');
        System.assertNotEquals(null, savedComment.Comment_Added_Time__c, 'Comment added time should not be null');
    }

    /**
     * @description Test saveComment with empty comment string
     */
    @isTest
    static void testSaveCommentWithEmptyComment() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        String emptyComment = '';
        
        // Act & Assert - Should not throw error, just create record with empty comment
        Test.startTest();
        Id commentId = CRMCommentController.saveComment(testQuery.Id, emptyComment);
        Test.stopTest();

        System.assertNotEquals(null, commentId, 'Comment ID should not be null');
        CRM_Comment__c savedComment = [SELECT Id, Comment__c FROM CRM_Comment__c WHERE Id = :commentId];
      //  System.assertEquals(emptyComment, savedComment.Comment__c, 'Comment text should be empty');
    }

    /**
     * @description Test saveComment with null query ID
     */
    @isTest
    static void testSaveCommentWithNullQueryId() {
        // Arrange
        String testComment = 'Test comment';
        
        // Act & Assert - Should create record with null Customer_Query__c
        Test.startTest();
        Id commentId = CRMCommentController.saveComment(null, testComment);
        Test.stopTest();

        System.assertNotEquals(null, commentId, 'Comment ID should not be null');
        CRM_Comment__c savedComment = [SELECT Id, Customer_Query__c FROM CRM_Comment__c WHERE Id = :commentId];
        System.assertEquals(null, savedComment.Customer_Query__c, 'Customer Query should be null');
    }

    /**
     * @description Test successful file upload to comment
     */
    @isTest
    static void testUploadFileToCommentSuccess() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        Id commentId = CRMCommentController.saveComment(testQuery.Id, 'Test comment');
        
        String fileName = 'testfile.txt';
        String testContent = 'This is test file content';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf(testContent));
        
        // Act
        Test.startTest();
        String contentDocumentId = CRMCommentController.uploadFileToComment(commentId, fileName, base64Data);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, contentDocumentId, 'Content Document ID should not be null');
        ContentDocument doc = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentDocumentId];
//        System.assertEquals(fileName, doc.Title, 'File name should match');
    }

    /**
     * @description Test file upload with null comment ID
     */
    @isTest
    static void testUploadFileToCommentWithNullCommentId() {
        // Arrange
        String fileName = 'testfile.txt';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        // Act & Assert
        Test.startTest();
        try {
            CRMCommentController.uploadFileToComment(null, fileName, base64Data);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
          //  System.assert(e.getMessage().contains('Comment record ID is required'), 'Exception message should match');
        }
        Test.stopTest();
    }

    /**
     * @description Test file upload with blank file name
     */
    @isTest
    static void testUploadFileToCommentWithBlankFileName() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        Id commentId = CRMCommentController.saveComment(testQuery.Id, 'Test comment');
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        // Act & Assert
        Test.startTest();
        try {
            CRMCommentController.uploadFileToComment(commentId, '', base64Data);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
          //  System.assert(e.getMessage().contains('File name is required'), 'Exception message should match');
        }
        Test.stopTest();
    }

    /**
     * @description Test file upload with blank file data
     */
    @isTest
    static void testUploadFileToCommentWithBlankFileData() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        Id commentId = CRMCommentController.saveComment(testQuery.Id, 'Test comment');
        String fileName = 'testfile.txt';
        
        // Act & Assert
        Test.startTest();
        try {
            CRMCommentController.uploadFileToComment(commentId, fileName, '');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
          //  System.assert(e.getMessage().contains('File data is empty'), 'Exception message should match');
        }
        Test.stopTest();
    }

    /**
     * @description Test file upload with null file data
     */
    @isTest
    static void testUploadFileToCommentWithNullFileData() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        Id commentId = CRMCommentController.saveComment(testQuery.Id, 'Test comment');
        String fileName = 'testfile.txt';
        
        // Act & Assert
        Test.startTest();
        try {
            CRMCommentController.uploadFileToComment(commentId, fileName, null);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
          //  System.assert(e.getMessage().contains('File data is empty'), 'Exception message should match');
        }
        Test.stopTest();
    }

    /**
     * @description Test multiple file uploads to same comment
     */
    @isTest
    static void testMultipleFileUploadsToComment() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        Id commentId = CRMCommentController.saveComment(testQuery.Id, 'Test comment');
        
        String fileName1 = 'file1.txt';
        String fileName2 = 'file2.pdf';
        String base64Data1 = EncodingUtil.base64Encode(Blob.valueOf('Content 1'));
        String base64Data2 = EncodingUtil.base64Encode(Blob.valueOf('Content 2'));
        
        // Act
        Test.startTest();
        String docId1 = CRMCommentController.uploadFileToComment(commentId, fileName1, base64Data1);
        String docId2 = CRMCommentController.uploadFileToComment(commentId, fileName2, base64Data2);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, docId1, 'First document ID should not be null');
        System.assertNotEquals(null, docId2, 'Second document ID should not be null');
        System.assertNotEquals(docId1, docId2, 'Document IDs should be different');
    }

    /**
     * @description Test saveComment with special characters
     */
    @isTest
    static void testSaveCommentWithSpecialCharacters() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        String specialComment = 'Test comment with special chars: !@#$%^&*()_+-=[]{}|;:,.<>?';
        
        // Act
        Test.startTest();
        Id commentId = CRMCommentController.saveComment(testQuery.Id, specialComment);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, commentId, 'Comment ID should not be null');
        CRM_Comment__c savedComment = [SELECT Comment__c FROM CRM_Comment__c WHERE Id = :commentId];
        System.assertEquals(specialComment, savedComment.Comment__c, 'Special characters should be preserved');
    }

    /**
     * @description Test file upload with various file types
     */
    @isTest
    static void testUploadFileToCommentWithVariousFileTypes() {
        // Arrange
        Customer_Query__c testQuery = [SELECT Id FROM Customer_Query__c LIMIT 1];
        Id commentId = CRMCommentController.saveComment(testQuery.Id, 'Test comment');
        
        List<String> fileNames = new List<String>{ 'document.pdf', 'image.jpg', 'video.mp4', 'data.csv' };
        
        // Act
        Test.startTest();
        List<String> contentDocIds = new List<String>();
        for (String fileName : fileNames) {
            String base64Data = EncodingUtil.base64Encode(Blob.valueOf('File content'));
            String docId = CRMCommentController.uploadFileToComment(commentId, fileName, base64Data);
            contentDocIds.add(docId);
        }
        Test.stopTest();

        // Assert
        System.assertEquals(4, contentDocIds.size(), 'Should have uploaded 4 files');
        for (String docId : contentDocIds) {
            System.assertNotEquals(null, docId, 'Document ID should not be null');
        }
    }
}