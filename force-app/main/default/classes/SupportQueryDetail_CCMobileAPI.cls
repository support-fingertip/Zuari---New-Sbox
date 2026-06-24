/**
 * @description REST API endpoint for Contact Center mobile application to fetch a single customer query detail with replies.
 * Validates customer and retrieves the query along with associated CRM Comments, file URLs, and feedback.
 *
 * Request:
 * {
 *   "userId": "CM-0001",
 *   "queryId": "CQ-0024"
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "support queries detail",
 *   "data": {
 *     "queryName": "Test Query Name",
 *     "queryDescription": "Test Query Description",
 *     "queryStatus": "Closed",
 *     "queryType": "Project Query",
 *     "queryRaisedDate": "2025-12-02T12:34:56Z",
 *     "queryDocName": "RentAggrement",
 *     "queryDocUrl": "https://...",
 *     "isQueryClose": true,
 *     "isFeedbackSubmitted": true,
 *     "queryReply": [
 *       {
 *         "replyId": "RC-0001",
 *         "replyDate": "2025-12-22T12:34:56Z",
 *         "replyPersonName": "John Doe",
 *         "replyDetail": "Comment text",
 *         "replyDocName": "Document.pdf",
 *         "replyDocUrl": "https://..."
 *       }
 *     ],
 *     "feedback": [
 *       {
 *         "feedBackId": "CQ-0024",
 *         "feedBackdate": "2025-12-02T12:34:56Z",
 *         "feedBackDescription": "Great service",
 *         "feedBackPersonName": "Test Customer",
 *         "feedBackStarCount": 4
 *       }
 *     ]
 *   }
 * }
 *
 * @author Praveen Kumar
 * @version 2.0
 * @since 2026-03-08
 */
@RestResource(urlMapping='/CCSupportQueryDetailAPI/*')
global without sharing class SupportQueryDetail_CCMobileAPI {

    /**
     * @description Handles POST requests to fetch a single customer query detail with replies,
     * file URLs (from ContentDistribution), feedback, and status flags.
     */
    @HttpPost
    global static void getSupportQueryDetail() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'SupportQueryDetail_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            QueryDetailRequestWrapper requestData = (QueryDetailRequestWrapper) JSON.deserialize(requestBody, QueryDetailRequestWrapper.class);

            String userId = requestData.userId;
            String queryId = requestData.queryId;

            // Validate that userId is provided
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'SupportQueryDetail_CCMobileAPI', requestBody);
                return;
            }

            // Validate customer exists
            List<Customer_Master__c> cmList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'SupportQueryDetail_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = cmList[0];

            // Validate that queryId is provided
            if (String.isBlank(queryId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide queryId', 'SupportQueryDetail_CCMobileAPI', requestBody);
                return;
            }

            // Fetch the Customer Query by Name (auto-number) and Customer
            List<Customer_Query__c> queryList = [
                SELECT Id, Name, Subject__c, Description__c, Query_Type__c, Query_Status__c, CreatedDate,
                       Feedback_Detail__c, Feedback_Rating__c, Feedback_Submitted_Time__c,
                       Customer_Master__r.Customer_Name__c,Other_Query__c
                FROM Customer_Query__c
                WHERE Name = :queryId
                AND Customer_Master__c = :customer.Id
                LIMIT 1
            ];

            if (queryList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Query Not Found', 'SupportQueryDetail_CCMobileAPI', requestBody);
                return;
            }

            Customer_Query__c cq = queryList[0];

            // Fetch related CRM Comments
            List<CRM_Comment__c> commentList = [
                SELECT Id, Name, Comment__c, Comment_Added_Time__c, Comment_Added_By__r.Name
                FROM CRM_Comment__c
                WHERE Customer_Query__c = :cq.Id
                ORDER BY Comment_Added_Time__c ASC
            ];

            // ===== File URL Retrieval (ContentDocumentLink -> ContentVersion -> ContentDistribution) =====

            // Collect all record IDs that need file lookups (query + all comments)
            Set<Id> allRecordIds = new Set<Id>();
            allRecordIds.add(cq.Id);
            for (CRM_Comment__c comment : commentList) {
                allRecordIds.add(comment.Id);
            }

            // Query ContentDocumentLink for all records
            List<ContentDocumentLink> docLinks = [
                SELECT Id, LinkedEntityId, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :allRecordIds
            ];

            // Collect ContentDocument IDs
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink cdl : docLinks) {
                docIds.add(cdl.ContentDocumentId);
            }

            // Build map: LinkedEntityId -> ContentDocumentId (first file per record)
            Map<Id, Id> entityToDocId = new Map<Id, Id>();
            for (ContentDocumentLink cdl : docLinks) {
                if (!entityToDocId.containsKey(cdl.LinkedEntityId)) {
                    entityToDocId.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                }
            }

            // Query latest ContentVersion for these documents
            Map<Id, ContentVersion> docIdToVersion = new Map<Id, ContentVersion>();
            if (!docIds.isEmpty()) {
                List<ContentVersion> versions = [
                    SELECT Id, ContentDocumentId, Title, FileExtension
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :docIds
                    AND IsLatest = true
                ];
                for (ContentVersion cv : versions) {
                    docIdToVersion.put(cv.ContentDocumentId, cv);
                }
            }

            // Collect ContentVersion IDs for ContentDistribution lookup
            Set<Id> versionIds = new Set<Id>();
            for (ContentVersion cv : docIdToVersion.values()) {
                versionIds.add(cv.Id);
            }

            // Query ContentDistribution for public URLs
            Map<Id, ContentDistribution> versionToDist = new Map<Id, ContentDistribution>();
            if (!versionIds.isEmpty()) {
                List<ContentDistribution> distributions = [
                    SELECT Id, ContentVersionId, DistributionPublicUrl, ContentDownloadUrl
                    FROM ContentDistribution
                    WHERE ContentVersionId IN :versionIds
                ];
                for (ContentDistribution cd : distributions) {
                    versionToDist.put(cd.ContentVersionId, cd);
                }

                // Create missing ContentDistribution records (for older files without auto-created distributions)
                Set<Id> missingDistVersionIds = new Set<Id>();
                for (Id vId : versionIds) {
                    if (!versionToDist.containsKey(vId)) {
                        missingDistVersionIds.add(vId);
                    }
                }

                if (!missingDistVersionIds.isEmpty()) {
                    List<ContentDistribution> newDists = new List<ContentDistribution>();
                    for (Id cvId : missingDistVersionIds) {
                        ContentDistribution cd = new ContentDistribution();
                        cd.ContentVersionId = cvId;
                        cd.Name = 'Public Link';
                        cd.PreferencesAllowViewInBrowser = true;
                        cd.PreferencesLinkLatestVersion = true;
                        cd.PreferencesNotifyOnVisit = false;
                        cd.PreferencesPasswordRequired = false;
                        cd.PreferencesAllowOriginalDownload = true;
                        newDists.add(cd);
                    }
                    insert newDists;

                    // Re-query to get generated URLs
                    for (ContentDistribution cd : [
                        SELECT Id, ContentVersionId, DistributionPublicUrl, ContentDownloadUrl
                        FROM ContentDistribution
                        WHERE Id IN :newDists
                    ]) {
                        versionToDist.put(cd.ContentVersionId, cd);
                    }
                }
            }

            // ===== Build reply list =====
            List<ReplyDetail> replyList = new List<ReplyDetail>();
            for (CRM_Comment__c comment : commentList) {
                ReplyDetail reply = new ReplyDetail();
                reply.replyId = comment.Name != null ? comment.Name : '';
                reply.replyDate = comment.Comment_Added_Time__c != null ? comment.Comment_Added_Time__c.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : '';
                reply.replyPersonName = comment.Comment_Added_By__r != null && comment.Comment_Added_By__r.Name != null ? comment.Comment_Added_By__r.Name : '';
                reply.replyDetail = comment.Comment__c != null ? comment.Comment__c : '';

                // Reply document URL
                reply.replyDocName = '';
                reply.replyDocUrl = '';
                if (entityToDocId.containsKey(comment.Id)) {
                    Id docId = entityToDocId.get(comment.Id);
                    if (docIdToVersion.containsKey(docId)) {
                        ContentVersion cv = docIdToVersion.get(docId);
                        reply.replyDocName = cv.Title != null ? cv.Title : '';
                        if (versionToDist.containsKey(cv.Id)) {
                            ContentDistribution dist = versionToDist.get(cv.Id);
                            reply.replyDocUrl = dist.DistributionPublicUrl != null ? dist.DistributionPublicUrl : '';
                        }
                    }
                }

                replyList.add(reply);
            }

            // ===== Build response data =====
            QueryDetailData detailData = new QueryDetailData();
            detailData.queryName = cq.Subject__c != null ? cq.Subject__c : '';
            detailData.queryDescription = cq.Description__c != null ? cq.Description__c : '';
            detailData.queryStatus = cq.Query_Status__c != null ? cq.Query_Status__c : '';
            detailData.queryType = cq.Query_Type__c != null ? cq.Query_Type__c : '';
            detailData.queryTypeId = cq.Query_Type__c != null ? cq.Query_Type__c : '';
            detailData.queryTypeDescription = cq.Other_Query__c != null ? cq.Other_Query__c : '';
            
            detailData.queryRaisedDate = cq.CreatedDate != null ? cq.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : '';

            // Query document URL
            detailData.queryDocName = '';
            detailData.queryDocUrl = '';
            if (entityToDocId.containsKey(cq.Id)) {
                Id docId = entityToDocId.get(cq.Id);
                if (docIdToVersion.containsKey(docId)) {
                    ContentVersion cv = docIdToVersion.get(docId);
                    detailData.queryDocName = cv.Title != null ? cv.Title : '';
                    if (versionToDist.containsKey(cv.Id)) {
                        ContentDistribution dist = versionToDist.get(cv.Id);
                        detailData.queryDocUrl = dist.DistributionPublicUrl != null ? dist.DistributionPublicUrl : '';
                    }
                }
            }

            // Boolean flags
            detailData.isQueryClose = cq.Query_Status__c != null && cq.Query_Status__c == 'Closed';
            detailData.isFeedbackSubmitted = cq.Feedback_Submitted_Time__c != null;

            detailData.queryReply = replyList;

            // Feedback array (0 or 1 item - feedback is stored on the query itself)
            List<FeedbackDetail> feedbackList = new List<FeedbackDetail>();
            if (cq.Feedback_Submitted_Time__c != null) {
                FeedbackDetail fb = new FeedbackDetail();
                fb.feedBackId = cq.Name != null ? cq.Name : '';
                fb.feedBackdate = cq.Feedback_Submitted_Time__c.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                fb.feedBackDescription = cq.Feedback_Detail__c != null ? cq.Feedback_Detail__c : '';
                fb.feedBackPersonName = cq.Customer_Master__r != null && cq.Customer_Master__r.Customer_Name__c != null
                                        ? cq.Customer_Master__r.Customer_Name__c : '';
                fb.feedBackStarCount = cq.Feedback_Rating__c != null ? cq.Feedback_Rating__c : null;
                feedbackList.add(fb);
            }
            detailData.feedback = feedbackList;

            // Build response
            QueryDetailResponse response = new QueryDetailResponse();
            response.status = true;
            response.message = 'support queries detail';
            response.data = detailData;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Retrieved query detail: ' + cq.Name + ' with ' + commentList.size() + ' replies';
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'SupportQueryDetail_CCMobileAPI', requestBody);
        }
    }

    // ===== Request Wrapper =====
    /**
     * @description Wrapper class for deserializing query detail request JSON.
     */
    public class QueryDetailRequestWrapper {
        public String userId;    // Customer identifier (e.g., "CM-0001")
        public String queryId;   // Query auto-number Name (e.g., "CQ-0024")
    }

    // ===== Response Wrapper Classes =====
    /**
     * @description Wrapper class for individual reply detail in response.
     */
    public class ReplyDetail {
        public String replyId;          // CRM_Comment__c auto-number Name
        public String replyDate;        // Comment_Added_Time__c formatted ISO 8601
        public String replyPersonName;  // Comment_Added_By__r.Name
        public String replyDetail;      // Comment__c
        public String replyDocName;     // ContentVersion.Title linked to the comment
        public String replyDocUrl;      // ContentDistribution.DistributionPublicUrl for the comment file
    }

    /**
     * @description Wrapper class for feedback detail in response.
     */
    public class FeedbackDetail {
        public String feedBackId;           // Customer_Query__c Name
        public String feedBackdate;         // Feedback_Submitted_Time__c formatted ISO 8601
        public String feedBackDescription;  // Feedback_Detail__c
        public String feedBackPersonName;   // Customer_Master__r.Customer_Name__c
        public String feedBackStarCount;   // Feedback_Rating__c as Integer
    }

    /**
     * @description Wrapper class for query detail data in response.
     */
    public class QueryDetailData {
        public String queryName;                    // Subject__c
        public String queryDescription;             // Description__c
        public String queryStatus;                  // Query_Status__c
        public String queryType;                    // Query_Status__c
        public String queryTypeId;                    // Query_Status__c
        public String queryTypeDescription;                    // Query_Type__c
        public String queryRaisedDate;              // CreatedDate formatted ISO 8601
        public String queryDocName;                 // ContentVersion.Title linked to query
        public String queryDocUrl;                  // ContentDistribution.DistributionPublicUrl for query file
        public Boolean isQueryClose;                // true if Query_Status__c == 'Closed'
        public Boolean isFeedbackSubmitted;         // true if Feedback_Submitted_Time__c != null
        public List<ReplyDetail> queryReply;        // List of CRM Comment replies
        public List<FeedbackDetail> feedback;       // List of feedback (0 or 1 item)
    }

    /**
     * @description Wrapper class for complete API response.
     */
    public class QueryDetailResponse {
        public Boolean status;              // Response status
        public String message;              // Response message
        public QueryDetailData data;        // Query detail with replies
    }

}