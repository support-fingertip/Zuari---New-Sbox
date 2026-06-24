@IsTest
public class NotificationTriggerTest {

    @IsTest
    static void cover_afterInsert_and_afterUpdate_paths() {

        // Create 2 notifications:
        // n1 -> eligible on INSERT (Active=true, Sent=false)
        // n2 -> ineligible on INSERT (Active=false)
        Notification__c n1 = (Notification__c) buildMinRequired(Notification__c.SObjectType);
        safeSet(n1, 'IsActive__c', true);
        safeSet(n1, 'IsNotificationSent__c', false);
        safeSetNameIfPossible(n1, 'N-Insert-Eligible');

        // set any initial Updated_Status__c value (to later change on update)
        setAnyActivePicklist(n1, 'Updated_Status__c');

        Notification__c n2 = (Notification__c) buildMinRequired(Notification__c.SObjectType);
        safeSet(n2, 'IsActive__c', false);
        safeSet(n2, 'IsNotificationSent__c', false);
        safeSetNameIfPossible(n2, 'N-Insert-Ineligible');
        setAnyActivePicklist(n2, 'Updated_Status__c');

        insert new List<Notification__c>{ n1, n2 }; // fires AFTER INSERT

        // Requery to get stored Updated_Status__c
        n1 = [
            SELECT Id, IsActive__c, Updated_Status__c
            FROM Notification__c
            WHERE Id = :n1.Id
        ];

        // AFTER UPDATE eligible: Active=true and Updated_Status__c changes
        Notification__c n1Upd = new Notification__c(Id = n1.Id);
        safeSet(n1Upd, 'IsActive__c', true);

        String oldStatus = String.valueOf(n1.get('Updated_Status__c'));
        String newStatus = pickDifferentActivePicklistValue(Notification__c.SObjectType, 'Updated_Status__c', oldStatus);

        // If picklist has only 1 value, we still do update safely (won't enter "add id" branch)
        if (!String.isBlank(newStatus)) {
            n1Upd.put('Updated_Status__c', newStatus);
        } else if (!String.isBlank(oldStatus)) {
            n1Upd.put('Updated_Status__c', oldStatus);
        }

        update n1Upd; // fires AFTER UPDATE

        // Also cover the "no dispatch" branch: update without changing Updated_Status__c
        Notification__c n2NoDispatch = new Notification__c(Id = n2.Id);
        safeSet(n2NoDispatch, 'IsActive__c', false); // stays ineligible
        update n2NoDispatch;
    }

    // ---------------- HELPERS ----------------

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
        if (!d.isCreateable()) return;
        if (d.getType() != Schema.DisplayType.Picklist) return;

        for (Schema.PicklistEntry pe : d.getPicklistValues()) {
            if (pe.isActive()) {
                sob.put(fieldApi, pe.getValue());
                return;
            }
        }
    }

    private static String pickDifferentActivePicklistValue(Schema.SObjectType sType, String fieldApi, String currentVal) {
        Map<String, Schema.SObjectField> fm = sType.getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return null;

        Schema.DescribeFieldResult d = fm.get(fieldApi).getDescribe();
        if (d.getType() != Schema.DisplayType.Picklist) return null;

        for (Schema.PicklistEntry pe : d.getPicklistValues()) {
            if (pe.isActive() && pe.getValue() != currentVal) {
                return pe.getValue();
            }
        }
        return null;
    }

    /**
     * Minimal required createable fields filler.
     * Uses VALID values for Email/Url to avoid your earlier "invalid email" screwup.
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

        // Name fallback (if required and createable)
        if (fmap.containsKey('Name')) {
            Schema.DescribeFieldResult nameDfr = fmap.get('Name').getDescribe();
            if (nameDfr.isCreateable() && !nameDfr.isNillable() && sob.get('Name') == null) {
                sob.put('Name', 'Test Name');
            }
        }

        return sob;
    }
}