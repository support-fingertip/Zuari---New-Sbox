@isTest
public class RelatedSourceHandlerTest {

    @isTest
    public static void testmech() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Pre Sales' LIMIT 1];

        User u = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm1ail.com',
            Username = 'RH@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma1n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = true,
            IsActive = true,
            is_working__c = true
        );
        insert u;

        User u1 = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm2ail.com',
            Username = 'RH2@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma2n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = false,
            IsActive = true,
            is_working__c = true
        );
        insert u1;

        System.runAs(u1) {

            // Disable heavy SLeadTrigger fan-out during setup to keep SOQL well below limit.
            Utility.runLeadTrigger = false;

            Round_Robin__c r = new Round_Robin__c(
                Active__c = true,
                Project_Assigned__c = 'Zuari Garden City',
                Lead_Source_Type__c = 'Digital Marketing'
            );
            insert r;

            insert new List<Round_Robin_member__c>{
                new Round_Robin_member__c(
                    Round_Robin__c = r.Id, Active__c = true,
                    User__c = u1.Id, User_Type__c = 'Pre Sales'
                ),
                new Round_Robin_member__c(
                    Round_Robin__c = r.Id, Active__c = true,
                    User__c = u.Id, User_Type__c = 'Sales'
                )
            };

            Campaign cmp = new Campaign(Name = 'Test Camp 12234');
            insert cmp;

            Channel_Partner__c cp = new Channel_Partner__c(
                Name = 'Test CP',
                Email__c = 'cptest@example.com',
                Active__c = true,
                Approval_Status__c = 'Pending'
            );
            insert cp;

            // ------- Bulk-build Leads (single insert) -------
            List<Lead> ldlist = new List<Lead>();

            Lead ld22 = new Lead(
                LastName = 'test ld', Phone__c = '+919908072233',
                Email = 'Test@gmai1l.com', allocated_project__c = 'Zuari Garden City',
                Secondary_Phone__c = '9922332246', Lead_status__c = 'Unqualified',
                Unqualified_Reason__c = 'Not Within Budget Range',
                Company = 'test', Campaign__c = 'Test Camp 12234'
            );
            ldlist.add(ld22);

            Lead ld222 = new Lead(
                LastName = 'test ld', Phone__c = '919908072211',
                Email = 'Test@gmai1l.com', allocated_project__c = 'Zuari Garden City',
                Secondary_Phone__c = '9922332233', Lead_status__c = 'Unqualified',
                Unqualified_Reason__c = 'Not Within Budget Range',
                Company = 'test', Campaign__c = 'Test Camp 12234'
            );
            ldlist.add(ld222);

            Lead ld2222 = new Lead(
                LastName = 'test ld', Phone__c = '9008072211',
                Email = 'Test@gmai1l.com', allocated_project__c = 'Zuari Garden City',
                Secondary_Phone__c = '9022332233', Lead_status__c = 'Unqualified',
                Unqualified_Reason__c = 'Not Within Budget Range',
                Company = 'test', Campaign__c = 'Test Camp 12234'
            );
            ldlist.add(ld2222);

            Lead ld23 = new Lead(
                LastName = 'test ld', Phone__c = '9908072233',
                Email = 'Test3845784@gmai2l.com', Company = 'test',
                allocated_project__c = 'Zuari Garden City'
            );
            ldlist.add(ld23);

            // Used for "no existing lead" branch of duplicateCheck2
            Lead c22 = new Lead(
                LastName = 'test ld', Phone__c = '9908072209',
                Email = 'Test@gmai2l.com', Company = 'Test',
                allocated_project__c = 'Zuari Garden City'
            );
            ldlist.add(c22);

            insert ldlist;

            // Newlist for afterinsertLogic / afterinsertLogic2
            List<RecordType> rts = [
                SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Lead'
            ];
            Id rtPre;
            for (RecordType rt : rts) {
                if (rt.Name == 'Pre Sales') rtPre = rt.Id;
            }

            List<Lead> Newlist = new List<Lead>();
            Newlist.add(new Lead(
                LastName = 'test', Allocated_Project__c = 'Zuari Garden City',
                Phone = '9182748516', Lead_Status__c = 'New',
                RecordTypeId = rtPre, Company = 'test'
            ));
            Newlist.add(new Lead(
                LastName = 'test1', Allocated_Project__c = 'Zuari Garden City',
                Phone = '9182748511', Lead_Status__c = 'New',
                RecordTypeId = rtPre, Company = 'test'
            ));
            insert Newlist;

            // Lists for branches
            List<Lead> ldlist1 = new List<Lead>();
            ldlist1.add(new Lead(
                LastName = 'test ld', Phone__c = '9908072299',
                Email = 'Test@gmai2l.com', allocated_project__c = 'Zuari Garden City',
                Company = 'Test'
            ));
            ldlist1.add(c22);

            // Related_Source__c (insert once; will fire RS trigger once)
            related_source__c rs = new related_source__c(
                Channel_Partner1__c = cp.Id,
                Name__c = 'dsyhd',
                OwnerId = u.Id
            );
            insert rs;

            Related_Source__c oldRS = [
                SELECT Id, OwnerId, Name, Lead_status1__c, Channel_Partner1__c
                FROM Related_Source__c WHERE Id = :rs.Id
            ];
            Map<Id, Related_Source__c> oldMap = new Map<Id, Related_Source__c>{ oldRS.Id => oldRS };

            Related_Source__c updatedRS = new Related_Source__c(
                Id = rs.Id, OwnerId = UserInfo.getUserId()
            );

            Set<String> repIds = new Set<String>{ UserInfo.getUserId() };

            Test.startTest();

            // Direct handler-method calls. SOQL budget is reset at startTest.
            RelatedSourceHandler.checkMobileNumber2(ldlist);
            RelatedSourceHandler.campaignMethod(ldlist);
            RelatedSourceHandler.cpmethod(ldlist);
            RelatedSourceHandler.cpRelatedSourcemethod(new List<Related_Source__c>{ rs });
            RelatedSourceHandler.FillCPManage(new List<Related_Source__c>{ rs });

            RelatedSourceHandler.sendCustomNotification(
                repIds, 'Totlr', 'hsdgfhdghgfgd', ldlist[0].Id, 'Lead_assignment_Notification'
            );
            RelatedSourceHandler.sendReassignNotifications(
                new List<Related_Source__c>{ updatedRS }, oldMap
            );

            RelatedSourceHandler.duplicateCheck2(ldlist);
            RelatedSourceHandler.duplicateCheck2(ldlist1);

            try { RelatedSourceHandler.afterinsertLogic(Newlist); } catch (Exception e) { System.debug(e); }
            try { RelatedSourceHandler.afterinsertLogic2(Newlist); } catch (Exception e) { System.debug(e); }

            // Cover addRelatedSource branch (Main_lead_status__c is a read-only
            // formula field — cannot be set directly, so we exercise the
            // null/default Re-Engaged path).
            ld22.Main_Lead__c = ld23.Id;
            try { RelatedSourceHandler.addRelatedSource(ld22); } catch (Exception e) { System.debug(e); }

            try { RelatedSourceHandler.addRelatedSource2(ld22, ld23); } catch (Exception e) { System.debug(e); }

            // Direct coverage for mapLeadToRelatedSource branches
            RelatedSourceHandler.mapLeadToRelatedSource(ld22, 'Main Lead', '');
            RelatedSourceHandler.mapLeadToRelatedSource(ld22, '', 'New Lead');
            RelatedSourceHandler.mapLeadToRelatedSource(ld22, '', '');

            RelatedSourceHandler.SourceHandlingMethod(new List<Related_Source__c>{ rs });

            // handleLeadLostAfterSV — exercise the "becameLost && hadSV" branch.
            // Insert with a default-valid status ('New'), then flip to 'Closed Lost'
            // in memory. Restricted-picklist validation only fires on DML, so the
            // handler still sees the lost-after-SV state without an insert failure.
            Related_Source__c rsLost = new Related_Source__c(
                Channel_Partner1__c = cp.Id,
                Name__c = 'lost-test',
                Lead_status1__c = 'New',
                No_of_Site_Visit__c = 1,
                STM2__c = u.Id
            );
            insert rsLost;
            Related_Source__c rsLostOld = rsLost.clone(true, true, true, true);
            rsLostOld.Lead_status1__c = 'New';
            rsLost.Lead_status1__c = 'Closed Lost';
            Map<Id, Related_Source__c> lostOldMap = new Map<Id, Related_Source__c>{
                rsLost.Id => rsLostOld
            };
            try {
                RelatedSourceHandler.handleLeadLostAfterSV(
                    new List<Related_Source__c>{ rsLost }, lostOldMap
                );
            } catch (Exception e) { System.debug(e); }

            Test.stopTest();
        }
    }

    @isTest(SeeAllData=true)
    static void test_reassignUnqualifiedLead1_CMDT() {

        Lead_Assignment_Config__mdt cfg = [
            SELECT User_Indentifier__c FROM Lead_Assignment_Config__mdt LIMIT 1
        ];

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        String safeAlias = cfg.User_Indentifier__c.length() > 8
            ? cfg.User_Indentifier__c.substring(0, 8)
            : cfg.User_Indentifier__c;

        User u1 = new User(
            ProfileId = p.Id, LastName = 'CMDTUser', Email = 'cmdt@test.com',
            Username = 'cmdt+' + System.currentTimeMillis() + '@test.com',
            Alias = safeAlias, TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u1;

        User u2 = new User(
            ProfileId = p.Id, LastName = 'Owner', Email = 'own@test.com',
            Username = 'owner+' + System.currentTimeMillis() + '@test.com',
            Alias = 'owner1', TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u2;

        Related_Source__c rs = new Related_Source__c(
            OwnerId = u2.Id,
            No_Of_Times_Unqualified__c = 1,
            Lead_status1__c = 'New'
        );
        insert rs;

        Test.startTest();
        RelatedSourceHandler.reassignUnqualifiedLead1(
            new List<Related_Source__c>{ rs }
        );
        Test.stopTest();
    }
}