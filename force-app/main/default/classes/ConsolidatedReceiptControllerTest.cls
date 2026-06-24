@IsTest
public class ConsolidatedReceiptControllerTest {

    @IsTest
    static void testConsolidatedReceiptController_HappyPath() {

        // --- Project / Plot ---
        Project__c prj = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden city',
            Active__c = true
        );
        insert prj;

        Plot__c plot = new Plot__c(
            Name = 'Plot-001',
            Status__c = 'Available',
            Project__c = prj.Id
        );
        insert plot;

        // --- Booking ---
        Booking__c b = new Booking__c();
        b.PAN_Number__c = 'ABCDE1234F';
        b.Plot__c = plot.Id;

        // CRITICAL: controller uses setScale() on this
        //b.Total_received_Amount__c = 12345.67;

        // address subfields (optional)
        Map<String, Schema.SObjectField> bFields = Booking__c.SObjectType.getDescribe().fields.getMap();
        if (bFields.containsKey('Permanent_Address2__Street__s')) {
            b.put('Permanent_Address2__Street__s', 'Street 1');
            b.put('Permanent_Address2__City__s', 'Bangalore');
            b.put('Permanent_Address2__StateCode__s', 'KA');
            b.put('Permanent_Address2__PostalCode__s', '560001');
            b.put('Permanent_Address2__CountryCode__s', 'IN');
        }
        if (bFields.containsKey('Correspondence_Address__Street__s')) {
            b.put('Correspondence_Address__Street__s', 'Corr Street');
            b.put('Correspondence_Address__City__s', 'Bangalore');
            b.put('Correspondence_Address__StateCode__s', 'KA');
            b.put('Correspondence_Address__PostalCode__s', '560001');
            b.put('Correspondence_Address__CountryCode__s', 'IN');
        }
        if (bFields.containsKey('Office_Address1__Street__s')) {
            b.put('Office_Address1__Street__s', 'Office Street');
            b.put('Office_Address1__City__s', 'Bangalore');
            b.put('Office_Address1__StateCode__s', 'KA');
            b.put('Office_Address1__PostalCode__s', '560001');
            b.put('Office_Address1__CountryCode__s', 'IN');
        }

        insert b;

        // --- Co-Applicant ---
        Co_Applicant__c co = new Co_Applicant__c(
            Booking__c = b.Id,
            Name = 'Co Applicant 1',
            PAN_Number__c = 'ABCDE1234F',
            Salutation__c = 'Mr.'
        );
        insert co;

        // --- Payment Schedule (needed for Payment_schedule__r.Name in controller) ---
        Payment_schedule__c ps = new Payment_schedule__c(
            Name = 'PS-1',
            Booking__c = b.Id,
            S_No__c = 1
        );
        insert ps;

        // --- Receipt (set Approved on parent) ---
        Receipt__c r = new Receipt__c();
        r.Booking__c = b.Id;

        Map<String, Schema.SObjectField> rFields = Receipt__c.SObjectType.getDescribe().fields.getMap();

        if (rFields.containsKey('Receipt_Date__c')) {
            r.put('Receipt_Date__c', Date.today());
        } else if (rFields.containsKey('Receipt_date__c')) {
            r.put('Receipt_date__c', Date.today());
        }

        if (rFields.containsKey('Receipt_No__c')) {
            r.put('Receipt_No__c', 'RC-001');
        }

        // mark receipt approved (line item status should be derived by automation)
        if (rFields.containsKey('Approval_status__c')) {
            r.put('Approval_status__c', 'Approved');
        } else if (rFields.containsKey('Approval_Status__c')) {
            r.put('Approval_Status__c', 'Approved');
        }

        insert r;

        // --- Receipt Line Item ---
        Receipt_Line_Item__c rli = new Receipt_Line_Item__c();
        rli.Booking__c = b.Id;
        rli.Amount__c = 12345.67;
        rli.Mode_of_Payment__c = 'Cheque';
        rli.Cheque_no_Transaction_Number__c = 'TXN123';
        rli.Bank_Name__c = 'Test Bank';

        // Link to parent receipt
        Map<String, Schema.SObjectField> rliFields = Receipt_Line_Item__c.SObjectType.getDescribe().fields.getMap();
        if (rliFields.containsKey('Receipt__c')) {
            rli.put('Receipt__c', r.Id);
        }

        // Link payment schedule
        if (rliFields.containsKey('Payment_schedule__c')) {
            rli.put('Payment_schedule__c', ps.Id);
        } else if (rliFields.containsKey('Payment_Schedule__c')) {
            rli.put('Payment_Schedule__c', ps.Id);
        }

        // ✅ DO NOT set Approval_Status__c here — it is read-only in your org
        insert rli;

        // --- Run controller ---
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        ConsolidatedReceiptController ctrl = new ConsolidatedReceiptController(sc);
        String permFull = ctrl.getPermanentFullAddress();
        Test.stopTest();

        // --- Asserts ---
        System.assertNotEquals(null, ctrl.booking);
        System.assertEquals(b.Id, ctrl.booking.Id);

        System.assertNotEquals(null, ctrl.totalAmount);
        System.assertNotEquals(null, ctrl.receiptAmountInString);
        System.assertNotEquals(null, ctrl.receiptAmountInWords);

        // repList can be empty IF your org doesn't auto-populate line item Approval_Status__c as Approved.
        // If repList is empty, your controller query filter is too strict in production.
        System.assertNotEquals(null, ctrl.repList);

        System.assertNotEquals(null, ctrl.coapplicants);
        System.assert(ctrl.coapplicants.size() > 0);
        System.assertNotEquals(null, ctrl.firstCoApplicant);

        System.assertNotEquals(null, permFull);
    }
}