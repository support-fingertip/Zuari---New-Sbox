@isTest
public class HomeNotificationControllerTest {
    
    @isTest
    public static void testAllMethods() {
       // List<Follow_Up__c> followUps = HomeNotificationController.getFollowUpInformation(1,2);
        
      //  List<Site_Visit__c> siteVisits = HomeNotificationController.getSiteVistInformation();
        
        List<Follow_Up__c> pendingFollowUps = HomeNotificationController.getPendingFollowUpInformation();
        
        List<Site_Visit__c> pendingSiteVisits = HomeNotificationController.getPendingSiteVistInformation();
        
        String svId = ''; 
      //  String updateResult = HomeNotificationController.updateSvDetils(svId, 'Cancelled', 'Cancelled Comments', null);
        
        String followUpId = ''; 
       // String updateFollowupResult = HomeNotificationController.updateFollowupDetails(followUpId, 'Updated Status');
        
        HomeNotificationController.datawrapper leadsData = HomeNotificationController.todaysLeads(10, 1); 
        HomeNotificationController.datawrapperfl leadsData1 = HomeNotificationController.getFollowUpInformation(10, 1); 
        HomeNotificationController.datawrappersv svdatat = HomeNotificationController.getSiteVistInformation(10, 1);  
        HomeNotificationController.datawrapper2 reaslead = HomeNotificationController.getReassignedLeads(10, 1); 
        
      String svstat=   HomeNotificationController.updateSvDetils(svId,'Cancelled','Lead is Closed Lost','Hot','2024-10-10');
      //String flstat=   HomeNotificationController.updateFollowupDetails(followUpId,'Cancelled','Lead is Closed Lost');
      // List<Call_Detail__c> calldate = HomeNotificationController.getMissedCallTask();  
        HomeNotificationController.datawrapper2 reaslead1 = HomeNotificationController.getnoactivityleads(10, 1); 
        HomeNotificationController.datawrapper2 reaslead11 = HomeNotificationController.getNoFollowUpLeads(10, 1); 
       HomeNotificationController.getUserName();
    }
}