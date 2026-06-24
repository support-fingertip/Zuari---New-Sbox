@IsTest
private class LightningFileUploadHandlerTest {

    @IsTest
    static void testGetFiles_and_DeleteFile() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Hello World'),
            IsMajorVersion = true
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Id docId = cv.ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = acc.Id,
            ContentDocumentId = docId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        List<ContentDocument> docs;

        Test.startTest();
        try {
            docs = LightningFileUploadHandler.getFiles(
                String.valueOf(acc.Id),
                new List<String>{ String.valueOf(docId) }
            );

            LightningFileUploadHandler.deleteFile(String.valueOf(docId));

        } catch (Exception e) {
            System.assert(false, 'Test failed due to exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, docs.size(), 'Expected exactly one ContentDocument returned');
        System.assertEquals(docId, docs[0].Id, 'Returned document Id mismatch');

        Integer remaining = [SELECT COUNT() FROM ContentDocument WHERE Id = :docId];
        System.assertEquals(0, remaining, 'ContentDocument should be deleted');
    }
}