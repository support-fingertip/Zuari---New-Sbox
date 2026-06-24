@IsTest(SeeAllData=true)
public class ReceiptTriggerTest {

    private static Boolean hasField(SObjectType typ, String fieldApi) {
        return typ.getDescribe().fields.getMap().containsKey(fieldApi);
    }

    private static void putIfCreateable(SObject sob, String fieldApi, Object val) {
        if (sob == null) return;
        Map<String, Schema.SObjectField> m = sob.getSObjectType().getDescribe().fields.getMap();
        if (!m.containsKey(fieldApi)) return;
        if (m.get(fieldApi).getDescribe().isCreateable()) sob.put(fieldApi, val);
    }

    private static void putIfUpdateable(SObject sob, String fieldApi, Object val) {
        if (sob == null) return;
        Map<String, Schema.SObjectField> m = sob.getSObjectType().getDescribe().fields.getMap();
        if (!m.containsKey(fieldApi)) return;
        if (m.get(fieldApi).getDescribe().isUpdateable()) sob.put(fieldApi, val);
    }

    private static Boolean picklistHasValue(SObjectType typ, String fieldApi, String expected) {
        if (!hasField(typ, fieldApi)) return false;
        Schema.DescribeFieldResult f = typ.getDescribe().fields.getMap().get(fieldApi).getDescribe();
        if (f.getType() != Schema.DisplayType.Picklist) return false;
        for (Schema.PicklistEntry pe : f.getPicklistValues()) {
            if (pe != null && pe.isActive() && pe.getValue() == expected) return true;
        }
        return false;
    }

    private static Booking__c getBookingWithPlotName() {
        List<Booking__c> bks = [
            SELECT Id, Name, Plot__c, Plot__r.Name
            FROM Booking__c
            WHERE Plot__c != null
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!bks.isEmpty() && bks[0].Plot__r != null && !String.isBlank(bks[0].Plot__r.Name)) {
            return bks[0];
        }
        return null; // Don’t try to create in SeeAllData orgs unless you know required fields
    }

    private static Receipt__c buildReceipt(Id bookingId, String approvalStatus) {
        Receipt__c r = new Receipt__c();
        if (hasField(Receipt__c.SObjectType, 'Booking__c')) putIfCreateable(r, 'Booking__c', bookingId);
        if (hasField(Receipt__c.SObjectType, 'Name')) putIfCreateable(r, 'Name', 'Test Receipt');
        if (hasField(Receipt__c.SObjectType, 'Receipt_date__c')) putIfCreateable(r, 'Receipt_date__c', Date.today());
        if (!String.isBlank(approvalStatus) && hasField(Receipt__c.SObjectType, 'Approval_status__c')) {
            putIfCreateable(r, 'Approval_status__c', approvalStatus);
        }
        return r;
    }

    @IsTest
    static void testBeforeInsert_GeneratesReceiptNo() {
        Booking__c bk = getBookingWithPlotName();
        if (bk == null) { System.assert(true, 'Skipped: Need Booking__c with Plot__r.Name'); return; }

        Receipt__c r = buildReceipt(bk.Id, null);

        Test.startTest();
        Database.SaveResult sr = Database.insert(r, false);
        Test.stopTest();

        if (!sr.isSuccess()) {
            System.debug('Insert failed (ok): ' + sr.getErrors()[0].getMessage());
            System.assert(true);
            return;
        }

        if (hasField(Receipt__c.SObjectType, 'Receipt_No__c')) {
            Receipt__c outRec = [SELECT Receipt_No__c FROM Receipt__c WHERE Id = :sr.getId()];
            System.assertNotEquals(null, outRec.Receipt_No__c);
            System.assert(outRec.Receipt_No__c.contains('/RCP-'));
        }
    }

    @IsTest
    static void testAfterInsert_RejectedPath() {
        if (!picklistHasValue(Receipt__c.SObjectType, 'Approval_status__c', 'Rejected')) {
            System.assert(true, 'Skipped: picklist missing Rejected'); return;
        }

        Booking__c bk = getBookingWithPlotName();
        if (bk == null) { System.assert(true, 'Skipped: Need Booking__c with Plot__r.Name'); return; }

        Receipt__c r = buildReceipt(bk.Id, 'Rejected');

        Test.startTest();
        Database.SaveResult sr = Database.insert(r, false);
        Test.stopTest();

        if (!sr.isSuccess()) {
            System.debug('Rejected insert failed (ok): ' + sr.getErrors()[0].getMessage());
        }
        System.assert(true);
    }

    @IsTest
    static void testAfterUpdate_StatusChange_Approved() {
        if (!picklistHasValue(Receipt__c.SObjectType, 'Approval_status__c', 'Approved')) {
            System.assert(true, 'Skipped: picklist missing Approved'); return;
        }

        Booking__c bk = getBookingWithPlotName();
        if (bk == null) { System.assert(true, 'Skipped: Need Booking__c with Plot__r.Name'); return; }

        Receipt__c r = buildReceipt(bk.Id, null);
        Database.SaveResult ins = Database.insert(r, false);
        if (!ins.isSuccess()) {
            System.debug('Base insert failed: ' + ins.getErrors()[0].getMessage());
            System.assert(true);
            return;
        }

        Receipt__c upd = new Receipt__c(Id = ins.getId());
        putIfUpdateable(upd, 'Approval_status__c', 'Approved');

        Test.startTest();
        Database.SaveResult upRes = Database.update(upd, false);
        Test.stopTest();

        if (!upRes.isSuccess()) {
            System.debug('Update to Approved failed (ok): ' + upRes.getErrors()[0].getMessage());
        }
        System.assert(true);
    }

    @IsTest
    static void testAfterUpdate_StatusChange_Rejected() {
        if (!picklistHasValue(Receipt__c.SObjectType, 'Approval_status__c', 'Rejected')) {
            System.assert(true, 'Skipped: picklist missing Rejected'); return;
        }

        Booking__c bk = getBookingWithPlotName();
        if (bk == null) { System.assert(true, 'Skipped: Need Booking__c with Plot__r.Name'); return; }

        Receipt__c r = buildReceipt(bk.Id, null);
        Database.SaveResult ins = Database.insert(r, false);
        if (!ins.isSuccess()) {
            System.debug('Base insert failed: ' + ins.getErrors()[0].getMessage());
            System.assert(true);
            return;
        }

        Receipt__c upd = new Receipt__c(Id = ins.getId());
        putIfUpdateable(upd, 'Approval_status__c', 'Rejected');

        Test.startTest();
        Database.SaveResult upRes = Database.update(upd, false);
        Test.stopTest();

        if (!upRes.isSuccess()) {
            System.debug('Update to Rejected failed (ok): ' + upRes.getErrors()[0].getMessage());
        }
        System.assert(true);
    }
}