/**
 * Centralised email notifications for the Channel Partner lifecycle...
 *
 * Profiles used for recipient lookup (User.Profile.Name):
 *   - "Head Sales and Partnership"
 *   - "CP Head"
 *   - "CRM TL"
 *   - "Finance"
 *
 * Trigger wiring:
 *   - ChannelPartnerTriggerHandler.onAfterInsert  -> sendDocumentsPending
 *   - ChannelPartnerTriggerHandler.onAfterUpdate  -> sendDocumentsSubmitted /
 *                                                    sendTrainingScheduled /
 *                                                    sendTrainingCompleted /
 *                                                    sendActivationCompleted
 *   - RelatedSourceTrigger after insert            -> sendFirstLeadReceived
 *   - SiteVisitTrigger after insert                -> sendFirstSiteVisitScheduled
 *   - BookingTriggerHandler.afterUpdate            -> sendFirstBookingClosed
 *   - CPDocsEscalationScheduler                    -> sendDocumentsEscalation
 *   - CPTrainingReminderScheduler                  -> sendTrainingReminder
 *
 * @description   Central email service for the 10 CP lifecycle notifications
 * @author        support2@fingertipplus.com
 * @created       2026-05-25
 * @lastModified  2026-05-25 (entry log per method — diagnose silent triggers)
 */
public without sharing class CPEmailNotificationService {

    private static final String OWA_ADDRESS  = System.Label.CP_OWA_Email_Address;
    private static final String CC_ADDRESS   = System.Label.CP_CC_Email_Address;

    private static final String P_HEAD_SP    = System.Label.CP_Profile_Head_Sales_Partnership;
    private static final String P_CP_HEAD    = System.Label.CP_Profile_CP_Head;
    private static final String P_CRM_TL     = System.Label.CP_Profile_CRM_TL;
    private static final String P_FINANCE    = System.Label.CP_Profile_Finance;

    private static final Set<String> RECIP_DOCS_PENDING       = new Set<String>{ P_HEAD_SP, P_CP_HEAD, P_CRM_TL };
    private static final Set<String> RECIP_DOCS_ESCALATION    = new Set<String>{ P_HEAD_SP };
    private static final Set<String> RECIP_DOCS_SUBMITTED     = new Set<String>{ P_HEAD_SP };
    private static final Set<String> RECIP_TRAINING_SCHEDULED = new Set<String>{ P_HEAD_SP, P_CP_HEAD };
    private static final Set<String> RECIP_TRAINING_REMINDER  = new Set<String>{ P_HEAD_SP, P_CP_HEAD };
    private static final Set<String> RECIP_TRAINING_COMPLETED = new Set<String>{ P_HEAD_SP, P_CP_HEAD };
    private static final Set<String> RECIP_ACTIVATION         = new Set<String>{ P_HEAD_SP };
    private static final Set<String> RECIP_FIRST_LEAD         = new Set<String>{ P_HEAD_SP };
    private static final Set<String> RECIP_FIRST_SV           = new Set<String>{ P_HEAD_SP };
    private static final Set<String> RECIP_FIRST_BOOKING      = new Set<String>{ P_HEAD_SP, P_FINANCE };

    // Notification name constants used as keys throughout
    private static final String N_DOCS_PENDING    = 'Documents Pending';
    private static final String N_DOCS_ESCAL      = 'Documents Escalation';
    private static final String N_DOCS_SUBMITTED  = 'Documents Submitted';
    private static final String N_TRAINING_SCHED  = 'Training Scheduled';
    private static final String N_TRAINING_REMIND = 'Training Reminder';
    private static final String N_TRAINING_DONE   = 'Product Training Completed';
    private static final String N_ACTIVATION      = 'Activation Completed';
    private static final String N_FIRST_LEAD      = 'First Lead Received';
    private static final String N_FIRST_SV        = 'First Site Visit Scheduled';
    private static final String N_FIRST_BOOKING   = 'First Booking Closed';

    private static Id cachedOweaId;
    private static Boolean oweaResolved = false;

    @TestVisible
    private static List<String> recipientEmailOverride;

    /* =====================================================================
     *  1) Documents Pending — fires on CP insert if any of the 9 doc
     *     checkboxes are unchecked.
     * ===================================================================== */
    public static void sendDocumentsPending(List<Channel_Partner__c> newList) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendDocumentsPending entered — CPs=' + (newList == null ? 0 : newList.size()));
        if (newList == null || newList.isEmpty()) return;

        Set<Id> ids = new Set<Id>();
        for (Channel_Partner__c cp : newList) ids.add(cp.Id);

        List<Channel_Partner__c> cps = queryCps(ids);
        List<Channel_Partner__c> pending = new List<Channel_Partner__c>();
        for (Channel_Partner__c cp : cps) {
            if (hasAnyDocPending(cp)) pending.add(cp);
        }
        if (pending.isEmpty()) return;

        sendBulk(pending, RECIP_DOCS_PENDING,
            N_DOCS_PENDING,
            'Channel Partner - Documents Pending');
    }

    /* =====================================================================
     *  2) Documents Escalation — invoked by CPDocsEscalationScheduler for
     *     CPs older than 2 days that still have pending documents.
     * ===================================================================== */
    public static void sendDocumentsEscalation(List<Channel_Partner__c> cps) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendDocumentsEscalation entered — CPs=' + (cps == null ? 0 : cps.size()));
        if (cps == null || cps.isEmpty()) return;
        sendBulk(cps, RECIP_DOCS_ESCALATION,
            N_DOCS_ESCAL,
            'Channel Partner - Documents Pending > 2 days');
    }

    /* =====================================================================
     *  3) Documents Submitted — fires when all 9 doc checkboxes flip true.
     * ===================================================================== */
    public static void sendDocumentsSubmitted(List<Channel_Partner__c> newList,
                                              Map<Id, Channel_Partner__c> oldMap) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendDocumentsSubmitted entered — CPs=' + (newList == null ? 0 : newList.size()));
        if (newList == null || newList.isEmpty()) return;

        Set<Id> ids = new Set<Id>();
        for (Channel_Partner__c cp : newList) {
            Channel_Partner__c oldCp = oldMap != null ? oldMap.get(cp.Id) : null;
            if (oldCp == null) continue;
            if (allDocsUploaded(cp) && !allDocsUploaded(oldCp)) ids.add(cp.Id);
        }
        if (ids.isEmpty()) return;

        sendBulk(queryCps(ids), RECIP_DOCS_SUBMITTED,
            N_DOCS_SUBMITTED,
            'Channel Partner - All Documents Submitted');
    }

    /* =====================================================================
     *  4) Training Scheduled — Training_Date__c moved from null to a value.
     * ===================================================================== */
    public static void sendTrainingScheduled(List<Channel_Partner__c> newList,
                                             Map<Id, Channel_Partner__c> oldMap) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendTrainingScheduled entered — CPs=' + (newList == null ? 0 : newList.size()));
        if (newList == null || newList.isEmpty()) return;

        Set<Id> ids = new Set<Id>();
        for (Channel_Partner__c cp : newList) {
            Channel_Partner__c oldCp = oldMap != null ? oldMap.get(cp.Id) : null;
            if (oldCp == null) continue;
            if (cp.Training_Date__c != null && oldCp.Training_Date__c == null) ids.add(cp.Id);
        }
        if (ids.isEmpty()) return;

        sendBulk(queryCps(ids), RECIP_TRAINING_SCHEDULED,
            N_TRAINING_SCHED,
            'Channel Partner - Training Scheduled');
    }

    /* =====================================================================
     *  5) Training Reminder — invoked by CPTrainingReminderScheduler one day
     *     before Training_Date__c.
     * ===================================================================== */
    public static void sendTrainingReminder(List<Channel_Partner__c> cps) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendTrainingReminder entered — CPs=' + (cps == null ? 0 : cps.size()));
        if (cps == null || cps.isEmpty()) return;
        sendBulk(cps, RECIP_TRAINING_REMINDER,
            N_TRAINING_REMIND,
            'Channel Partner - Training Tomorrow');
    }

    /* =====================================================================
     *  6) Product Training Completed — Training_Completed__c changes to 'yes'.
     * ===================================================================== */
    public static void sendTrainingCompleted(List<Channel_Partner__c> newList,
                                             Map<Id, Channel_Partner__c> oldMap) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendTrainingCompleted entered — CPs=' + (newList == null ? 0 : newList.size()));
        if (newList == null || newList.isEmpty()) return;

        Set<Id> ids = new Set<Id>();
        for (Channel_Partner__c cp : newList) {
            Channel_Partner__c oldCp = oldMap != null ? oldMap.get(cp.Id) : null;
            if (oldCp == null) continue;
            if (cp.Training_Completed__c == 'yes' && oldCp.Training_Completed__c != 'yes') ids.add(cp.Id);
        }
        if (ids.isEmpty()) return;

        sendBulk(queryCps(ids), RECIP_TRAINING_COMPLETED,
            N_TRAINING_DONE,
            'Channel Partner - Product Training Completed');
    }

    /* =====================================================================
     *  7) Activation Completed — Approval_Status__c becomes 'Approved'.
     * ===================================================================== */
    public static void sendActivationCompleted(List<Channel_Partner__c> newList,
                                               Map<Id, Channel_Partner__c> oldMap) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendActivationCompleted entered — CPs=' + (newList == null ? 0 : newList.size()));
        if (newList == null || newList.isEmpty()) return;

        Set<Id> ids = new Set<Id>();
        for (Channel_Partner__c cp : newList) {
            Channel_Partner__c oldCp = oldMap != null ? oldMap.get(cp.Id) : null;
            if (oldCp == null) continue;
            if (cp.Approval_Status__c == 'Approved' && oldCp.Approval_Status__c != 'Approved') ids.add(cp.Id);
        }
        if (ids.isEmpty()) return;

        sendBulk(queryCps(ids), RECIP_ACTIVATION,
            N_ACTIVATION,
            'Channel Partner - Activation Completed');
    }

    /* =====================================================================
     *  8) First Lead Received — first Related_Source__c on a CP.
     *
     *  Must be called BEFORE ChannelPartnerCountHelper.updateLeadCapturedDates
     *  so the "First_Lead_Captured_Date_Time__c IS NULL" probe still holds.
     * ===================================================================== */
    public static void sendFirstLeadReceived(List<Related_Source__c> newRsList) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendFirstLeadReceived entered — RS=' + (newRsList == null ? 0 : newRsList.size()));
        if (newRsList == null || newRsList.isEmpty()) return;

        Map<Id, Related_Source__c> cpToFirstRs = new Map<Id, Related_Source__c>();
        for (Related_Source__c rs : newRsList) {
            if (rs.Channel_Partner1__c == null) continue;
            if (!cpToFirstRs.containsKey(rs.Channel_Partner1__c)) {
                cpToFirstRs.put(rs.Channel_Partner1__c, rs);
            }
        }
        if (cpToFirstRs.isEmpty()) return;

        Map<Id, Channel_Partner__c> cps = new Map<Id, Channel_Partner__c>([
            SELECT Id, User_Id__c, Name, Email__c, OwnerId, Mobile_APP_login_Time__c,
                   Approval_Status__c, Training_Date__c, Training_Completed__c,
                   First_Lead_Captured_Date_Time__c
            FROM Channel_Partner__c
            WHERE Id IN :cpToFirstRs.keySet()
              AND First_Lead_Captured_Date_Time__c = NULL
        ]);
        if (cps.isEmpty()) return;

        Set<Id> rsIds = new Set<Id>();
        for (Id cpId : cps.keySet()) rsIds.add(cpToFirstRs.get(cpId).Id);

        Map<Id, Related_Source__c> rsFull = new Map<Id, Related_Source__c>([
            SELECT Id, Name, Name__c, SLead__c, Channel_Partner1__c
            FROM Related_Source__c
            WHERE Id IN :rsIds
        ]);

        Map<Id, Map<String, Object>> extras = new Map<Id, Map<String, Object>>();
        for (Id cpId : cps.keySet()) {
            Related_Source__c rs = rsFull.get(cpToFirstRs.get(cpId).Id);
            if (rs == null) continue;
            extras.put(cpId, new Map<String, Object>{
                'Lead Name__c'             => rs.Name__c,
                'Lead SLead__c'            => rs.SLead__c,
                'Lead Channel_Partner1__c' => rs.Channel_Partner1__c,
                'Related Source Name'      => rs.Name
            });
        }

        sendBulk(cps.values(), RECIP_FIRST_LEAD,
            N_FIRST_LEAD,
            'Channel Partner - First Lead Received',
            extras);
    }

    /* =====================================================================
     *  9) First Site Visit Scheduled.
     *
     *  Must be called BEFORE SiteVisitTriggerHandler.updateChannelPartnerSiteVisitDates.
     * ===================================================================== */
    public static void sendFirstSiteVisitScheduled(List<Site_Visit__c> newSvList) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendFirstSiteVisitScheduled entered — SV=' + (newSvList == null ? 0 : newSvList.size()));
        if (newSvList == null || newSvList.isEmpty()) return;

        Map<Id, Site_Visit__c> cpToFirstSv = new Map<Id, Site_Visit__c>();
        for (Site_Visit__c sv : newSvList) {
            if (String.isBlank(sv.Channel_Partner1__c)) continue;
            Id cpId;
            try { cpId = (Id) sv.Channel_Partner1__c; } catch (Exception e) { continue; }
            if (!cpToFirstSv.containsKey(cpId)) cpToFirstSv.put(cpId, sv);
        }
        if (cpToFirstSv.isEmpty()) return;

        Map<Id, Channel_Partner__c> cps = new Map<Id, Channel_Partner__c>([
            SELECT Id, User_Id__c, Name, Email__c, OwnerId, Mobile_APP_login_Time__c,
                   Approval_Status__c, Training_Date__c, Training_Completed__c,
                   First_Site_Visit_Date_Time__c
            FROM Channel_Partner__c
            WHERE Id IN :cpToFirstSv.keySet()
              AND First_Site_Visit_Date_Time__c = NULL
        ]);
        if (cps.isEmpty()) return;

        Set<Id> svIds = new Set<Id>();
        for (Id cpId : cps.keySet()) svIds.add(cpToFirstSv.get(cpId).Id);

        Map<Id, Site_Visit__c> svFull = new Map<Id, Site_Visit__c>([
            SELECT Id, Name, SLead__c, Status__c, Channel_Partner1__c, Related_Source__c
            FROM Site_Visit__c
            WHERE Id IN :svIds
        ]);

        // Fetch Related_Source lead context for the site visit
        Set<Id> rsIdsForSV = new Set<Id>();
        for (Site_Visit__c sv : svFull.values()) {
            if (sv.Related_Source__c != null) rsIdsForSV.add(sv.Related_Source__c);
        }
        Map<Id, Related_Source__c> rsByIdForSV = new Map<Id, Related_Source__c>();
        if (!rsIdsForSV.isEmpty()) {
            for (Related_Source__c rs : [
                SELECT Id, Name__c, SLead__c, Channel_Partner1__c
                FROM Related_Source__c
                WHERE Id IN :rsIdsForSV
            ]) {
                rsByIdForSV.put(rs.Id, rs);
            }
        }

        Map<Id, Map<String, Object>> extras = new Map<Id, Map<String, Object>>();
        for (Id cpId : cps.keySet()) {
            Site_Visit__c sv = svFull.get(cpToFirstSv.get(cpId).Id);
            if (sv == null) continue;
            Map<String, Object> extMap = new Map<String, Object>{
                'SV Name'      => sv.Name,
                'SV SLead__c'  => sv.SLead__c,
                'SV Status__c' => sv.Status__c
            };
            if (sv.Related_Source__c != null && rsByIdForSV.containsKey(sv.Related_Source__c)) {
                Related_Source__c rs = rsByIdForSV.get(sv.Related_Source__c);
                extMap.put('Lead Name__c',             rs.Name__c);
                extMap.put('Lead SLead__c',            rs.SLead__c);
                extMap.put('Lead Channel_Partner1__c', rs.Channel_Partner1__c);
            }
            extras.put(cpId, extMap);
        }

        sendBulk(cps.values(), RECIP_FIRST_SV,
            N_FIRST_SV,
            'Channel Partner - First Site Visit Scheduled',
            extras);
    }

    /* =====================================================================
     *  10) First Booking Closed — Booking__c.Status__c becomes 'Closed won'
     *      and the CP has never had a closed booking before.
     *      Stamps First_Booking_Closed_Date_Time__c on the CP.
     * ===================================================================== */
    public static void sendFirstBookingClosed(List<Booking__c> newBookings,
                                              Map<Id, Booking__c> oldMap) {
        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService.sendFirstBookingClosed entered — Bookings=' + (newBookings == null ? 0 : newBookings.size()));
        if (newBookings == null || newBookings.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'sendFirstBookingClosed: newBookings null or empty — exiting.');
            return;
        }

        Map<Id, Booking__c> cpToFirstBooking = new Map<Id, Booking__c>();
        for (Booking__c bk : newBookings) {
            if (bk.Channel_Partner__c == null) continue;
            if (bk.Status__c != 'Closed won') continue;
            Booking__c oldBk = oldMap != null ? oldMap.get(bk.Id) : null;
            if (oldBk != null && oldBk.Status__c == 'Closed won') continue;
            if (!cpToFirstBooking.containsKey(bk.Channel_Partner__c)) {
                cpToFirstBooking.put(bk.Channel_Partner__c, bk);
            }
        }
        if (cpToFirstBooking.isEmpty()) {
            List<String> bkSummaries = new List<String>();
            for (Booking__c bk : newBookings) {
                Booking__c oldBk = oldMap != null ? oldMap.get(bk.Id) : null;
                bkSummaries.add(bk.Id + '[cp=' + bk.Channel_Partner__c
                    + ',old=' + (oldBk == null ? 'null' : oldBk.Status__c)
                    + ',new=' + bk.Status__c + ']');
            }
            System.debug(LoggingLevel.INFO, 'sendFirstBookingClosed: no Booking transitioned to Closed won in this batch — exiting. Bookings=' + bkSummaries);
            return;
        }

        Map<Id, Channel_Partner__c> cps = new Map<Id, Channel_Partner__c>([
            SELECT Id, User_Id__c, Name, Email__c, OwnerId, Mobile_APP_login_Time__c,
                   Approval_Status__c, Training_Date__c, Training_Completed__c,
                   First_Booking_Closed_Date_Time__c
            FROM Channel_Partner__c
            WHERE Id IN :cpToFirstBooking.keySet()
              AND First_Booking_Closed_Date_Time__c = NULL
        ]);
        if (cps.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'sendFirstBookingClosed: all candidate CPs already have First_Booking_Closed_Date_Time__c stamped — nothing to send. Filtered CP Ids=' + cpToFirstBooking.keySet());
            return;
        }

        Set<Id> bkIds = new Set<Id>();
        for (Id cpId : cps.keySet()) bkIds.add(cpToFirstBooking.get(cpId).Id);

        Map<Id, Booking__c> bkFull = new Map<Id, Booking__c>([
            SELECT Id, Name, Status__c, Mode_Of_Payment__c, Channel_Partner__c
            FROM Booking__c
            WHERE Id IN :bkIds
        ]);

        Map<Id, Map<String, Object>> extras = new Map<Id, Map<String, Object>>();
        List<Channel_Partner__c> stamps = new List<Channel_Partner__c>();
        Datetime now = Datetime.now();
        for (Id cpId : cps.keySet()) {
            Booking__c bk = bkFull.get(cpToFirstBooking.get(cpId).Id);
            if (bk == null) continue;
            extras.put(cpId, new Map<String, Object>{
                'Booking Name'               => bk.Name,
                'Booking Status__c'          => bk.Status__c,
                'Booking Mode_Of_Payment__c' => bk.Mode_Of_Payment__c,
                'Booking Channel_Partner__c' => bk.Channel_Partner__c
            });
            stamps.add(new Channel_Partner__c(Id = cpId, First_Booking_Closed_Date_Time__c = now));
        }

        Boolean emailSent = sendBulkWithResult(cps.values(), RECIP_FIRST_BOOKING,
            N_FIRST_BOOKING,
            'Channel Partner - First Booking Closed',
            extras);

        if (!emailSent) {
            System.debug(LoggingLevel.WARN, 'sendFirstBookingClosed: skipping stamp because email was not sent (no recipients / send failure). CPs left unstamped=' + cps.keySet());
            return;
        }

        if (!stamps.isEmpty()) {
            try { update stamps; } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'CP First Booking stamp failed: ' + e.getMessage());
            }
        }
    }

    /* =====================================================================
     *  Shared helpers
     * ===================================================================== */

    private static List<Channel_Partner__c> queryCps(Set<Id> ids) {
        return [
            SELECT Id, User_Id__c, Name, Email__c, OwnerId,
                   Approval_Status__c, Training_Date__c, Training_Completed__c,
                   Mobile_APP_login_Time__c,
                   Aadhar_Document_Uploaded__c, Authorization_Letter_Document_Uploaded__c,
                   Address_Proof_Document_Uploaded__c, GST_Document_Uploaded__c,
                   RERA_Document_Uploaded__c, Cancel_Cheque_Document_Uploaded__c,
                   Board_Resolution_Document_Uploaded__c, Company_Registration_Document_Uploaded__c,
                   PAN_Document_Uploaded__c
            FROM Channel_Partner__c
            WHERE Id IN :ids
        ];
    }

    @TestVisible
    private static Boolean allDocsUploaded(Channel_Partner__c cp) {
        return cp.Aadhar_Document_Uploaded__c == true
            && cp.Authorization_Letter_Document_Uploaded__c == true
            && cp.Address_Proof_Document_Uploaded__c == true
            && cp.GST_Document_Uploaded__c == true
            && cp.RERA_Document_Uploaded__c == true
            && cp.Cancel_Cheque_Document_Uploaded__c == true
            && cp.Board_Resolution_Document_Uploaded__c == true
            && cp.Company_Registration_Document_Uploaded__c == true
            && cp.PAN_Document_Uploaded__c == true;
    }

    @TestVisible
    private static Boolean hasAnyDocPending(Channel_Partner__c cp) {
        return cp.Aadhar_Document_Uploaded__c != true
            || cp.Authorization_Letter_Document_Uploaded__c != true
            || cp.Address_Proof_Document_Uploaded__c != true
            || cp.GST_Document_Uploaded__c != true
            || cp.RERA_Document_Uploaded__c != true
            || cp.Cancel_Cheque_Document_Uploaded__c != true
            || cp.Board_Resolution_Document_Uploaded__c != true
            || cp.Company_Registration_Document_Uploaded__c != true
            || cp.PAN_Document_Uploaded__c != true;
    }

    @TestVisible
    private static List<String> getCcAddresses() {
        List<String> ccs = new List<String>();
        if (String.isBlank(CC_ADDRESS)) return ccs;
        for (String raw : CC_ADDRESS.split(',')) {
            String trimmed = raw == null ? '' : raw.trim();
            if (String.isNotBlank(trimmed)) ccs.add(trimmed);
        }
        return ccs;
    }

    private static List<String> getRecipientEmails(Set<String> profileNames) {
        if (recipientEmailOverride != null) return recipientEmailOverride;
        List<String> emails = new List<String>();
        if (profileNames == null || profileNames.isEmpty()) return emails;
        for (User u : [
            SELECT Email FROM User
            WHERE Profile.Name IN :profileNames
              AND IsActive = true
              AND Email != null
        ]) {
            emails.add(u.Email);
        }
        return emails;
    }

    private static Id getOweaId() {
        if (oweaResolved) return cachedOweaId;
        oweaResolved = true;
        List<OrgWideEmailAddress> owea = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = :OWA_ADDRESS LIMIT 1
        ];
        cachedOweaId = owea.isEmpty() ? null : owea[0].Id;
        return cachedOweaId;
    }

    private static void sendBulk(List<Channel_Partner__c> cps,
                                 Set<String> profileNames,
                                 String notificationName,
                                 String subjectPrefix) {
        sendBulk(cps, profileNames, notificationName, subjectPrefix, null);
    }

    private static void sendBulk(List<Channel_Partner__c> cps,
                                 Set<String> profileNames,
                                 String notificationName,
                                 String subjectPrefix,
                                 Map<Id, Map<String, Object>> extrasByCp) {
        sendBulkWithResult(cps, profileNames, notificationName, subjectPrefix, extrasByCp);
    }

    private static Boolean sendBulkWithResult(List<Channel_Partner__c> cps,
                                              Set<String> profileNames,
                                              String notificationName,
                                              String subjectPrefix,
                                              Map<Id, Map<String, Object>> extrasByCp) {
        if (cps == null || cps.isEmpty()) return false;

        List<String> toAddresses = getRecipientEmails(profileNames);
        if (toAddresses.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'CPEmailNotificationService ' + notificationName
                + ': no recipients found for profiles ' + profileNames);
            return false;
        }

        System.debug(LoggingLevel.INFO, 'CPEmailNotificationService ' + notificationName
            + ': preparing ' + cps.size() + ' email(s) to ' + toAddresses.size()
            + ' recipient(s): ' + toAddresses);

        Id oweaId = getOweaId();
        if (oweaId == null) {
            System.debug(LoggingLevel.WARN, 'CPEmailNotificationService ' + notificationName
                + ': OrgWideEmailAddress not found for ' + OWA_ADDRESS
                + ' — sending from running user instead.');
        }

        List<String> ccAddresses = getCcAddresses();

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Channel_Partner__c cp : cps) {
            Map<String, Object> extras = extrasByCp != null ? extrasByCp.get(cp.Id) : null;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            if (!ccAddresses.isEmpty()) mail.setCcAddresses(ccAddresses);
            mail.setSubject(subjectPrefix + ' - ' + (cp.Name != null ? cp.Name : ''));
            mail.setHtmlBody(buildHtmlBody(notificationName, cp, extras));
            mail.setPlainTextBody(buildPlainTextFallback(notificationName, cp, extras));
            mail.setSaveAsActivity(false);
            if (oweaId != null) mail.setOrgWideEmailAddressId(oweaId);
            emails.add(mail);
        }

        if (emails.isEmpty()) return false;
        try {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
            Integer ok = 0;
            Integer fail = 0;
            for (Messaging.SendEmailResult res : results) {
                if (res.isSuccess()) {
                    ok++;
                } else {
                    fail++;
                    for (Messaging.SendEmailError err : res.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'CPEmailNotificationService ' + notificationName
                            + ' delivery error: ' + err.getStatusCode() + ' — ' + err.getMessage()
                            + ' (target: ' + err.getTargetObjectId() + ', fields: ' + err.getFields() + ')');
                    }
                }
            }
            System.debug(LoggingLevel.INFO, 'CPEmailNotificationService ' + notificationName
                + ': sendEmail finished — success=' + ok + ', failure=' + fail);
            return ok > 0;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'CPEmailNotificationService send threw ('
                + notificationName + '): ' + e.getMessage() + ' — ' + e.getStackTraceString());
            return false;
        }
    }

    /* =====================================================================
     *  HTML email builder — returns a complete, inline-styled HTML document.
     * ===================================================================== */
    private static String buildHtmlBody(String notificationName,
                                        Channel_Partner__c cp,
                                        Map<String, Object> extras) {
        // Per-notification visual config
        String accentColor, icon, heading, intro;

        if (notificationName == N_DOCS_PENDING) {
            accentColor = '#E67E22'; icon = '&#128203;';
            heading = 'Documents Pending';
            intro   = 'A Channel Partner has been registered but one or more required documents have not yet been uploaded. Please follow up to ensure all documents are submitted promptly.';
        } else if (notificationName == N_DOCS_ESCAL) {
            accentColor = '#C0392B'; icon = '&#9888;';
            heading = 'Documents Escalation &mdash; Action Required';
            intro   = 'This Channel Partner was created more than 2 days ago and required documents are still pending. Immediate action is required to avoid further delays in onboarding.';
        } else if (notificationName == N_DOCS_SUBMITTED) {
            accentColor = '#27AE60'; icon = '&#10003;';
            heading = 'All Documents Submitted';
            intro   = 'All required documents have been successfully uploaded for this Channel Partner. The onboarding process can now proceed to the next stage.';
        } else if (notificationName == N_TRAINING_SCHED) {
            accentColor = '#2980B9'; icon = '&#128197;';
            heading = 'Training Scheduled';
            intro   = 'A product training session has been scheduled for this Channel Partner. Please ensure all necessary preparations are in place before the training date.';
        } else if (notificationName == N_TRAINING_REMIND) {
            accentColor = '#E67E22'; icon = '&#9200;';
            heading = 'Training Reminder &mdash; Tomorrow';
            intro   = 'This is a reminder that a product training session is scheduled for tomorrow for the following Channel Partner. Please confirm all arrangements are ready.';
        } else if (notificationName == N_TRAINING_DONE) {
            accentColor = '#27AE60'; icon = '&#127891;';
            heading = 'Product Training Completed';
            intro   = 'The Channel Partner has successfully completed the product training session and is now ready to proceed to the activation stage.';
        } else if (notificationName == N_ACTIVATION) {
            accentColor = '#27AE60'; icon = '&#128640;';
            heading = 'Channel Partner Activated';
            intro   = 'The Channel Partner\'s account has been approved and is now fully activated. They can begin their operations as an official channel partner.';
        } else if (notificationName == N_FIRST_LEAD) {
            accentColor = '#8E44AD'; icon = '&#127919;';
            heading = 'First Lead Received';
            intro   = 'This Channel Partner has successfully submitted their first lead. This marks a significant milestone in their partnership journey.';
        } else if (notificationName == N_FIRST_SV) {
            accentColor = '#2C3E50'; icon = '&#127968;';
            heading = 'First Site Visit Scheduled';
            intro   = 'The Channel Partner has booked their first site visit. This is a key step toward achieving their first booking.';
        } else if (notificationName == N_FIRST_BOOKING) {
            accentColor = '#D4A017'; icon = '&#127942;';
            heading = 'First Booking Closed';
            intro   = 'Congratulations! The Channel Partner has successfully closed their first booking. This is a major milestone in their partnership journey.';
        } else {
            accentColor = '#1a3c5e'; icon = '&#128276;';
            heading = notificationName;
            intro   = 'A notification has been triggered for the following Channel Partner.';
        }

        List<String> p = new List<String>();
        p.add('<!DOCTYPE html><html><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/></head>');
        p.add('<body style="margin:0;padding:0;background-color:#f4f6f8;font-family:Arial,Helvetica,sans-serif;">');

        // ── Header ──────────────────────────────────────────────────────────
        p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#1a3c5e;">');
        p.add('<tr><td style="padding:20px 32px 18px;">');
        p.add('<span style="color:#ffffff;font-size:22px;font-weight:bold;letter-spacing:0.4px;">Zuari Properties</span>');
        p.add('<span style="color:#8ab4d4;font-size:12px;display:block;margin-top:3px;letter-spacing:0.3px;">Channel Partner Management System</span>');
        p.add('</td></tr></table>');

        // ── Accent heading strip ─────────────────────────────────────────────
        p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:' + accentColor + ';">');
        p.add('<tr><td style="padding:14px 32px;">');
        p.add('<span style="color:#ffffff;font-size:17px;font-weight:bold;">' + icon + ' &nbsp;' + heading + '</span>');
        p.add('</td></tr></table>');

        // ── Main card ────────────────────────────────────────────────────────
        p.add('<table role="presentation" width="600" align="center" cellpadding="0" cellspacing="0"');
        p.add(' style="background-color:#ffffff;margin:24px auto;border-radius:6px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">');
        p.add('<tr><td style="padding:28px 32px 20px;">');

        // Intro paragraph
        p.add('<p style="color:#444444;font-size:14px;line-height:1.6;margin:0 0 24px;">' + intro + '</p>');

        // CP Details
        p.add(htmlSectionHeader('Channel Partner Details'));
        p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-bottom:28px;">');
        p.add(htmlRow(true,  'CP ID', safeH(cp.User_Id__c)));
        p.add(htmlRow(false, 'Name',  safeH(cp.Name)));
        p.add(htmlRow(true,  'Email', safeH(cp.Email__c)));

        // Notification-specific conditional fields (ri tracks alternating row shade)
        Integer ri = 3;
        if (notificationName == N_TRAINING_SCHED || notificationName == N_TRAINING_REMIND) {
            String tDate = cp.Training_Date__c != null ? cp.Training_Date__c.format() : '&mdash;';
            p.add(htmlRow(Math.mod(ri++, 2) == 0, 'Training Date', tDate));
        } else if (notificationName == N_TRAINING_DONE) {
            String tDate = cp.Training_Date__c != null ? cp.Training_Date__c.format() : '&mdash;';
            p.add(htmlRow(Math.mod(ri++, 2) == 0, 'Training Date',      tDate));
            p.add(htmlRow(Math.mod(ri++, 2) == 0, 'Training Completed', safeH(cp.Training_Completed__c)));
            String loginTime = cp.Mobile_APP_login_Time__c != null ? cp.Mobile_APP_login_Time__c.format('dd MMM yyyy, HH:mm') : '&mdash;';
            p.add(htmlRow(Math.mod(ri++, 2) == 0, 'Mobile App Login Time', loginTime));
        } else if (notificationName == N_ACTIVATION) {
            p.add(htmlRow(Math.mod(ri++, 2) == 0, 'Approval Status', safeH(cp.Approval_Status__c)));
            String loginTime = cp.Mobile_APP_login_Time__c != null ? cp.Mobile_APP_login_Time__c.format('dd MMM yyyy, HH:mm') : '&mdash;';
            p.add(htmlRow(Math.mod(ri++, 2) == 0, 'Mobile App Login Time', loginTime));
        } else if (notificationName == N_FIRST_LEAD || notificationName == N_FIRST_SV || notificationName == N_FIRST_BOOKING) {
            String loginTime = cp.Mobile_APP_login_Time__c != null ? cp.Mobile_APP_login_Time__c.format('dd MMM yyyy, HH:mm') : '&mdash;';
            p.add(htmlRow(Math.mod(ri++, 2) == 0, 'Mobile App Login Time', loginTime));
        }
        p.add(htmlRow(Math.mod(ri++, 2) == 0, 'Owner ID', safeH(cp.OwnerId)));
        p.add('</table>');

        // Document checklist intentionally hidden from the email body per request.
        /*
        if (notificationName == N_DOCS_PENDING || notificationName == N_DOCS_ESCAL) {
            // Pending / escalation: only list the documents still missing.
            p.add(buildDocChecklist(cp, true));
        } else if (notificationName == N_DOCS_SUBMITTED) {
            // Submitted: full list confirming all documents are uploaded.
            p.add(buildDocChecklist(cp, false));
        }
        */

        // Related-record section (notifications 8, 9, 10)
        if (extras != null && !extras.isEmpty()) {
            p.add(buildExtrasSection(notificationName, extras));
        }

        p.add('</td></tr></table>');

        // ── Footer ───────────────────────────────────────────────────────────
        p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0">');
        p.add('<tr><td style="padding:16px 32px;text-align:center;">');
        p.add('<p style="font-size:11px;color:#aaaaaa;margin:0;">This is an automated notification from Zuari Properties CRM. Please do not reply to this email.</p>');
        p.add('</td></tr></table>');
        p.add('</body></html>');

        return String.join(p, '');
    }

    private static String htmlSectionHeader(String title) {
        return '<h3 style="color:#1a3c5e;font-size:11px;text-transform:uppercase;letter-spacing:1.2px;'
             + 'border-bottom:2px solid #1a3c5e;padding-bottom:8px;margin:0 0 0;">' + title + '</h3>';
    }

    private static String htmlRow(Boolean isEven, String label, String value) {
        String bg = isEven ? 'background-color:#f7f9fb;' : '';
        return '<tr style="' + bg + '">'
             + '<td style="font-size:13px;color:#666666;padding:9px 10px;width:38%;border-bottom:1px solid #eeeeee;"><b>' + label + '</b></td>'
             + '<td style="font-size:13px;color:#222222;padding:9px 10px;border-bottom:1px solid #eeeeee;">' + value + '</td>'
             + '</tr>';
    }

    /**
     * Builds the document checklist section.
     * @param pendingOnly  when true, only the not-yet-uploaded documents are listed
     *                     (used by the Pending / Escalation emails so the recipient
     *                     sees exactly what is outstanding); when false the full
     *                     9-row list is shown (used by the Submitted confirmation).
     */
    private static String buildDocChecklist(Channel_Partner__c cp, Boolean pendingOnly) {
        List<List<String>> docs = new List<List<String>>{
            new List<String>{ 'Aadhar Card',          cp.Aadhar_Document_Uploaded__c == true                  ? 'yes' : 'no' },
            new List<String>{ 'Authorization Letter',  cp.Authorization_Letter_Document_Uploaded__c == true    ? 'yes' : 'no' },
            new List<String>{ 'Address Proof',         cp.Address_Proof_Document_Uploaded__c == true           ? 'yes' : 'no' },
            new List<String>{ 'GST Certificate',       cp.GST_Document_Uploaded__c == true                     ? 'yes' : 'no' },
            new List<String>{ 'RERA Certificate',      cp.RERA_Document_Uploaded__c == true                    ? 'yes' : 'no' },
            new List<String>{ 'Cancelled Cheque',      cp.Cancel_Cheque_Document_Uploaded__c == true           ? 'yes' : 'no' },
            new List<String>{ 'Board Resolution',      cp.Board_Resolution_Document_Uploaded__c == true        ? 'yes' : 'no' },
            new List<String>{ 'Company Registration',  cp.Company_Registration_Document_Uploaded__c == true    ? 'yes' : 'no' },
            new List<String>{ 'PAN Document',          cp.PAN_Document_Uploaded__c == true                     ? 'yes' : 'no' }
        };

        List<String> p = new List<String>();
        p.add(htmlSectionHeader(pendingOnly ? 'Pending Documents' : 'Document Checklist'));
        p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-bottom:28px;">');

        Integer idx = 0;
        for (List<String> doc : docs) {
            Boolean uploaded   = (doc[1] == 'yes');
            // In pending-only mode skip the documents that are already uploaded so
            // the email lists exactly the outstanding documents.
            if (pendingOnly && uploaded) continue;
            String statusIcon  = uploaded ? '&#10003;' : '&#10007;';
            String statusColor = uploaded ? '#27AE60'  : '#C0392B';
            String statusText  = uploaded ? 'Uploaded'  : 'Pending';
            String bg = (Math.mod(idx, 2) == 0) ? 'background-color:#f7f9fb;' : '';
            p.add('<tr style="' + bg + '">');
            p.add('<td style="font-size:13px;color:#444444;padding:9px 10px;width:62%;border-bottom:1px solid #eeeeee;">' + doc[0] + '</td>');
            p.add('<td style="font-size:13px;font-weight:bold;color:' + statusColor + ';padding:9px 10px;border-bottom:1px solid #eeeeee;">' + statusIcon + ' &nbsp;' + statusText + '</td>');
            p.add('</tr>');
            idx++;
        }

        // Safety net: these emails only fire when something is pending, but never
        // render an empty table if every document happens to be uploaded.
        if (pendingOnly && idx == 0) {
            p.add('<tr><td colspan="2" style="font-size:13px;color:#27AE60;padding:9px 10px;border-bottom:1px solid #eeeeee;">&#10003; &nbsp;All documents uploaded.</td></tr>');
        }

        p.add('</table>');
        return String.join(p, '');
    }

    private static String buildExtrasSection(String notificationName, Map<String, Object> extras) {
        List<String> p = new List<String>();

        if (notificationName == N_FIRST_LEAD) {
            p.add(htmlSectionHeader('Lead Details'));
            p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-bottom:28px;">');
            p.add(htmlRow(true,  'Lead Name',       safeH(extras.get('Lead Name__c'))));
            p.add(htmlRow(false, 'Lead ID (SLead)', safeH(extras.get('Lead SLead__c'))));
            p.add(htmlRow(true,  'Channel Partner', safeH(extras.get('Lead Channel_Partner1__c'))));
            p.add('</table>');

        } else if (notificationName == N_FIRST_SV) {
            if (extras.containsKey('Lead Name__c')) {
                p.add(htmlSectionHeader('Lead Details'));
                p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-bottom:24px;">');
                p.add(htmlRow(true,  'Lead Name',       safeH(extras.get('Lead Name__c'))));
                p.add(htmlRow(false, 'Lead ID (SLead)', safeH(extras.get('Lead SLead__c'))));
                p.add(htmlRow(true,  'Channel Partner', safeH(extras.get('Lead Channel_Partner1__c'))));
                p.add('</table>');
            }
            p.add(htmlSectionHeader('Site Visit Details'));
            p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-bottom:28px;">');
            p.add(htmlRow(true,  'Site Visit Name', safeH(extras.get('SV Name'))));
            p.add(htmlRow(false, 'Lead (SLead)',    safeH(extras.get('SV SLead__c'))));
            p.add(htmlRow(true,  'Status',          safeH(extras.get('SV Status__c'))));
            p.add('</table>');

        } else if (notificationName == N_FIRST_BOOKING) {
            p.add(htmlSectionHeader('Booking Details'));
            p.add('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-bottom:28px;">');
            p.add(htmlRow(true,  'Booking Name',    safeH(extras.get('Booking Name'))));
            p.add(htmlRow(false, 'Status',          safeH(extras.get('Booking Status__c'))));
            p.add(htmlRow(true,  'Mode of Payment', safeH(extras.get('Booking Mode_Of_Payment__c'))));
            p.add(htmlRow(false, 'Channel Partner', safeH(extras.get('Booking Channel_Partner__c'))));
            p.add('</table>');
        }

        return String.join(p, '');
    }

    /* =====================================================================
     *  Plain-text fallback (for email clients that don't render HTML)
     * ===================================================================== */
    private static String buildPlainTextFallback(String notificationName,
                                                  Channel_Partner__c cp,
                                                  Map<String, Object> extras) {
        String body = 'ZUARI PROPERTIES - Channel Partner CRM\n';
        body += '=========================================\n';
        body += 'Notification: ' + notificationName + '\n\n';
        body += 'Channel Partner Details:\n';
        body += '  CP ID      : ' + safe(cp.User_Id__c) + '\n';
        body += '  Name       : ' + safe(cp.Name) + '\n';
        body += '  Email      : ' + safe(cp.Email__c) + '\n';
        body += '  OwnerId    : ' + safe(cp.OwnerId) + '\n';
        if (cp.Training_Date__c != null)
            body += '  Training Date         : ' + cp.Training_Date__c + '\n';
        if (cp.Training_Completed__c != null)
            body += '  Training Completed    : ' + cp.Training_Completed__c + '\n';
        if (cp.Approval_Status__c != null)
            body += '  Approval Status       : ' + cp.Approval_Status__c + '\n';
        if (cp.Mobile_APP_login_Time__c != null)
            body += '  Mobile App Login Time : ' + cp.Mobile_APP_login_Time__c + '\n';
        if (extras != null && !extras.isEmpty()) {
            body += '\nRelated Record:\n';
            for (String key : extras.keySet()) {
                body += '  ' + key + ' : ' + safe(extras.get(key)) + '\n';
            }
        }
        body += '\nRegards,\nZuari CRM';
        return body;
    }

    private static String safeH(Object o) {
        if (o == null) return '&mdash;';
        String s = String.valueOf(o);
        return String.isBlank(s) ? '&mdash;' : s;
    }

    private static String safe(Object o) {
        return o == null ? '' : String.valueOf(o);
    }
}