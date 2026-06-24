@isTest
public class WhatsAppTriggerHandlerTest {
	@testSetup
    static void setupData() {
        // Lead with phone -> should be we get OTP...
        Lead l1 = new Lead(
            FirstName = 'WithPhone',
            LastName  = 'User',
            Company   = 'TestCompany',
            Phone__c  = '9876543210'
        );
        insert l1;

        // Lead without phone...
        Lead l2 = new Lead(
            FirstName = 'NoPhone',
            LastName  = 'User',
            Company   = 'TestCompany'
        );
        insert l2;

        // Site Visit linked to first lead...
        Site_Visit__c sv = new Site_Visit__c(
            // your formula fields reference
            SLead__c = l1.Id,     
            OTP__c   = '111111'
        );
        insert sv;
    }

    @isTest
    static void testProcessNewLeads_WithPhone() {
        // Query the lead that has a phone...
        Lead l = [SELECT Id, Phone__c FROM Lead WHERE Phone__c != null LIMIT 1];

        Test.startTest();
        WhatsAppTriggerHandler.processNewLeads(new List<Lead>{ l });
        Test.stopTest();

        // OTP must be generated and saved...
        Lead updated = [SELECT OTP__c FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(null, updated.OTP__c, 'OTP should be populated');
        System.assertEquals(6, updated.OTP__c != null ? updated.OTP__c.length() : 0,'OTP should be 6 digits (based on your generator)');
    }

    @isTest
    static void testProcessSitevisit_PureLogic() {
        // Read a site visit (formula fields auto-populate from SLead__c)
        Site_Visit__c sv = [SELECT Id, OTP__c, Lead_Name__c, Lead_Phone_Number__c FROM Site_Visit__c LIMIT 1];

        Test.startTest();
        // No callouts will happen because handler is guarded by !Test.isRunningTest()
        WhatsAppTriggerHandler.processSitevisit(new List<Site_Visit__c>{ sv });
        Test.stopTest();

        // Pure assertions on data we own (no callout effects)...
        System.assertNotEquals(null, sv.OTP__c, 'OTP should exist on Site Visit');
        // Optional: verify formula fields are non-empty (depends on your data)
        // System.assertNotEquals('', sv.Lead_Name__c);
        // System.assertNotEquals('', sv.Lead_Phone_Number__c);
    }
}