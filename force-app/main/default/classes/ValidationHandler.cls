public class ValidationHandler {
    
    public static String CheckScheduleSiteVist(List<Lead> ldlst){
        
        Set<Id> ldid = new Set<Id>();
        for(Lead ld : ldlst){
            ldid.add(ld.Id);
        }
      /*  List<Follow_up__c> followup = [SELECT Id, Status__c FROM Follow_up__c WHERE SLead__c IN :ldid  ORDER BY CreatedDate DESC LIMIT 1]; 
        
        if (!followup.isEmpty() && followup[0].Status__c != 'Completed') {
            return 'Please complete the last Follow-Up before updating the Lead Status to "Site Visit Scheduled".';
        }
        */
        List<Site_Visit__c> sitelst = [select id,Status__c,SLead__c from Site_Visit__c where SLead__c IN : ldid and Status__c='Scheduled'];
        
        if(sitelst.isEmpty()){
            return 'Please Create a Site Visit before updating the Lead Status To Site Visit Scheduled';
        }
        return null;
        
    }

}