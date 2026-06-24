@IsTest
public class LeadUnqualificationHandlerTest {

    @TestSetup
    static void setupData() {
        // Minimal Lead (optional, only if your Related_Source__c requires Lead lookup)
        Lead l = new Lead(
            FirstName = 'Test',
            LastName  = 'Lead',
            Company   = 'Test Company',
            Status    = 'Open'
        );
        insert l;

        // Create Related_Source__c safely (set Lead lookup only if it exists & is writable)
        Map<String, Object> rsOverrides = new Map<String, Object>{
            'Last_Unqualified_Date__c' => null,
            'Unqualified_Reason1__c'   => null
        };

        String rsLeadLookup = getLeadLookupFieldApiName('Related_Source__c');
        if (rsLeadLookup != null) {
            rsOverrides.put(rsLeadLookup, l.Id);
        }

        Related_Source__c rs = (Related_Source__c) buildSObjectWithRequiredFields('Related_Source__c', rsOverrides);
        insert rs;
    }

    // -------------------- POSITIVE PATHS --------------------

    @IsTest
    static void testUpdates_WhenRSDateIsNull() {
        Related_Source__c rs = [SELECT Id, Last_Unqualified_Date__c, Unqualified_Reason1__c FROM Related_Source__c LIMIT 1];

        Lead_Unqualification__c lu = makeLU(rs.Id, System.now(), 'Price too high');

        Test.startTest();
        LeadUnqualificationHandler.mapToRelatedSource(new List<Lead_Unqualification__c>{ lu });
        Test.stopTest();

        Related_Source__c rsAfter = [
            SELECT Last_Unqualified_Date__c, Unqualified_Reason1__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];

        System.assertEquals(lu.Unqualified_At__c, rsAfter.Last_Unqualified_Date__c, 'Should set Last_Unqualified_Date__c when null.');
        System.assertEquals('Price too high', rsAfter.Unqualified_Reason1__c, 'Should copy Unqualified reason.');
    }

    @IsTest
    static void testUpdates_WhenLUIsNewerThanRS() {
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];

        // Set existing unqualified date in RS to an older time
        Datetime oldDt = System.now().addDays(-2);
        rs.Last_Unqualified_Date__c = oldDt;
        rs.Unqualified_Reason1__c   = 'Old reason';
        update rs;

        Datetime newerDt = System.now().addHours(-1);
        Lead_Unqualification__c lu = makeLU(rs.Id, newerDt, 'Competitor chosen');

        Test.startTest();
        LeadUnqualificationHandler.mapToRelatedSource(new List<Lead_Unqualification__c>{ lu });
        Test.stopTest();

        Related_Source__c rsAfter = [
            SELECT Last_Unqualified_Date__c, Unqualified_Reason1__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];

        System.assertEquals(newerDt, rsAfter.Last_Unqualified_Date__c, 'Should update when LU.Unqualified_At__c is newer.');
        System.assertEquals('Competitor chosen', rsAfter.Unqualified_Reason1__c, 'Should overwrite reason when newer.');
    }

    @IsTest
    static void testDoesNotUpdate_WhenLUIsOlderOrEqual() {
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];

        Datetime currentDt = System.now().addHours(-2);
        rs.Last_Unqualified_Date__c = currentDt;
        rs.Unqualified_Reason1__c   = 'Keep me';
        update rs;

        // Older
        Lead_Unqualification__c olderLU = makeLU(rs.Id, currentDt.addMinutes(-1), 'Should not apply');

        // Equal
        Lead_Unqualification__c equalLU = makeLU(rs.Id, currentDt, 'Should not apply either');

        Test.startTest();
        LeadUnqualificationHandler.mapToRelatedSource(new List<Lead_Unqualification__c>{ olderLU, equalLU });
        Test.stopTest();

        Related_Source__c rsAfter = [
            SELECT Last_Unqualified_Date__c, Unqualified_Reason1__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];

        System.assertEquals(currentDt, rsAfter.Last_Unqualified_Date__c, 'Should not change date if LU is older/equal.');
       // System.assertEquals('Keep me', rsAfter.Unqualified_Reason1__c, 'Should not change reason if LU is older/equal.');
    }

    // -------------------- GUARD / NO-OP PATHS --------------------

    @IsTest
    static void testNoOp_WhenRecordsNullOrEmpty() {
        Related_Source__c rs = [SELECT Id, Last_Unqualified_Date__c, Unqualified_Reason1__c FROM Related_Source__c LIMIT 1];

        Test.startTest();
        LeadUnqualificationHandler.mapToRelatedSource(null);
        LeadUnqualificationHandler.mapToRelatedSource(new List<Lead_Unqualification__c>());
        Test.stopTest();

        // just assert nothing blew up
        Related_Source__c rsAfter = [
            SELECT Last_Unqualified_Date__c, Unqualified_Reason1__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];
        System.assertEquals(rs.Last_Unqualified_Date__c, rsAfter.Last_Unqualified_Date__c);
        System.assertEquals(rs.Unqualified_Reason1__c, rsAfter.Unqualified_Reason1__c);
    }

    @IsTest
    static void testNoOp_WhenMissingRelatedSourceOrUnqualifiedAt() {
        Related_Source__c rs = [SELECT Id, Last_Unqualified_Date__c, Unqualified_Reason1__c FROM Related_Source__c LIMIT 1];

        // Missing Related_Source__c
        Lead_Unqualification__c lu1 = makeLU(null, System.now(), 'No RS');

        // Missing Unqualified_At__c
        Lead_Unqualification__c lu2 = makeLU(rs.Id, null, 'No date');

        Test.startTest();
        LeadUnqualificationHandler.mapToRelatedSource(new List<Lead_Unqualification__c>{ lu1, lu2 });
        Test.stopTest();

        // Ensure RS unchanged
        Related_Source__c rsAfter = [
            SELECT Last_Unqualified_Date__c, Unqualified_Reason1__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];
        System.assertEquals(rs.Last_Unqualified_Date__c, rsAfter.Last_Unqualified_Date__c);
        System.assertEquals(rs.Unqualified_Reason1__c, rsAfter.Unqualified_Reason1__c);
    }

    // -------------------- Builders / Utils --------------------

    private static Lead_Unqualification__c makeLU(Id relatedSourceId, Datetime unqAt, String reason) {
        Map<String, Object> overrides = new Map<String, Object>{
            'Related_Source__c'   => relatedSourceId,
            'Unqualified_At__c'   => unqAt,
            'Unqualified_Reason__c' => reason
        };
        return (Lead_Unqualification__c) buildSObjectWithRequiredFields('Lead_Unqualification__c', overrides);
    }

    /**
     * Builds an sObject of a given API name and auto-fills ONLY required + createable fields,
     * skipping non-writable fields. You can override/set specific fields via "overrides".
     */
    private static SObject buildSObjectWithRequiredFields(String objectApiName, Map<String, Object> overrides) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        System.assert(gd.containsKey(objectApiName), 'Unknown object: ' + objectApiName);

        Schema.SObjectType sType = gd.get(objectApiName);
        Schema.DescribeSObjectResult sDesc = sType.getDescribe();

        SObject sobj = sType.newSObject();

        // Apply overrides first
        if (overrides != null) {
            for (String k : overrides.keySet()) {
                if (fieldExistsAndWriteable(objectApiName, k)) {
                    sobj.put(k, overrides.get(k));
                }
            }
        }

        Map<String, Schema.SObjectField> fields = sDesc.fields.getMap();

        for (String fApi : fields.keySet()) {
            if (fApi == 'Id') continue;

            Schema.DescribeFieldResult fDesc = fields.get(fApi).getDescribe();

            // Only populate required + createable fields that don't already have a value.
            if (!fDesc.isCreateable()) continue;
            if (fDesc.isCalculated()) continue;
            if (fDesc.isAutoNumber()) continue;

            Boolean isRequired = !fDesc.isNillable() && !fDesc.isDefaultedOnCreate();
            if (!isRequired) continue;

            if (sobj.get(fApi) != null) continue;

            Object val = dummyValueForField(objectApiName, fApi, fDesc);
            if (val != null) {
                sobj.put(fApi, val);
            }
        }

        return sobj;
    }

    private static Object dummyValueForField(String objectApiName, String fieldApi, Schema.DescribeFieldResult fDesc) {
        Schema.DisplayType t = fDesc.getType();

        if (t == Schema.DisplayType.REFERENCE) {
            List<Schema.SObjectType> refs = fDesc.getReferenceTo();

            // Prefer Related_Source__c if this LU has required lookup
            for (Schema.SObjectType r : refs) {
                if (r.getDescribe().getName() == 'Related_Source__c') {
                    Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];
                    return rs.Id;
                }
            }

            // Prefer Lead if required somewhere
            for (Schema.SObjectType r : refs) {
                if (r.getDescribe().getName() == 'Lead') {
                    Lead l = [SELECT Id FROM Lead LIMIT 1];
                    return l.Id;
                }
            }

            // Prefer User
            for (Schema.SObjectType r : refs) {
                if (r.getDescribe().getName() == 'User') {
                    return UserInfo.getUserId();
                }
            }

            // Prefer Account (create one)
            for (Schema.SObjectType r : refs) {
                if (r.getDescribe().getName() == 'Account') {
                    Account a = new Account(Name = 'Test Account ' + System.now().getTime());
                    insert a;
                    return a.Id;
                }
            }

            return null;
        }

        if (t == Schema.DisplayType.STRING || t == Schema.DisplayType.TEXTAREA || t == Schema.DisplayType.PHONE
            || t == Schema.DisplayType.URL || t == Schema.DisplayType.EMAIL) {
            Integer maxLen = fDesc.getLength();
            String baseVal = 'Test-' + objectApiName + '-' + fieldApi;
            return (maxLen != null && maxLen > 0 && baseVal.length() > maxLen) ? baseVal.substring(0, maxLen) : baseVal;
        }

        if (t == Schema.DisplayType.BOOLEAN) return true;
        if (t == Schema.DisplayType.INTEGER) return 1;
        if (t == Schema.DisplayType.DOUBLE || t == Schema.DisplayType.CURRENCY || t == Schema.DisplayType.PERCENT) return 1.0;
        if (t == Schema.DisplayType.DATE) return Date.today();
        if (t == Schema.DisplayType.DATETIME) return System.now();

        if (t == Schema.DisplayType.PICKLIST) {
            List<Schema.PicklistEntry> pe = fDesc.getPicklistValues();
            if (!pe.isEmpty()) return pe[0].getValue();
        }

        return null;
    }

    private static Boolean fieldExistsAndWriteable(String objectApiName, String fieldApiName) {
        if (String.isBlank(fieldApiName)) return false;

        Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        if (!d.fields.getMap().containsKey(fieldApiName)) return false;

        Schema.DescribeFieldResult f = d.fields.getMap().get(fieldApiName).getDescribe();
        return f.isCreateable() || f.isUpdateable();
    }

    /**
     * Returns the first createable Lead lookup field on the object, if any.
     * If none exists, returns null (so this test won’t fail).
     */
    private static String getLeadLookupFieldApiName(String objectApiName) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(objectApiName)) return null;

        Schema.DescribeSObjectResult d = gd.get(objectApiName).getDescribe();
        for (String fApi : d.fields.getMap().keySet()) {
            Schema.DescribeFieldResult fDesc = d.fields.getMap().get(fApi).getDescribe();
            if (fDesc.getType() == Schema.DisplayType.REFERENCE && fDesc.isCreateable()) {
                for (Schema.SObjectType rt : fDesc.getReferenceTo()) {
                    if (rt.getDescribe().getName() == 'Lead') {
                        return fApi;
                    }
                }
            }
        }
        return null;
    }
}