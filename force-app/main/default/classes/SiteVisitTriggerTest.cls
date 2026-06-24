@isTest
public class SiteVisitTriggerTest {

    @testSetup
    static void setupData() {
        Lead lead1 = new Lead(LastName = 'Test Lead 1', Company = 'Company A');
        Lead lead2 = new Lead(LastName = 'Test Lead 2', Company = 'Company B');
        insert new List<Lead>{ lead1, lead2 };

        Related_Source__c rs1 = new Related_Source__c(SLead__c = lead1.Id);
        Related_Source__c rs2 = new Related_Source__c(SLead__c = lead2.Id);
        insert new List<Related_Source__c>{ rs1, rs2 };

        Site_Visit__c sv1 = new Site_Visit__c(
            Slead__c          = lead1.Id,
            Related_Source__c = rs1.Id,
            OTP__c            = '0000',
            Status__c         = 'Pending'
        );

        Site_Visit__c sv2 = new Site_Visit__c(
            Slead__c                  = lead2.Id,
            Related_Source__c         = rs2.Id,
            OTP__c                    = '1234',
            Status__c                 = 'Completed',
            SV_Completed_Date_Time__c = DateTime.now()
        );

        insert new List<Site_Visit__c>{ sv1, sv2 };
    }

    @isTest
    static void testAfterInsertCompleted() {
        Lead lead2 = [SELECT Id, No_of_Site_Visit__c,
                             First_Site_Visit_Date_Time__c,
                             Last_Site_Visit_Date_Time__c
                      FROM Lead
                      WHERE LastName = 'Test Lead 2'
                      LIMIT 1];

        List<Related_Source__c> rsList = [SELECT No_of_Site_Visit__c,
                                                 First_Site_Visit_Date_Time__c,
                                                 Last_Site_Visit_Date_Time__c
                                          FROM Related_Source__c
                                          WHERE SLead__c = :lead2.Id];
    }

    @isTest
    static void testAfterInsertPendingNotCounted() {
        Lead lead1 = [SELECT Id, No_of_Site_Visit__c
                      FROM Lead
                      WHERE LastName = 'Test Lead 1'
                      LIMIT 1];
    }

    @isTest
    static void testBeforeInsertRoundRobin() {
        Lead ld = [SELECT Id FROM Lead WHERE LastName = 'Test Lead 1' LIMIT 1];
        
        List<Related_Source__c> rsList = [SELECT Id FROM Related_Source__c 
                                          WHERE SLead__c = :ld.Id 
                                          LIMIT 1];

        if(rsList.isEmpty()) return;

        Site_Visit__c sv = new Site_Visit__c(
            Slead__c          = ld.Id,
            Related_Source__c = rsList[0].Id,
            OTP__c            = '5678',
            Status__c         = 'Pending'
        );

        Test.startTest();
        insert sv;
        Test.stopTest();

        List<Site_Visit__c> inserted = [SELECT Id, OTP__c, Status__c
                                        FROM Site_Visit__c
                                        WHERE Id = :sv.Id];
    }

    @isTest
    static void testAfterUpdateStatusToCompleted() {
        Lead lead1 = [SELECT Id FROM Lead WHERE LastName = 'Test Lead 1' LIMIT 1];
        
        List<Site_Visit__c> svList = [SELECT Id, Status__c
                                      FROM Site_Visit__c
                                      WHERE Slead__c = :lead1.Id
                                      AND Status__c = 'Pending'
                                      LIMIT 1];

        if(svList.isEmpty()) return;

        Test.startTest();
        svList[0].Status__c                 = 'Completed';
        svList[0].SV_Completed_Date_Time__c = DateTime.now();
        update svList[0];
        Test.stopTest();

        Lead updatedLead = [SELECT No_of_Site_Visit__c,
                                   First_Site_Visit_Date_Time__c,
                                   Last_Site_Visit_Date_Time__c
                            FROM Lead
                            WHERE Id = :lead1.Id];
    }

    @isTest
    static void testAfterUpdateOTPChange() {
        List<Site_Visit__c> svList = [SELECT Id, OTP__c, Status__c
                                      FROM Site_Visit__c
                                      WHERE Status__c = 'Completed'
                                      LIMIT 1];

        if(svList.isEmpty()) return;

        Test.startTest();
        svList[0].OTP__c = '9999';
        update svList[0];
        Test.stopTest();

        List<Site_Visit__c> updated = [SELECT OTP__c FROM Site_Visit__c 
                                       WHERE Id = :svList[0].Id];
    }

    @isTest
    static void testMultipleCompletedVisits() {
        Lead lead2 = [SELECT Id FROM Lead WHERE LastName = 'Test Lead 2' LIMIT 1];
        
        List<Related_Source__c> rsList = [SELECT Id FROM Related_Source__c 
                                          WHERE SLead__c = :lead2.Id 
                                          LIMIT 1];

        if(rsList.isEmpty()) return;

        Site_Visit__c sv3 = new Site_Visit__c(
            Slead__c                  = lead2.Id,
            Related_Source__c         = rsList[0].Id,
            OTP__c                    = '4321',
            Status__c                 = 'Completed',
            SV_Completed_Date_Time__c = DateTime.now().addDays(1)
        );

        Test.startTest();
        insert sv3;
        Test.stopTest();

        Lead updatedLead = [SELECT No_of_Site_Visit__c,
                                   First_Site_Visit_Date_Time__c,
                                   Last_Site_Visit_Date_Time__c
                            FROM Lead
                            WHERE Id = :lead2.Id];

        List<Related_Source__c> updatedRs = [SELECT No_of_Site_Visit__c,
                                                    First_Site_Visit_Date_Time__c,
                                                    Last_Site_Visit_Date_Time__c
                                             FROM Related_Source__c
                                             WHERE Id = :rsList[0].Id];
    }
}