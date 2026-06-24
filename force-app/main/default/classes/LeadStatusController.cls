public with sharing class LeadStatusController {
    
    public static Boolean markleadUnqualified=false;
    
    public class dataWrapper{
        @AuraEnabled
        public string profileName{get;set;}
        @AuraEnabled
        public string recordTypeName{get;set;}
    }
    
    @AuraEnabled
    public static dataWrapper getLeadRecordTypeName(Id leadId) {
        dataWrapper dw = new dataWrapper();
        Lead lead = [SELECT RecordType.Name,Lead_Record_Type__c FROM Lead WHERE Id = :leadId LIMIT 1];
        Id profileId = UserInfo.getProfileId();
        
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id = :profileId];
        dw.profileName = userProfile.Name;
        dw.recordTypeName = lead.RecordType.Name;
        return dw;
    }
    
    @AuraEnabled
    public static String updateLeadWithStatus(Id leadId, String status, DateTime scheduleDate, String rating, String othercom, String openreason,String alloctreason) {
        String returnmessage='';
        Lead leadRecord = [SELECT Id, Status,RecordTypeId, RecordType.Name, Rating,Lead_Status__c, Unqualified_Reason__c,Last_Unqualified_At__c,Remark__c,OwnerId,
                           Last_Unqualified_by__c,Mark_Unqualified__c,No_Of_Times_Unqualified__c,Lead_Assigned__c FROM Lead WHERE Id = :leadId LIMIT 1];
        system.debug(rating);
        List<Lead_Unqualification__c> lqlst = new List<Lead_Unqualification__c>();
        
        try{
            
            if (status == 'RNR' || status == 'Pre Sales Follow Up'|| status == 'Sales Follow up') {
                insert new Follow_Up__c(
                    SLead__c = leadId,
                    Scheduled_Date__c = scheduleDate,
                    Subject__c = 'Follow up for ' + othercom
                );
            }
            
            if (status == 'Site Visit Schedule') {
                system.debug('Inside');
                insert new Site_Visit__c(
                    SLead__c = leadId,
                    Date__c = scheduleDate,
                    Status__c = 'Scheduled'
                );
            }
            
            user u = [SELECT Id,Name,Profile.Name FROM user WHERE Id=:userinfo.getUserId()];
            
            leadRecord.Lead_Status__c = status;
            //leadRecord.Closed_Lost_Reason__c=rating;
            if(status == 'Request For Rejection' && leadRecord.RecordType.Name=='Pre Sales' && leadRecord.No_Of_Times_Unqualified__c < 3){
                markleadUnqualified = true;
                leadRecord.Last_Unqualified_At__c = system.now();
                leadRecord.Last_Unqualified_by__c = UserInfo.getUserId();
                leadRecord.Mark_Unqualified__c = true;
                leadRecord.No_Of_Times_Unqualified__c += 1;
                leadRecord.Lead_Assigned__c = false;
                leadRecord.Lead_status__c = 'New';
                leadRecord.Reason_For_Rejection__c=rating;
                leadRecord.Reasons_in_Detail__c=othercom;
                
                Lead_Unqualification__c lq = new Lead_Unqualification__c();
                lq.User__c = UserInfo.getUserId();
                if (rating == 'Other') {
                    lq.Unqualified_Reason__c = rating +' : '+othercom;
                }
                else{
                    lq.Unqualified_Reason__c = rating;
                }
                lq.Unqualified_At__c = system.now();
                lq.Lead__c =leadRecord.Id;
                lq.Type__c='Pre Sales';
                lqlst.add(lq);
            }
            else if(status == 'Request For Rejection' && leadRecord.RecordType.Name=='Sales'){
                User ur= [select id,ManagerId from User where Id =:leadRecord.OwnerId];
                leadRecord.OwnerId=ur.ManagerId;
                leadRecord.Closed_Lost_Reason__c=rating;
                leadRecord.Reasons_in_Detail__c=othercom;
                
                Lead_Unqualification__c lq = new Lead_Unqualification__c();
                lq.User__c = UserInfo.getUserId();
                lq.Unqualified_Reason__c = rating +' : '+othercom;
                lq.Unqualified_At__c = system.now();
                lq.Lead__c =leadRecord.Id;
                lq.Type__c='Sales';
                lqlst.add(lq);
            }
            if(status == 'Unqualified'){
                leadRecord.Unqualified_Reason__c=rating;
            }
            if(status == 'Rejected'){
                leadRecord.Reason_For_Rejection__c=rating;
            }
            if(status == 'Closed Lost'){
                leadRecord.Closed_Lost_Reason__c=rating;
            }
            if(status == 'Open'){
                leadRecord.Open_Reason__c=openreason;
            }
            if(status == 'Allocated'){
                leadRecord.Allocated_Reason__c=alloctreason;
            }
            if(lqlst.size()>0){
                insert lqlst;
            }
            
            update leadRecord;
            returnmessage= 'Updated Successully';
        }
        catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Get the error message for the current error
                String errorMessage = e.getDmlMessage(i);
                // You can log or handle the error message as needed
                System.debug('An error occurred: ' + errorMessage);
                returnmessage= errorMessage;
                return returnmessage;
            }
        }
        return returnmessage;
    }
    @AuraEnabled
    public static List<String> getUnqualifiedReasons() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Lead.Unqualified_Reason__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            options.add(entry.getLabel());
        }
        return options;
    }
    
    @AuraEnabled
    public static List<String> getClosedLostReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Lead.Reason_For_Rejection__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
            
        }
        system.debug('stages '+stages);
        return stages;
    }
    
    @AuraEnabled
    public static List<String> getOpenReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Lead.Open_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
        }
        system.debug('stages '+stages);
        return stages;
    }
    
    @AuraEnabled
    public static List<String> getAllocatedReason() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Lead.Allocated_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            stages.add(entry.getLabel());
        }
        system.debug('stages '+stages);
        return stages;
    }
}