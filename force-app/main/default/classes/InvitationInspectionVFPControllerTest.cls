@IsTest
private class InvitationInspectionVFPControllerTest {

    @IsTest
    static void testConstructor_WithPlot_SetsPlotName() {

        // Create required Project + Plot (use same fields/values style as your other tests)
        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c = true
        );
        insert pjt;

        Plot__c ut = new Plot__c(
            Name = 'Test plot',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        // Create Quote (if Booking requires it in your org)
        Quote__c qc = new Quote__c(
            Quote_status__c  = 'Converted',
            Block__c         = ' ',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100
        );
        insert qc;

        // Create Booking with Plot
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c        = qc.Id,
            Plot__c         = ut.Id,
            Email__c        = 'test@gmail.com'
        );
        insert book;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        InvitationInspectionVFPController ctrl;
        try {
            ctrl = new InvitationInspectionVFPController(sc);
        } catch (Exception e) {
            System.assert(false, 'Controller constructor threw exception: ' + e.getMessage());
            return;
        }
        Test.stopTest();

        System.assertEquals(book.Id, ctrl.bookingId, 'bookingId should be set from StandardController.');
        System.assertEquals('Test plot', ctrl.plotName, 'plotName should match Plot__r.Name.');
    }

    @IsTest
    static void testConstructor_WithoutPlot_SetsPlotNameNull() {

        // Create Quote (if Booking requires it in your org)
        Quote__c qc = new Quote__c(
            Quote_status__c  = 'Converted',
            Block__c         = ' ',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100
        );
        insert qc;

        // Create Booking WITHOUT Plot__c
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c        = qc.Id,
            Email__c        = 'test@gmail.com'
        );
        insert book;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        InvitationInspectionVFPController ctrl;
        try {
            ctrl = new InvitationInspectionVFPController(sc);
        } catch (Exception e) {
            System.assert(false, 'Controller constructor threw exception: ' + e.getMessage());
            return;
        }
        Test.stopTest();

        System.assertEquals(book.Id, ctrl.bookingId, 'bookingId should be set from StandardController.');
        System.assertEquals(null, ctrl.plotName, 'plotName should be null when Plot__r is null.');
    }
}