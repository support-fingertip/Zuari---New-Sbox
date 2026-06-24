/****************************************************************
* Class Name   : LeadDetail_MobileAPI
* Company      : Fingertipplus
* Created Date : 16-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API fetches Lead details along with related
* Site Visits, Follow-ups, Call Details, and Additional Notes.
*
* Input JSON:
* {
*   "userId": "9",
*   "leadId": "111"
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "lead detail",
*   "data": { ... }
* }
******************************************************************************************/

@RestResource(urlMapping='/LeadDetailAPI/*')
global without sharing class LeadDetail_MobileAPI {


    @HttpPost
    global static void getLeadDetails() {

        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        Apex_Log__c log = new Apex_Log__c(Request_Type__c = 'LeadDetail_MobileAPI', Request__c = requestBody);

        Boolean logInserted = false;

        try {
            // Deserialize input
            LeadDetailWrapper input = (LeadDetailWrapper) JSON.deserialize(requestBody, LeadDetailWrapper.class);
            System.debug('Input: ' + JSON.serialize(input));

            if (String.isBlank(input.userId) || String.isBlank(input.leadId)) {
                ErrorResponseUitilityClass.sendErrorResponse('userId and leadId are required','LeadDetail_MobileAPI',requestBody);
              
               // sendError('userId and leadId are required', log, logInserted);
                return;
            }
             List<Channel_Partner__c> cpList = [SELECT Id, Name  FROM Channel_Partner__c  WHERE User_Id__c = :input.userId AND Active__c = TRUE LIMIT 1];

            if (cpList.isEmpty()) {
              //  sendError('Channel Partner not found', log, logInserted);
                  ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','LeadDetail_MobileAPI',requestBody);
              
                return;
            }


            // Fetch Lead
           // Lead l = [SELECT Id, LastName, Phone__c,Lead_ID__c, Email,CreatedDate, Description,OwnerId, CreatedBy.Name,Lead_Status__c, Allocated_Project__c
              //        FROM Lead WHERE Lead_ID__c = :input.leadId AND Channel_Partner__c = :cpList[0].id  LIMIT 1];
           Related_Source__c rl = [Select id,Name__c,Lead_status1__c,OwnerId,Primary_Phone__c,Email__c,Allocated_Project__c,CreatedDate from Related_Source__c Where Is_Locked__c = FALSE AND Lead_Id__c = :input.leadId AND Channel_Partner1__c =:cpList[0].id limit 1];
            
system.debug(rl);
            if (rl == null) {
               // sendError('Lead not found', log, logInserted);
                  ErrorResponseUitilityClass.sendErrorResponse('Lead not found','LeadDetail_MobileAPI',requestBody);
              
                return;
            }
            User u;
             if (rl.OwnerId != null) {
               u = [SELECT Id, Name, Email,CreatedDate, MobilePhone FROM User WHERE Id = :rl.OwnerId];
            }
           //   List<Related_Source__c> relatedSources = [SELECT Id FROM Related_Source__c WHERE SLead__c = :l.Id  ];
            
            Set<Id> relatedSourceIds = new Set<Id>();
         //   for (Related_Source__c rs : relatedSources) {
             //   relatedSourceIds.add(rs.Id);
           // }

            // Prepare contact info
            ContactInformation contactInfo = new ContactInformation();
            contactInfo.leadStatusId = rl.Lead_status1__c;
            contactInfo.creatorName = rl.Name__c;
            contactInfo.phoneNumber = rl.Primary_Phone__c;
            contactInfo.emailAddress = rl.Email__c;
            contactInfo.projectName = rl.Allocated_Project__c;
            contactInfo.assignExecutive = u.Name;
            contactInfo.createdOn = rl.CreatedDate;

            // Site Visits
            List<SiteVisitInfo> siteVisits = new List<SiteVisitInfo>();
            for (Site_Visit__c sv : [SELECT Id,Name, Date__c,Site_Visit_Type__c,SLead__r.Allocated_Project__c,Project__c,Feedback__c, Status__c
                                      FROM Site_Visit__c WHERE Related_Source__c = :rl.Id]) {
                SiteVisitInfo svi = new SiteVisitInfo();
                svi.id = sv.Name;
                svi.visitDate = sv.Date__c;
                svi.notes = sv.Feedback__c;
                svi.projectName = sv.SLead__r.Allocated_Project__c;
                svi.visitStatusId = sv.Status__c;
                svi.isRevisit = (sv.Site_Visit_Type__c == 'Revisit');
                siteVisits.add(svi);
            }
        

            // FollowUps
            List<FollowUpInfo> followUps = new List<FollowUpInfo>();
            for (Follow_Up__c fu : [SELECT Id,Name, Related_Source__c, Scheduled_Date__c, Comments__c, Status__c,Subject__c,SLead__c
                                     FROM Follow_Up__c WHERE Related_Source__c =: rl.Id 
                                    ORDER BY Scheduled_Date__c DESC]) {
                FollowUpInfo fui = new FollowUpInfo();
                fui.id = fu.Name;
                fui.followUpDate = fu.Scheduled_Date__c;
                fui.notes = fu.Comments__c;
                fui.subject = fu.Subject__c;
                fui.followUpStatusId = fu.Status__c;
                followUps.add(fui);
            }
           

            // Call Details
            List<CallInfo> callDetails = new List<CallInfo>();
            for (Call_Detail__c c : [SELECT Id,Name, Call_ID__c, Lead__c, Call_Type__c,CreatedDate,Discription__c,Duration__c,Created_By_CP_Mobile_APP__c, Customer_Number__c, Status__c, Execuive_Number__c, Start_Time__c, End_Time__c, Duration_in_Minutes__c
                               FROM Call_Detail__c WHERE Related_Source__c = :rl.Id]) {
                CallInfo ci = new CallInfo();
                ci.id = c.Name;
                ci.callTypeID = c.Call_Type__c;
				ci.callTypeName = c.Call_Type__c;
                ci.duration = c.Created_By_CP_Mobile_APP__c == TRUE ?Integer.ValueOf(c.Duration__c)  : Integer.valueOf(c.Duration_in_Minutes__c);
                ci.description = c.Discription__c;
                ci.callStatusID = c.Status__c;
                ci.callStatusName = c.Status__c; // populate if needed
                ci.callDate = c.CreatedDate;
                callDetails.add(ci);
            }
            
          

            // Additional Notes
            List<AdditionalNoteInfo> additionalNotes = new List<AdditionalNoteInfo>();
            if (rl.id != null) {
                for (Call_Comments__c an : [ SELECT Id, Name, Related_Source__c, Lead__c, Comments__c, Created_Date__c,Title__c FROM Call_Comments__c
                    WHERE Related_Source__c =:rl.Id  ORDER BY Created_Date__c DESC   ]) {
                    AdditionalNoteInfo ani = new AdditionalNoteInfo();
                    ani.id = an.Name;
                    ani.noteDate = an.Created_Date__c;
                    ani.title = an.Title__c;
                    ani.notes = an.Comments__c;
                    additionalNotes.add(ani);
                }
            }

            LeadDataWrapper dataWrapper = new LeadDataWrapper();
            dataWrapper.contactInformation = contactInfo;
            dataWrapper.siteVisits = siteVisits;
            dataWrapper.followUp = followUps;
            dataWrapper.callDetails = callDetails;
            dataWrapper.additionalNotes = additionalNotes;

            ResponseWrapper res = new ResponseWrapper(true, 'lead detail', dataWrapper);
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

            // Log success
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;

        } catch (Exception e) {
            System.debug('Error fetching lead detail: ' + e);
           
            // sendError('Failed to fetch lead detail: ' + e.getMessage(), log, logInserted);

            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'LeadDetail_MobileAPI',requestBody);
        }
    }

    // ---------- Input Wrapper ----------
    public class LeadDetailWrapper {
        public String userId;
        public String leadId;
    }

    // ---------- Response Wrapper ----------
    public class ResponseWrapper {
        public Boolean status;
        public String message;
        public LeadDataWrapper data;
        public ResponseWrapper(Boolean s, String m, LeadDataWrapper d) {
            status = s;
            message = m;
            data = d;
        }
    }

    // ---------- Data Wrappers ----------
    public class LeadDataWrapper {
        public ContactInformation contactInformation;
        public List<SiteVisitInfo> siteVisits;
        public List<FollowUpInfo> followUp;
        public List<CallInfo> callDetails;
        public List<AdditionalNoteInfo> additionalNotes;
    }

    public class ContactInformation {
        public String leadStatusId;
        public String creatorName;
        public String phoneNumber;
        public String emailAddress;
        public String projectName;
        public String assignExecutive;
        public Datetime createdOn;
    }

    public class SiteVisitInfo {
        public String id;
        public Datetime visitDate;
        public String notes;
        public String projectName;
        public String visitStatusId;
        public Boolean isRevisit;
    }

    public class FollowUpInfo {
        public String id;
        public Datetime followUpDate;
        public String notes;
        public String subject;
        public String followUpStatusId;
    }

    public class CallInfo {
        public String id;
        public String callTypeID;
        public String callTypeName;
        public Integer duration;
        public String description;
        public String callStatusID;
        public String callStatusName;
        public Datetime callDate;
    }

    public class AdditionalNoteInfo {
        public String id;
        public Datetime noteDate;
        public String title;
        public String notes;
    }

    // ---------- Error Helper ----------
    /*
    private static void sendError(String msg, Apex_Log__c log, Boolean logInserted) {
        ResponseWrapper res = new ResponseWrapper(false, msg, null);
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);

        if (logInserted) {
            update log;
        } else {
            insert log;
        }
    }*/

}