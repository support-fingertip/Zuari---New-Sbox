@isTest
public class LeadStatusControllerTest {
    
    @isTest
    public static void method() {
      
        Lead lad= new Lead();
        lad.LastName='test';
        lad.Allocated_Project__c = 'Zuari Garden City';
        lad.Phone = '9182748514';
        lad.Source_Type__c='Digital Marketing';
        lad.Lead_source__c = 'Social Media';
        lad.Lead_Status__c ='New';
        lad.OwnerId = UserInfo.getUserId();
        lad.Lead_Assigned__c = false;
        lad.IsPushed__c = true;
        lad.Company='test';
        insert lad;
        
        DateTime dt = System.Now().addDays(1);
        
        Test.startTest();
        
        //  Cover getRecordTypeName
        LeadStatusController.getLeadRecordTypeName(lad.Id);
        
        //  Cover picklist methods
        LeadStatusController.getUnqualifiedReasons();
        LeadStatusController.getClosedLostReason();
        LeadStatusController.getOpenReason();
        LeadStatusController.getAllocatedReason();
        
        //  Cover "Open"
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Open', dt, 'Hot', 'TestOpen', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "RNR"
        LeadStatusController.updateLeadWithStatus(lad.Id, 'RNR', dt, 'Hot', 'TestRNR', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Pre Sales Follow Up"
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Pre Sales Follow Up', dt, 'Warm', 'TestFollowup', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Sales Follow up"
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Sales Follow up', dt, 'Cold', 'TestSalesFollowup', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Site Visit Schedule"
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Site Visit Schedule', dt, 'Hot', 'TestVisit', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Unqualified" (normal rating)
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Unqualified', dt, 'Hot', 'Normal Reason', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Unqualified" with rating = Other (special branch)
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Unqualified', dt, 'Other', 'Other Comments', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Closed Lost"
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Closed Lost', dt, 'Budget Issue', 'Detailed reason', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Allocated"
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Allocated', dt, 'Hot', 'TestAlloc', 'ReasonOpen', 'ReasonAlloc');
        LeadStatusController.updateLeadWithStatus(lad.Id, 'Request For Rejection', dt, 'Hot', 'TestAlloc', 'ReasonOpen', 'ReasonAlloc');
        
        Test.stopTest();
    }
}