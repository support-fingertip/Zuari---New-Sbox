public without sharing class GREFormNotifier {

    // ── Called from controller (guest context safe) ──────────────────────
    @future
    public static void sendNotificationsAsync(String formDetails) {
        // Custom notification — works in @future
        sendCustomNotification(formDetails);

        // Email — needs its OWN @future call from here
        // Can't call @future from @future, so send directly here
        sendEmails(formDetails);
    }

    // ── Notification only ────────────────────────────────────────────────
    private static void sendCustomNotification(String formDetails) {
        System.debug('===> sendCustomNotification START');

        List<CustomNotificationType> notifTypes = [
            SELECT Id FROM CustomNotificationType
            WHERE DeveloperName = 'GRE_Form_Submitted'
            LIMIT 1
        ];
        if (notifTypes.isEmpty()) {
            System.debug('===> STOPPING: GRE_Form_Submitted not found');
            return;
        }

        Set<String> recipientIds = getRecipientIds();
        if (recipientIds.isEmpty()) {
            System.debug('===> STOPPING: No recipient IDs found');
            return;
        }

        try {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Security Register Alert');
            notification.setBody(formDetails.left(750));
            notification.setNotificationTypeId(notifTypes[0].Id);
            notification.setTargetId(new List<String>(recipientIds)[0]);
            notification.send(recipientIds);
            System.debug('===> Custom Notification SENT');
        } catch (Exception e) {
            System.debug('===> Notification ERROR: ' + e.getMessage());
        }
    }

    // ── Email only ───────────────────────────────────────────────────────
    private static void sendEmails(String formDetails) {
        System.debug('===> sendEmails START');

        List<GRE_User__mdt> greUsers = [
            SELECT Email__c FROM GRE_User__mdt
        ];
        if (greUsers.isEmpty()) {
            System.debug('===> STOPPING: No GRE users found');
            return;
        }

        // ✅ Use OrgWideEmailAddress to bypass guest sender restrictions
        List<OrgWideEmailAddress> oweaList = [
            SELECT Id FROM OrgWideEmailAddress
            WHERE IsAllowAllProfiles = true
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (GRE_User__mdt greUser : greUsers) {
            if (String.isNotBlank(greUser.Email__c)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ greUser.Email__c });
                mail.setSubject('New Security Register Form Submission');
                mail.setPlainTextBody(formDetails);
                mail.setSaveAsActivity(false);

                // ✅ Set org-wide address if available — avoids "no-reply" bounce
                if (!oweaList.isEmpty()) {
                    mail.setOrgWideEmailAddressId(oweaList[0].Id);
                }

                emails.add(mail);
                System.debug('===> Email prepared for: ' + greUser.Email__c);
            }
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                System.debug('===> Emails SENT: ' + emails.size());
            } catch (Exception e) {
                System.debug('===> Email ERROR: ' + e.getMessage());
            }
        }
    }

    // ── Shared helper: get Salesforce User IDs from metadata ─────────────
    private static Set<String> getRecipientIds() {
        List<GRE_User__mdt> greUsers = [
            SELECT Salesforce_Username__c FROM GRE_User__mdt
        ];

        Set<String> usernames = new Set<String>();
        for (GRE_User__mdt u : greUsers) {
            usernames.add(u.Salesforce_Username__c);
        }

        Set<String> recipientIds = new Set<String>();
        for (User usr : [
            SELECT Id FROM User
            WHERE Username IN :usernames AND IsActive = true
        ]) {
            recipientIds.add(String.valueOf(usr.Id));
        }

        System.debug('===> recipientIds: ' + recipientIds);
        return recipientIds;
    }

    // ── Keep this for Execute Anonymous testing ──────────────────────────
    public static void sendNotificationsSync(String formDetails) {
        System.debug('===> GREFormNotifier START');
        sendCustomNotification(formDetails);
        sendEmails(formDetails);
        System.debug('===> GREFormNotifier END');
    }
}