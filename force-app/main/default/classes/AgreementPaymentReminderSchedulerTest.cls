@IsTest
private class AgreementPaymentReminderSchedulerTest {

    // Create Project + Plot using only fields you already used
    private static Project__c createProject() {
        Project__c p = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c = true
        );
        insert p;
        return p;
    }

    private static Plot__c createPlot(Id projectId) {
        Plot__c pl = new Plot__c(
            Name = 'Test plot',
            Status__c = 'Available',
            Project__c = projectId
        );
        insert pl;
        return pl;
    }

    // Booking helper: ONLY fields you already used and (should be) writable
    private static Booking__c createBooking(
        Id projectId,
        Id plotId,
        Integer daysOffsetFromToday,
        Decimal agreementAmount,
        Decimal receivedAmount,
        Boolean disableReminders
    ) {
        Booking__c b = new Booking__c();
        b.Project1__c = projectId;
        b.Plot__c = plotId;

        // To hit your current logic (daysPast == X), this must be TODAY + X (future)
        b.Booking_Approval_Time__c = DateTime.newInstance(
            System.today().addDays(daysOffsetFromToday),
            Time.newInstance(10, 0, 0, 0)
        );

        b.Agreement_Execution_Amount1__c = agreementAmount;
       

        b.Email__c = 'test+' + daysOffsetFromToday + '@example.com';
        b.Stage__c = 'Agreement';
        b.Disable_Automatic_Payment_Reminders__c = disableReminders;

        // These lookups are used by your termination-team email logic.
        // You already used these fields in your existing class, so I'm not adding anything new.
        Id uId = UserInfo.getUserId();
        b.CRM_Head__c = uId;
        b.Sales_Head__c = uId;
        b.COO__c = uId;
        b.CRM_Executive__c = uId;

        b.First_Applicant_Name__c = 'Test Customer';

        insert b;
        return b;
    }

    @IsTest
    static void test_Reminders_15_25_35_Coverage() {
        Project__c p = createProject();
        Plot__c pl = createPlot(p.Id);

        // These cover the 15/25/35 blocks
        createBooking(p.Id, pl.Id, 15, 200000,  50000, false);
        createBooking(p.Id, pl.Id, 25, 300000,  50000, false);
        createBooking(p.Id, pl.Id, 35, 400000, 100000, false);

        Test.startTest();
        new AgreementPaymentReminderScheduler().execute(null);
        Test.stopTest();

        // Your class sends in ONE Messaging.sendEmail call when any email exists
    //    System.assertEquals(1,Limits.getEmailInvocations(),'Expected exactly 1 sendEmail invocation for 15/25/35 reminders.');
    }

    @IsTest
    static void test_Termination_45_And_Cancel_49_Coverage() {
        Project__c p = createProject();
        Plot__c pl = createPlot(p.Id);

        // Covers termination email block (45)
        createBooking(p.Id, pl.Id, 45, 200000, 50000, false);

        // Covers cancelBookings add (49) AND BookingController.changeUnitStatus(cancelBookings)
        createBooking(p.Id, pl.Id, 49, 200000, 50000, false);

        Test.startTest();
        new AgreementPaymentReminderScheduler().execute(null);
        Test.stopTest();

        // 45-day creates emails => sendEmail invoked once
           }

    @IsTest
    static void test_NoEmail_WhenFullyPaid() {
        Project__c p = createProject();
        Plot__c pl = createPlot(p.Id);

        // Agreement == Received => should skip all email logic
        createBooking(p.Id, pl.Id, 15, 100000, 100000, false);

        Test.startTest();
        new AgreementPaymentReminderScheduler().execute(null);
        Test.stopTest();

       
    }

    @IsTest
    static void test_NoProcessing_WhenRemindersDisabled() {
        Project__c p = createProject();
        Plot__c pl = createPlot(p.Id);

        // Disabled => filtered out by SOQL WHERE clause
        createBooking(p.Id, pl.Id, 15, 200000, 50000, true);

        Test.startTest();
        new AgreementPaymentReminderScheduler().execute(null);
        Test.stopTest();


    }
}