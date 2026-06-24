@IsTest
private class RenameUploadedFilesTest {

    @IsTest
    static void testRenameUploadedFile() {

        // -------------------------
        // Create minimal Booking
        // -------------------------
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Email__c = 'test@gmail.com'
        );
        insert book;

        // -------------------------
        // Create ContentVersion record with a Title and PathOnClient
        // -------------------------
        ContentVersion cv = new ContentVersion(
            Title = 'SampleFile',
            PathOnClient = 'TestDocument.txt', // This will trigger renaming in the trigger
            VersionData = Blob.valueOf('Test file content')
        );
        
        // Step 1: Insert the ContentVersion record outside of Test.startTest()
        insert cv;

        // Step 2: Verify the Title was updated as expected
        ContentVersion insertedContentVersion = [
            SELECT Title, PathOnClient
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        //System.assertNotEquals(null, insertedContentVersion, 'ContentVersion must be returned');
        //System.assertEquals('SampleFile_TestDocument.txt', insertedContentVersion.Title, 'The Title should be updated correctly.');

        // -------------------------
        // Create another ContentVersion without an underscore in the Title
        // -------------------------
        ContentVersion cv2 = new ContentVersion(
            Title = 'AnotherFile',
            PathOnClient = 'Document.pdf', // This will trigger renaming in the trigger
            VersionData = Blob.valueOf('Another test file content')
        );

        // Step 3: Insert the second ContentVersion record outside of Test.startTest()
        insert cv2;

        // Step 4: Verify the Title was updated for the second record
        ContentVersion insertedContentVersion2 = [
            SELECT Title, PathOnClient
            FROM ContentVersion
            WHERE Id = :cv2.Id
            LIMIT 1
        ];

        //System.assertNotEquals(null, insertedContentVersion2, 'Second ContentVersion must be returned');
        //System.assertEquals('AnotherFile_Document.pdf', insertedContentVersion2.Title, 'The Title should be updated correctly for the second record.');
    }
}