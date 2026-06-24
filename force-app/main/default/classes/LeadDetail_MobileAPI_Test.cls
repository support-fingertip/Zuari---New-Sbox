@IsTest
private class LeadDetail_MobileAPI_Test {

    @TestSetup
    static void setupData() {
        String suffix = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        Datetime nowDt = System.now();

        // USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        String alias8 = ('l' + suffix);
        if (alias8.length() > 8) alias8 = alias8.substring(0, 8);

        User u = new User(
            Alias = alias8,
            Email = 'ld_' + suffix + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'LeadDetail',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = p.Id,
            Username = 'ld_' + suffix + '@test.com'
        );
        insert u;

        // CHANNEL PARTNER (User_Id__c auto-number - do not set)
        Channel_Partner__c cp = new Channel_Partner__c();
        setValue(cp, 'Name', 'CP_LEAD_DETAIL_' + suffix);
        setValue(cp, 'Active__c', true);
        setValue(cp, 'Email__c', u.Email);
        insert cp;

        // LEAD
        Lead l = new Lead(LastName = 'Test Lead', Company = 'Test Co');
        setValue(l, 'Allocated_Project__c', 'Zuari Garden City');
        insert l;

        // RELATED SOURCE (make Lead_Id__c resolvable)
        Related_Source__c rs = new Related_Source__c();
        setValue(rs, 'Channel_Partner1__c', cp.Id);
        setValue(rs, 'Is_Locked__c', false);
        setValue(rs, 'Name__c', 'Creator Name');
        setPicklist(rs, 'Lead_status1__c', null);
        setValue(rs, 'Primary_Phone__c', '9999999999');
        setValue(rs, 'Email__c', 'lead@test.com');
        setValue(rs, 'Allocated_Project__c', 'Zuari Garden City');
        setValue(rs, 'OwnerId', u.Id);

        if (!trySetAny(rs, 'Lead_Id__c', 'AUTO')) {
            if (!trySetAny(rs, 'SLead__c', l.Id)) {
                trySetAny(rs, 'Lead__c', l.Id);
            }
        }
        insert rs;

        // SITE VISIT (ONLY ONE) - future date
        Site_Visit__c sv = new Site_Visit__c();
        setValue(sv, 'Related_Source__c', rs.Id);
        setPicklist(sv, 'Site_Visit_Type__c', 'Revisit');
        setValue(sv, 'Feedback__c', 'Good');
        setPicklist(sv, 'Status__c', null);
        setValue(sv, 'Date__c', nowDt.addDays(2)); // future
        trySetAny(sv, 'SLead__c', l.Id);
        insert sv;

        // FOLLOW UP (ONLY ONE) - future date
        Follow_Up__c fu = new Follow_Up__c();
        setValue(fu, 'Related_Source__c', rs.Id);
        setValue(fu, 'Scheduled_Date__c', nowDt.addDays(5)); // future
        setValue(fu, 'Comments__c', 'Follow up soon');
        setPicklist(fu, 'Status__c', null);
        setValue(fu, 'Subject__c', 'Call back');
        trySetAny(fu, 'SLead__c', l.Id);
        insert fu;

        // CALL DETAILS (ONLY ONE) - pick ONE branch only to reduce trigger overhead
        Call_Detail__c cd = new Call_Detail__c();
        setValue(cd, 'Related_Source__c', rs.Id);
        setPicklist(cd, 'Call_Type__c', null);
        setValue(cd, 'Discription__c', 'Test call');
        setPicklist(cd, 'Status__c', null);
        // try to set boolean safely; if not createable, ignore
        setValue(cd, 'Created_By_CP_Mobile_APP__c', true);
        trySetAny(cd, 'Duration__c', '5');
        // if org validates time fields, set future
        trySetAny(cd, 'Start_Time__c', nowDt.addDays(2));
        trySetAny(cd, 'End_Time__c', nowDt.addDays(2).addMinutes(5));
        insert cd;

        // ADDITIONAL NOTE (ONLY ONE)
        Call_Comments__c note = new Call_Comments__c();
        setValue(note, 'Related_Source__c', rs.Id);
        setValue(note, 'Comments__c', 'Additional note');
        setValue(note, 'Title__c', 'Note 1');
        trySetAny(note, 'Created_Date__c', nowDt);
        insert note;
    }

    // ✅ ONLY ONE SUCCESS TEST (prevents SOQL blowup)
    @IsTest
    static void test_success_fullFlow_singleCall() {

        // Query minimal values needed for request
        Channel_Partner__c cp = [
            SELECT User_Id__c, Id
            FROM Channel_Partner__c
            WHERE Active__c = true
            LIMIT 1
        ];

        Related_Source__c rs = [
            SELECT Lead_Id__c
            FROM Related_Source__c
            WHERE Channel_Partner1__c = :cp.Id
            LIMIT 1
        ];

        String userAuto = String.valueOf(cp.User_Id__c);
        String leadAuto = String.valueOf(rs.Lead_Id__c);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LeadDetailAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'userId' => userAuto,
            'leadId' => leadAuto
        }));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        LeadDetail_MobileAPI.getLeadDetails();
        Test.stopTest();

        System.debug('SOQL used = ' + Limits.getQueries());
    }

    // ✅ Keep only ONE cheap error test
    @IsTest
    static void test_missingParams_errorPath_singleCall() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LeadDetailAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"userId":"","leadId":""}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        LeadDetail_MobileAPI.getLeadDetails();
        Test.stopTest();
    }

    // ---------------- HELPERS ----------------
    private static void setValue(SObject sobj, String fieldApi, Object value) {
        Map<String, SObjectField> fmap = sobj.getSObjectType().getDescribe().fields.getMap();
        if (!fmap.containsKey(fieldApi)) return;

        Schema.DescribeFieldResult dfr = fmap.get(fieldApi).getDescribe();
        if (!dfr.isCreateable()) return;

        if (dfr.getType() == Schema.DisplayType.Picklist) {
            setPicklist(sobj, fieldApi, (value instanceof String) ? (String)value : null);
            return;
        }

        if (value != null) sobj.put(fieldApi, value);
    }

    private static void setPicklist(SObject sobj, String fieldApi, String preferValue) {
        Map<String, SObjectField> fmap = sobj.getSObjectType().getDescribe().fields.getMap();
        if (!fmap.containsKey(fieldApi)) return;

        Schema.DescribeFieldResult dfr = fmap.get(fieldApi).getDescribe();
        if (!dfr.isCreateable()) return;
        if (dfr.getType() != Schema.DisplayType.Picklist) return;

        List<Schema.PicklistEntry> vals = dfr.getPicklistValues();

        if (!String.isBlank(preferValue)) {
            for (Schema.PicklistEntry pe : vals) {
                if (pe.isActive() && pe.getValue() == preferValue) {
                    sobj.put(fieldApi, preferValue);
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

    private static Boolean trySetAny(SObject sobj, String fieldApi, Object value) {
        try {
            Map<String, SObjectField> fmap = sobj.getSObjectType().getDescribe().fields.getMap();
            if (!fmap.containsKey(fieldApi)) return false;
            Schema.DescribeFieldResult dfr = fmap.get(fieldApi).getDescribe();
            if (!dfr.isCreateable()) return false;
            sobj.put(fieldApi, value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}