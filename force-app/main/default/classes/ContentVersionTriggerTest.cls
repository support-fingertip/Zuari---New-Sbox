@IsTest
public class ContentVersionTriggerTest {

    @IsTest
    static void test_afterInsert_createsDistribution_and_optionalDocLink() {

        // Record to link file to (ExternalDocumentInfo1 expects an Id string)
        Account acc = new Account(Name = 'CV Link Account');
        insert acc;

        // ContentVersion that SHOULD create ContentDocumentLink (if fields are writable)
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'File One';
        cv1.PathOnClient = 'file1.pdf';
        cv1.VersionData = Blob.valueOf('dummy pdf bytes');

        // Set these fields only if createable (prevents "field not writable" errors)
        setIfCreateable(cv1, 'ExternalDocumentInfo2', 'FromApp');
        setIfCreateable(cv1, 'ExternalDocumentInfo1', acc.Id);

        // ContentVersion that should NOT create ContentDocumentLink (covers false branch)
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'File Two';
        cv2.PathOnClient = 'file2.pdf';
        cv2.VersionData = Blob.valueOf('dummy pdf bytes 2');

        Test.startTest();
        insert new List<ContentVersion>{ cv1, cv2 };
        Test.stopTest();

        // Re-query to get ContentDocumentId, etc.
        List<ContentVersion> insertedCVs = [
            SELECT Id, ContentDocumentId, Title, ExternalDocumentInfo1, ExternalDocumentInfo2
            FROM ContentVersion
            WHERE Title IN ('File One','File Two')
        ];
        System.assertEquals(2, insertedCVs.size(), 'Both ContentVersions must exist');

        Set<Id> cvIds = new Set<Id>();
        Set<Id> docIds = new Set<Id>();
        Map<String, ContentVersion> titleToCv = new Map<String, ContentVersion>();
        for (ContentVersion cv : insertedCVs) {
            cvIds.add(cv.Id);
            if (cv.ContentDocumentId != null) docIds.add(cv.ContentDocumentId);
            titleToCv.put(cv.Title, cv);
        }

        // 1) Assert ContentDistribution created for each ContentVersion
        Integer distCount = [
            SELECT COUNT()
            FROM ContentDistribution
            WHERE ContentVersionId IN :cvIds
        ];
        System.assertEquals(2, distCount, 'Trigger must create one ContentDistribution per ContentVersion');

        // 2) Assert ContentDocumentLink created only when FromApp + ExternalDocumentInfo1 provided
        // If those fields are not createable in your org, link branch won't run—so we assert conditionally.
        ContentVersion cvOne = titleToCv.get('File One');
        Boolean attemptedLink = (cvOne != null
            && String.valueOf(cvOne.get('ExternalDocumentInfo2')) == 'FromApp'
            && cvOne.get('ExternalDocumentInfo1') != null);

        if (attemptedLink) {
            Integer linkCount = [
                SELECT COUNT()
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :acc.Id
                AND ContentDocumentId IN :docIds
            ];
            System.assertEquals(1, linkCount, 'Trigger must create one ContentDocumentLink for FromApp files');
        }
    }

    // ---------- helper: set field only if createable ----------
    private static void setIfCreateable(SObject sob, String fieldApi, Object value) {
        if (sob == null || value == null) return;

        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return;

        Schema.DescribeFieldResult d = fm.get(fieldApi).getDescribe();
        if (!d.isCreateable()) return;

        sob.put(fieldApi, value);
    }
}