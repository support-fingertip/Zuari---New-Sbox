/**
 * @description REST API endpoint for Contact Center mobile application home screen.
 * Validates customer and booking, then retrieves comprehensive booking details including
 * property info, payment status, co-applicants, demands, payments, documents, and milestones.
 *
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "bookingId": "CCP005"
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-18
 */
@RestResource(urlMapping='/CCHomeScreenAPI/*')
global without sharing class HomeScreen_CCMobileAPI {

    /**
     * @description Handles POST requests to retrieve home screen data for a booking.
     * Validates userId and bookingId, verifies booking belongs to customer,
     * and retrieves all associated booking details.
     * All requests and responses are logged to Apex_Log__c for audit trail.
     */
    @HttpPost
    global static void getHomeScreenData() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'HomeScreen_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            HomeScreenRequestWrapper requestData = (HomeScreenRequestWrapper) JSON.deserialize(requestBody, HomeScreenRequestWrapper.class);

            String userId = requestData.userId;
            String bookingId = requestData.bookingId;

            // Validate that required fields are not empty
            if (String.isBlank(userId) || String.isBlank(bookingId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId and bookingId', 'HomeScreen_CCMobileAPI', requestBody);
                return;
            }

            // Query customer by userId (Name or Id)
            List<Customer_Master__c> cmList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'HomeScreen_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = cmList[0];

            // Query Booking with related details
            List<Booking__c> bookingList = [
                SELECT Id, Name, Customer_Master__c, Plot__c, Plot__r.Name, Plot__r.Project__c, Plot__r.Project__r.Name, Plot__r.Project__r.Project_Address__c,
                       Plot__r.BHK_Type__c, Plot__r.Carpet_Area__c, 
                       GRAND_TOTAL__c, Total_received_Amount__c,
                        (SELECT Id FROM Demand_Raised__r),
                       (SELECT Id FROM Receipts__r),
                       (SELECT Id FROM Co_Applicants__r),
                       (SELECT Id FROM Payment_schedules__r)
                FROM Booking__c
                WHERE Name = :bookingId AND Customer_Master__c =:customer.Id
                LIMIT 1
            ];

            if (bookingList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Booking Not Found', 'HomeScreen_CCMobileAPI', requestBody);
                return;
            }

            Booking__c booking = bookingList[0];

            // Verify booking belongs to the customer
            if (booking.Customer_Master__c != customer.Id) {
                ErrorResponseUitilityClass.sendErrorResponse('Booking does not belong to this customer', 'HomeScreen_CCMobileAPI', requestBody);
                return;
            }

            // Query Unit/Plot details
            List<Plot__c> plotList = [
                SELECT Id, Name, BHK_Type__c, Carpet_Area__c,  Project__r.Name, Project__r.Project_Address__c,Unit_Facing_Direction__c,Super_Built_up_Area__c
                FROM Plot__c
                WHERE Id = :booking.Plot__c
                LIMIT 1
            ];

            Plot__c plot = plotList.isEmpty() ? null : plotList[0];

            // Query Demands for this booking
            Integer demandCount = booking.Demand_Raised__r != null ? booking.Demand_Raised__r.size() : 0;
            Integer propertyCount = [SELECT COUNT() FROM Booking__c WHERE Customer_Master__c = :customer.Id];

            // Query Payments for this booking
            Integer paymentCount = booking.Receipts__r != null ? booking.Receipts__r.size() : 0;

            // Query Co-Applicants
            List<Co_Applicant__c> coApplicants = [
                SELECT Id, Name, Son_Daughter_Wife_of__c, Aadhar_Number__c, PAN_Number__c
                FROM Co_Applicant__c
                WHERE Booking__c = :booking.Id
            ];

            // Query Project Milestones
            List<Payment_schedule__c> projectMilestones = [
                SELECT Id, Name, Last_Payment_Date__c, Payment_percent__c, Amount__c, AmountB__c,
                       Received_Amount1__c, Pending_Amount__c, Status__c
                FROM Payment_schedule__c
                WHERE Booking__c = :booking.Id
                ORDER BY S_No__c ASC
            ];

            // Query Customer Queries related to Booking
            Integer queryCount = [SELECT COUNT() FROM Customer_Query__c WHERE Booking__c = :booking.Id];

            // Build property detail
            PropertyDetail propertyDetail = new PropertyDetail();
            propertyDetail.propertyName = plot != null && plot.Name != null ? plot.Name+' '+Plot.Project__r.Name : ' ';
            propertyDetail.propertyUnit = plot != null && plot.Name != null ? plot.Name : ' ';
            propertyDetail.bhk = plot != null && plot.BHK_Type__c != null ? plot.BHK_Type__c : ' ';
            propertyDetail.propertySqft = plot != null && plot.Super_Built_up_Area__c != null ? String.valueOf(plot.Super_Built_up_Area__c) + ' sq.ft' : '';
            propertyDetail.propertyFacing = plot != null && plot.Unit_Facing_Direction__c != null ? plot.Unit_Facing_Direction__c : '';

            // Build co-applicants list
            List<CoApplicantDetail> coApplicantsList = new List<CoApplicantDetail>();
            for (Co_Applicant__c coApp : coApplicants) {
                CoApplicantDetail coAppDetail = new CoApplicantDetail();
                coAppDetail.coApplicantName = coApp.Name != null ? coApp.Name : '';
                coAppDetail.coApplicantCareOf = coApp.Son_Daughter_Wife_of__c != null ? coApp.Son_Daughter_Wife_of__c : '';
                coAppDetail.coApplicantAadharNumber = coApp.Aadhar_Number__c != null ? coApp.Aadhar_Number__c : '';
                coAppDetail.coApplicantPANNumber = coApp.PAN_Number__c != null ? coApp.PAN_Number__c : '';
                coApplicantsList.add(coAppDetail);
            }

            // Build project milestones list
            List<MilestoneDetail> milestonesList = new List<MilestoneDetail>();
            Decimal totalMilestonePaymentPercentage = 0;
            for (Payment_schedule__c milestone : projectMilestones) {
                MilestoneDetail milestoneDetail = new MilestoneDetail();
                milestoneDetail.milestoneName = milestone.Name != null ? milestone.Name : '';
                milestoneDetail.milestoneDate = formatDateAsIsoUtc(milestone.Last_Payment_Date__c);
                milestoneDetail.milestonePaymentPercentage = milestone.Payment_percent__c != null ? milestone.Payment_percent__c.intValue() : 0;
                if (milestone.Payment_percent__c != null && milestone.Status__c != null && milestone.Status__c.trim().toLowerCase() == 'completed') {
                    totalMilestonePaymentPercentage += milestone.Payment_percent__c;
                }
                //milestoneDetail.milestoneAmount = formatAmountInLakhs(milestone.Amount__c);
                 milestoneDetail.milestoneAmount = String.Valueof(milestone.AmountB__c);
             milestoneDetail.milestonePaidAmount = String.Valueof(milestone.Received_Amount1__c);
                milestoneDetail.milestonePendingAmount = String.Valueof(milestone.Pending_Amount__c);
                milestoneDetail.milestoneStatus = milestone.Status__c != null ? milestone.Status__c : '';
                milestonesList.add(milestoneDetail);
            }

            // Calculate payment percentage and amounts
            Decimal totalAmount = booking.GRAND_TOTAL__c != null ? booking.GRAND_TOTAL__c : 0;
            Decimal paidAmount = booking.Total_received_Amount__c != null ? booking.Total_received_Amount__c : 0;
            Decimal balanceAmount = totalAmount - paidAmount;
            Decimal paymentPercentage = totalMilestonePaymentPercentage;

            //For new Launch Project Image
            List<Project__c> projects = [ SELECT Id, Name FROM Project__c   WHERE Active__c = TRUE   AND New_Launch__c = TRUE];
               Boolean unReadNotificationExists = [SELECT COUNT() FROM Customer_Portal_Notification_Subscriber__c WHERE Customer_Master__c = :cmList[0].Id AND isRead__c = FALSE] > 0;

            Set<Id> projectIds = new Set<Id>();
            Map<Id, String> projectIdToName = new Map<Id, String>();
            
            for (Project__c p : projects) {
                projectIds.add(p.Id);
                projectIdToName.put(p.Id, p.Name);
            }
            
            Map<Id, Id> contentDocToProject = new Map<Id, Id>();
            if (!projectIds.isEmpty()) {
                List<ContentDocumentLink> cdlst =[SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink  WHERE LinkedEntityId IN :projectIds];
                System.debug(cdlst);
                for (ContentDocumentLink cdl : cdlst) {
                    contentDocToProject.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
            }
            
            Map<Id, ContentVersion> docToVersion = new Map<Id, ContentVersion>();
            List<ContentVersion> cvlist =[SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE IsLatest = TRUE AND ContentDocumentId IN :contentDocToProject.keySet() ];
            System.debug(cvlist);
            for (ContentVersion cv : cvlist) {
                if (cv.Title != null && cv.Title.contains('New Launch')) {
                    //docToVersion.put(cv.Id, cv);
                    docToVersion.put(cv.ContentDocumentId, cv);
                    
                }
            }
            Map<Id, String> projectIdToImageUrl = new Map<Id, String>();
              Map<Id, List<String>> projectIdToImageUrls = new Map<Id, List<String>>();
            
            // List<ContentDistribution> cdlsy =[select id,DistributionPublicUrl,ContentDownloadUrl,ContentVersion.Title,ContentVersion.FileExtension,createdDate from ContentDistribution where ContentVersionId IN :docToVersion.keySet() ORDER BY CREATEDDATE DESC ];
            
            
            List<ContentDistribution> cdlsy = [ SELECT ContentVersionId, ContentDownloadUrl  FROM ContentDistribution  WHERE ContentVersionId IN :docToVersion.values()   ORDER BY CreatedDate DESC];
            System.debug(cdlsy);
            for (ContentDistribution cd : cdlsy) {
            Id contentDocumentId;
                
                for (ContentVersion cv : docToVersion.values()) {
                    if (cv.Id == cd.ContentVersionId) {
                        contentDocumentId = cv.ContentDocumentId;
                        break;
                    }
                }
                
                if (contentDocumentId == null) continue;
                
                Id projectId = contentDocToProject.get(contentDocumentId);
                if (projectId == null) continue;
                
            String imgUrl = cd.ContentDownloadUrl
                .replace('download/?', 'renditionDownload?rendition=ORIGINAL_Jpg&')
                .replace('&ids', '&versionId');

            if (!projectIdToImageUrls.containsKey(projectId)) {
                projectIdToImageUrls.put(projectId, new List<String>());
            }
            projectIdToImageUrls.get(projectId).add(imgUrl);
        }
 


            // Build home screen data
            // Get actual document count for this booking
            Integer documentCount = 0;
            List<ContentDocumentLink> bookingDocLinks = [
                SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :booking.Id
            ];
            if (!bookingDocLinks.isEmpty()) {
                Set<Id> bookingDocIds = new Set<Id>();
                for (ContentDocumentLink cdl : bookingDocLinks) {
                    bookingDocIds.add(cdl.ContentDocumentId);
                }
                documentCount = [SELECT COUNT() FROM ContentVersion WHERE ContentDocumentId IN :bookingDocIds AND IsLatest = true];
            }

            HomeScreenData homeScreenData = new HomeScreenData();
            homeScreenData.percentagePaymentDone = paymentPercentage;
            homeScreenData.paidAmount = formatAmountInLakhs(paidAmount);
            homeScreenData.balanceAmount = formatAmountInLakhs(balanceAmount);
            homeScreenData.propertyDetail = propertyDetail;
            homeScreenData.newLaunch = new List<NewLaunch>(); // Static for now
            homeScreenData.unReadNotification = unReadNotificationExists;
            homeScreenData.demandCount = demandCount;
            homeScreenData.propertyCount = propertyCount;
            homeScreenData.payments = paymentCount;
            homeScreenData.documents = documentCount;
            homeScreenData.raiseQuery = queryCount;
            homeScreenData.referrals = [SELECT COUNT() FROM Referral__c WHERE Customer_Master__c = :customer.Id];
            homeScreenData.coApplicantsDetails = coApplicantsList;
            homeScreenData.projectMilestones = milestonesList;

            // Build response
            HomeScreenResponse response = new HomeScreenResponse();
            response.status = true;
            response.message = 'Basic Data';
            response.data = homeScreenData;
            /*
             for (Id pid : projectIdToName.keySet()) {
                if (projectIdToImageUrl.containsKey(pid)) {
                    response.data.newLaunch.add(
                        new NewLaunch(
                            projectIdToImageUrl.get(pid),
                            projectIdToName.get(pid)
                        )
                    );
                }
            }*/
            for (Id pid : projectIdToImageUrls.keySet()) {
            for (String url : projectIdToImageUrls.get(pid)) {
                response.data.newLaunch.add(
                    new NewLaunch(url, projectIdToName.get(pid))
                );
            }
        }
          

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Home screen data retrieved for booking ' + booking.Name + ' - ' + JSON.serialize(response.data);
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'HomeScreen_CCMobileAPI', requestBody);
        }
    }

    // ===== Request Wrapper =====
    public class HomeScreenRequestWrapper {
        public String userId;    // Customer identifier
        public String bookingId; // Booking identifier
    }

    // ===== Response Data Wrappers =====
    public class PropertyDetail {
        public String propertyName;      // Property/Project name
        public String propertyUnit;      // Unit/Plot number
        public String propertySqft;      // Property area in sq.ft
        public String propertyFacing;    // Property area in sq.ft
        public String bhk;    // Property facing direction
    }

    public class NewLaunch {
        public String siteImage;
        public String siteName;
        public NewLaunch(String siteImage, String siteName) {
            this.siteImage = siteImage;
            this.siteName = siteName;
        }
    }

    public class CoApplicantDetail {
        public String coApplicantName;        // Co-applicant name
        public String coApplicantCareOf;      // Care of information
        public String coApplicantAadharNumber; // Aadhaar number (masked)
        public String coApplicantPANNumber;   // PAN number
    }

    public class MilestoneDetail {
        public String milestoneName;              // Milestone name
        public String milestoneDate;              // Milestone date
        public Integer milestonePaymentPercentage; // Payment percentage
        public String milestoneAmount;            // Total milestone amount
        public String milestonePaidAmount;        // Amount paid
        public String milestonePendingAmount;     // Pending amount
        public String milestoneStatus;            // Milestone status
    }

    public class HomeScreenData {
        public Decimal percentagePaymentDone;        // Payment percentage
        public String paidAmount;                    // Total paid amount
        public String balanceAmount;                 // Balance amount
        public PropertyDetail propertyDetail;        // Property information
        public List<NewLaunch> newLaunch;            // New launches
        public Integer demandCount;
        public Integer propertyCount;                  // Total demands
        public Integer payments;                     // Total payments
        public Integer documents;                    // Total documents
        public Integer raiseQuery;                   // Total queries/issues
        public Integer referrals;                    // Total referrals        
        public Boolean unReadNotification;
        public List<CoApplicantDetail> coApplicantsDetails; // Co-applicants
        public List<MilestoneDetail> projectMilestones;     // Project milestones
    }

    public class HomeScreenResponse {
        public Boolean status;           // Response status
        public String message;           // Response message
        public HomeScreenData data;      // Response data
    }

    private static String formatAmountInLakhs(Decimal amount) {
        Decimal safeAmount = amount != null ? amount : 0;
        Decimal amountInLakhs = safeAmount / 100000;
        return String.valueOf(amountInLakhs.setScale(2)) + 'L';
    }

    private static String formatDateAsIsoUtc(Date inputDate) {
        if (inputDate == null) {
            return '';
        }
        Datetime dateTimeValue = Datetime.newInstanceGMT(inputDate.year(), inputDate.month(), inputDate.day(), 12, 34, 56);
        return dateTimeValue.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

}