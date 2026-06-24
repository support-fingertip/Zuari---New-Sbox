public class pushToSalesController {
    
    public static Boolean pushToSales=false;
    @auraEnabled
    public static string moveToSales(string LeadId, string addNote){
        pushToSales = true;
       // system.debug(project);
        Lead ld = [SELECT Id,Lead_Status__c,Pre_sales_user__c,OwnerId,Lead_Transfer_Note__c,RecordTypeId,Lead_Assigned__c,Allocated_Project__c,Pushed_On__c,Pushed_By__c	 FROM Lead WHERE Id=:LeadId];
        //ld.status ='Qualified';
        ld.Pre_sales_user__c = ld.OwnerId;
        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        ld.Lead_Assigned__c = false;
        //ld.Projects__c = projectType;
        //ld.Allocated_Project__c = project;
        ld.Lead_Status__c = 'New sales enquiry';
        ld.Pushed_On__c = system.now();
        ld.Pushed_By__c = UserInfo.getUserId();
        ld.IsPushed__c=true;
        ld.Lead_Transfer_Note__c=addNote;
        
        update ld;
      //  ListView lw= [SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE SobjectType='Lead' AND DeveloperName='TodaysLeads'];
        return ld.Id;
    }
 @auraEnabled
    public static Integer CheckFollowups(string LeadId){
        List<Follow_up__c>fplist = [SELECT Id, Name, Status__c, OwnerId, SLead__c FROM Follow_up__c WHERE Status__c='Scheduled' AND SLead__c=:LeadId];
        return fplist.size();
    }
    @AuraEnabled
    public static Boolean isSiteVisitScheduled(string LdId) {
        system.debug('Inside the the validation' + LdId);
        List<Site_Visit__c> sitelst = [select id,Status__c from Site_Visit__c where SLead__c =: LdId and Status__c='Scheduled'];
        System.debug(sitelst.size());
        if(sitelst.isEmpty()){
            return false;
        }
        else{
            return true;
        }
        
       // return null;
       // Integer siteVisitCount = [SELECT COUNT() FROM Site_Visit__c WHERE Lead__c = :leadId AND Status__c = 'Scheduled'];
      //system.debug(siteVisitCount);
        // Return true if there is at least one scheduled site visit
       // return siteVisitCount > 0;
       
    }
}