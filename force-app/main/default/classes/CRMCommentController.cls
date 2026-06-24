/**
 * @description Apex controller for crmCommentAction LWC component.
 * Handles creating CRM Comment records on Customer Query.
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-03-08
 */
public with sharing class CRMCommentController {

    /**
     * @description Creates a CRM Comment record linked to a Customer Query.
     * @param queryId The Customer_Query__c record Id
     * @param comment The comment text
     */
    @AuraEnabled
    public static Id saveComment(Id queryId, String comment) {
        CRM_Comment__c crmComment = new CRM_Comment__c();
        crmComment.Customer_Query__c = queryId;
        crmComment.Comment__c = comment;
        crmComment.Comment_Added_By__c = UserInfo.getUserId();
        crmComment.Comment_Added_Time__c = System.now();
        insert crmComment;
        return crmComment.Id;
    }

    /**
     * @description Uploads a file and links it to a CRM Comment record.
     * @param commentId The CRM_Comment__c record Id to link the file to
     * @param fileName The name of the file being uploaded
     * @param base64Data The base64 encoded file content
     * @return The ContentDocumentId of the uploaded file
     */
    @AuraEnabled
    public static String uploadFileToComment(Id commentId, String fileName, String base64Data) {
        try {
            if (commentId == null) {
                throw new AuraHandledException('Comment record ID is required.');
            }
            if (String.isBlank(fileName)) {
                throw new AuraHandledException('File name is required.');
            }
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('File data is empty.');
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.FirstPublishLocationId = commentId;
            insert cv;

            ContentDocument doc = [
                SELECT Id FROM ContentDocument
                WHERE LatestPublishedVersionId = :cv.Id
                LIMIT 1
            ];
            return doc.Id;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw new AuraHandledException('File upload failed: ' + ex.getMessage());
        }
    }
}