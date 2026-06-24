public with sharing class HomeNotificationController {
    
    
    @AuraEnabled
    public static datawrapperfl getFollowUpInformation(Integer pageNumber,Integer pageSize)
    {
        datawrapperfl dwfl = new datawrapperfl();
        Integer offset = (pageNumber - 1)  * pageSize;
        Id currentUserId = UserInfo.getUserId();
        list<Follow_Up__c>followUpDetails = New list<Follow_Up__c>();
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';
        // Get the role of the current user
User currentUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];

        system.debug(isAdmin+'==='+ currentUser.UserRole);
        system.debug(pageNumber);
        system.debug(pageSize);
        system.debug(offset);
        
        
        List<Follow_Up__c> allCount = [Select Id,Name,Scheduled_Date__c,Status__c,Owner.Name,Related_Source__c,SLead__c,SLead__r.Name,SLead__r.Status,SLead__r.Last_Comment__c,SLead__r.Id,SLead__r.Lead_Age__c from Follow_Up__c  where Status__c='Scheduled' AND Scheduled_Date__c=today ];
        
        followUpDetails = [Select Id,Name,Scheduled_Date__c,Status__c,Owner.Name,Related_Source__c,Related_Source__r.Name__c,Related_Source__r.Lead_status1__c,Related_Source__r.Lead_Score__c,SLead__c,SLead__r.Name,SLead__r.Status,SLead__r.Last_Comment__c,SLead__r.Id,SLead__r.Lead_Age__c from Follow_Up__c  where Status__c='Scheduled' AND Scheduled_Date__c=today order by Scheduled_Date__c
                           LIMIT :pageSize OFFSET :offset];
        
        dwfl.FollowupldList = followUpDetails;
        dwfl.FollowupCount = allCount.size();
        
        return dwfl;
    }
    public class datawrapperfl{
        @AuraEnabled
        public Decimal FollowupCount {get; set;}
        @AuraEnabled
        public List<Follow_Up__c> FollowupldList {get; set;}
    }
   /* 
    @AuraEnabled
public static DataWrapperFL getFollowUpInformation(Integer pageNumber, Integer pageSize) {
    try {
        // Validate inputs
        if (pageNumber == null || pageNumber < 1) pageNumber = 1;
        if (pageSize == null || pageSize < 1) pageSize = 10;
        
        DataWrapperFL dwfl = new DataWrapperFL();
        Integer offset = (pageNumber - 1) * pageSize;
        Date today = Date.today();
        
        // Get paginated follow-ups for today
        dwfl.FollowupldList = [
            SELECT Id, Name, Scheduled_Date__c, Status__c, Owner.Name, 
                   SLead__c, SLead__r.Name, SLead__r.Status, 
                   SLead__r.Last_Comment__c, SLead__r.Id, SLead__r.Lead_Age__c 
            FROM Follow_Up__c  
            WHERE Status__c = 'Scheduled' 
            AND Scheduled_Date__c = :today 
            ORDER BY Scheduled_Date__c
            LIMIT :pageSize 
            OFFSET :offset
        ];
        
        // Get total count in single query (more efficient)
        dwfl.FollowupCount = [
            SELECT COUNT() 
            FROM Follow_Up__c  
            WHERE Status__c = 'Scheduled' 
            AND Scheduled_Date__c = :today
        ];
        
        return dwfl;
        
    } catch (Exception e) {
        System.debug('Error in getFollowUpInformation: ' + e.getMessage() + ' at ' + e.getLineNumber());
        throw new AuraHandledException('Error retrieving follow-up information: ' + e.getMessage());
    }
}

// Wrapper class with improved naming convention
public class DataWrapperFL {
    @AuraEnabled public List<Follow_Up__c> FollowupldList {get; set;}
    @AuraEnabled public Integer FollowupCount {get; set;}
}*/
    @auraEnabled
    public static datawrappersv getSiteVistInformation(Integer pageNumber,Integer pageSize)
    {
        datawrappersv dwsv = new datawrappersv();
      /* Integer offset = (pageNumber - 1) * pageSize;
        Id currentUserId = UserInfo.getUserId();
        list<Site_Visit__c>svDetails = New list<Site_Visit__c>();
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';
        List<Site_Visit__c> allCount =[Select Id,Name,SLead__c,Date__c,Status__c,Owner.Name,SLead__r.Name,SLead__r.Lead_status__c,SLead__r.Last_Comment__c,SLead__r.Id,Remainder_Date__c,Canceled_Reason__c,SLead__r.Description,SLead__r.Lead_Age__c from Site_Visit__c  where (Status__c='Scheduled' OR Status__c='Rescheduled' ) AND (Remainder_Date__c=today)];
        svDetails=[Select Id,Name,SLead__c,Date__c,Status__c,Owner.Name,SLead__r.Name,SLead__r.Lead_status__c,SLead__r.Last_Note__c,SLead__r.Id,Canceled_Reason__c,Remainder_Date__c,SLead__r.Description,SLead__r.Lead_Age__c from Site_Visit__c  where (Status__c='Scheduled' OR Status__c='Rescheduled' ) AND (Remainder_Date__c=today)  order by Date__c  LIMIT :pageSize OFFSET :offset];
        
	*/
        // Calculate Offset for Pagination
Integer offset = (pageNumber - 1) * pageSize;
Id currentUserId = UserInfo.getUserId();

// Check if the Current User is a System Administrator
Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';

// Construct the base query condition
String baseCondition = '(Status__c = \'Scheduled\' OR Status__c = \'Rescheduled\') AND (Remainder_Date__c = TODAY)';

// If the user is not an admin, filter records by OwnerId
if (!isAdmin) {
    baseCondition += ' AND OwnerId = :currentUserId';
}

// Fetch the Total Count of Site Visit Records Matching the Criteria
Integer totalSiteVisits = Database.countQuery(
    'SELECT COUNT() FROM Site_Visit__c WHERE ' + baseCondition
);

// Fetch Paginated Site Visit Records
List<Site_Visit__c> svDetails = Database.query(
    'SELECT Id, Name, SLead__c, Date__c, Status__c, Owner.Name, ' +
           'SLead__r.Name, SLead__r.Lead_status__c, SLead__r.Last_Note__c, ' +
           'SLead__r.Id, Canceled_Reason__c, Remainder_Date__c, ' +
           'SLead__r.Description, SLead__r.Lead_Age__c ' +
    'FROM Site_Visit__c ' +
    'WHERE ' + baseCondition + ' ' +
    'ORDER BY Date__c ' +
    'LIMIT :pageSize OFFSET :offset'
);

// Assign Values to Wrapper Class or Response Object
dwsv.SiteVisitldList = svDetails;
dwsv.Noofsitevisits = totalSiteVisits;

        
        
        return dwsv;
    }
    public class datawrappersv{
        @AuraEnabled
        public Decimal Noofsitevisits {get; set;}
        @AuraEnabled
        public List<Site_Visit__c> SiteVisitldList {get; set;}
    }
    @auraEnabled
    public static list<Follow_Up__c> getPendingFollowUpInformation()
    {
        Id currentUserId = UserInfo.getUserId();
        
        List<Follow_Up__c> followUpDetails=[Select Id,Name,Scheduled_Date__c,Status__c,Owner.Name,SLead__c,SLead__r.Last_Comment__c,SLead__r.Name,SLead__r.Status,SLead__r.Id,SLead__r.Lead_Age__c from Follow_Up__c  where (Status__c='Scheduled') AND Scheduled_Date__c < today And OwnerId = :UserInfo.getUserId() order by Scheduled_Date__c  ];
        System.debug(followUpDetails);
        return followUpDetails;
    }
    @auraEnabled
    public static datawrapper2 getReassignedLeads(Integer pageSize, Integer pageNumber)
    {
        
        
        
        Date today = Date.today();
        
        // Query LeadHistory for changes to the OwnerId field that happened today
        List<LeadHistory> leadHistoryList = [SELECT LeadId  FROM LeadHistory WHERE Field = 'Owner'     AND CreatedDate = TODAY];
        
        // Extract LeadIds from the history records
        Set<Id> leadIds = new Set<Id>();
        for (LeadHistory history : leadHistoryList) {
            leadIds.add(history.LeadId);
        }
        
        // Query the Lead records using the extracted LeadIds and filter by current owner and CreatedDate
        
        datawrapper2 dw2 = new datawrapper2();
        date dt = system.today() -7;
        Integer offset = (pageNumber - 1) * pageSize;
        Id currentUserId = UserInfo.getUserId();
        List<Lead> lstld= new  List<Lead>();
        List<Lead> lstldnewLead= new  List<Lead>();
        List<Lead> totalld= new  List<Lead>();
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';
       lstld = [SELECT Id, Name, OwnerId, CreatedDate,Allocated_Project__c,Phone__c/*,(select id,name from Call_Details__r where createddate = today)*/ FROM Lead WHERE Id IN :leadIds  AND CreatedDate < TODAY
                 ORDER BY CreatedDate DESC 
                 LIMIT :pageSize OFFSET :offset];
        for(Lead ld : lstld){
            if(ld.Call_Details__r.size() == 0){
                lstldnewLead.add(ld);
            }
        }
        dw2.noActivityldList = lstldnewLead;
        totalld = [SELECT Id, Name, OwnerId,Allocated_Project__c,Phone__c, CreatedDate FROM Lead WHERE Id IN :leadIds AND CreatedDate < TODAY
                   ORDER BY CreatedDate DESC];    
        dw2.noActivityCount = totalld.size();
        
        return dw2;
    }
    @auraEnabled
    public static list<Site_Visit__c> getPendingSiteVistInformation()
    {
        System.debug('Sv Details');
        List<Site_Visit__c> svDetails=[Select Id,Name,SLead__c,Date__c,Status__c,Owner.Name,SLead__r.Last_Comment__c,SLead__r.Name,SLead__r.Status,SLead__r.Id,Canceled_Reason__c,SLead__r.Description,SLead__r.Lead_Age__c from Site_Visit__c  where (Status__c='Scheduled' OR Status__c='Reschedule') AND Date__c < today AND  OwnerId = :UserInfo.getUserId() order by Date__c ];
        return svDetails;
    }
   /* @auraEnabled
    public static list<Task> getMissedCallTask()
    {
        List<Task> taskDetails=[select  id,subject,TaskSubtype,Status,Owner.Name,whoid,who.Name from task where subject='Missed Call' AND TaskSubtype='Task' AND Status='Open' AND whoid!=null AND ownerId=:userinfo.getUserId()];
        System.debug(taskDetails);
        return taskDetails;
    }*/
    
    @auraEnabled
    public static list<Call_Detail__c> getMissedCallTask()
    {
         Id currentUserId = UserInfo.getUserId();
        List<Call_Detail__c> taskDetails=[SELECT Id,Lead__c,Lead__r.Name,Lead__r.Lead_Status__c,Lead__r.OwnerId,Lead__r.Owner.Name,Call_From__c,Status__c,   Lead__r.Last_Note__c,    Start_Time__c FROM     Call_Detail__c WHERE     CreatedDate = TODAY    AND Status__c IN ('Customer Busy', 'BUSY', 'CANCEL','EXECUTIVE BUSY')    AND Lead__r.OwnerId = :currentUserId    AND Lead__c != NULL];
        System.debug(taskDetails);
        return taskDetails;
    }
    
    @auraEnabled
    public static String updateSvDetils(String recID,String svStatus,String updateValue,String siterating, String conducatedDate)
    {
        System.debug(conducatedDate+'===='+updateValue);
        list<Site_Visit__c> svData=[select Id,Name,SLead__c,Status__c,Feedback__c,Date__c,Canceled_Reason__c from Site_Visit__c where id=:recID];
        if(svData.size()>0)
        {
            svData[0].Status__c=svStatus;
            if(svStatus=='Cancelled')
                svData[0].Canceled_Reason__c=updateValue;
            else if(svStatus=='Completed') {	 
                if(conducatedDate!=null && conducatedDate!=''&& siterating!=''){
                   String formattedFollowUpDate = followUpController.dateFormat(conducatedDate);
                    svData[0].SV_Completed_Date_Time__c=datetime.valueOf(formattedFollowUpDate);
                }
                svData[0].Feedback__c=updateValue;
                svData[0].Site_Visit_Rating__c=siterating;
            } 
            else if(svStatus=='Rescheduled')
            {
                String formattedFollowUpDate = followUpController.dateFormat(conducatedDate);
                svData[0].Reschedule_Date__c = datetime.valueOf(formattedFollowUpDate);
            } 
            update  svData[0];
            return 'Updated';
        }
        return null;
    }
  /*  
    @auraEnabled
    public static String updateFollowupDetails(String recID, String FLStatus, String comments) {
        List<Follow_Up__c> svData = [SELECT Id, Status__c,Expected_Follow_Up__c, Next_Follow_Up_Date__c,Description__c FROM Follow_Up__c WHERE Id = :recID LIMIT 1];
        if (!svData.isEmpty()) {
            svData[0].Status__c = FLStatus;
            svData[0].Comments__c = comments;
            update svData[0];
            return 'Updated';
        } 
        else {
            return 'Record not found';
        }
    }
    */
    
    @AuraEnabled
    public static String updateFollowupDetails(
        String recID,
        String FLStatus,
        String comments,
        String expectedFollowUp,
        Date nextFollowUpDate
    ) {
        Follow_Up__c fu = [
            SELECT Id, Status__c, Comments__c, Expected_Follow_Up__c, Next_Follow_Up_Date__c
            FROM Follow_Up__c
            WHERE Id = :recID
            LIMIT 1
        ];
        
        fu.Status__c = FLStatus;
        fu.Comments__c = comments;
        
        //Mapping
        fu.Expected_Follow_Up__c = expectedFollowUp;
        fu.Next_Follow_Up_Date__c = nextFollowUpDate;
        
        update fu;
        return 'Updated';
    }
    
    
    
    @AuraEnabled
    public static datawrapper todaysLeads(Integer pageSize, Integer pageNumber){
        datawrapper dw = new datawrapper();
        Integer offset = (pageNumber - 1) * pageSize;
        Id currentUserId = UserInfo.getUserId();
        List<Lead> lstld;
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';
        lstld = [SELECT id,Name,Lead_Type__c,Lead_ID__c,Status,Lead_source__c,Lead_Age__c,Allocated_Project__c,Email,Secondary_Email__c,Phone__c,Secondary_Phone__c,createddate/*,Last_Modified_Date__c,(select id from call_details__r) */
                 FROM Lead 
                 WHERE createddate = TODAY 
                 ORDER BY CreatedDate DESC 
                 LIMIT :pageSize OFFSET :offset];
        
        List<Lead> lstld1 =[select id,Name,Lead_Type__c,Lead_ID__c,Lead_Age__c,Status,Lead_source__c,Allocated_Project__c,Email,Secondary_Email__c,Phone__c,Secondary_Phone__c/*,Last_Modified_Date__c*/,createddate from Lead where createddate=today];
        List<Lead> lstld2 =[select id,Name,Lead_Type__c,Lead_ID__c,Lead_Age__c,Status,Lead_source__c,Allocated_Project__c,Email,Secondary_Email__c,Phone__c,Secondary_Phone__c,/*Last_Modified_Date__c,*/createddate from Lead where createddate=today And Lead_Type__c='Re-Engaged'];
        dw.ldListtodays = lstld;
        dw.todaysldCount = lstld1.size();
        dw.ldreengagedleads = lstld2.size();
        return dw;
    }
    
    public class datawrapper{
        @AuraEnabled
        public Decimal todaysldCount {get; set;}
        @AuraEnabled
        public List<Lead> ldListtodays {get; set;}
        @AuraEnabled
        public Decimal ldreengagedleads {get; set;}
    }
    
    public class datawrapper2{
        @AuraEnabled
        public Decimal noActivityCount {get; set;}
        @AuraEnabled
        public List<Lead> noActivityldList {get; set;}
    }
    @AuraEnabled
    public static String getUserName() {
        String userId = UserInfo.getUserId();
        User currentUser = [SELECT Name FROM User WHERE Id = :userId];
        return currentUser.Name;
    }
    @AuraEnabled
    public static datawrapper2 getnoactivityleads(Integer pageSize, Integer pageNumber) {
        datawrapper2 dw2 = new datawrapper2();
        date dt = system.today() -7;
        Integer offset = (pageNumber - 1) * pageSize;
        Id currentUserId = UserInfo.getUserId();
        List<Lead> lstld= new  List<Lead>();
        List<Lead> totalld= new  List<Lead>();
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';
        lstld = [select Id, Name,Lead_ID__c,Allocated_Project__c,Phone__c from Lead where Lead_Status__c != 'Unqualifed' AND Lead_Status__c != 'Closed Lost' AND Lead_Status__c != 'Booked' AND LastmodifiedDate < :dt AND (Id NOT IN (select SLead__c from Site_visit__c where LastmodifiedDate >=:dt)) AND (Id NOT IN (select SLead__c from Follow_up__c where LastmodifiedDate >=:dt))
                 ORDER BY CreatedDate DESC 
                 LIMIT :pageSize OFFSET :offset];
        dw2.noActivityldList = lstld;
        totalld = [select Id, Name,Lead_ID__c,Allocated_Project__c,Phone__c from Lead where Lead_Status__c != 'Unqualifed' AND Lead_Status__c != 'Closed Lost' AND Lead_Status__c != 'Booked' AND LastmodifiedDate < :dt AND (Id NOT IN (select SLead__c from Site_visit__c where LastmodifiedDate >=:dt)) AND (Id NOT IN (select SLead__c from Follow_up__c where LastmodifiedDate >=:dt))
                   ORDER BY CreatedDate DESC];    
        dw2.noActivityCount = totalld.size();
        
        return dw2;
    }
    
    @AuraEnabled
    public static datawrapper2 getNoFollowUpLeads(Integer pageSize, Integer pageNumber){
        
        datawrapper2 dw2 = new datawrapper2();
        date dt = system.today() -7;
        Integer offset = (pageNumber - 1) * pageSize;
        Id currentUserId = UserInfo.getUserId();
        List<Lead> lstld= new  List<Lead>();
        List<Lead> totalld= new  List<Lead>();
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';
        lstld = [SELECT Id, Name,Lead_ID__c,Allocated_Project__c,Phone__c FROM Lead WHERE Id NOT IN (SELECT SLead__c FROM Follow_Up__c) AND Lead_Status__c != 'Unqualifed' AND Lead_Status__c != 'Closed Lost' AND Lead_Status__c != 'Booked'
                 ORDER BY CreatedDate DESC 
                 LIMIT :pageSize OFFSET :offset];
        dw2.noActivityldList = lstld;
        totalld = [SELECT Id, Name,Lead_ID__c,Allocated_Project__c,Phone__c FROM Lead WHERE Id NOT IN (SELECT SLead__c FROM Follow_Up__c) AND Lead_Status__c != 'Unqualifed' AND Lead_Status__c != 'Closed Lost' AND Lead_Status__c != 'Booked'
                   ORDER BY CreatedDate DESC];    
        dw2.noActivityCount = totalld.size();
        
        return dw2;
        
        
        
    }
    
   /* @AuraEnabled
    public static datawrapper4 todaysBookings(Integer pageSize, Integer pageNumber){
        datawrapper4 dw4 = new datawrapper4();
        Integer offset = (pageNumber - 1) * pageSize;
        Id currentUserId = UserInfo.getUserId();
        List<Booking__c> lstbook;
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name == 'System Administrator';
        lstbook = [SELECT id,Name,Project__c,Stage__c,Contact_Telephone_Number__c,Block_Number__c,Contact_Telephone_Number1__c,Mobile__c,Mobile_Primary1__c,Mobile_Primary2__c,createddate 
                   FROM Booking__c 
                   WHERE createddate = TODAY 
                   ORDER BY CreatedDate DESC 
                   LIMIT :pageSize OFFSET :offset];
        dw4.ldListbooking = lstbook;
        dw4.Noofbooking = lstbook.size();
        return dw4;
    }*/
    
    public class datawrapper4{
        @AuraEnabled
        public List<Booking__c> ldListbooking {get; set;}
        @AuraEnabled
        public integer Noofbooking {get; set;}
        
    }

}