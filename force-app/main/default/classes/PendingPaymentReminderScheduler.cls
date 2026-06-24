global class PendingPaymentReminderScheduler
    implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    // Priority: first match wins per booking
    private static final List<String> PRIORITY = new List<String>{
        'CANCEL_BOOKING',
        'TERMINATION',
        'PRE_TERMINATION',
        '3RD_INTEREST',
        '2ND_INTEREST',
        '1ST_INTEREST',
        '2ND_REMINDER',
        '1ST_REMINDER'
    };

    // Stateful variables to track email counts
    private Integer totalEmailsSent = 0;
    private Integer customerEmailsSent = 0;
    private Integer internalEmailsSent = 0;
    private Integer bookingsProcessed = 0;
    private Integer bookingsCancelled = 0;
    private Map<String, Integer> emailsByType = new Map<String, Integer>{
        '1ST_REMINDER' => 0,
        '2ND_REMINDER' => 0,
        '1ST_INTEREST' => 0,
        '2ND_INTEREST' => 0,
        '3RD_INTEREST' => 0,
        'PRE_TERMINATION' => 0,
        'TERMINATION' => 0,
        'CANCEL_BOOKING' => 0
    };

    // -------------------- START --------------------
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();

        return Database.getQueryLocator([
            SELECT Id, Pending_Amount__c, S_No__c, Booking__c, Received_Amount1__c, Demanded_Date__c,
                   X1st_Reminder_Date__c, X2nd_Reminder_Date__c,
                   X1st_Interest_Reminder_Date__c, X2nd_Interest_Reminder_Date__c,
                   X3rd_Interest_Reminder_Date__c, Pre_Termination_Mail_Date__c,
                   Termination_Mail_Date__c,
                   Booking__r.First_Applicant_Name__c, Booking__r.Email__c,
                   Booking__r.Plot__r.Name, Booking__r.Project1__r.Name,
                   Booking__r.Owner_Full_Name__c, Booking__r.CRM_Head__r.Email,
                   Booking__r.Sales_Head__r.Email, Booking__r.COO__r.Email,
                   Booking__r.CRM_Executive__r.Email, Booking__r.CreatedDate,
                   Booking__r.Stage__c, Booking__r.Disable_Automatic_Payment_Reminders__c,
                   Booking__r.Id
            FROM Payment_Schedule__c
            WHERE Is_Demanded__c = true
              AND Pending_Amount__c > 0
              AND Booking__r.Stage__c NOT IN ('Swapping', 'Cancellation')
              AND Booking__r.Disable_Automatic_Payment_Reminders__c != true
              AND Demanded_Date__c != null
              AND (
                    X1st_Reminder_Date__c = TODAY
                 OR X2nd_Reminder_Date__c = TODAY
                 OR X1st_Interest_Reminder_Date__c = TODAY
                 OR X2nd_Interest_Reminder_Date__c = TODAY
                 OR X3rd_Interest_Reminder_Date__c = TODAY
                 OR Pre_Termination_Mail_Date__c = TODAY
                 OR Termination_Mail_Date__c = TODAY
                 OR Termination_Mail_Date__c = LAST_N_DAYS:30
              )
            ORDER BY Booking__c, S_No__c ASC
        ]);
    }

    // -------------------- EXECUTE --------------------
    global void execute(Database.BatchableContext bc, List<Payment_Schedule__c> scope) {
        Date today = Date.today();
        
        System.debug('=== Batch Execute Started ===');
        System.debug('Scope Size: ' + scope.size());

        // Group all schedules by Booking
        Map<Id, List<Payment_Schedule__c>> bookingToSchedules = new Map<Id, List<Payment_Schedule__c>>();
        Set<Id> bookingIds = new Set<Id>();
        
        for (Payment_Schedule__c ps : scope) {
            if (ps.Booking__c == null) continue;

            if (!bookingToSchedules.containsKey(ps.Booking__c)) {
                bookingToSchedules.put(ps.Booking__c, new List<Payment_Schedule__c>());
            }
            bookingToSchedules.get(ps.Booking__c).add(ps);
            bookingIds.add(ps.Booking__c);
        }

        System.debug('Unique Bookings in Scope: ' + bookingToSchedules.size());

        if (bookingToSchedules.isEmpty()) {
            System.debug('No bookings to process in this batch');
            return;
        }

        // Query co-applicants for all bookings in this batch
        Map<Id, List<Co_Applicant__c>> bookingToCoApplicants = new Map<Id, List<Co_Applicant__c>>();
        for (Co_Applicant__c coApp : [
            SELECT Id, Email__c, Booking__c 
            FROM Co_Applicant__c 
            WHERE Booking__c IN :bookingIds 
              AND Email__c != null
        ]) {
            if (!bookingToCoApplicants.containsKey(coApp.Booking__c)) {
                bookingToCoApplicants.put(coApp.Booking__c, new List<Co_Applicant__c>());
            }
            bookingToCoApplicants.get(coApp.Booking__c).add(coApp);
        }
        
        System.debug('Co-Applicants loaded for ' + bookingToCoApplicants.size() + ' bookings');

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Booking__c> cancelBookings = new List<Booking__c>();
        
        Integer batchCustomerEmails = 0;
        Integer batchInternalEmails = 0;

        for (Id bookingId : bookingToSchedules.keySet()) {
            List<Payment_Schedule__c> schedules = bookingToSchedules.get(bookingId);
            if (schedules == null || schedules.isEmpty()) continue;

            Booking__c booking = schedules[0].Booking__r;
            if (booking == null) continue;

            String reminderType = determineReminderTypeForBooking(schedules, today);
            if (String.isBlank(reminderType)) {
                System.debug('No reminder type determined for Booking: ' + bookingId);
                continue;
            }

            System.debug('Processing Booking: ' + bookingId + ', Reminder Type: ' + reminderType);

            bookingsProcessed++;
            emailsByType.put(reminderType, emailsByType.get(reminderType) + 1);

            // Filter schedules matching this reminder type
            List<Payment_Schedule__c> matched = filterSchedulesByReminderType(schedules, reminderType, today);
            if (matched.isEmpty()) matched = schedules;

            // Calculate total pending amount
            Decimal totalPending = 0;
            for (Payment_Schedule__c ps : matched) {
                totalPending += (ps.Pending_Amount__c == null ? 0 : ps.Pending_Amount__c);
            }

            String projectName = (booking.Project1__r != null ? booking.Project1__r.Name : '');
            String unitName    = (booking.Plot__r != null ? booking.Plot__r.Name : '');
            String formattedAmount = '₹' + String.valueOf(totalPending.setScale(2));

            Payment_Schedule__c firstSchedule = matched[0];

            String subject = '';
            String body = '';

            // -------------------- EMAIL TEMPLATES --------------------
            if (reminderType == '1ST_REMINDER') {
                subject = 'Payment Reminder for Plot/Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'This is a gentle reminder that the payment of ' + formattedAmount +
                    ' towards Plot/Unit No. ' + unitName + ' at Zuari ' + projectName +
                    ' was due as per the Final Demand Letter previously sent to you.<br/><br/>' +
                    'We kindly request you to treat this reminder as a priority and make the payment at the earliest along with interest thereon.<br/><br/>' +
                    'Should you require any clarification or assistance, please feel free to contact us. We&#39;ll be happy to help.<br/><br/>' +
                    'Thank you for your prompt attention to this matter.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';

            } else if (reminderType == '2ND_REMINDER') {
                subject = 'Second Reminder: Overdue Payment for Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'This is in reference to our earlier communication dated ' +
                    formatAny(firstSchedule.X1st_Reminder_Date__c) +
                    ', where we reminded you about the outstanding payment of ' + formattedAmount +
                    ' towards Unit No. ' + unitName + ' at Zuari ' + projectName + '.<br/><br/>' +
                    'To date, we have neither received the payment nor any communication explaining the reason for the delay. Please note that the amount is now seriously overdue.<br/><br/>' +
                    'As the payment deadline has passed, we request you to either settle the outstanding amount or contact us to discuss the matter within the next 7 days.<br/><br/>' +
                    'Kindly be advised that failure to make the payment or respond within this period may lead to the cancellation of your booking as per the applicable terms.<br/><br/>' +
                    'We look forward to hearing from you within the next 7 days.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';

            } else if (reminderType == '1ST_INTEREST' || reminderType == '2ND_INTEREST' || reminderType == '3RD_INTEREST') {
                subject = 'Final Reminder: Immediate Action Required – Overdue Payment for Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'This is to formally inform you that, despite multiple reminders—including our last communication dated ' +
                    formatAny(firstSchedule.X2nd_Reminder_Date__c) +
                    '—the payment of ' + formattedAmount + ' towards Unit No. ' + unitName +
                    ' at Zuari ' + projectName + ' remains unpaid.<br/><br/>' +
                    'We have also attempted to reach you through phone calls, messages, and emails, but have not received any confirmation or commitment regarding the clearance of the outstanding amount.<br/><br/>' +
                    'As previously communicated, delayed payments are subject to interest on the outstanding amount. Continued non-response will leave us with no choice but to escalate this matter to higher authorities for appropriate action.<br/><br/>' +
                    'Please note, this is our final reminder, and the payment is now critically overdue.<br/><br/>' +
                    'We urge you to take immediate action by either:<br/>' +
                    '<ul>' +
                    '<li>Clearing the outstanding dues, or</li>' +
                    '<li>Getting in touch with us within the next 7 days to discuss your situation.</li>' +
                    '</ul>' +
                    'Failure to do so will result in further steps being taken, which may include:<br/>' +
                    '<ul>' +
                    '<li>Cancellation of your booking, and/or</li>' +
                    '<li>Forfeiture of any amounts already paid, as per the terms and conditions of your agreement.</li>' +
                    '</ul>' +
                    'Thank you.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';

            } else if (reminderType == 'PRE_TERMINATION') {
                subject = 'Pre-Termination Notice – Outstanding Payment for Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'This is to notify you that your payment of ' + formattedAmount +
                    ' towards Unit No. ' + unitName + ' at Zuari ' + projectName +
                    ' has been overdue for more than 6 weeks despite repeated reminders.<br/><br/>' +
                    'Please note that as per the terms of your booking, continued default in payment may lead to the termination of your allotment.<br/><br/>' +
                    'You are hereby given a final opportunity to clear all outstanding dues within 7 days from the date of this notice to avoid termination.<br/><br/>' +
                    'In case of any difficulty or query, please contact our office immediately.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';

            } else if (reminderType == 'TERMINATION') {
                subject = 'Termination Notice – Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'We regret to inform you that despite multiple communications and reminders, the payment of ' + formattedAmount +
                    ' towards Unit No. ' + unitName + ' at Zuari ' + projectName +
                    ' has not been received.<br/><br/>' +
                    'As per the terms and conditions of your booking, your allotment stands terminated with immediate effect.<br/><br/>' +
                    'Any further communication regarding this matter will be considered only at the sole discretion of the management.<br/><br/>' +
                    'For any clarifications, please reach out to our Customer Relations Department.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';

                // Add internal team notification for termination
                batchInternalEmails += addTerminationInternalEmail(emails, booking, projectName, unitName);

            } else if (reminderType == 'CANCEL_BOOKING') {
                // CANCEL_BOOKING: Only send internal notification, no customer email
                batchInternalEmails += addCancellationInternalEmail(emails, booking, projectName, unitName, formattedAmount);
                cancelBookings.add(booking);
                continue; // Skip customer email
            }

            // Send customer email (only if email exists and we have content)
            if (!String.isBlank(subject) && !String.isBlank(body) && booking.Email__c != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { booking.Email__c });
                
                // Add co-applicants as CC
                List<String> ccAddresses = new List<String>();
                if (bookingToCoApplicants.containsKey(booking.Id)) {
                    for (Co_Applicant__c coApp : bookingToCoApplicants.get(booking.Id)) {
                        if (!String.isBlank(coApp.Email__c)) {
                            ccAddresses.add(coApp.Email__c);
                        }
                    }
                }
                
                if (!ccAddresses.isEmpty()) {
                    mail.setCcAddresses(ccAddresses);
                    System.debug('CC Addresses added: ' + ccAddresses);
                }
                
                mail.setSubject(subject);
                mail.setHtmlBody(body);
                mail.setSaveAsActivity(false);
                emails.add(mail);
                batchCustomerEmails++;
                System.debug('Customer email created for: ' + booking.Email__c + ' with ' + ccAddresses.size() + ' CC recipients');
            } else {
                System.debug('Skipping customer email - Subject: ' + (String.isBlank(subject) ? 'BLANK' : 'OK') + ', Body: ' + (String.isBlank(body) ? 'BLANK' : 'OK') + ', Email: ' + booking.Email__c);
            }
        }

        // Send all emails
        if (!emails.isEmpty()) {
            System.debug('Sending ' + emails.size() + ' emails...');
            Messaging.sendEmail(emails);
            totalEmailsSent += emails.size();
            customerEmailsSent += batchCustomerEmails;
            internalEmailsSent += batchInternalEmails;
            System.debug('Emails sent successfully');
        } else {
            System.debug('No emails to send in this batch');
        }

        // Cancel bookings (30 days after termination)
        if (!cancelBookings.isEmpty()) {
            System.debug('Cancelling ' + cancelBookings.size() + ' bookings...');
            bookingsCancelled += cancelBookings.size();
            BookingController.changeUnitStatus(cancelBookings);
            System.debug('Bookings cancelled successfully');
        }

        System.debug('=== Batch Execute Summary ===');
        System.debug('Customer Emails in Batch: ' + batchCustomerEmails);
        System.debug('Internal Emails in Batch: ' + batchInternalEmails);
        System.debug('Total Emails in Batch: ' + emails.size());
        System.debug('Cumulative - Total Emails: ' + totalEmailsSent);
        System.debug('Cumulative - Customer Emails: ' + customerEmailsSent);
        System.debug('Cumulative - Internal Emails: ' + internalEmailsSent);
        System.debug('Cumulative - Bookings Processed: ' + bookingsProcessed);
        System.debug('Cumulative - Bookings Cancelled: ' + bookingsCancelled);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('=== Batch Finish Method Started ===');
        System.debug('Final Totals:');
        System.debug('Total Emails Sent: ' + totalEmailsSent);
        System.debug('Customer Emails Sent: ' + customerEmailsSent);
        System.debug('Internal Emails Sent: ' + internalEmailsSent);
        System.debug('Bookings Processed: ' + bookingsProcessed);
        System.debug('Bookings Cancelled: ' + bookingsCancelled);
        System.debug('Emails by Type: ' + emailsByType);
        
        // Send summary email to admin
        sendAdminSummaryEmail();
        
        System.debug('=== Batch Finish Method Completed ===');
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PendingPaymentReminderScheduler(), 100);
    }

    // -------------------- TYPE-SAFE DATE MATCHING --------------------
    private static Boolean isSameDay(DateTime dt, Date d) {
        return dt != null && dt.date() == d;
    }

    private static Boolean isSameDay(Date dd, Date d) {
        return dd != null && dd == d;
    }

    private static String formatAny(DateTime dt) {
        return (dt == null ? '' : dt.date().format());
    }
    
    private static String formatAny(Date dd) {
        return (dd == null ? '' : dd.format());
    }

    // -------------------- REMINDER TYPE DETERMINATION --------------------
    private static String determineReminderTypeForBooking(List<Payment_Schedule__c> schedules, Date today) {
        Set<String> matches = new Set<String>();

        for (Payment_Schedule__c ps : schedules) {
            if (isSameDay(ps.X1st_Reminder_Date__c, today))           matches.add('1ST_REMINDER');
            if (isSameDay(ps.X2nd_Reminder_Date__c, today))           matches.add('2ND_REMINDER');
            if (isSameDay(ps.X1st_Interest_Reminder_Date__c, today))  matches.add('1ST_INTEREST');
            if (isSameDay(ps.X2nd_Interest_Reminder_Date__c, today))  matches.add('2ND_INTEREST');
            if (isSameDay(ps.X3rd_Interest_Reminder_Date__c, today))  matches.add('3RD_INTEREST');
            if (isSameDay(ps.Pre_Termination_Mail_Date__c, today))    matches.add('PRE_TERMINATION');
            if (isSameDay(ps.Termination_Mail_Date__c, today))        matches.add('TERMINATION');
            if (isSameDay(ps.Termination_Mail_Date__c, today.addDays(-30))) matches.add('CANCEL_BOOKING');
        }

        for (String t : PRIORITY) {
            if (matches.contains(t)) return t;
        }
        return null;
    }

    private static List<Payment_Schedule__c> filterSchedulesByReminderType(
        List<Payment_Schedule__c> schedules,
        String reminderType,
        Date today
    ) {
        List<Payment_Schedule__c> outList = new List<Payment_Schedule__c>();

        for (Payment_Schedule__c ps : schedules) {
            if (reminderType == '1ST_REMINDER' && isSameDay(ps.X1st_Reminder_Date__c, today)) {
                outList.add(ps);
            } else if (reminderType == '2ND_REMINDER' && isSameDay(ps.X2nd_Reminder_Date__c, today)) {
                outList.add(ps);
            } else if (reminderType == '1ST_INTEREST' && isSameDay(ps.X1st_Interest_Reminder_Date__c, today)) {
                outList.add(ps);
            } else if (reminderType == '2ND_INTEREST' && isSameDay(ps.X2nd_Interest_Reminder_Date__c, today)) {
                outList.add(ps);
            } else if (reminderType == '3RD_INTEREST' && isSameDay(ps.X3rd_Interest_Reminder_Date__c, today)) {
                outList.add(ps);
            } else if (reminderType == 'PRE_TERMINATION' && isSameDay(ps.Pre_Termination_Mail_Date__c, today)) {
                outList.add(ps);
            } else if (reminderType == 'TERMINATION' && isSameDay(ps.Termination_Mail_Date__c, today)) {
                outList.add(ps);
            } else if (reminderType == 'CANCEL_BOOKING' && isSameDay(ps.Termination_Mail_Date__c, today.addDays(-30))) {
                outList.add(ps);
            }
        }
        return outList;
    }

    // -------------------- INTERNAL EMAIL NOTIFICATIONS --------------------
    private static Integer addTerminationInternalEmail(
        List<Messaging.SingleEmailMessage> emails,
        Booking__c booking,
        String projectName,
        String unitName
    ) {
        String subjectcc = 'Termination Confirmation Sent to Customer for Unit ' + unitName;

        String bodycc = ''
            + '<p>Dear Team,</p>'
            + '<p>This is to inform you that a <strong>termination confirmation email</strong> has been successfully sent to the customer regarding <strong>Unit ' + unitName + '</strong>.</p>'
            + '<p><strong>Termination Details:</strong></p>'
            + '<table style="border-collapse: collapse; border: 1px solid #ddd;">'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Project Name</td><td style="padding: 6px; border: 1px solid #ddd;">' + projectName + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Unit Number</td><td style="padding: 6px; border: 1px solid #ddd;">' + unitName + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Customer Name</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.First_Applicant_Name__c + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Customer Email</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Email__c + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Initiated By</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Owner_Full_Name__c + '</td></tr>'
            + '</table>'
            + '<br/>'
            + '<p><strong>Summary:</strong><br/>The termination confirmation mail has been sent to the customer as per the standard communication process. '
            + 'All concerned departments are requested to update their respective systems accordingly.</p>'
            + '<ul>'
            + '<li><strong>Sales Team</strong> – Update lead/opportunity status to Terminated</li>'
            + '<li><strong>Finance Team</strong> – Process refund or financial settlement as applicable</li>'
            + '<li><strong>CRM Team</strong> – Ensure CRM record accuracy</li>'
            + '</ul>'
            + '<br/>'
            + '<p>Best Regards,<br/><strong>CRM Notification System</strong><br/>Zuari Infraworld India Ltd.</p>';

        List<String> toaddress = new List<String>();
        if (booking.CRM_Executive__r != null && booking.CRM_Executive__r.Email != null) toaddress.add(booking.CRM_Executive__r.Email);
        if (booking.CRM_Head__r != null && booking.CRM_Head__r.Email != null)           toaddress.add(booking.CRM_Head__r.Email);
        if (booking.Sales_Head__r != null && booking.Sales_Head__r.Email != null)       toaddress.add(booking.Sales_Head__r.Email);
        if (booking.COO__r != null && booking.COO__r.Email != null)                     toaddress.add(booking.COO__r.Email);

        if (!toaddress.isEmpty()) {
            Messaging.SingleEmailMessage internalMail = new Messaging.SingleEmailMessage();
            internalMail.setToAddresses(toaddress);
            internalMail.setSubject(subjectcc);
            internalMail.setHtmlBody(bodycc);
            internalMail.setSaveAsActivity(false);
            emails.add(internalMail);
            return 1;
        }
        return 0;
    }

    private static Integer addCancellationInternalEmail(
        List<Messaging.SingleEmailMessage> emails,
        Booking__c booking,
        String projectName,
        String unitName,
        String formattedAmount
    ) {
        String subjectcc = 'Booking Cancellation: Unit ' + unitName + ' - 30 Days Post Termination';

        String bodycc = ''
            + '<p>Dear Team,</p>'
            + '<p>This is to inform you that <strong>Unit ' + unitName + '</strong> has been automatically cancelled as it is 30 days past the termination date with outstanding payment.</p>'
            + '<p><strong>Cancellation Details:</strong></p>'
            + '<table style="border-collapse: collapse; border: 1px solid #ddd;">'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Project Name</td><td style="padding: 6px; border: 1px solid #ddd;">' + projectName + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Unit Number</td><td style="padding: 6px; border: 1px solid #ddd;">' + unitName + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Customer Name</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.First_Applicant_Name__c + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Customer Email</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Email__c + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Outstanding Amount</td><td style="padding: 6px; border: 1px solid #ddd;">' + formattedAmount + '</td></tr>'
            + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Booking Owner</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Owner_Full_Name__c + '</td></tr>'
            + '</table>'
            + '<br/>'
            + '<p><strong>Action Required:</strong></p>'
            + '<ul>'
            + '<li><strong>Sales Team</strong> – Update booking status and release unit for new bookings</li>'
            + '<li><strong>Finance Team</strong> – Process cancellation settlements and forfeitures as per policy</li>'
            + '<li><strong>CRM Team</strong> – Update customer records and close communication threads</li>'
            + '<li><strong>Legal Team</strong> – Review any pending legal or contractual obligations</li>'
            + '</ul>'
            + '<br/>'
            + '<p><strong>Note:</strong> This cancellation was triggered automatically as 30 days have passed since the termination notice with no payment received.</p>'
            + '<br/>'
            + '<p>Best Regards,<br/><strong>CRM Notification System</strong><br/>Zuari Infraworld India Ltd.</p>';

        List<String> toaddress = new List<String>();
        if (booking.CRM_Executive__r != null && booking.CRM_Executive__r.Email != null) toaddress.add(booking.CRM_Executive__r.Email);
        if (booking.CRM_Head__r != null && booking.CRM_Head__r.Email != null)           toaddress.add(booking.CRM_Head__r.Email);
        if (booking.Sales_Head__r != null && booking.Sales_Head__r.Email != null)       toaddress.add(booking.Sales_Head__r.Email);
        if (booking.COO__r != null && booking.COO__r.Email != null)                     toaddress.add(booking.COO__r.Email);

        if (!toaddress.isEmpty()) {
            Messaging.SingleEmailMessage internalMail = new Messaging.SingleEmailMessage();
            internalMail.setToAddresses(toaddress);
            internalMail.setSubject(subjectcc);
            internalMail.setHtmlBody(bodycc);
            internalMail.setSaveAsActivity(false);
            emails.add(internalMail);
            return 1;
        }
        return 0;
    }

    // -------------------- ADMIN SUMMARY EMAIL --------------------
    private void sendAdminSummaryEmail() {
        System.debug('=== Sending Admin Summary Email ===');
        
        // Get admin email from custom settings or organization-wide email
        // For now, using a placeholder - replace with actual admin email retrieval
        String adminEmail = 'admin@zuari.com'; // TODO: Replace with actual admin email
        
        System.debug('Admin Email: ' + adminEmail);
        
        String subject = 'Payment Reminder Batch Job Summary - ' + Date.today().format();
        
        String body = ''
            + '<h2>Payment Reminder Batch Job Execution Summary</h2>'
            + '<p><strong>Execution Date:</strong> ' + DateTime.now().format('dd-MMM-yyyy HH:mm:ss') + '</p>'
            + '<hr/>'
            + '<h3>Overall Statistics</h3>'
            + '<table style="border-collapse: collapse; border: 1px solid #ddd; width: 100%;">'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;"><strong>Total Bookings Processed</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + bookingsProcessed + '</td></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Total Emails Sent</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + totalEmailsSent + '</td></tr>'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;"><strong>Customer Emails Sent</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + customerEmailsSent + '</td></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Internal Emails Sent</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + internalEmailsSent + '</td></tr>'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;"><strong>Bookings Cancelled</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + bookingsCancelled + '</td></tr>'
            + '</table>'
            + '<br/>'
            + '<h3>Email Breakdown by Reminder Type</h3>'
            + '<table style="border-collapse: collapse; border: 1px solid #ddd; width: 100%;">'
            + '<tr style="background-color: #4CAF50; color: white;"><th style="padding: 8px; border: 1px solid #ddd;">Reminder Type</th><th style="padding: 8px; border: 1px solid #ddd;">Count</th></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;">1st Reminder</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('1ST_REMINDER') + '</td></tr>'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;">2nd Reminder</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('2ND_REMINDER') + '</td></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;">1st Interest Reminder</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('1ST_INTEREST') + '</td></tr>'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;">2nd Interest Reminder</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('2ND_INTEREST') + '</td></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;">3rd Interest Reminder</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('3RD_INTEREST') + '</td></tr>'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;">Pre-Termination</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('PRE_TERMINATION') + '</td></tr>'
            + '<tr style="background-color: #ffebee;"><td style="padding: 8px; border: 1px solid #ddd;"><strong>Termination</strong></td><td style="padding: 8px; border: 1px solid #ddd;"><strong>' + emailsByType.get('TERMINATION') + '</strong></td></tr>'
            + '<tr style="background-color: #ffe0e0;"><td style="padding: 8px; border: 1px solid #ddd;"><strong>Cancellation (30 days post-termination)</strong></td><td style="padding: 8px; border: 1px solid #ddd;"><strong>' + emailsByType.get('CANCEL_BOOKING') + '</strong></td></tr>'
            + '</table>'
            + '<br/>'
            + '<hr/>'
            + '<p style="color: #666; font-size: 12px;"><em>This is an automated summary generated by the Payment Reminder Scheduler batch job.</em></p>'
            + '<p style="color: #666; font-size: 12px;"><em>For any queries, please contact the CRM Team.</em></p>'
            + '<br/>'
            + '<p>Best Regards,<br/><strong>Zuari CRM Automation System</strong></p>';

        try {
            System.debug('Creating admin summary email...');
            Messaging.SingleEmailMessage summaryEmail = new Messaging.SingleEmailMessage();
            summaryEmail.setToAddresses(new String[] { adminEmail });
            summaryEmail.setSubject(subject);
            summaryEmail.setHtmlBody(body);
            summaryEmail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { summaryEmail });
            System.debug('Admin summary email sent successfully');
        } catch (Exception e) {
            System.debug('Error sending admin summary email: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
}