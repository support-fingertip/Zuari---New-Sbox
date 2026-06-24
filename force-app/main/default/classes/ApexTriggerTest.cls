@IsTest
public class ApexTriggerTest {
    
    public static testMethod void getSLeadTriggerTest() {
        Apex_Log__c ap = new Apex_Log__c();
        ap.Error_Message__c ='test';
        
        insert ap;
    }

}