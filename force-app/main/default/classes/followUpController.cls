public class followUpController {
    
    @AuraEnabled
public static List<Follow_Up__c> getFollowUpDetails(Id leadId) {
    return [SELECT Scheduled_Date__c, Status__c FROM Follow_Up__c WHERE SLead__c = :leadId AND Status__c = 'Scheduled' ORDER BY CreatedDate DESC LIMIT 1 ];
}

    
    public static String dateFormat(String followupdate)
    { 	String dateTimeFormatted='';	
     String formattedDate='';
     String[] splitDateTime=followupdate.split(',');
     String[] splitDate=splitDateTime[0].split('/');
     for(integer i=splitDate.size()-1;i>=0;i--)
     {
         formattedDate+=splitDate[i];
         if(i!=0)
             formattedDate+='-';
     }
     
     dateTimeFormatted=	formattedDate+' '+splitDateTime[1];
     
     return dateTimeFormatted;
    }
}