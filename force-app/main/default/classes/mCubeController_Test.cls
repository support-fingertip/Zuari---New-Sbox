@istest 
public class mCubeController_Test {

    @testSetup
    static void setupData() {
        // Insert MCUBE config once
        MCUBE_Object_Api__c m = new MCUBE_Object_Api__c();
        m.name = 'Lead';
        m.Field_to_Compare_Mobile_Incoming_Number__c = 'MobilePhone';
        m.field__c  = 'FirstName';
        m.field1__c = 'LastName';
        m.field2__c = 'Company';
        m.Value__c  = 'TestCompany';
        m.value1__c = 'TestLast';
        m.value2__c = 'TestCo';
        m.LandingNumber__c = '9987765432';
        insert m;

        // Insert Lead
        Lead lead = new Lead();
        lead.LastName   = 'Test Lead';
        lead.Company    = 'TestCompany';
        lead.Phone      = '67878';
        lead.MobilePhone = '1111111';
        lead.Email      = 'standarduser@testorgfil.com';
        insert lead;

        // Insert Related Source linked to lead
        Related_Source__c rs = new Related_Source__c();
        rs.SLead__c      = lead.Id;
        rs.Phone__c      = '1111111';
        rs.Source_Type__c = 'Digital Marketing';
        rs.Is_Locked__c  = false;
        insert rs;

        // Insert User
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        User u = new User(
            Alias            = 'standt12',
            Email            = 'standarduser@testorgfil.com',
            EmailEncodingKey = 'UTF-8',
            LastName         = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey     = 'en_US',
            ProfileId        = p.Id,
            TimeZoneSidKey   = 'America/Los_Angeles',
            UserName         = 'standarduser@testorg.com.123',
            MobilePhone      = '111'
        );
        u.massdialerIds__c = ',' + lead.Id;
        insert u;
    }

    // ── Inbound CONNECTING ──────────────────────────────────────────────────
    @istest
    static void testInboundConnecting() {
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);

        String data = '{"dialstatus":"CONNECTING","endtime":"' + system.now() 
                    + '","starttime":"' + system.now() 
                    + '","empnumber":"111","callfrom":"1111111"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
    }

    // ── Inbound ANSWER ──────────────────────────────────────────────────────
    @istest
    static void testInboundAnswer() {
        // Need a pre-existing Call_Detail__c with matching Call_ID for the ANSWER branch
        Call_Detail__c cd = new Call_Detail__c();
        cd.Call_ID__c   = 'TESTCALLID001';
        cd.Call_From__c = '1111111';
        cd.Call_Type__c = 'Inbound Call';
        cd.Status__c    = 'CONNECTING';
        insert cd;

        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);

        String data = '{"dialstatus":"ANSWER","callid":"TESTCALLID001","endtime":"' + system.now() 
                    + '","starttime":"' + system.now() 
                    + '","empnumber":"111","callfrom":"1111111"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
    }

    // ── Outbound ORIGINATE ──────────────────────────────────────────────────
    @istest
    static void testOutboundOriginate() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);

        String data = '{"status":"ORIGINATE","callid":"TESTCALLID002","endtime":"' + system.now() 
                    + '","starttime":"' + system.now() 
                    + '","executive":"111","customer":"1111111","refid":"' + lead.Id + '"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
    }

    // ── Outbound CALL COMPLETE ──────────────────────────────────────────────
    @istest
    static void testOutboundComplete() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        // Pre-insert a Call_Detail__c so the update branch is hit
        Call_Detail__c cd = new Call_Detail__c();
        cd.Call_ID__c   = 'TESTCALLID003';
        cd.Call_From__c = '111';
        cd.Call_Type__c = 'Outbound Call';
        cd.Status__c    = 'ORIGINATE';
        insert cd;

        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);

        String data = '{"status":"CALL COMPLETE","callid":"TESTCALLID003","endtime":"' + system.now() 
                    + '","starttime":"' + system.now() 
                    + '","executive":"111","customer":"1111111","refid":"' + lead.Id + '"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
    }

    // ── routecalling – new lead (no RS match) ───────────────────────────────
    @istest
    static void testRouteCallingNewLead() {
        Test.setCurrentPageReference(new PageReference('/report/Callroute'));
        ApexPages.currentPage().getParameters().put('fromnumber',    '9983345562');
        ApexPages.currentPage().getParameters().put('landingNumber', '9987765432');
        mCubeController.routecalling();
    }

    // ── routecalling – existing RS Step 1 (non-excluded, unlocked) ──────────
    @istest
    static void testRouteCallingExistingRS() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Related_Source__c rs = new Related_Source__c();
        rs.SLead__c       = lead.Id;
        rs.Phone__c       = '7771112098';
        rs.Source_Type__c = 'Digital Marketing';
        rs.Is_Locked__c   = false;
        insert rs;

        Test.setCurrentPageReference(new PageReference('/report/Callroute'));
        ApexPages.currentPage().getParameters().put('fromnumber',    '7771112098');
        ApexPages.currentPage().getParameters().put('landingNumber', '9987765432');
        mCubeController.routecalling();
    }

    // ── routecalling – Step 2 fallback (excluded Source_Type) ───────────────
    @istest
    static void testRouteCallingFallback() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Related_Source__c rs = new Related_Source__c();
        rs.SLead__c       = lead.Id;
        rs.Phone__c       = '7771119999';
        rs.Source_Type__c = 'Channel partner';  // excluded → triggers Step 2
        rs.Is_Locked__c   = false;
        insert rs;

        Test.setCurrentPageReference(new PageReference('/report/Callroute'));
        ApexPages.currentPage().getParameters().put('fromnumber',    '7771119999');
        ApexPages.currentPage().getParameters().put('landingNumber', '9987765432');
        mCubeController.routecalling();
    }

    // ── Click-to-call methods ────────────────────────────────────────────────
    @istest
    static void testClickToCallMethods() {
        Lead lead             = [SELECT Id FROM Lead LIMIT 1];
        Related_Source__c rs  = [SELECT Id FROM Related_Source__c LIMIT 1];
        User u                = [SELECT Id FROM User WHERE UserName = 'standarduser@testorg.com.123' LIMIT 1];

        System.runAs(u) {
            mCubeController.clickToCall(lead.Id, rs.Id,'Zuari Gangothri Tribhuja');
            mCubeController.clickToCalllatest(lead.Id, '9987765432', '+91');
            mCubeController.clickToCallNumber(String.valueOf(lead.Id), '1111111');
            mCubeController.readNumbers(String.valueOf(lead.Id));
        }
    }

    // ── readCall ─────────────────────────────────────────────────────────────
    @istest
    static void testReadCall() {
        mCubeController.readCall();
    }

    // ── Dialer controller ────────────────────────────────────────────────────
    @istest
    static void testDialerController() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        User u    = [SELECT Id FROM User WHERE UserName = 'standarduser@testorg.com.123' LIMIT 1];

        System.runAs(u) {
            PageReference pageRef = Page.Dialer;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardSetController stdSetController = 
                new ApexPages.StandardSetController(new List<Lead>{ lead });
            Dialercontroller s = new Dialercontroller(stdSetController);
            s.direct();

            u.massdialerIds__c = ',' + lead.Id;
            update u;
        }
    }
}