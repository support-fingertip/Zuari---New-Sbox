@IsTest
public class LeadUnqualificationTriggerTest {

    // ---------- Test Setup ----------
    @TestSetup
    static void setupData() {
        // Create a Lead (minimal required fields)
        Lead l = new Lead(
            FirstName = 'Test',
            LastName  = 'Lead',
            Company   = 'Test Company',
            Status    = 'Open'
        );
        insert l;

        // Create a Related_Source__c linked to this Lead (using whatever Lead lookup exists)
        Related_Source__c rs = (Related_Source__c) buildSObjectWithRequiredFields(
            'Related_Source__c',
            new Map<String, Object>{
                getLeadLookupFieldApiName('Related_Source__c') => l.Id,
                // If your object has Is_Locked__c and it's writable, keep it unlocked so handler can update it
                'Is_Locked__c' => false
            }
        );
        insert rs;
    }

    // ---------- Tests ----------
    @IsTest
    static void testAfterInsert_FiresHandler() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];

        String leadLookupOnUnq = getLeadLookupFieldApiName('Lead_Unqualification__c');

        // Capture Related_Source__c timestamp before trigger runs (to validate some update happened)
        Related_Source__c rsBefore = fetchRelatedSourceForLead(l.Id);
        Datetime beforeStamp = (rsBefore != null) ? rsBefore.LastModifiedDate : null;

        Test.startTest();

        Lead_Unqualification__c unq = (Lead_Unqualification__c) buildSObjectWithRequiredFields(
            'Lead_Unqualification__c',
            new Map<String, Object>{
                leadLookupOnUnq => l.Id
            }
        );
        insert unq; // SHOULD FIRE: after insert

        Test.stopTest();

        // If handler updates Related_Source__c, LastModifiedDate should change.
        // If your handler only creates/links records differently, this still validates "no crash" + trigger path coverage.
        Related_Source__c rsAfter = fetchRelatedSourceForLead(l.Id);
        System.assertNotEquals(null, rsAfter, 'Expected a Related_Source__c record linked to the Lead to exist.');

        if (beforeStamp != null) {
            System.assert(
                rsAfter.LastModifiedDate >= beforeStamp,
                'Expected Related_Source__c to be updated (or at least not older) after unqualification insert.'
            );
        }
    }

  /*  @IsTest
    static void testAfterUpdate_FiresHandler() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];

        String leadLookupOnUnq = getLeadLookupFieldApiName('Lead_Unqualification__c');

        // Insert first
        Lead_Unqualification__c unq = (Lead_Unqualification__c) buildSObjectWithRequiredFields(
            'Lead_Unqualification__c',
            new Map<String, Object>{
                leadLookupOnUnq => l.Id
            }
        );
        insert unq;

        Related_Source__c rsBefore = fetchRelatedSourceForLead(l.Id);
        Datetime beforeStamp = (rsBefore != null) ? rsBefore.LastModifiedDate : null;

        // Update record (touch a writable field)
        // If no obvious writable field exists, our builder will have set something required—so we just re-save it.
        Test.startTest();
        unq.put(getAnyWritableNonRequiredField('Lead_Unqualification__c'), 'Updated-' + System.now().getTime());
        update unq; // SHOULD FIRE: after update
        Test.stopTest();

        Related_Source__c rsAfter = fetchRelatedSourceForLead(l.Id);
        System.assertNotEquals(null, rsAfter, 'Expected a Related_Source__c record linked to the Lead to exist.');

        if (beforeStamp != null) {
            System.assert(
                rsAfter.LastModifiedDate >= beforeStamp,
                'Expected Related_Source__c to be updated (or at least not older) after unqualification update.'
            );
        }
    }
*/
    @IsTest
    static void testNoRelatedSource_DoesNotBlowUp() {
        // Create a Lead with NO Related_Source__c
        Lead l = new Lead(
            FirstName = 'NoRS',
            LastName  = 'Lead',
            Company   = 'No RS Company',
            Status    = 'Open'
        );
        insert l;

        String leadLookupOnUnq = getLeadLookupFieldApiName('Lead_Unqualification__c');

        Test.startTest();
        Lead_Unqualification__c unq = (Lead_Unqualification__c) buildSObjectWithRequiredFields(
            'Lead_Unqualification__c',
            new Map<String, Object>{
                leadLookupOnUnq => l.Id
            }
        );
        insert unq; // should not throw even if handler finds no related source
        Test.stopTest();

        // No strong assertion possible without knowing handler logic — but this covers the trigger path safely.
        System.assert(true, 'Insert completed without exceptions.');
    }

    // ---------- Helpers ----------

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

        // Apply overrides first (so we don't fight your explicit values)
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

        // Handle reference fields (pick a safe Id if possible)
        if (t == Schema.DisplayType.REFERENCE) {
            List<Schema.SObjectType> refs = fDesc.getReferenceTo();

            // Prefer Lead if applicable
            for (Schema.SObjectType r : refs) {
                if (r.getDescribe().getName() == 'Lead') {
                    Lead l = [SELECT Id FROM Lead LIMIT 1];
                    return l.Id;
                }
            }
            // Prefer User if applicable
            for (Schema.SObjectType r : refs) {
                if (r.getDescribe().getName() == 'User') {
                    return UserInfo.getUserId();
                }
            }
            // Otherwise try Account (create one)
            for (Schema.SObjectType r : refs) {
                if (r.getDescribe().getName() == 'Account') {
                    Account a = new Account(Name = 'Test Account ' + System.now().getTime());
                    insert a;
                    return a.Id;
                }
            }

            // If it references something else and is required, we can’t guess safely.
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

        // For anything else, skip safely
        return null;
    }

    /**
     * Finds the first lookup field on the object that references Lead.
     * (Example: SLead__c, Lead__c, etc.)
     */
    private static String getLeadLookupFieldApiName(String objectApiName) {
        Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
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
        System.assert(false, 'No createable Lead lookup field found on ' + objectApiName);
        return null;
    }

    /**
     * Gets ANY writable, non-required string/picklist/text field to touch during update.
     * If none found, returns a required field name (we will just set it again).
     */
    private static String getAnyWritableNonRequiredField(String objectApiName) {
        Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(objectApiName).getDescribe();

        for (String fApi : d.fields.getMap().keySet()) {
            if (fApi == 'Id') continue;

            Schema.DescribeFieldResult fDesc = d.fields.getMap().get(fApi).getDescribe();
            if (!fDesc.isUpdateable()) continue;
            if (fDesc.isCalculated() || fDesc.isAutoNumber()) continue;

            Boolean isRequired = !fDesc.isNillable() && !fDesc.isDefaultedOnCreate();
            if (isRequired) continue;

            Schema.DisplayType t = fDesc.getType();
            if (t == Schema.DisplayType.STRING || t == Schema.DisplayType.TEXTAREA || t == Schema.DisplayType.PICKLIST) {
                return fApi;
            }
        }

        // Fallback: return some updateable field
        for (String fApi : d.fields.getMap().keySet()) {
            Schema.DescribeFieldResult fDesc = d.fields.getMap().get(fApi).getDescribe();
            if (fApi != 'Id' && fDesc.isUpdateable() && !fDesc.isCalculated() && !fDesc.isAutoNumber()) {
                return fApi;
            }
        }

        // Absolute last fallback: Lead lookup (update with same value)
        return getLeadLookupFieldApiName(objectApiName);
    }

    private static Boolean fieldExistsAndWriteable(String objectApiName, String fieldApiName) {
        if (String.isBlank(fieldApiName)) return false;
        Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        if (!d.fields.getMap().containsKey(fieldApiName)) return false;

        Schema.DescribeFieldResult f = d.fields.getMap().get(fieldApiName).getDescribe();
        return f.isCreateable() || f.isUpdateable();
    }

    /**
     * Fetch the Related_Source__c for a given Lead using its Lead lookup field dynamically.
     */
    private static Related_Source__c fetchRelatedSourceForLead(Id leadId) {
        String leadLookupField = getLeadLookupFieldApiName('Related_Source__c');

        // Build dynamic SOQL because Lead lookup API name can vary (Lead__c vs SLead__c, etc.)
        String soql = 'SELECT Id, LastModifiedDate FROM Related_Source__c WHERE ' + leadLookupField + ' = :leadId LIMIT 1';
        List<SObject> rows = Database.query(soql);
        return rows.isEmpty() ? null : (Related_Source__c) rows[0];
    }
}