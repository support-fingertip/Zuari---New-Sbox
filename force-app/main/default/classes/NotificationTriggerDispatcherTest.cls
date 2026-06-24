@IsTest
public class NotificationTriggerDispatcherTest {

    @IsTest
    static void cover_invokeFromTrigger_emptySet() {
        // should simply do nothing
        NotificationTriggerDispatcher.invokeFromTrigger(new Set<Id>());
    }

    @IsTest
    static void cover_invokeFromTrigger_withRecordIds() {
        // Create a Notification__c record with minimum safe fields
        Notification__c n = (Notification__c) buildMinRequired(Notification__c.SObjectType);
        safeSet(n, 'IsActive__c', true);
        safeSet(n, 'IsNotificationSent__c', false);
        setAnyActivePicklist(n, 'Updated_Status__c');
        safeSetNameIfPossible(n, 'Dispatcher-Cover');
        insert n;

        // Call dispatcher with 1 id (covers loop + controller call)
        NotificationTriggerDispatcher.invokeFromTrigger(new Set<Id>{ n.Id });
    }

    // ---------------- Helpers (same safe pattern) ----------------

    private static void safeSet(SObject sob, String fieldApi, Object value) {
        if (sob == null || value == null) return;
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return;
        Schema.DescribeFieldResult d = fm.get(fieldApi).getDescribe();
        if (!d.isCreateable()) return;
        sob.put(fieldApi, value);
    }

    private static void safeSetNameIfPossible(SObject sob, String nameVal) {
        if (sob == null) return;
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey('Name')) return;
        Schema.DescribeFieldResult d = fm.get('Name').getDescribe();
        if (!d.isCreateable()) return;
        sob.put('Name', nameVal);
    }

    private static void setAnyActivePicklist(SObject sob, String fieldApi) {
        if (sob == null) return;
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return;

        Schema.DescribeFieldResult d = fm.get(fieldApi).getDescribe();
        if (!d.isCreateable() || d.getType() != Schema.DisplayType.Picklist) return;

        for (Schema.PicklistEntry pe : d.getPicklistValues()) {
            if (pe.isActive()) {
                sob.put(fieldApi, pe.getValue());
                return;
            }
        }
    }

    /**
     * Minimal required createable fields filler.
     * Uses VALID values for Email/Url to avoid INVALID_EMAIL_ADDRESS.
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
                    List<Schema.SObjectType> refs = dfr.getReferenceTo();
                    if (!refs.isEmpty() && refs[0].getDescribe().getName() == 'User') {
                        sob.put(f, UserInfo.getUserId());
                    }
                }
            } catch (Exception ignore) {}
        }

        if (fmap.containsKey('Name')) {
            Schema.DescribeFieldResult nameDfr = fmap.get('Name').getDescribe();
            if (nameDfr.isCreateable() && !nameDfr.isNillable() && sob.get('Name') == null) {
                sob.put('Name', 'Test Name');
            }
        }
        return sob;
    }
}