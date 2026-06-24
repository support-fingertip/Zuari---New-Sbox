@isTest
public class RoundRobinHandlerTest {
    @isTest
    public static void method1() {
        
        // Create Users first (Setup objects)
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

        // ✅ Separate context for non-setup objects
        System.runAs(u1) {
            Round_Robin__c r = new Round_Robin__c(
                Active__c = true,
                Project_Assigned__c = 'Zuari Garden City',
                Lead_Source_Type__c = 'Digital Marketing'
            );
            insert r;

            Round_Robin_member__c rrm = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u1.Id,
                User_Type__c = 'Pre Sales'
            );
            insert rrm;

            Round_Robin_member__c rrm1 = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u.Id,
                User_Type__c = 'Sales'
            );
            insert rrm1;

            List<Lead> conlst = new List<Lead>();
            Lead c = new Lead(
                LastName = 'test',
                Allocated_Project__c = 'Zuari Garden City',
                Phone__c = '9194949494',
                Secondary_Phone__c = '9849594049',
                Secondary_Email__c = 'cc@gmail.com',
                Source_Type__c = 'Digital Marketing',
                Company = 'Test Company'
            );
            conlst.add(c);

            RoundRobinHandler.assignLead(conlst, false, 'Pre Sales');
            RoundRobinHandler.assignLead(conlst, false, 'Sales');

            List<Site_Visit__c> svlist = new List<Site_Visit__c>{
                new Site_Visit__c(
                    Date__c = System.now() + 3,
                    Status__c = 'Scheduled',
                    Go_For_Round_Robin__c = true,
                    Source_Type__c = 'Digital Marketing',
                    Project__c = 'Zuari Garden City'
                )
            };

            RoundRobinHandler.siteVisitRoundRobin(svlist);

            // Cover method
            System.runAs(u) {
                User us = [SELECT Id, Name, Availability__c FROM User WHERE Id = :UserInfo.getUserId()];
                us.Availability__c = false;
                update us;
                RoundRobinHandler.testcover();
            }
        }
    }
     @isTest
    static void test_assignRelatedSource_fullCoverage() {
        

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Pre Sales' LIMIT 1];
        User notifUser = new User(
            ProfileId = p.Id,
            LastName = 'NotifUser',
            Email = 'notif@test.com',
            Username = 'notif' + System.currentTimeMillis() + '@test.com',
            Alias = 'notif1',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Availability__c = true,
            IsActive = true,
            is_working__c = true
        );
        insert notifUser;

        // AVAILABLE USER
        User uAvailable = new User(
            ProfileId = p.Id,
            LastName = 'Avail',
            Email = 'avail@test.com',
            Username = 'avail' + System.currentTimeMillis() + '@test.com',
            Alias = 'avail1',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Availability__c = true,
            IsActive = true,
            is_working__c = true
        );
        insert uAvailable;

        // FALLBACK USER (Availability = false)
        User uFallback = new User(
            ProfileId = p.Id,
            LastName = 'Fallback',
            Email = 'fb@test.com',
            Username = 'fb' + System.currentTimeMillis() + '@test.com',
            Alias = 'fbuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Availability__c = false,
            IsActive = true,
            is_working__c = true
        );
        insert uFallback;

        // ROUND ROBIN
        Round_Robin__c rr = new Round_Robin__c(
            Active__c = true,
            Lead_Source_Type__c = 'Digital Marketing'
        );
        insert rr;

        // AVAILABLE MEMBER
        insert new Round_Robin_Member__c(
            Round_Robin__c = rr.Id,
            Active__c = true,
            User__c = uAvailable.Id,
            User_Type__c = 'Pre Sales'
        );

        // FALLBACK MEMBER
        insert new Round_Robin_Member__c(
            Round_Robin__c = rr.Id,
            Active__c = true,
            User__c = uFallback.Id,
            User_Type__c = 'Pre Sales'
        );

        // RELATED SOURCE
        Related_Source__c rs = new Related_Source__c(
            Source_Type__c = 'Digital Marketing',
            Lead_Assigned__c = false,
            OwnerId = notifUser.Id,
            Delete_Lead__c = false
        );
        insert rs;

        Test.startTest();

        // 🔹 AVAILABLE QUEUE PATH
        RoundRobinHandler.assignRelatedsource(
            new List<Related_Source__c>{ rs },
            true,
            'Pre Sales'
        );

        // 🔹 FALLBACK QUEUE PATH (Availability = false)
        uAvailable.Availability__c = false;
        update uAvailable;

        rs.Lead_Assigned__c = false;
        update rs;

        RoundRobinHandler.assignRelatedsource(
            new List<Related_Source__c>{ rs },
            true,
            'Pre Sales'
        );

        Test.stopTest();

    }
}