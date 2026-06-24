/**
 * @description REST API to fetch all documents related to a booking for Contact Center mobile app.
 * Validates customer -> booking, retrieves ContentDocumentLink/ContentVersion/ContentDistribution.
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "bookingId": "CPP001",
 *   "documentName": "",
 *   "pageSize": 0
 * }
 *
 * Response:
 * {
 *  "status": true,
 *  "message": "All Documents",
 *  "data": [ { document objects... } ]
 * }
 */
@RestResource(urlMapping='/CCAllDocumentsAPI/*')
global without sharing class AllDocument_CCMobileAPI {

    @HttpPost
    global static void getAllDocuments() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AllDocument_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            AllDocumentRequest requestData = (AllDocumentRequest) JSON.deserialize(requestBody, AllDocumentRequest.class);

            String userId = requestData.userId;
            String bookingId = requestData.bookingId;
            String documentName = requestData.documentName;
            Datetime fromDateTime = requestData.fromDate;
            Datetime toDateTime = requestData.toDate;
            Integer pageSize = requestData.pageSize != null ? requestData.pageSize : 0;

            if (fromDateTime != null && toDateTime != null && fromDateTime > toDateTime) {
                ErrorResponseUitilityClass.sendErrorResponse('fromDate should be less than or equal to toDate', 'AllDocument_CCMobileAPI', requestBody);
                return;
            }

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'AllDocument_CCMobileAPI', requestBody);
                return;
            }

            // Validate customer
            List<Customer_Master__c> cmList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'AllDocument_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = cmList[0];

            // Validate booking belongs to customer
            if (String.isBlank(bookingId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide bookingId', 'AllDocument_CCMobileAPI', requestBody);
                return;
            }

            List<Booking__c> bkList = [
                SELECT Id, Name, Project1__c
                FROM Booking__c
                WHERE Name = :bookingId
                AND Customer_Master__c = :customer.Id
                LIMIT 1
            ];

            if (bkList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Booking not found for customer', 'AllDocument_CCMobileAPI', requestBody);
                return;
            }

            Booking__c booking = bkList[0];

            // Get ContentDocumentLink records linked to the booking
            List<ContentDocumentLink> docLinks = [
                SELECT Id, ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :booking.Id
            ];

            if (docLinks.isEmpty()) {
                AllDocumentResponse resp = new AllDocumentResponse();
                resp.status = true;
                resp.message = 'All Documents';
                resp.data = new List<DocumentDetail>();
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
                log.Response__c = 'No documents found for booking';
                log.Status__c = 'SUCCESS';
                insert log;
                return;
            }

            // Collect ContentDocument IDs
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink cdl : docLinks) {
                docIds.add(cdl.ContentDocumentId);
            }

            // Get ContentVersion records for these documents----
            List<ContentVersion> docVersions = [
                SELECT Id, ContentDocumentId, Title, CreatedDate, ContentSize,FileExtension
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIds
                AND IsLatest = true
                ORDER BY CreatedDate DESC
            ];

            // Get ContentDistribution records for URLs
            List<ContentDistribution> docDistributions = [
                SELECT Id, ContentVersionId, DistributionPublicUrl,ContentDownloadUrl
                FROM ContentDistribution
                WHERE ContentVersionId IN (
                    SELECT Id FROM ContentVersion
                    WHERE ContentDocumentId IN :docIds
                    AND IsLatest = true
                )
            ];

            // Build map of ContentVersionId -> ContentDistribution for quick lookup
            Map<Id, ContentDistribution> versionToDist = new Map<Id, ContentDistribution>();
            for (ContentDistribution cd : docDistributions) {
                versionToDist.put(cd.ContentVersionId, cd);
            }

            // Build response
            List<DocumentDetail> data = new List<DocumentDetail>();
            Map<Id, DocumentDetail> missingDistMap = new Map<Id, DocumentDetail>();
            Integer offset = pageSize * 15;
            Integer count = 0;

            for (ContentVersion cv : docVersions) {
                // Optional created date range filter
                System.debug(cv.CreatedDate +'=== '+ fromDateTime +'=== '+ toDateTime);
                if (fromDateTime != null && !(cv.CreatedDate >= fromDateTime)) {
                    continue;
                }
                if (toDateTime != null && !(cv.CreatedDate <= toDateTime)) {
                    continue;
                }

                // Optional document name filter
                if (!String.isBlank(documentName) && !cv.Title.containsIgnoreCase(documentName)) {
                    continue;
                }

                // Skip records before offset
                if (count < offset) {
                    count++;
                    continue;
                }

                // Limit to 15 records per page
                if (data.size() >= 15) {
                    break;
                }

                DocumentDetail det = new DocumentDetail();
                det.documentId = cv.ContentDocumentId;
                string docname= cv.Title + '.' + cv.FileExtension;
                det.documentName = docname != null ? docname : '';
                
                // Format upload date
                String uploadDateStr = '';
                if (cv.CreatedDate != null) {
                    uploadDateStr = cv.CreatedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                }
                det.documentUploadDate = uploadDateStr;
                
                // Get URLs from ContentDistribution
                if (versionToDist.containsKey(cv.Id)) {
                    ContentDistribution dist = versionToDist.get(cv.Id);
                    det.documentFileViewURL = dist.DistributionPublicUrl != null ? dist.DistributionPublicUrl : '';
                    det.documentFileDownloadURL = dist.ContentDownloadUrl != null ? dist.ContentDownloadUrl : '';
                } else {
                    det.documentFileViewURL = '';
                    det.documentFileDownloadURL = '';
                    missingDistMap.put(cv.Id, det);
                }
                
                data.add(det);
                count++;
            }

            // Create public links for documents that don't have one
            if (!missingDistMap.isEmpty()) {
                List<ContentDistribution> newDists = new List<ContentDistribution>();
                for (Id cvId : missingDistMap.keySet()) {
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
                    if (missingDistMap.containsKey(cd.ContentVersionId)) {
                        DocumentDetail det = missingDistMap.get(cd.ContentVersionId);
                        det.documentFileViewURL = cd.DistributionPublicUrl != null ? cd.DistributionPublicUrl : '';
                        det.documentFileDownloadURL = cd.ContentDownloadUrl != null ? cd.ContentDownloadUrl : '';
                    }
                }
            }

            AllDocumentResponse respData = new AllDocumentResponse();
            respData.status = true;
            respData.message = 'All Documents';
            respData.data = data;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(respData));

            log.Response__c = 'Retrieved ' + data.size() + ' documents for booking ' + JSON.serialize(respData);
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'AllDocument_CCMobileAPI', RestContext.request.requestBody.toString());
        }
    }

    // ===== Request / Response wrappers =====
    public class AllDocumentRequest {
        public String userId;
        public String bookingId;
        public String documentName;
        public Datetime fromDate;
        public Datetime toDate;
        public Integer pageSize;
    }

    public class DocumentDetail {
        public String documentId;
        public String documentName;
        public String documentUploadDate;
        public String documentFileViewURL;
        public String documentFileDownloadURL;
    }

    public class AllDocumentResponse {
        public Boolean status;
        public String message;
        public List<DocumentDetail> data;
    }

}