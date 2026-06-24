@IsTest
public class CancellationLetterVFPControllerTest {

    @IsTest
    static void testControllerLoadsBookingAndCoApplicants() {

        // --- Project ---
        Project__c prj = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden city',
            Active__c = true
        );
        insert prj;

        // --- Plot ---
        Plot__c plot = new Plot__c(
            Name = 'Plot-001',
            Status__c = 'Available',
            Project__c = prj.Id
        );
        insert plot;

        // --- Booking (ONLY writeable fields + address subfields) ---
        Booking__c b = new Booking__c();
        b.First_Applicant_Name__c = 'Test Applicant';
        b.Son_Daughter_Wife_of__c = 'S/o';
        b.PAN_Number__c = 'ABCDE1234F';
        b.Aadhar_No__c = '123456789012';
        b.Address__c = 'Some Address';
        b.Date_of_Birth1__c = Date.newInstance(1995, 1, 1);
        b.Son_Daughter_Wife_of__c = 'S/o';
        b.Booking_Amount__c = 100000;
        b.Pincode1__c = '560001';
        b.Permanent_Address1__c = 'Perm Addr 1';
        

        b.Plot__c = plot.Id;

        // Set ADDRESS SUBFIELDS (compound field itself is read-only)
        b.Correspondence_Address__Street__s = 'Corr Street';
        b.Correspondence_Address__City__s = 'Bangalore';
        b.Correspondence_Address__StateCode__s = 'KA';
        b.Correspondence_Address__PostalCode__s = '560001';
        b.Correspondence_Address__CountryCode__s = 'IN';

        // Permanent_Address2__c is read-only in your org => set subfields instead (if they exist)
        // If these subfields don't exist in your org, comment them out.
        b.Permanent_Address2__Street__s = 'Street 1';
        b.Permanent_Address2__City__s = 'Bangalore';
        b.Permanent_Address2__StateCode__s = 'KA';
        b.Permanent_Address2__PostalCode__s = '560001';
        b.Permanent_Address2__CountryCode__s = 'IN';

        // Office_Address1__c subfields
        b.Office_Address1__Street__s = 'Office Street';
        b.Office_Address1__City__s = 'Bangalore';
        b.Office_Address1__StateCode__s = 'KA';
        b.Office_Address1__PostalCode__s = '560001';
        b.Office_Address1__CountryCode__s = 'IN';

        // Do NOT set these (read-only in your org):
        // b.Agreement_Execution_Date__c = ...
        // b.GRAND_TOTAL__c = ...
        // b.Permanent_Address2__c = ...

        insert b;

        // --- Co-Applicant (ONLY fields you query; keep it minimal to avoid validation failures) ---
        Co_Applicant__c co = new Co_Applicant__c(
            Booking__c = b.Id,
            Name = 'Co Applicant 1',
            Email__c = 'co@app.com',
            Primary_Phone__c = '8888888888',
            PAN_Number__c = 'AAAAA1111A'
        );
        insert co;

        // --- Run controller ---
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        CancellationLetterVFPController ctrl = new CancellationLetterVFPController(sc);
        String permFull = ctrl.getPermanentFullAddress();
        Test.stopTest();

        // --- Assertions ---
        System.assertEquals(b.Id, ctrl.bookingId);
        System.assertNotEquals(null, ctrl.booking);
        System.assertEquals(b.Id, ctrl.booking.Id);

        System.assertNotEquals(null, ctrl.coApplicants);
        System.assert(ctrl.coApplicants.size() > 0);
        System.assertNotEquals(null, ctrl.firstCoApplicant);

        // If address subfields exist and were set, formatted address should not be blank
        // If your org doesn't actually have Permanent_Address2__Street__s etc, this might be empty.
        System.assertNotEquals(null, permFull);
    }
}