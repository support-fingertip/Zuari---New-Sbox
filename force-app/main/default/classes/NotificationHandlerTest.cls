@IsTest
public class NotificationHandlerTest {

    @TestSetup
    static void setup() {
        Channel_Partner__c cp = new Channel_Partner__c(Name = 'Test CP', Email__c = 'test@example.com', Active__c = true);
        insert cp;

        Related_Source__c rs = new Related_Source__c(Lead_status1__c = 'Open');
        insert rs;

        Site_Visit__c sv = new Site_Visit__c(Status__c = 'Scheduled');
        insert sv;

        Follow_up__c fu = new Follow_up__c(Status__c = 'Scheduled', Comments__c = 'Test');
        insert fu;

        Payment__c pay = new Payment__c();
        insert pay;

        Payment_Line_Item__c pli = new Payment_Line_Item__c(Payament_Status__c = 'Pending', Payment__c = pay.Id, Name = 'PLI-1');
        insert pli;
    }

    private static SObject forceFields(SObject record, Map<String, Object> overrides) {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(record));
        m.put('attributes', new Map<String, Object>{ 'type' => String.valueOf(record.getSObjectType()) });
        m.putAll(overrides);
        return (SObject) JSON.deserialize(JSON.serialize(m), Type.forName(String.valueOf(record.getSObjectType())));
    }

    // ─── Related Source ───

    @IsTest
    static void relatedSource_newNotification() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Related_Source__c rs = [SELECT Id, Lead_status1__c FROM Related_Source__c LIMIT 1];

        Related_Source__c newRec = (Related_Source__c) forceFields(rs, new Map<String, Object>{
            'Lead_status1__c' => 'Allocated', 'Channel_Partner1__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForRelatedSource(
            new List<Related_Source__c>{ newRec }, new Map<Id, Related_Source__c>{ rs.Id => rs }
        );
        Test.stopTest();

        List<Notification__c> n = [SELECT Notification_Type__c, Updated_Status__c FROM Notification__c WHERE Related_Source__c = :rs.Id];
        System.assertEquals(1, n.size());
        System.assertEquals('Lead Notification', n[0].Notification_Type__c);
        System.assertEquals('Allocated', n[0].Updated_Status__c);
    }

    @IsTest
    static void relatedSource_updateExisting() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Related_Source__c rs = [SELECT Id, Lead_status1__c FROM Related_Source__c LIMIT 1];

        insert new Notification__c(
            Related_Source__c = rs.Id, Channel_Partner__c = cp.Id,
            IsActive__c = true, Notification_Category__c = 'User Specific', Updated_Status__c = 'Open'
        );

        Related_Source__c newRec = (Related_Source__c) forceFields(rs, new Map<String, Object>{
            'Lead_status1__c' => 'Rejected', 'Channel_Partner1__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForRelatedSource(
            new List<Related_Source__c>{ newRec }, new Map<Id, Related_Source__c>{ rs.Id => rs }
        );
        Test.stopTest();

        Notification__c updated = [SELECT Updated_Status__c FROM Notification__c WHERE Related_Source__c = :rs.Id LIMIT 1];
        System.assertEquals('Rejected', updated.Updated_Status__c);
    }

    @IsTest
    static void relatedSource_skippedWhenNullCP() {
        Related_Source__c rs = [SELECT Id, Lead_status1__c FROM Related_Source__c LIMIT 1];

        Related_Source__c newRec = (Related_Source__c) forceFields(rs, new Map<String, Object>{
            'Lead_status1__c' => 'Allocated'
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForRelatedSource(
            new List<Related_Source__c>{ newRec }, new Map<Id, Related_Source__c>{ rs.Id => rs }
        );
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Notification__c WHERE Related_Source__c = :rs.Id]);
    }

    // ─── Site Visit ───

    @IsTest
    static void siteVisit_newNotification() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];
        Site_Visit__c sv = [SELECT Id, Status__c FROM Site_Visit__c LIMIT 1];

        Site_Visit__c newRec = (Site_Visit__c) forceFields(sv, new Map<String, Object>{
            'Status__c' => 'Completed', 'Related_Source__c' => rs.Id, 'Channel_Partner_Id__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForSiteVisit(
            new List<Site_Visit__c>{ newRec }, new Map<Id, Site_Visit__c>{ sv.Id => sv }
        );
        Test.stopTest();

        List<Notification__c> n = [SELECT Notification_Type__c FROM Notification__c WHERE Site_Visit__c = :sv.Id];
        System.assertEquals(1, n.size());
        System.assertEquals('Site Visit Notification', n[0].Notification_Type__c);
    }

    @IsTest
    static void siteVisit_updateExisting() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];
        Site_Visit__c sv = [SELECT Id, Status__c FROM Site_Visit__c LIMIT 1];

        insert new Notification__c(
            Site_Visit__c = sv.Id, Channel_Partner__c = cp.Id,
            IsActive__c = true, Notification_Category__c = 'User Specific', Updated_Status__c = 'Scheduled'
        );

        Site_Visit__c newRec = (Site_Visit__c) forceFields(sv, new Map<String, Object>{
            'Status__c' => 'Completed', 'Related_Source__c' => rs.Id, 'Channel_Partner_Id__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForSiteVisit(
            new List<Site_Visit__c>{ newRec }, new Map<Id, Site_Visit__c>{ sv.Id => sv }
        );
        Test.stopTest();

        System.assertEquals('Completed', [SELECT Updated_Status__c FROM Notification__c WHERE Site_Visit__c = :sv.Id LIMIT 1].Updated_Status__c);
    }

    @IsTest
    static void siteVisit_skippedWhenNullFields() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Site_Visit__c sv = [SELECT Id, Status__c FROM Site_Visit__c LIMIT 1];

        // Missing Related_Source__c
        Site_Visit__c newRec = (Site_Visit__c) forceFields(sv, new Map<String, Object>{
            'Status__c' => 'Completed', 'Channel_Partner_Id__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForSiteVisit(
            new List<Site_Visit__c>{ newRec }, new Map<Id, Site_Visit__c>{ sv.Id => sv }
        );
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Notification__c WHERE Site_Visit__c = :sv.Id]);
    }

    // ─── Follow Up ───

    @IsTest
    static void followUp_newNotification() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];
        Follow_up__c fu = [SELECT Id, Status__c FROM Follow_up__c LIMIT 1];

        Follow_up__c newRec = (Follow_up__c) forceFields(fu, new Map<String, Object>{
            'Status__c' => 'Completed', 'Related_Source__c' => rs.Id, 'Channel_Partner_Id__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForFollowUp(
            new List<Follow_up__c>{ newRec }, new Map<Id, Follow_up__c>{ fu.Id => fu }
        );
        Test.stopTest();

        List<Notification__c> n = [SELECT Notification_Type__c FROM Notification__c WHERE Follow_up__c = :fu.Id];
        System.assertEquals(1, n.size());
        System.assertEquals('Followup Notification', n[0].Notification_Type__c);
    }

    @IsTest
    static void followUp_updateExisting() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];
        Follow_up__c fu = [SELECT Id, Status__c FROM Follow_up__c LIMIT 1];

        insert new Notification__c(
            Follow_up__c = fu.Id, Channel_Partner__c = cp.Id,
            IsActive__c = true, Notification_Category__c = 'User Specific', Updated_Status__c = 'Scheduled'
        );

        Follow_up__c newRec = (Follow_up__c) forceFields(fu, new Map<String, Object>{
            'Status__c' => 'Completed', 'Related_Source__c' => rs.Id, 'Channel_Partner_Id__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForFollowUp(
            new List<Follow_up__c>{ newRec }, new Map<Id, Follow_up__c>{ fu.Id => fu }
        );
        Test.stopTest();

        System.assertEquals('Completed', [SELECT Updated_Status__c FROM Notification__c WHERE Follow_up__c = :fu.Id LIMIT 1].Updated_Status__c);
    }

    @IsTest
    static void followUp_skippedWhenNullFields() {
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];
        Follow_up__c fu = [SELECT Id, Status__c FROM Follow_up__c LIMIT 1];

        // Missing Channel_Partner_Id__c
        Follow_up__c newRec = (Follow_up__c) forceFields(fu, new Map<String, Object>{
            'Status__c' => 'Completed', 'Related_Source__c' => rs.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForFollowUp(
            new List<Follow_up__c>{ newRec }, new Map<Id, Follow_up__c>{ fu.Id => fu }
        );
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Notification__c WHERE Follow_up__c = :fu.Id]);
    }

    // ─── Payment ───

    @IsTest
    static void payment_newNotification() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Payment_Line_Item__c pli = [SELECT Id, Payament_Status__c FROM Payment_Line_Item__c LIMIT 1];

        Payment_Line_Item__c newRec = (Payment_Line_Item__c) forceFields(pli, new Map<String, Object>{
            'Payament_Status__c' => 'Processed', 'Channel_Partner__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForPayment(
            new List<Payment_Line_Item__c>{ newRec }, new Map<Id, Payment_Line_Item__c>{ pli.Id => pli }
        );
        Test.stopTest();

        List<Notification__c> n = [SELECT Notification_Type__c FROM Notification__c WHERE Payment_Line_Item__c = :pli.Id];
        System.assertEquals(1, n.size());
        System.assertEquals('Payment Notification', n[0].Notification_Type__c);
    }

    @IsTest
    static void payment_updateExisting() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        Payment_Line_Item__c pli = [SELECT Id, Payament_Status__c FROM Payment_Line_Item__c LIMIT 1];

        insert new Notification__c(
            Payment_Line_Item__c = pli.Id, Channel_Partner__c = cp.Id,
            IsActive__c = true, Notification_Category__c = 'User Specific', Updated_Status__c = 'Pending'
        );

        Payment_Line_Item__c newRec = (Payment_Line_Item__c) forceFields(pli, new Map<String, Object>{
            'Payament_Status__c' => 'Processed', 'Channel_Partner__c' => cp.Id
        });

        Test.startTest();
        NotificationHandler.createNotificationRecordsForPayment(
            new List<Payment_Line_Item__c>{ newRec }, new Map<Id, Payment_Line_Item__c>{ pli.Id => pli }
        );
        Test.stopTest();

        System.assertEquals('Processed', [SELECT Updated_Status__c FROM Notification__c WHERE Payment_Line_Item__c = :pli.Id LIMIT 1].Updated_Status__c);
    }

    // ─── Null & Empty Guards ───

    @IsTest
    static void allMethods_handleNullAndEmptyInputs() {
        NotificationHandler.createNotificationRecordsForRelatedSource(null, null);
        NotificationHandler.createNotificationRecordsForSiteVisit(null, null);
        NotificationHandler.createNotificationRecordsForFollowUp(null, null);
        NotificationHandler.createNotificationRecordsForPayment(null, null);

        NotificationHandler.createNotificationRecordsForRelatedSource(new List<Related_Source__c>(), new Map<Id, Related_Source__c>());
        NotificationHandler.createNotificationRecordsForSiteVisit(new List<Site_Visit__c>(), new Map<Id, Site_Visit__c>());
        NotificationHandler.createNotificationRecordsForFollowUp(new List<Follow_up__c>(), new Map<Id, Follow_up__c>());
        NotificationHandler.createNotificationRecordsForPayment(new List<Payment_Line_Item__c>(), new Map<Id, Payment_Line_Item__c>());

        System.assertEquals(0, [SELECT COUNT() FROM Notification__c]);
    }
}