/**
 * Daily scheduler: sends "Documents Escalation" emails for Channel Partners
 * created more than 2 days ago that still have at least one document checkbox
 * unchecked...
 *
 * Schedule (one-time, anonymous Apex):
 *   System.schedule('CP Docs Escalation Daily', '0 0 10 * * ?', new CPDocsEscalationScheduler());
 *
 * @description   Daily job sending "Documents Escalation" emails (notification #2)
 * @author        support2@fingertipplus.com
 * @created       2026-05-25
 * @lastModified  2026-05-25 (one-shot bundle deploy)
 */
public without sharing class CPDocsEscalationScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        run();
    }

    @TestVisible
    private static void run() {
        List<Channel_Partner__c> cps = [
            SELECT Id, User_Id__c, Name, Email__c, OwnerId,
                   Approval_Status__c, Training_Date__c, Training_Completed__c,
                   Mobile_APP_login_Time__c,
                   Aadhar_Document_Uploaded__c, Authorization_Letter_Document_Uploaded__c,
                   Address_Proof_Document_Uploaded__c, GST_Document_Uploaded__c,
                   RERA_Document_Uploaded__c, Cancel_Cheque_Document_Uploaded__c,
                   Board_Resolution_Document_Uploaded__c, Company_Registration_Document_Uploaded__c,
                   PAN_Document_Uploaded__c
            FROM Channel_Partner__c
            WHERE CreatedDate <= :Datetime.now().addDays(-2)
              AND (Aadhar_Document_Uploaded__c = false
                OR Authorization_Letter_Document_Uploaded__c = false
                OR Address_Proof_Document_Uploaded__c = false
                OR GST_Document_Uploaded__c = false
                OR RERA_Document_Uploaded__c = false
                OR Cancel_Cheque_Document_Uploaded__c = false
                OR Board_Resolution_Document_Uploaded__c = false
                OR Company_Registration_Document_Uploaded__c = false
                OR PAN_Document_Uploaded__c = false)
            LIMIT 200
        ];
        if (cps.isEmpty()) return;
        CPEmailNotificationService.sendDocumentsEscalation(cps);
    }
}