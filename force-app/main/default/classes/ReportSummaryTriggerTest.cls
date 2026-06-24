@IsTest
public class ReportSummaryTriggerTest {

    @IsTest
    static void cover_afterInsert_enqueuesJob() {

        Report_Summary__c rs = (Report_Summary__c) buildMinRequired(Report_Summary__c.SObjectType);
        safeSetNameIfPossible(rs, 'RS-TEST');

        Test.startTest();
        insert rs; // fires trigger -> System.enqueueJob(...)
        Test.stopTest(); // forces queueable to run in test context
    }

    // ---------------- Helpers ----------------

    private static void safeSetNameIfPossible(SObject sob, String nameVal) {
        if (sob == null) return;
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey('Name')) return;
        Schema.DescribeFieldResult d = fm.get('Name').getDescribe();
        if (!d.isCreateable()) return;
        sob.put('Name', nameVal);
    }

    /**
     * Minimal required createable fields filler.
     * Uses VALID values for Email/Url to avoid INVALID_EMAIL_ADDRESS.
     * Does NOT guess required lookups - if your object has required lookups,
     * you'll get REQUIRED_FIELD_MISSING and must create that parent explicitly.
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

                if (t == Schema.DisplayType.EMAIL) {
                    sob.put(f, 'test@example.com');
                } else if (t == Schema.DisplayType.URL) {
                    sob.put(f, 'https://example.com');
                } else if (t == Schema.DisplayType.PHONE) {
                    sob.put(f, '9999999999');
                } else if (t == Schema.DisplayType.STRING || t == Schema.DisplayType.TEXTAREA) {
                    sob.put(f, 'TEST');
                } else if (t == Schema.DisplayType.BOOLEAN) {
                    sob.put(f, true);
                } else if (t == Schema.DisplayType.DATE) {
                    sob.put(f, Date.today());
                } else if (t == Schema.DisplayType.DATETIME) {
                    sob.put(f, System.now().addMinutes(5));
                } else if (t == Schema.DisplayType.INTEGER) {
                    sob.put(f, 1);
                } else if (t == Schema.DisplayType.DOUBLE || t == Schema.DisplayType.CURRENCY || t == Schema.DisplayType.PERCENT) {
                    sob.put(f, 1.0);
                } else if (t == Schema.DisplayType.PICKLIST) {
                    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                        if (pe.isActive()) {
                            sob.put(f, pe.getValue());
                            break;
                        }
                    }
                } else if (t == Schema.DisplayType.REFERENCE) {
                    // Only safe reference is User; do NOT set random lookups
                    List<Schema.SObjectType> refs = dfr.getReferenceTo();
                    if (!refs.isEmpty() && refs[0].getDescribe().getName() == 'User') {
                        sob.put(f, UserInfo.getUserId());
                    }
                }
            } catch (Exception ignore) {}
        }

        // Name fallback if required
        if (fmap.containsKey('Name')) {
            Schema.DescribeFieldResult nameDfr = fmap.get('Name').getDescribe();
            if (nameDfr.isCreateable() && !nameDfr.isNillable() && sob.get('Name') == null) {
                sob.put('Name', 'Test Name');
            }
        }
        return sob;
    }
}