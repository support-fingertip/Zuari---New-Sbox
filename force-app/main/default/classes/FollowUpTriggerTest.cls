@IsTest
public class FollowUpTriggerTest {

    @testSetup
    static void setupData() {

        // Create Related Source
        Related_Source__c rs = new Related_Source__c(
           
        );
        insert rs;

        // Create two Follow Ups (no scheduled date initially)
        List<Follow_up__c> fuList = new List<Follow_up__c>();

        fuList.add(new Follow_up__c(
            Related_Source__c = rs.Id,
            Subject__c = 'First Followup'
        ));

        fuList.add(new Follow_up__c(
            Related_Source__c = rs.Id,
            Subject__c = 'Second Followup'
        ));

        insert fuList;
    }

    @IsTest
    static void testAfterUpdate_FollowUpDatesUpdated() {

        Related_Source__c rs = [
            SELECT Id 
            FROM Related_Source__c 
            LIMIT 1
        ];

        List<Follow_up__c> followups = [
            SELECT Id, Scheduled_Date__c, Related_Source__c
            FROM Follow_up__c
            WHERE Related_Source__c = :rs.Id
            ORDER BY CreatedDate ASC
        ];

        // Update Scheduled Dates (this fires AFTER UPDATE trigger)
        followups[0].Scheduled_Date__c = System.now().addDays(1);
        followups[1].Scheduled_Date__c = System.now().addDays(2);

        Test.startTest();
        update followups;
        Test.stopTest();

        // Verify Related Source got updated
        Related_Source__c updatedRS = [
            SELECT Latest_FollowUp_Date__c, Last_Follow_Up_Date__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];

        System.assertNotEquals(
            null,
            updatedRS.Latest_FollowUp_Date__c,
            'Latest follow-up date should be set'
        );

        System.assertNotEquals(
            null,
            updatedRS.Last_Follow_Up_Date__c,
            'Last follow-up date should be set'
        );

        // Latest should be the most recent scheduled date
        System.assertEquals(
            followups[1].Scheduled_Date__c,
            updatedRS.Latest_FollowUp_Date__c
        );
    }

    @IsTest
    static void testSingleFollowUp() {

        // New Related Source
        Related_Source__c rs = new Related_Source__c(
           
        );
        insert rs;

        Follow_up__c fu = new Follow_up__c(
            Related_Source__c = rs.Id,
            Subject__c = 'Only Followup'
        );
        insert fu;

        // Update scheduled date
        fu.Scheduled_Date__c = System.now().addDays(3);

        Test.startTest();
        update fu;
        Test.stopTest();

        Related_Source__c updatedRS = [
            SELECT Latest_FollowUp_Date__c, Last_Follow_Up_Date__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];

        System.assertEquals(
            fu.Scheduled_Date__c,
            updatedRS.Latest_FollowUp_Date__c
        );

        System.assertEquals(
            null,
            updatedRS.Last_Follow_Up_Date__c,
            'Last follow-up should be null when only one followup exists'
        );
    }

    @IsTest
    static void testNoRelatedSource_NoError() {

        Follow_up__c fu = new Follow_up__c(
            Subject__c = 'No Related Source'
        );
        insert fu;

        fu.Scheduled_Date__c = System.now().addDays(1);

        Test.startTest();
        update fu; // should NOT fail
        Test.stopTest();

        System.assertNotEquals(null, fu.Id);
    }
}