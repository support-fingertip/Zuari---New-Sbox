public with sharing class FileUploadController {
    
    private static final String ISSUE_UPLOADING_FILE = 'There is a problem in uploading the file';
    
    @AuraEnabled
    public static String fileUpload(String parentId, String name, String fileType, String fileData, String documentName) {
        try {
            System.debug('**Uploading File: ' + documentName + '**');
            
            if (String.isEmpty(parentId)) {
                throw new AuraHandledException('Parent Record ID is required.');
            }
            
            if (String.isEmpty(fileData)) {
                throw new AuraHandledException('File data is empty.');
            }
            
            // Decode the base64 data
            Blob fileBody;
            try {
                fileBody = EncodingUtil.base64Decode(fileData);
            } catch (Exception e) {
                throw new AuraHandledException('Invalid file data: ' + e.getMessage());
            }
            
            // Use documentName if provided, otherwise use the original filename
            String title = !String.isBlank(documentName) ? documentName.trim() : name;
            
            // Check if file with this title already exists for this record
            List<ContentDocumentLink> existingLinks = [
                SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :parentId
                AND ContentDocument.Title = :title
                LIMIT 1
            ];
            
            ContentVersion fileVersion = new ContentVersion();
            fileVersion.Title = title;
            fileVersion.PathOnClient = name;
            fileVersion.VersionData = fileBody;
            
            if (!existingLinks.isEmpty()) {
                // Create new version of existing document
                fileVersion.ContentDocumentId = existingLinks[0].ContentDocumentId;
                System.debug('**Creating new version for existing document**');
            } else {
                // New document - link to parent
                fileVersion.FirstPublishLocationId = parentId;
                System.debug('**Creating new document**');
            }
            
            insert fileVersion;
            System.debug('**FileVersion Inserted: ' + fileVersion.Id + '**');
            
            // Get ContentDocumentId
            ContentDocument newDoc = [
                SELECT Id 
                FROM ContentDocument 
                WHERE LatestPublishedVersionId = :fileVersion.Id 
                LIMIT 1
            ];
            
            String contentDocId = newDoc.Id;
            
            // If new document, ensure it's linked to parent
            if (existingLinks.isEmpty()) {
                try {
                    ContentDocumentLink newLink = new ContentDocumentLink();
                    newLink.LinkedEntityId = parentId;
                    newLink.ShareType = 'V';
                    newLink.ContentDocumentId = contentDocId;
                    newLink.Visibility = 'AllUsers';
                    insert newLink;
                    System.debug('**ContentDocumentLink Created**');
                } catch (DmlException linkEx) {
                    System.debug('Link may already exist: ' + linkEx.getMessage());
                }
            }
            
            System.debug('**File Successfully Uploaded. ContentDocumentId: ' + contentDocId + '**');
            return contentDocId;
            
        } catch (Exception ex) {
            System.debug('### Exception Details ###');
            System.debug('Line Number: ' + ex.getLineNumber());
            System.debug('Error Message: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            throw new AuraHandledException('Upload failed: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String multifileUpload(String parentId, String name, String fileType, String fileData, String documentName,Boolean isPicklist) {
        try {
            System.debug('**Uploading File: ' + name + '**');
            
            // Ensure parentId is valid
            if (String.isEmpty(parentId)) {
                throw new AuraHandledException('Parent Record ID is required.');
            }
            
            // Step 1: Create a new ContentVersion object without versioning
            ContentVersion fileVersion = new ContentVersion();
            fileVersion.Title = isPicklist == true? documentName : documentName+'-'+name;  // Use 'name' as the title
            fileVersion.PathOnClient = name;
            fileVersion.VersionData = EncodingUtil.base64Decode(fileData);
            
            // Set the FirstPublishLocationId to link it to the parent record
            fileVersion.FirstPublishLocationId = parentId;
            
            insert fileVersion;
            System.debug('**FileVersion Inserted: ' + fileVersion.Id + '**');
            
            // Fetch ContentDocumentId from the inserted ContentVersion
            ContentDocument newDoc = [
                SELECT Id FROM ContentDocument 
                WHERE LatestPublishedVersionId = :fileVersion.Id
                LIMIT 1
            ];
            String newDocId = newDoc.Id;
            
            System.debug('**ContentDocumentId Retrieved: ' + newDocId + '**');
            
            // Step 2: Always link the document to the parent record
            try {
                ContentDocumentLink newLink = new ContentDocumentLink();
                newLink.LinkedEntityId = parentId;
                newLink.ShareType = 'V';
                newLink.ContentDocumentId = newDocId;
                insert newLink;
                System.debug('**ContentDocumentLink Created: ' + newLink.Id + '**');
            } catch (DmlException linkEx) {
                System.debug('Link may already exist. DML Error: ' + linkEx.getMessage());
            }
            
            System.debug('**File Successfully Uploaded and Linked**');
            
            // Confirm that the file is available in ContentDocument
            ContentDocument verifyDoc = [SELECT Id, Title FROM ContentDocument WHERE Id = :newDocId LIMIT 1];
            System.debug('**File Verified: ' + verifyDoc.Title + '**');
            
            return newDocId;
            
        } catch (Exception ex) {
            System.debug('### Exception Details ###');
            System.debug('Line Number: ' + ex.getLineNumber());
            System.debug('Error Message: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            throw new AuraHandledException('Exception: ' + ex.getMessage() + ' on Line Number: ' + ex.getLineNumber());
        }
    }
    
    
    // Wrapper class for returning file metadata
    public class FileWrapper {
        @AuraEnabled public String fileId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public String previewUrl;
        @AuraEnabled public String downloadUrl;
        
        public FileWrapper(ContentDocumentLink docLink) {
            this.fileId = docLink.ContentDocumentId;
            this.title = docLink.ContentDocument.Title;
            this.fileExtension = docLink.ContentDocument.FileExtension;
            this.previewUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB120BY90&versionId=' + docLink.ContentDocument.LatestPublishedVersionId;
            this.downloadUrl = '/sfc/servlet.shepherd/document/download/' + docLink.ContentDocumentId;
        }
    }
    
    // Get files linked to a specific record
    @AuraEnabled
    public static List<FileWrapper> getFiles(String recordId, String fileName) {
        List<FileWrapper> files = new List<FileWrapper>();
        
        List<ContentDocumentLink> documentLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId, 
            ContentDocument.Title, ContentDocument.FileExtension, 
            ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];
        
        for (ContentDocumentLink docLink : documentLinks) {
            if (String.isEmpty(fileName) || docLink.ContentDocument.Title == fileName) {
                files.add(new FileWrapper(docLink));
            }
        }
        return files;
    }
    
    @AuraEnabled
    public static List<FileWrapper> getMultiFiles(String recordId, String fileName) {
        List<FileWrapper> files = new List<FileWrapper>();
        
        try {
            if (String.isEmpty(recordId)) {
                return files;
            }
            
            List<ContentDocumentLink> documentLinks;
            
            // FIX: Use exact match when fileName is provided, wildcard only when fetching all
            if (String.isEmpty(fileName)) {
                documentLinks = [
                    SELECT Id, LinkedEntityId, ContentDocumentId, 
                    ContentDocument.Title, ContentDocument.FileExtension, 
                    ContentDocument.LatestPublishedVersionId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :recordId
                    ORDER BY ContentDocument.CreatedDate DESC
                ];
            } else {
                documentLinks = [
                    SELECT Id, LinkedEntityId, ContentDocumentId, 
                    ContentDocument.Title, ContentDocument.FileExtension, 
                    ContentDocument.LatestPublishedVersionId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :recordId
                    AND ContentDocument.Title = :fileName
                    ORDER BY ContentDocument.CreatedDate DESC
                ];
            }
            
            for (ContentDocumentLink docLink : documentLinks) {
                files.add(new FileWrapper(docLink));
            }
            
            System.debug('Found ' + files.size() + ' files for recordId: ' + recordId);
            
        } catch (Exception ex) {
            System.debug('Error in getMultiFiles: ' + ex.getMessage());
            throw new AuraHandledException('Error fetching files: ' + ex.getMessage());
        }
        
        return files;
    }

    @AuraEnabled
    public static void deleteFileFromSalesforce(String fileId) {
        try {
            // Fetch the ContentDocument using the ContentDocumentId (fileId)
            ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Id = :fileId LIMIT 1];
            
            // Deleting the ContentDocument will also delete all associated ContentVersions
            delete contentDoc;
            
            // Log success
            System.debug('File successfully deleted: ' + contentDoc.Id);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting file: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void markDocumentForType(Id recordId, String docType, String fileName, Id contentDocumentId) {
        try {
            System.debug('Marking document type - RecordId: ' + recordId + ', FileName: ' + fileName + ', ContentDocId: ' + contentDocumentId);
            
            if (contentDocumentId == null) {
                throw new AuraHandledException('Content Document ID is required');
            }
            
            // Get latest version
            List<ContentDocument> docs = [
                SELECT LatestPublishedVersionId 
                FROM ContentDocument 
                WHERE Id = :contentDocumentId 
                LIMIT 1
            ];
            
            if (docs.isEmpty()) {
                throw new AuraHandledException('Content Document not found');
            }
            
            ContentVersion cv = [
                SELECT Id, Description, Title 
                FROM ContentVersion 
                WHERE Id = :docs[0].LatestPublishedVersionId 
                LIMIT 1
            ];
            
            // Update description and ensure title matches
            cv.Description = docType;
            if (!String.isBlank(fileName)) {
                cv.Title = fileName;
            }
            update cv;
            
            System.debug('Document marked successfully');
            
            // Update related record fields if needed
            String objectName = recordId.getSObjectType().getDescribe().getName();
            
            if (objectName == 'Booking__c') {
                updateBookingFileFlags(recordId, fileName);
            } else if (objectName == 'Snag_List__c') {
                updateSnagFileFlags(recordId, fileName);
            }
            
        } catch (Exception ex) {
            System.debug('Error in markDocumentForType: ' + ex.getMessage());
            throw new AuraHandledException('Error marking document: ' + ex.getMessage());
        }
    }
    
    public static void updateBookingFileFlags(Id bookingId, String fileName) {
        Booking__c booking = new Booking__c(Id = bookingId);
        String typeLower = fileName != null ? fileName.trim().toLowerCase() : '';
        
        if (typeLower == 'sale agreement') {
            booking.Sale_Agreement_Sent__c = true;
        }
        if (typeLower == 'sale deed') {
            booking.Sale_Deed_Uploaded__c = true;
        }
        if (typeLower == 'maintenance agreement' || typeLower == 'maintenance letter') {
            booking.Maintenance_Agreement_Uploaded__c = 'Yes';
        }
        
        update booking;
    }
    
    // HELPER: Update Snag file upload flags
    public static void updateSnagFileFlags(Id snagId, String fileName) {
        Snag_List__c sng = new Snag_List__c(Id = snagId);
        String typeLower = fileName != null ? fileName.trim().toLowerCase() : '';
        
        if (typeLower == 'snag resolved file') {
            sng.Snag_Completed_File_Uploaded__c = true;
        }
        
        update sng;
    }
    
}