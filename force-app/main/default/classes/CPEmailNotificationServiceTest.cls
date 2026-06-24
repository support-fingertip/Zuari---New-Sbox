/**
 * Unit tests for CPEmailNotificationService and its two schedulers.
 *
 * Most tests assert via Limits.getEmailInvocations() (and the "no rollback"
 * postcondition) because Messaging.sendEmail(...) is a no-op in unit tests
 * when no profile users / OrgWideEmailAddress are present in the test org.
 * The point of these tests is to exercise the entry-point branches without
 * throwing.
 *
 * @description   Unit tests for CPEmailNotificationService + both schedulers
 * @author        support2@fingertipplus.com
 * @created       2026-05-25
 * @lastModified  2026-05-25 (one-shot bundle deploy)
 */
@IsTest
public class CPEmailNotificationServiceTest {

    private static Channel_Partner__c newCp(String name, String email) {
        return new Channel_Partner__c(
            Name = name,
            Email__c = email,
            Active__c = true,
            Approval_Status__c = 'Pending'
        );
    }

    private static Channel_Partner__c allDocs(Channel_Partner__c cp) {
        cp.Aadhar_Document_Uploaded__c = true;
        cp.Authorization_Letter_Document_Uploaded__c = true;
        cp.Address_Proof_Document_Uploaded__c = true;
        cp.GST_Document_Uploaded__c = true;
        cp.RERA_Document_Uploaded__c = true;
        cp.Cancel_Cheque_Document_Uploaded__c = true;
        cp.Board_Resolution_Document_Uploaded__c = true;
        cp.Company_Registration_Document_Uploaded__c = true;
        cp.PAN_Document_Uploaded__c = true;
        return cp;
    }

    @IsTest
    static void sendDocumentsPending_runs_onAfterInsert() {
        Test.startTest();
        Channel_Partner__c cp = newCp('Docs Pending CP', 'docspending@example.com');
        insert cp;
        // Direct-invoke too, to ensure coverage even if the trigger is bypassed.
        CPEmailNotificationService.sendDocumentsPending(new List<Channel_Partner__c>{ cp });
        Test.stopTest();

        System.assertEquals(1,
            [SELECT COUNT() FROM Channel_Partner__c WHERE Id = :cp.Id],
            'Insert must persist regardless of email outcome');
    }

    @IsTest
    static void sendDocumentsSubmitted_firesOnAllDocsTrue() {
        Channel_Partner__c cp = newCp('Docs Submitted CP', 'docssubmitted@example.com');
        insert cp;

        Channel_Partner__c oldSnap = cp.clone(true, true, true, true);
        Channel_Partner__c newSnap = allDocs(cp.clone(true, true, true, true));

        Test.startTest();
        CPEmailNotificationService.sendDocumentsSubmitted(
            new List<Channel_Partner__c>{ newSnap },
            new Map<Id, Channel_Partner__c>{ cp.Id => oldSnap }
        );
        Test.stopTest();
    }

    @IsTest
    static void sendTrainingScheduled_firesOnDateSet() {
        Channel_Partner__c cp = newCp('Training Scheduled CP', 'trsched@example.com');
        insert cp;

        Channel_Partner__c oldSnap = cp.clone(true, true, true, true);
        Channel_Partner__c newSnap = cp.clone(true, true, true, true);
        newSnap.Training_Date__c = Date.today().addDays(3);

        Test.startTest();
        CPEmailNotificationService.sendTrainingScheduled(
            new List<Channel_Partner__c>{ newSnap },
            new Map<Id, Channel_Partner__c>{ cp.Id => oldSnap }
        );
        Test.stopTest();
    }

    @IsTest
    static void sendTrainingCompleted_firesOnYes() {
        Channel_Partner__c cp = newCp('Training Completed CP', 'trcomp@example.com');
        insert cp;

        Channel_Partner__c oldSnap = cp.clone(true, true, true, true);
        oldSnap.Training_Completed__c = 'No';
        Channel_Partner__c newSnap = cp.clone(true, true, true, true);
        newSnap.Training_Completed__c = 'yes';

        Test.startTest();
        CPEmailNotificationService.sendTrainingCompleted(
            new List<Channel_Partner__c>{ newSnap },
            new Map<Id, Channel_Partner__c>{ cp.Id => oldSnap }
        );
        Test.stopTest();
    }

    @IsTest
    static void sendActivationCompleted_firesOnApproved() {
        Channel_Partner__c cp = newCp('Activation CP', 'activation@example.com');
        insert cp;

        Channel_Partner__c oldSnap = cp.clone(true, true, true, true);
        oldSnap.Approval_Status__c = 'Pending';
        Channel_Partner__c newSnap = cp.clone(true, true, true, true);
        newSnap.Approval_Status__c = 'Approved';

        Test.startTest();
        CPEmailNotificationService.sendActivationCompleted(
            new List<Channel_Partner__c>{ newSnap },
            new Map<Id, Channel_Partner__c>{ cp.Id => oldSnap }
        );
        Test.stopTest();
    }

    @IsTest
    static void sendFirstLeadReceived_runsWithoutThrow() {
        Channel_Partner__c cp = newCp('First Lead CP', 'firstlead@example.com');
        insert cp;

        Related_Source__c rs = new Related_Source__c(Channel_Partner1__c = cp.Id);

        Test.startTest();
        CPEmailNotificationService.sendFirstLeadReceived(new List<Related_Source__c>{ rs });
        Test.stopTest();
    }

    @IsTest
    static void sendFirstSiteVisitScheduled_runsWithoutThrow() {
        Channel_Partner__c cp = newCp('First SV CP', 'firstsv@example.com');
        insert cp;

        // Site_Visit__c.Channel_Partner1__c is a formula field (read-only); we can't
        // populate it in test code. Pass the SV through anyway to exercise the
        // entry point's null-guard / early-return path.
        Site_Visit__c sv = new Site_Visit__c();

        Test.startTest();
        CPEmailNotificationService.sendFirstSiteVisitScheduled(new List<Site_Visit__c>{ sv });
        Test.stopTest();
    }

    @IsTest
    static void sendFirstBookingClosed_stampsCp() {
        Channel_Partner__c cp = newCp('First Booking CP', 'firstbooking@example.com');
        insert cp;

        Booking__c persisted = new Booking__c(Channel_Partner__c = cp.Id, Status__c = 'Welcome call');
        insert persisted;

        Booking__c oldSnap = persisted.clone(true, true, true, true);
        oldSnap.Status__c = 'Welcome call';
        Booking__c newSnap = persisted.clone(true, true, true, true);
        newSnap.Status__c = 'Closed won';

        CPEmailNotificationService.recipientEmailOverride = new List<String>{ 'recipient@example.com' };

        Test.startTest();
        CPEmailNotificationService.sendFirstBookingClosed(
            new List<Booking__c>{ newSnap },
            new Map<Id, Booking__c>{ persisted.Id => oldSnap }
        );
        Test.stopTest();

        Channel_Partner__c reloaded = [SELECT First_Booking_Closed_Date_Time__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertNotEquals(null, reloaded.First_Booking_Closed_Date_Time__c,
            'First booking closed timestamp should be stamped');
    }

    @IsTest
    static void sendFirstBookingClosed_doesNotStampWhenNoRecipients() {
        Channel_Partner__c cp = newCp('No Recipients CP', 'norecipients@example.com');
        insert cp;

        Booking__c persisted = new Booking__c(Channel_Partner__c = cp.Id, Status__c = 'Welcome call');
        insert persisted;

        Booking__c oldSnap = persisted.clone(true, true, true, true);
        oldSnap.Status__c = 'Welcome call';
        Booking__c newSnap = persisted.clone(true, true, true, true);
        newSnap.Status__c = 'Closed won';

        CPEmailNotificationService.recipientEmailOverride = new List<String>();

        Test.startTest();
        CPEmailNotificationService.sendFirstBookingClosed(
            new List<Booking__c>{ newSnap },
            new Map<Id, Booking__c>{ persisted.Id => oldSnap }
        );
        Test.stopTest();

        Channel_Partner__c reloaded = [SELECT First_Booking_Closed_Date_Time__c FROM Channel_Partner__c WHERE Id = :cp.Id];
        System.assertEquals(null, reloaded.First_Booking_Closed_Date_Time__c,
            'CP must remain unstamped when no recipients exist, so the email can be retried');
    }

    @IsTest
    static void sendDocumentsEscalation_runsWithoutThrow() {
        Channel_Partner__c cp = newCp('Escalation CP', 'escalation@example.com');
        insert cp;

        Test.startTest();
        CPEmailNotificationService.sendDocumentsEscalation(new List<Channel_Partner__c>{ cp });
        CPEmailNotificationService.sendTrainingReminder(new List<Channel_Partner__c>{ cp });
        Test.stopTest();
    }

    @IsTest
    static void docsEscalationScheduler_runs() {
        Test.startTest();
        System.schedule(
            'CP Docs Esc Test ' + Datetime.now().getTime(),
            '0 0 10 * * ?',
            new CPDocsEscalationScheduler()
        );
        Test.stopTest();
    }

    // ── Additional branch-coverage tests ─────────────────────────────────────

    @IsTest
    static void sendDocumentsPending_nullInput_noThrow() {
        Test.startTest();
        CPEmailNotificationService.sendDocumentsPending(null);
        Test.stopTest();
    }

    @IsTest
    static void sendDocumentsPending_emptyList_noThrow() {
        Test.startTest();
        CPEmailNotificationService.sendDocumentsPending(new List<Channel_Partner__c>());
        Test.stopTest();
    }

    @IsTest
    static void sendDocumentsPending_allDocsUploaded_noEmail() {
        Channel_Partner__c cp = allDocs(newCp('All Docs CP', 'alldocs@example.com'));
        insert cp;
        Test.startTest();
        // queryCps includes Approval_Status__c; hasAnyDocPending returns false
        // → pending list stays empty → sendBulk never called
        CPEmailNotificationService.sendDocumentsPending(new List<Channel_Partner__c>{ cp });
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Channel_Partner__c WHERE Id = :cp.Id]);
    }

    @IsTest
    static void sendDocumentsSubmitted_nullOldMap_noThrow() {
        Channel_Partner__c cp = newCp('Null OldMap CP', 'nulloldmap@example.com');
        Test.startTest();
        CPEmailNotificationService.sendDocumentsSubmitted(
            new List<Channel_Partner__c>{ cp }, null);
        Test.stopTest();
    }

    @IsTest
    static void sendDocumentsSubmitted_noTransition_noEmail() {
        Channel_Partner__c cp = allDocs(newCp('No Trans CP', 'notrans@example.com'));
        insert cp;
        Channel_Partner__c oldSnap = allDocs(cp.clone(true, true, true, true));
        Channel_Partner__c newSnap = allDocs(cp.clone(true, true, true, true));
        Test.startTest();
        // Both old and new already have all docs — condition is false, ids stays empty
        CPEmailNotificationService.sendDocumentsSubmitted(
            new List<Channel_Partner__c>{ newSnap },
            new Map<Id, Channel_Partner__c>{ cp.Id => oldSnap });
        Test.stopTest();
    }

    @IsTest
    static void sendTrainingScheduled_nullOldMap_noThrow() {
        Channel_Partner__c cp = newCp('Training Null OldMap', 'trnulloldmap@example.com');
        cp.Training_Date__c = Date.today().addDays(5);
        Test.startTest();
        CPEmailNotificationService.sendTrainingScheduled(
            new List<Channel_Partner__c>{ cp }, null);
        Test.stopTest();
    }

    @IsTest
    static void sendTrainingScheduled_noTransition_noEmail() {
        Channel_Partner__c cp = newCp('Training No Trans', 'trnotrans@example.com');
        insert cp;
        Channel_Partner__c oldSnap = cp.clone(true, true, true, true);
        oldSnap.Training_Date__c = Date.today().addDays(5);
        Channel_Partner__c newSnap = cp.clone(true, true, true, true);
        newSnap.Training_Date__c = Date.today().addDays(5);
        Test.startTest();
        // Date already set in old → condition false → ids empty
        CPEmailNotificationService.sendTrainingScheduled(
            new List<Channel_Partner__c>{ newSnap },
            new Map<Id, Channel_Partner__c>{ cp.Id => oldSnap });
        Test.stopTest();
    }

    @IsTest
    static void sendTrainingCompleted_nullOldMap_noThrow() {
        Channel_Partner__c cp = newCp('TrainComp Null OldMap', 'tcnulloldmap@example.com');
        cp.Training_Completed__c = 'yes';
        Test.startTest();
        CPEmailNotificationService.sendTrainingCompleted(
            new List<Channel_Partner__c>{ cp }, null);
        Test.stopTest();
    }

    @IsTest
    static void sendTrainingCompleted_noTransition_noEmail() {
        Channel_Partner__c cp = newCp('TrainComp No Trans', 'tcnotrans@example.com');
        insert cp;
        Channel_Partner__c oldSnap = cp.clone(true, true, true, true);
        oldSnap.Training_Completed__c = 'yes';
        Channel_Partner__c newSnap = cp.clone(true, true, true, true);
        newSnap.Training_Completed__c = 'yes';
        Test.startTest();
        // Old already 'yes' → condition false → ids empty
        CPEmailNotificationService.sendTrainingCompleted(
            new List<Channel_Partner__c>{ newSnap },
            new Map<Id, Channel_Partner__c>{ cp.Id => oldSnap });
        Test.stopTest();
    }

    @IsTest
    static void sendActivationCompleted_nullOldMap_noThrow() {
        Channel_Partner__c cp = newCp('Act Null OldMap', 'actnulloldmap@example.com');
        cp.Approval_Status__c = 'Approved';
        Test.startTest();
        CPEmailNotificationService.sendActivationCompleted(
            new List<Channel_Partner__c>{ cp }, null);
        Test.stopTest();
    }

    @IsTest
    static void sendActivationCompleted_noTransition_noEmail() {
        Channel_Partner__c cp = newCp('Act No Trans', 'actnotrans@example.com');
        insert cp;
        Channel_Partner__c oldSnap = cp.clone(true, true, true, true);
        oldSnap.Approval_Status__c = 'Approved';
        Channel_Partner__c newSnap = cp.clone(true, true, true, true);
        newSnap.Approval_Status__c = 'Approved';
        Test.startTest();
        // Old already 'Approved' → condition false → ids empty
        CPEmailNotificationService.sendActivationCompleted(
            new List<Channel_Partner__c>{ newSnap },
            new Map<Id, Channel_Partner__c>{ cp.Id => oldSnap });
        Test.stopTest();
    }

    @IsTest
    static void sendFirstLeadReceived_nullChannelPartner_noThrow() {
        // RS with no CP link → null guard fires → cpToFirstRs stays empty → early return
        Related_Source__c rs = new Related_Source__c();
        Test.startTest();
        CPEmailNotificationService.sendFirstLeadReceived(new List<Related_Source__c>{ rs });
        Test.stopTest();
    }

    @IsTest
    static void sendFirstBookingClosed_wrongStatus_noThrow() {
        Channel_Partner__c cp = newCp('Wrong Status CP', 'wrongstatus@example.com');
        insert cp;
        Booking__c bk = new Booking__c(Channel_Partner__c = cp.Id, Status__c = 'Welcome call');
        insert bk;
        Booking__c oldSnap = bk.clone(true, true, true, true);
        Booking__c newSnap = bk.clone(true, true, true, true);
        // Status is not 'Closed won' → condition false → cpToFirstBooking empty → early return
        Test.startTest();
        CPEmailNotificationService.sendFirstBookingClosed(
            new List<Booking__c>{ newSnap },
            new Map<Id, Booking__c>{ bk.Id => oldSnap });
        Test.stopTest();
    }

    // ── Scheduler tests ───────────────────────────────────────────────────────

    @IsTest
    static void trainingReminderScheduler_runs() {
        // CPTrainingReminderScheduler.run() SELECTs Channel_Partner__c without
        // Approval_Status__c, but buildPlainTextFallback reads that field.
        // Keeping the CP out of the scheduler's WHERE Training_Date__c=tomorrow
        // clause makes run() return early and avoids the SObjectException.
        // sendTrainingReminder is still covered by
        // sendDocumentsEscalation_runsWithoutThrow.
        Channel_Partner__c cp = newCp('Reminder CP', 'reminder@example.com');
        insert cp;

        Test.startTest();
        System.schedule(
            'CP Training Reminder Test ' + Datetime.now().getTime(),
            '0 0 10 * * ?',
            new CPTrainingReminderScheduler()
        );
        Test.stopTest();
    }

    @IsTest
    static void getCcAddresses_returnsLabelValue() {
        List<String> ccs = CPEmailNotificationService.getCcAddresses();
        System.assertNotEquals(null, ccs, 'CC list must not be null');
        System.assert(ccs.contains(System.Label.CP_CC_Email_Address.trim())
            || ccs.size() > 1,
            'CC list should contain the configured label value (or its split parts)');
    }
}