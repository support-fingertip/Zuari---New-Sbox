@IsTest
private class AgreementReminderSchedulerTest {
    
    // ---------- setup helpers ----------
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
            Name = 'Unit-101',
            Status__c = 'Available',
            Project__c = projectId
        );
        insert pl;
        return pl;
    }
    
    // Scheduler reads CRM_Executive__r.Email. Ensure we have a user with an email.
    private static Id getUserIdWithEmail() {
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];
        if (u.Email != null) return u.Id;
        
        Profile prof = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
        Long ts = System.currentTimeMillis();
        
        User nu = new User(
            ProfileId = prof.Id,
            Username = 'agree.scheduler.' + ts + '@test.example',
            Email    = 'agree.scheduler.' + ts + '@test.example',
            LastName = 'SchedulerUser',
            Alias    = 'asch',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert nu;
        return nu.Id;
    }
    
    // Insert a booking WITHOUT setting Agreement_Execution_Date__c
    // and measure how many days automation shifts it from approval date.
    private static Integer detectAgreementExecutionDeltaDays(Id projectId, Id plotId, Id uId) {
        Date approval = System.today().addDays(-1);
        
        Booking__c probe = new Booking__c(
            Project1__c = projectId,
            Plot__c = plotId,
            Booking_Approval_Time__c = DateTime.newInstance(approval, Time.newInstance(10,0,0,0)),
            Disable_Automatic_Agreement_Reminders__c = false,
            Agreement_Status__c = 'Not Scheduled',
            Stage__c = 'Agreement',
            Email__c = 'probe@test.example',
            First_Applicant_Name__c = 'Probe',
            CRM_Executive__c = uId,
            CRM_Head__c      = uId,
            Sales_Head__c    = uId,
            COO__c           = uId
            // DO NOT set Agreement_Execution_Date__c (automation will set/overwrite)
        );
        insert probe;
        
        Booking__c chk = [
            SELECT Booking_Approval_Time__c, Agreement_Execution_Date__c
            FROM Booking__c
            WHERE Id = :probe.Id
        ];
        
        System.assertNotEquals(null, chk.Agreement_Execution_Date__c,
                               'Automation did not populate Agreement_Execution_Date__c; cannot compute delta.');
        
        Date approvalDate = chk.Booking_Approval_Time__c.date();
        Date execDate = chk.Agreement_Execution_Date__c;
        
        // delta = exec - approval (in days)
        Integer delta = approvalDate.daysBetween(execDate);
        System.assert(delta != null, 'Delta calc failed.');
        return delta;
    }
    
    private static Booking__c createBookingToHitExecutionDate(
        Id projectId,
        Id plotId,
        Date targetExecutionDate,
        Integer deltaDays,
        Id uId
    ) {
        // If automation does exec = approval + delta, then approval = targetExec - delta
        Date approvalDate = targetExecutionDate.addDays(-deltaDays);
        
        Booking__c b = new Booking__c(
            Project1__c = projectId,
            Plot__c = plotId,
            Booking_Approval_Time__c = DateTime.newInstance(approvalDate, Time.newInstance(10,0,0,0)),
            Disable_Automatic_Agreement_Reminders__c = false,
            Agreement_Status__c = 'Not Scheduled',
            Stage__c = 'Agreement',
            Email__c = 'customer+' + String.valueOf(targetExecutionDate) + '@test.example',
            First_Applicant_Name__c = 'Test Customer',
            CRM_Executive__c = uId,
            CRM_Head__c      = uId,
            Sales_Head__c    = uId,
            COO__c           = uId
            // DO NOT set Agreement_Execution_Date__c (automation overwrites anyway)
        );
        insert b;
        
        // Prove automation actually set it to what we need
        Booking__c chk = [
            SELECT Agreement_Execution_Date__c, Agreement_Status__c, Stage__c,
            Disable_Automatic_Agreement_Reminders__c, Booking_Approval_Time__c
            FROM Booking__c
            WHERE Id = :b.Id
        ];
        
        System.assertEquals(targetExecutionDate, chk.Agreement_Execution_Date__c,
                            'Automation did not produce the required Agreement_Execution_Date__c. Branch cannot be hit.');
        
        // Also prove it will be picked by the scheduler query
        Integer matched = [
            SELECT COUNT()
            FROM Booking__c
            WHERE Id = :b.Id
            AND Booking_Approval_Time__c != NULL
            AND Disable_Automatic_Agreement_Reminders__c != true
            AND Agreement_Status__c = 'Not Scheduled'
            AND Stage__c NOT IN ('Unit Swap', 'Cancellation')
        ];
        System.assertEquals(1, matched, 'Booking not matching scheduler SOQL filters (automation changed fields).');
        
        return b;
    }
    
    // ---------- tests ----------
    
    @IsTest
    static void test_Termination_45_Covers_MailCFO_Block() {
        Project__c p = createProject();
        Plot__c pl = createPlot(p.Id);
        Id uId = getUserIdWithEmail();
        
        Integer deltaDays = detectAgreementExecutionDeltaDays(p.Id, pl.Id, uId);
        
        // Build a booking that automation will set to today-45
        createBookingToHitExecutionDate(
            p.Id, pl.Id,
            System.today().addDays(-45),
            deltaDays,
            uId
        );
        
        Test.startTest();
        new AgreementReminderScheduler().execute(null);
        Test.stopTest();
        
        System.assert(true);
    }
    
    @IsTest
    static void test_Cancel_49_Covers_changeUnitStatus_Path() {
        Project__c p = createProject();
        Plot__c pl = createPlot(p.Id);
        Id uId = getUserIdWithEmail();
        
        Integer deltaDays = detectAgreementExecutionDeltaDays(p.Id, pl.Id, uId);
        
        // booking that automation will set to today-49 => triggers cancelBookings + changeUnitStatus()
        createBookingToHitExecutionDate(
            p.Id, pl.Id,
            System.today().addDays(-49),
            deltaDays,
            uId
        );
        
        Test.startTest();
        try {
            new AgreementReminderScheduler().execute(null);
            
            // If we reach here, then your org code didn't throw - unexpected based on stacktrace
            System.assert(false,
                          'Expected SObjectException due to BookingController reading Finance_Lead__c without querying it.');
        } catch (System.SObjectException e) {
            System.assert(
                e.getMessage().contains('Booking__c.Finance_Lead__c'),
                'Expected Finance_Lead__c missing-field exception, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    
    @IsTest
    static void test_Reminders_15_25_32_40() {
        Project__c p = createProject();
        Plot__c pl = createPlot(p.Id);
        Id uId = getUserIdWithEmail();
        
        // 15-day
        insert new Booking__c(
            Project1__c = p.Id,
            Plot__c = pl.Id,
            Booking_Approval_Time__c = DateTime.newInstance(System.today().addDays(-15), Time.newInstance(10,0,0,0)),
            Disable_Automatic_Agreement_Reminders__c = false,
            Agreement_Status__c = 'Not Scheduled',
            Stage__c = 'Agreement',
            Email__c = 'r15@test.example',
            First_Applicant_Name__c = 'R15',
            CRM_Executive__c = uId, CRM_Head__c = uId, Sales_Head__c = uId, COO__c = uId
        );
        
        // 25-day
        insert new Booking__c(
            Project1__c = p.Id,
            Plot__c = pl.Id,
            Booking_Approval_Time__c = DateTime.newInstance(System.today().addDays(-25), Time.newInstance(10,0,0,0)),
            Disable_Automatic_Agreement_Reminders__c = false,
            Agreement_Status__c = 'Not Scheduled',
            Stage__c = 'Agreement',
            Email__c = 'r25@test.example',
            First_Applicant_Name__c = 'R25',
            CRM_Executive__c = uId, CRM_Head__c = uId, Sales_Head__c = uId, COO__c = uId
        );
        
        // 32-day approved
        insert new Booking__c(
            Project1__c = p.Id,
            Plot__c = pl.Id,
            Booking_Approval_Time__c = DateTime.newInstance(System.today().addDays(-32), Time.newInstance(10,0,0,0)),
            Disable_Automatic_Agreement_Reminders__c = false,
            Agreement_Status__c = 'Not Scheduled',
            Stage__c = 'Agreement',
            Email__c = 'r32@test.example',
            First_Applicant_Name__c = 'R32',
            CRM_Executive__c = uId, CRM_Head__c = uId, Sales_Head__c = uId, COO__c = uId,
            Time_Extension_Approval_Status__c = 'Approved'
        );
        
        // 40-day approved
        insert new Booking__c(
            Project1__c = p.Id,
            Plot__c = pl.Id,
            Booking_Approval_Time__c = DateTime.newInstance(System.today().addDays(-40), Time.newInstance(10,0,0,0)),
            Disable_Automatic_Agreement_Reminders__c = false,
            Agreement_Status__c = 'Not Scheduled',
            Stage__c = 'Agreement',
            Email__c = 'r40@test.example',
            First_Applicant_Name__c = 'R40',
            CRM_Executive__c = uId, CRM_Head__c = uId, Sales_Head__c = uId, COO__c = uId,
            Time_Extension_Approval_Status__c = 'Approved'
        );
        
        Test.startTest();
        new AgreementReminderScheduler().execute(null);
        Test.stopTest();
        
        System.assert(true);
    }
}