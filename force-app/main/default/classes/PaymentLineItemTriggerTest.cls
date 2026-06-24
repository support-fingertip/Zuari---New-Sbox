@IsTest
public class PaymentLineItemTriggerTest {

    @IsTest
    static void cover_afterUpdate() {

        // 1) Create Payment__c (parent) - minimal safe record
        Payment__c pay = (Payment__c) buildMinRequired(Payment__c.SObjectType);
        safeSetNameIfPossible(pay, 'PAY-TEST');
        insert pay;

        // 2) Create Payment_Line_Item__c with required lookup Payment__c
        Payment_Line_Item__c pli = (Payment_Line_Item__c) buildMinRequired(Payment_Line_Item__c.SObjectType);
        safeSetNameIfPossible(pli, 'PLI-TEST');

        // REQUIRED FIELD
        setIfCreateable(pli, 'Payment__c', pay.Id);

        insert pli;

        // 3) Update any updateable field to fire AFTER UPDATE trigger
        Payment_Line_Item__c upd = new Payment_Line_Item__c(Id = pli.Id);

        // Try updateable fields safely
        if (!trySetAnyUpdateableField(upd)) {
            upd.Name = 'PLI-TEST-UPD';
        }

        update upd; // fires PaymentLineItemTrigger
    }

    // ---------------- Helpers ----------------

    private static Boolean trySetAnyUpdateableField(SObject sob) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();

        // Common candidates first (ignore if not present)
        List<String> candidates = new List<String>{ 'Status__c', 'Remarks__c', 'Description__c', 'Is_Active__c' };

        for (String f : candidates) {
            if (setIfUpdateable(sob, f, 'X')) return true;
            if (setIfUpdateable(sob, f, true)) return true;
        }

        // Brute pick first updateable field type we can safely set
        for (String f : fm.keySet()) {
            Schema.DescribeFieldResult d = fm.get(f).getDescribe();
            if (!d.isUpdateable()) continue;
            if (d.isCalculated() || d.isAutoNumber()) continue;
            if (f == 'Id') continue;

            try {
                Schema.DisplayType t = d.getType();
                if (t == Schema.DisplayType.STRING || t == Schema.DisplayType.TEXTAREA) {
                    sob.put(f, 'X');
                    return true;
                }
                if (t == Schema.DisplayType.BOOLEAN) {
                    sob.put(f, true);
                    return true;
                }
                if (t == Schema.DisplayType.INTEGER) {
                    sob.put(f, 2);
                    return true;
                }
                if (t == Schema.DisplayType.DOUBLE || t == Schema.DisplayType.CURRENCY || t == Schema.DisplayType.PERCENT) {
                    sob.put(f, 2.0);
                    return true;
                }
                if (t == Schema.DisplayType.DATE) {
                    sob.put(f, Date.today().addDays(1));
                    return true;
                }
                if (t == Schema.DisplayType.DATETIME) {
                    sob.put(f, System.now().addMinutes(10));
                    return true;
                }
                if (t == Schema.DisplayType.PICKLIST) {
                    for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                        if (pe.isActive()) {
                            sob.put(f, pe.getValue());
                            return true;
                        }
                    }
                }
            } catch (Exception ignore) {}
        }

        return false;
    }

    private static Boolean setIfUpdateable(SObject sob, String fieldApi, Object value) {
        if (sob == null || value == null) return false;
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return false;
        if (!fm.get(fieldApi).getDescribe().isUpdateable()) return false;

        try {
            sob.put(fieldApi, value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static void setIfCreateable(SObject sob, String fieldApi, Object value) {
        if (sob == null || value == null) return;
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (!fm.containsKey(fieldApi)) return;
        if (!fm.get(fieldApi).getDescribe().isCreateable()) return;
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

    /**
     * Minimal required createable fields filler.
     * Uses valid values for Email/URL to avoid INVALID_EMAIL_ADDRESS.
     * Does NOT guess required lookups like Payment__c (caller must set).
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
                    // do NOT set random lookups; only safe User
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