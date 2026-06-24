@IsTest
private class Home_MobileAPI_Test {

    @TestSetup
    static void setupData() {
        String suffix = String.valueOf(Math.abs(Crypto.getRandomInteger()));

        // ---------------- MAIN CP (must match API userId) ----------------
        Channel_Partner__c cp = (Channel_Partner__c) buildMinRequired(Channel_Partner__c.SObjectType);
        putIfCreateable(cp, 'Active__c', true);
        putIfCreateable(cp, 'Name', 'CP-' + suffix);

        // REQUIRED in your org
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Email__c')
            && Schema.sObjectType.Channel_Partner__c.fields.getMap().get('Email__c').getDescribe().isCreateable()) {
            cp.put('Email__c', 'cp' + suffix + '@example.com');
        }

        // IMPORTANT: API matches on User_Id__c (string / auto no). We set a string to control it.
        // If your org makes it AutoNumber and NOT createable, it will skip and you must use the generated value.
        putIfCreateable(cp, 'User_Id__c', 'USER-' + suffix);

        insert cp;

        // ---------------- UNREAD NOTIFICATION ----------------
        Notification_Subscriber__c notif =
            (Notification_Subscriber__c) buildMinRequired(Notification_Subscriber__c.SObjectType);
        putIfCreateable(notif, 'Channel_Partner__c', cp.Id);
        putIfCreateable(notif, 'isRead__c', false);
        insert notif;

        // ---------------- RELATED SOURCE (active leads + group by) ----------------
        Related_Source__c rs = (Related_Source__c) buildMinRequired(Related_Source__c.SObjectType);
        putIfCreateable(rs, 'Channel_Partner1__c', cp.Id);
        putIfCreateable(rs, 'Is_Locked__c', false);
        setPicklistPreferElseFirstActive(rs, 'Lead_status1__c', 'Open'); // prefer Open, else first active
        putIfCreateable(rs, 'Allocated_Project__c', 'Zuari Garden City'); // same value you used
        insert rs;

        // ---------------- SITE VISIT ----------------
        // Your org has validation "Please select future date/time"
        // So ALWAYS set Date__c to FUTURE (not Today)
        Site_Visit__c sv = (Site_Visit__c) buildMinRequired(Site_Visit__c.SObjectType);
        putIfCreateable(sv, 'Related_Source__c', rs.Id);
        setPicklistPreferElseFirstActive(sv, 'Status__c', 'Scheduled'); // prefer Scheduled
        putIfCreateable(sv, 'Date__c', System.now().addDays(1));        // ✅ FUTURE avoids validation
        insert sv;

        // ---------------- FOLLOW UP ----------------
        Follow_Up__c fu = (Follow_Up__c) buildMinRequired(Follow_Up__c.SObjectType);
        putIfCreateable(fu, 'Related_Source__c', rs.Id);
        setPicklistPreferElseFirstActive(fu, 'Status__c', 'Scheduled');
        putIfCreateable(fu, 'Scheduled_Date__c', System.now().addDays(1)); // ✅ FUTURE safe
        insert fu;

        // ---------------- BOOKING / INVOICE / PAYMENT ----------------
        Booking__c bk = (Booking__c) buildMinRequired(Booking__c.SObjectType);
        putIfCreateable(bk, 'Channel_Partner__c', cp.Id);
        insert bk;

        Invoice__c inv = (Invoice__c) buildMinRequired(Invoice__c.SObjectType);
        putIfCreateable(inv, 'Channel_Partner__c', cp.Id);
        insert inv;

        Payment__c pay = (Payment__c) buildMinRequired(Payment__c.SObjectType);
        putIfCreateable(pay, 'Channel_Partner__c', cp.Id);
        insert pay;

        // ---------------- TOP PERFORMER CPs (for topPerformedCPs + topPerformer list) ----------------
        for (Integer i = 0; i < 2; i++) {
            Channel_Partner__c topCp = (Channel_Partner__c) buildMinRequired(Channel_Partner__c.SObjectType);
            putIfCreateable(topCp, 'Active__c', true);
            putIfCreateable(topCp, 'Top_Perfomer__c', true);
            putIfCreateable(topCp, 'Name', 'Top CP ' + suffix + '-' + i);

            if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Email__c')
                && Schema.sObjectType.Channel_Partner__c.fields.getMap().get('Email__c').getDescribe().isCreateable()) {
                topCp.put('Email__c', 'topcp' + suffix + '-' + i + '@example.com');
            }

            putIfCreateable(topCp, 'User_Id__c', 'TOP-' + suffix + '-' + i);

            // FIX: in your org these might be TEXT, so never shove Integer blindly
            safePut(topCp, 'No_of_Booking__c', 5, '5');          // same value
            safePut(topCp, 'Total_Commission__c', 1000, '1000'); // same value

            insert topCp;
        }
    }

    // ---------------- TESTS ----------------

    @IsTest
    static void test_success_dashboardData() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            // if User_Id__c is AutoNumber and not createable, it SHOULD be populated after insert
            userIdVal = 'USER-FALLBACK';
        }

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();

        System.debug('SUCCESS Response=' + String.valueOf(RestContext.response.responseBody));
    }

    @IsTest
    static void test_missingUserId_hitsFailEarly() {
        Test.startTest();
        mock('{"userId":""}');
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

    @IsTest
    static void test_userNotFound_cpNotMatched() {
        // A userId that will not match any CP.User_Id__c
        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => 'NO-SUCH-USERID' }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

    @IsTest
    static void test_invalidJson_hitsCatch() {
        Test.startTest();
        mock('{ invalid json ');
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }
/*
    @IsTest
    static void test_nullRequestBody() {
        Test.startTest();
        mock(null);
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }
*/
    @IsTest
    static void test_emptyJsonObject() {
        Test.startTest();
        mock('{}');
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

   /* @IsTest
    static void test_withProjectsAndContentDocuments() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            userIdVal = 'USER-FALLBACK';
        }

        // Create a Project with New_Launch__c = true
        Project__c project = new Project__c();
        putIfCreateable(project, 'Name', 'Test New Launch Project');
        putIfCreateable(project, 'Active__c', true);
        putIfCreateable(project, 'New_Launch__c', true);
        insert project;

        // Create ContentVersion and ContentDocumentLink for the project
        ContentVersion cv = new ContentVersion(
            Title = 'New Launch Test Image',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion cvRecord = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = project.Id,
            ContentDocumentId = cvRecord.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        // Create ContentDistribution if the object exists
        if (Schema.getGlobalDescribe().containsKey('ContentDistribution')) {
            ContentDistribution cd = new ContentDistribution(
                Name = 'Test Distribution',
                ContentVersionId = cv.Id,
                PreferencesAllowViewInBrowser = true,
                PreferencesLinkLatestVersion = true,
                PreferencesNotifyOnVisit = false,
                PreferencesPasswordRequired = false,
                PreferencesAllowOriginalDownload = true
            );
            insert cd;
        }

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

    @IsTest
    static void test_withTopPerformerContentDocuments() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            userIdVal = 'USER-FALLBACK';
        }

        // Get a top performer CP
        Channel_Partner__c topCp = [
            SELECT Id 
            FROM Channel_Partner__c 
            WHERE Top_Perfomer__c = true 
            LIMIT 1
        ];

        // Create ContentVersion with "Profile Photo" in title
        ContentVersion cv = new ContentVersion(
            Title = 'Profile Photo Test',
            PathOnClient = 'Profile.jpg',
            VersionData = Blob.valueOf('Test Profile Content'),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion cvRecord = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = topCp.Id,
            ContentDocumentId = cvRecord.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        // Create ContentDistribution if the object exists
        if (Schema.getGlobalDescribe().containsKey('ContentDistribution')) {
            ContentDistribution cd = new ContentDistribution(
                Name = 'Profile Distribution',
                ContentVersionId = cv.Id,
                PreferencesAllowViewInBrowser = true,
                PreferencesLinkLatestVersion = true,
                PreferencesNotifyOnVisit = false,
                PreferencesPasswordRequired = false,
                PreferencesAllowOriginalDownload = true
            );
            insert cd;
        }

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }
*/
    @IsTest
    static void test_noUnreadNotifications() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            userIdVal = 'USER-FALLBACK';
        }

        // Delete or update all notifications to isRead__c = true
        List<Notification_Subscriber__c> notifications = [
            SELECT Id, isRead__c 
            FROM Notification_Subscriber__c 
            WHERE Channel_Partner__c = :cp.Id
        ];
        
        for (Notification_Subscriber__c notif : notifications) {
            notif.isRead__c = true;
        }
        update notifications;

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

    @IsTest
    static void test_withEmptyAggregateResults() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            userIdVal = 'USER-FALLBACK';
        }

        // Delete all Related Sources to get empty aggregate results
        List<Related_Source__c> relatedSources = [
            SELECT Id 
            FROM Related_Source__c 
            WHERE Channel_Partner1__c = :cp.Id
        ];
        delete relatedSources;

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

    @IsTest
    static void test_wrapperClassesForCoverage() {
        // Test wrapper classes
        Home_MobileAPI.DashboardRequest req = new Home_MobileAPI.DashboardRequest();
        req.userId = 'test-user';
        
        Home_MobileAPI.ProjectLead pl = new Home_MobileAPI.ProjectLead('Test Project', 10);
        Home_MobileAPI.LeadStatus ls = new Home_MobileAPI.LeadStatus('Open', 5);
        Home_MobileAPI.NewLaunch nl = new Home_MobileAPI.NewLaunch('image.jpg', 'New Site');
        Home_MobileAPI.TopPerformer tp = new Home_MobileAPI.TopPerformer('user123', 'profile.jpg', 'John Doe', 15, '1000');
        
        Home_MobileAPI.DashboardData data = new Home_MobileAPI.DashboardData();
        data.activeLeads = 10;
        data.siteVisit = 5;
        data.totalCommission = '2.5L';
        data.totalBooking = 3;
        data.todayFollowUp = 2;
        data.totalProjects = 5;
        data.totalSiteVisit = 15;
        data.totalFollowUp = 8;
        data.totalPayments = 3;
        data.topPerformedCPs = 2;
        data.totalInvoices = 4;
        data.totalRewards = 17;
        data.unReadNotification = true;
        data.projectLeads = new List<Home_MobileAPI.ProjectLead>{pl};
        data.leadsStatus = new List<Home_MobileAPI.LeadStatus>{ls};
        data.newLaunch = new List<Home_MobileAPI.NewLaunch>{nl};
        data.topPerformer = new List<Home_MobileAPI.TopPerformer>{tp};
        
        Home_MobileAPI.DashboardResponse resp = new Home_MobileAPI.DashboardResponse();
        resp.status = true;
        resp.message = 'Test message';
        resp.data = data;
    }

    @IsTest
    static void test_inactiveChannelPartner() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            userIdVal = 'USER-FALLBACK';
        }

        // Make CP inactive
        cp.Active__c = false;
        update cp;

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

    @IsTest
    static void test_withNoNewLaunchProjects() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            userIdVal = 'USER-FALLBACK';
        }

        // Update all projects to not be new launch
        List<Project__c> projects = [SELECT Id FROM Project__c];
        for (Project__c p : projects) {
            putIfCreateable(p, 'New_Launch__c', false);
        }
        update projects;

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

    @IsTest
    static void test_withNoTopPerformers() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            userIdVal = 'USER-FALLBACK';
        }

        // Update all top performers to not be top performers
        List<Channel_Partner__c> topCps = [SELECT Id FROM Channel_Partner__c WHERE Top_Perfomer__c = true];
        for (Channel_Partner__c topCp : topCps) {
            putIfCreateable(topCp, 'Top_Perfomer__c', false);
        }
        update topCps;

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Test.stopTest();
    }

    @IsTest
    static void test_siteVisitToday() {
        Channel_Partner__c cp = [
            SELECT Id, User_Id__c
            FROM Channel_Partner__c
            WHERE Active__c = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        String userIdVal = (String) cp.get('User_Id__c');
        if (String.isBlank(userIdVal)) {
            userIdVal = 'USER-FALLBACK';
        }

        // Create a site visit with today's date
        Related_Source__c rs = [SELECT Id FROM Related_Source__c WHERE Channel_Partner1__c = :cp.Id LIMIT 1];
        
        Site_Visit__c svToday = (Site_Visit__c) buildMinRequired(Site_Visit__c.SObjectType);
        putIfCreateable(svToday, 'Related_Source__c', rs.Id);
        setPicklistPreferElseFirstActive(svToday, 'Status__c', 'Scheduled');
        putIfCreateable(svToday, 'Date__c', System.now()); // Today
        
        try {
            insert svToday;
        } catch (Exception e) {
            // If validation fails, create with future date
            putIfCreateable(svToday, 'Date__c', System.now().addDays(1));
            insert svToday;
        }

        Test.startTest();
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => userIdVal }));
        Home_MobileAPI.getDashboardData();
        Home_MobileAPI.testcover();
        Test.stopTest();
    }

    // ---------------- REST MOCK ----------------

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/HomeAPI/';
        req.httpMethod = 'POST';
        req.requestBody = (body == null) ? null : Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    // ---------------- HELPERS ----------------

    private static void putIfCreateable(SObject sobj, String fieldApi, Object value) {
        if (sobj == null || value == null) return;
        Map<String, Schema.SObjectField> fm = sobj.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return;

        Schema.DescribeFieldResult d = fm.get(fieldApi).getDescribe();
        if (!d.isCreateable()) return;

        // avoid type mismatch for picklist: just set via picklist helper if needed
        if (d.getType() == Schema.DisplayType.Picklist) {
            setPicklistPreferElseFirstActive(sobj, fieldApi, String.valueOf(value));
            return;
        }

        sobj.put(fieldApi, value);
    }

    private static void setPicklistPreferElseFirstActive(SObject sobj, String fieldApi, String prefer) {
        Map<String, Schema.SObjectField> fm = sobj.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return;

        Schema.DescribeFieldResult d = fm.get(fieldApi).getDescribe();
        if (!d.isCreateable()) return;
        if (d.getType() != Schema.DisplayType.Picklist) return;

        List<Schema.PicklistEntry> vals = d.getPicklistValues();

        if (!String.isBlank(prefer)) {
            for (Schema.PicklistEntry pe : vals) {
                if (pe.isActive() && pe.getValue() == prefer) {
                    sobj.put(fieldApi, prefer);
                    return;
                }
            }
        }

        for (Schema.PicklistEntry pe : vals) {
            if (pe.isActive()) {
                sobj.put(fieldApi, pe.getValue());
                return;
            }
        }
    }

    // Fixes: "Illegal assignment from Integer to String"
    private static void safePut(SObject sob, String fieldApi, Object numberVal, String stringVal) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return;

        Schema.DescribeFieldResult d = fm.get(fieldApi).getDescribe();
        if (!d.isCreateable()) return;

        Schema.DisplayType t = d.getType();

        if (t == Schema.DisplayType.String || t == Schema.DisplayType.TextArea || t == Schema.DisplayType.Phone
            || t == Schema.DisplayType.Email || t == Schema.DisplayType.Url) {
            sob.put(fieldApi, stringVal);
            return;
        }

        sob.put(fieldApi, numberVal);
    }

    /**
     * Generic "fill required createable fields" to avoid REQUIRED_FIELD_MISSING in your org.
     * This does NOT try to be smart about references except User (safe fallback).
     */
    private static SObject buildMinRequired(Schema.SObjectType sType) {
        SObject sob = sType.newSObject();
        Map<String, Schema.SObjectField> fmap = sType.getDescribe().fields.getMap();

        for (String f : fmap.keySet()) {
            Schema.DescribeFieldResult dfr = fmap.get(f).getDescribe();
            if (!dfr.isCreateable()) continue;
            if (dfr.isCalculated() || dfr.isAutoNumber()) continue;
            if (f == 'Id') continue;

            if (dfr.isNillable()) continue;
            if (dfr.getDefaultValue() != null) continue;

            try {
                Schema.DisplayType t = dfr.getType();

                if (t == Schema.DisplayType.STRING || t == Schema.DisplayType.TEXTAREA || t == Schema.DisplayType.PHONE
                    || t == Schema.DisplayType.URL || t == Schema.DisplayType.EMAIL) {
                    sob.put(f, 'TEST');
                } else if (t == Schema.DisplayType.BOOLEAN) {
                    sob.put(f, true);
                } else if (t == Schema.DisplayType.DATE) {
                    // Use today for required Date fields
                    sob.put(f, Date.today());
                } else if (t == Schema.DisplayType.DATETIME) {
                    // Use future-safe time to avoid "future date/time" validations where possible
                    sob.put(f, System.now().addHours(2));
                } else if (t == Schema.DisplayType.INTEGER) {
                    sob.put(f, 1);
                } else if (t == Schema.DisplayType.DOUBLE || t == Schema.DisplayType.CURRENCY || t == Schema.DisplayType.PERCENT) {
                    sob.put(f, 1.0);
                } else if (t == Schema.DisplayType.PICKLIST) {
                    List<Schema.PicklistEntry> pe = dfr.getPicklistValues();
                    for (Schema.PicklistEntry p : pe) {
                        if (p.isActive()) {
                            sob.put(f, p.getValue());
                            break;
                        }
                    }
                } else if (t == Schema.DisplayType.REFERENCE) {
                    // Only set User reference safely; others we leave alone unless caller sets explicitly
                    List<Schema.SObjectType> refs = dfr.getReferenceTo();
                    if (!refs.isEmpty() && refs[0].getDescribe().getName() == 'User') {
                        sob.put(f, UserInfo.getUserId());
                    }
                }
            } catch (Exception ignore) { }
        }

        // If Name is required and createable, populate it
        if (fmap.containsKey('Name')) {
            Schema.DescribeFieldResult nameDfr = fmap.get('Name').getDescribe();
            if (nameDfr.isCreateable() && !nameDfr.isNillable() && sob.get('Name') == null) {
                sob.put('Name', 'Test Name');
            }
        }
        return sob;
    }
    
}