public with sharing class FileDocumentController {

    // Wrapper returned to Aura
    public class DocumentStatusWrapper {
        @AuraEnabled public String label;      // Document type / label
        @AuraEnabled public Boolean uploaded;  // true / false
        @AuraEnabled public String fileName;   // Name of uploaded file
        @AuraEnabled public Id documentId;     // ContentDocumentId

        public DocumentStatusWrapper(String l) {
            label = l;
            uploaded = false;
        }
    }

    // Called by parent to load statuses
    @AuraEnabled
    public static List<DocumentStatusWrapper> getDocuments(Id recordId, List<String> docNames) {

        Map<String, DocumentStatusWrapper> docMap = new Map<String, DocumentStatusWrapper>();

        // Initialize all docs as not uploaded
        for (String d : docNames) {
            docMap.put(d, new DocumentStatusWrapper(d));
        }

        // Get all files linked to this record, with their ContentVersion.Description
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
                   ContentDocument.Title,
                   ContentDocument.LatestPublishedVersion.Description
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];

        for (ContentDocumentLink cdl : links) {
            String docType = cdl.ContentDocument.LatestPublishedVersion.Description;
            if (docType != null && docMap.containsKey(docType)) {
                DocumentStatusWrapper wrap = docMap.get(docType);
                wrap.uploaded   = true;
                wrap.fileName   = cdl.ContentDocument.Title;
                wrap.documentId = cdl.ContentDocumentId;
            }
        }

        return docMap.values();
    }

    // Called by child after upload to tag file with docType
    @AuraEnabled
    public static void markDocumentForType(Id recordId, String docType,String fileName, Id contentDocumentId) {
System.debug(fileName);
        // Update latest version's Description to the docType
        ContentDocument doc = [
            SELECT LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :contentDocumentId
            LIMIT 1
        ];

        ContentVersion cv = [
            SELECT Id, Description,Title
            FROM ContentVersion
            WHERE Id = :doc.LatestPublishedVersionId
            LIMIT 1
        ];

        cv.Description = docType;
        cv.Title = fileName;
        update cv;
    }

    // Delete link + (optionally) the file for this record + docType
    @AuraEnabled
    public static void deleteFile(Id recordId, Id contentDocumentId, String docType) {

        // Delete link for this record
        List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
                  AND ContentDocumentId = :contentDocumentId
        ];

        if (!links.isEmpty()) {
            delete links;
        }

        // Optionally, delete the document if no more links exist
        Integer remainingLinks = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
        ];

        if (remainingLinks == 0) {
            delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
        }
    }
}