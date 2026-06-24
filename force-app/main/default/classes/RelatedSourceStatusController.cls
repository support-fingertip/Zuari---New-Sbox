public without sharing class RelatedSourceStatusController {

    public static Boolean markleadUnqualified = false;

    // Terminal statuses where follow-up creation should be SKIPPED
    private static final Set<String> TERMINAL_STATUSES = new Set<String>{
        'Request for Rejection', 'Rejected', 'Closed Lost', 'Unqualified','Pre-Sales Unqualified','Pre-Sales Closed Lost'
    };

    public class dataWrapper {
        @AuraEnabled public String profileName { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
    }

    @AuraEnabled
    public static dataWrapper getLeadRecordTypeName(Id relatedSourceId) {
        dataWrapper dw = new dataWrapper();

        Related_Source__c rs = [
            SELECT RecordType.Name, Lead_Record_Type__c
            FROM Related_Source__c
            WHERE Id = :relatedSourceId
            LIMIT 1
        ];

        Id profileId = UserInfo.getProfileId();
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id = :profileId];

        dw.profileName = userProfile.Name;
        dw.recordTypeName = rs.RecordType.Name;
        return dw;
    }

    @AuraEnabled
    public static Boolean hasCompletedSiteVisit(Id relatedSourceId) {
        if (relatedSourceId == null) {
            return false;
        }
        Integer completedCount = [
            SELECT COUNT()
            FROM Site_Visit__c
            WHERE Related_Source__c = :relatedSourceId
            AND Status__c = 'Completed'
        ];
        return completedCount > 0;
    }

    @AuraEnabled
    public static String updateLeadWithStatus(
        Id relatedSourceId,
        String status,
        String lastnote,
        Datetime scheduleDate,
        String rating,
        String othercom,
        String openreason,
        String alloctreason,
        String leadQuality,
        Datetime followUpDate
    ) {
        String returnMessage = '';
        List<Lead_Unqualification__c> lqList = new List<Lead_Unqualification__c>();
        User currentUser = [
            SELECT Id, Name, Profile.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ];
        try {
            Related_Source__c rsRecord = [
                SELECT Id,SLead__c,Lead_status1__c,Last_Note__c,RecordTypeId,Lead_quality__c, RecordType.Name, Rating__c, Lead_Status__c,
                       Unqualified_Reason__c, Last_Unqualified_At__c, Remark__c, OwnerId,
                       Last_Unqualified_by__c, Mark_Unqualified__c, No_Of_Times_Unqualified__c,
                       Lead_Assigned__c, Closed_Lost_Reason__c, Reasons_in_Detail__c,
                       Reason_For_Rejection__c, Open_Reason__c, Allocated_Reason__c
                FROM Related_Source__c
                WHERE Id = :relatedSourceId
                LIMIT 1
            ];

            // ============================================================
            // Server-side backward-movement validation — strict forward-only.
            // ============================================================
            List<String> statusOrder;
            if (rsRecord.RecordType.Name == 'Pre Sales') {
                statusOrder = new List<String>{
                    'New', 'Open', 'RNR', 'Pre Sales Follow Up', 'Allocated', 'Site Visit Schedule',
                    'Request for Rejection', 'Rejected', 'Unqualified'
                        
                };
            } else {
                statusOrder = new List<String>{
                    'New Sales Enquiry', 'Sales RNR', 'Sales Follow up', 'Site Visit Schedule',
                    'SV Completed', 'Negotiation', 'Booked',
                    'Request for Rejection', 'Unqualified', 'Closed Lost'
                };
            }
            String existingStatus = rsRecord.Lead_status1__c;
            Integer newIdx = statusOrder.indexOf(status);
            Integer curIdx = (existingStatus == null) ? -1 : statusOrder.indexOf(existingStatus);
            if (String.isNotBlank(existingStatus)
                && newIdx != -1 && curIdx != -1 && newIdx < curIdx) {
                throw new AuraHandledException(
                    'You cannot move the Related Source status backward from ' 
                    + existingStatus + ' to ' + status + '.'
                );
            }

            // ============================================================
            // Follow-up creation is mandatory for EVERY status except the 4 terminal ones.
            // For Site Visit Schedule the follow-up uses the separate followUpDate so it is
            // tracked independently of the actual site visit date.
            // For every other non-terminal status the scheduleDate IS the follow-up date.
            // ============================================================
            if (!TERMINAL_STATUSES.contains(status)) {
                Datetime followUpDt = (status == 'Site Visit Schedule') ? followUpDate : scheduleDate;
                String subjectText = String.isNotBlank(othercom)
                    ? ('Follow up for ' + othercom)
                    : ('Follow up - ' + status);
                insert new Follow_Up__c(
                    Related_Source__c = relatedSourceId,
                    Scheduled_Date__c = followUpDt,
                    Subject__c        = subjectText
                );
            }

            // Insert Site Visit if applicable
            if (status == 'Site Visit Schedule' || status == 'Pre-Sales Site Visit Schedule') {
                insert new Site_Visit__c(
                    Related_Source__c = relatedSourceId,
                    Date__c           = scheduleDate,
                    Status__c         = 'Scheduled'
                );
            }

            User u = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            rsRecord.Lead_status1__c = status;

            // --- Append Notes Section ---
            if (String.isNotBlank(lastnote)) {
                Datetime dt = Datetime.now();
                String strTimeInAMorPM = dt.format('dd-MM-yy hh:mm a', 'Asia/Kolkata');

                Integer noteCount = 1;
                if (rsRecord.Last_Note__c == null) {
                    rsRecord.Last_Note__c = '';
                } else if (!rsRecord.Last_Note__c.trim().equals('')) {
                    List<String> notes = rsRecord.Last_Note__c.split('\nCall Summary ');
                    noteCount = notes.size();
                }

                rsRecord.Execuive_Count__c = noteCount;
                rsRecord.Last_Note__c += '\nCall Summary ' + noteCount + ': '
                    + u.Name + ' [' + strTimeInAMorPM + ']: '
                    + lastnote;

                Call_Comments__c comment = new Call_Comments__c();
                comment.Comments__c       = lastnote;
                comment.User_Profile__c   = currentUser.Profile.Name;
                comment.Related_Source__c = rsRecord.id;
                comment.Created_User__c   = currentUser.Id;
                comment.Created_Date__c   = System.now();

                if (rsRecord.SLead__c != null) {
                    comment.Lead__c = rsRecord.SLead__c;
                }

                insert comment;
            }

            Integer unqCount = (rsRecord.No_Of_Times_Unqualified__c == null) ? 0 : Integer.valueOf(rsRecord.No_Of_Times_Unqualified__c);

            // --- Handle Request for Rejection (Pre Sales, < 3 attempts) ---
            if (status == 'Request for Rejection' && rsRecord.RecordType.Name == 'Pre Sales' && unqCount < 3) {
                markleadUnqualified = true;
                rsRecord.Last_Unqualified_At__c     = System.now();
                rsRecord.Last_Unqualified_by__c     = UserInfo.getUserId();
                rsRecord.Mark_Unqualified__c        = true;
                rsRecord.No_Of_Times_Unqualified__c = unqCount + 1;
                rsRecord.Lead_Assigned__c           = false;
                rsRecord.Lead_status1__c            = 'New';
                rsRecord.Closed_Lost_Reason__c      = rating;
                rsRecord.Reasons_in_Detail__c       = othercom;

                Lead_Unqualification__c lq = new Lead_Unqualification__c();
                lq.User__c               = UserInfo.getUserId();
                lq.Unqualified_Reason__c = (rating == 'Other') ? (rating + ' : ' + othercom) : rating;
                lq.Unqualified_At__c     = System.now();
                lq.Related_Source__c     = rsRecord.Id;
                lq.Lead__c               = rsRecord.SLead__c;
                lq.Type__c               = 'Pre Sales';
                lqList.add(lq);
            }
            else if (status == 'Request for Rejection' && rsRecord.RecordType.Name == 'Sales') {
                User ur = [SELECT Id, ManagerId FROM User WHERE Id = :rsRecord.OwnerId];
                rsRecord.Closed_Lost_Reason__c = rating;
                rsRecord.Reasons_in_Detail__c  = othercom;

                Lead_Unqualification__c lq = new Lead_Unqualification__c();
                lq.User__c               = UserInfo.getUserId();
                lq.Unqualified_Reason__c = rating + ' : ' + othercom;
                lq.Unqualified_At__c     = System.now();
                lq.Related_Source__c     = rsRecord.Id;
                lq.Lead__c               = rsRecord.SLead__c;
                lq.Type__c               = 'Sales';
                lqList.add(lq);
            }
            if (status == 'Unqualified') {
                rsRecord.Unqualified_Reason__c = rating;
            }

            if (status == 'Rejected') {
                rsRecord.Reason_For_Rejection__c = rating;
            }
            
            if (status == 'Open') {
                rsRecord.Open_Reason__c = openreason;
            }
            if (status == 'Allocated') {
                rsRecord.Allocated_Reason__c = alloctreason;
            }
            if (status == 'Closed Lost' || status == 'Pre-Sales Unqualified' || status == 'Pre-Sales Closed Lost') {
                rsRecord.Closed_Lost_Reason__c = rating;
            }

            if (!lqList.isEmpty()) {
                insert lqList;
            }

            if (String.isBlank(rsRecord.Lead_quality__c) && String.isNotBlank(leadQuality)) {
                rsRecord.Lead_quality__c = leadQuality;
            }

            update rsRecord;
            returnMessage = 'Updated Successfully';
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }

        return returnMessage;
    }

    @AuraEnabled
    public static List<String> getUnqualifiedReasons() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Related_Source__c.Unqualified_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            options.add(entry.getLabel());
        }
        return options;
    }

    @AuraEnabled
    public static List<String> getClosedLostReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Related_Source__c.Closed_Lost_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
        }
        return stages;
    }

    @AuraEnabled
    public static List<String> getOpenReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Related_Source__c.Open_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
        }
        return stages;
    }

    @AuraEnabled
    public static List<String> getAllocatedReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Related_Source__c.Allocated_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
        }
        return stages;
    }

    @AuraEnabled
    public static String getLeadCurrentStatus(Id relatedSourceId) {
        return [SELECT Lead_status1__c FROM Related_Source__c WHERE Id = :relatedSourceId LIMIT 1].Lead_status1__c;
    }

    public class LeadQualityWrapper {
        @AuraEnabled public List<String> picklistValues;
        @AuraEnabled public String currentValue;
    }

    @AuraEnabled
    public static LeadQualityWrapper getLeadQuality(Id relatedSourceId) {
        LeadQualityWrapper wrap = new LeadQualityWrapper();

        List<String> leadQualityList = new List<String>();
        Schema.DescribeFieldResult fieldDescribe =
            Related_Source__c.Lead_Quality__c.getDescribe();

        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            leadQualityList.add(entry.getLabel());
        }
        wrap.picklistValues = leadQualityList;

        if (relatedSourceId != null) {
            Related_Source__c rs = [
                SELECT Lead_Quality__c
                FROM Related_Source__c
                WHERE Id = :relatedSourceId
                LIMIT 1
            ];
            wrap.currentValue = rs.Lead_Quality__c;
        }

        return wrap;
    }
  
@AuraEnabled
public static dataWrappers getLeadRecordTypeName1(Id relatedSourceId) {

    dataWrappers dw = new dataWrappers();

    Related_Source__c rs = [SELECT Lead_Record_Type__c FROM Related_Source__c WHERE Id = :relatedSourceId LIMIT 1];

    dw.statusOptions = new List<String>();

    Id recordTypeId = Schema.SObjectType.Related_Source__c
        .getRecordTypeInfosByName()
        .get(rs.Lead_Record_Type__c)
        .getRecordTypeId();

   ConnectApi.PicklistValuesCollection pvc =        ConnectApi.RecordUi.getPicklistValuesByRecordType('Related_Source__c',recordTypeId );

    ConnectApi.PicklistValues fieldValues = pvc.picklistFieldValues.get('Lead_status1__c');

    if(fieldValues != null){
        for(ConnectApi.PicklistValue pv : fieldValues.values){
            dw.statusOptions.add(pv.value);
        }
    }

    return dw;
}

public class dataWrappers {
    @AuraEnabled public String profileName;
    @AuraEnabled public String recordTypeName;
    @AuraEnabled public List<String> statusOptions;
}
}