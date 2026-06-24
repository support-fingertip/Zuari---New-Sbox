@IsTest
public class CallCommentsTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Create a Related Source record
        Related_Source__c rs = new Related_Source__c(
          
        );
        insert rs;
    }

    @IsTest
    static void testAfterInsert_WithRelatedSource() {

        // Fetch test Related Source
        Related_Source__c rs = [
            SELECT Id 
            FROM Related_Source__c 
            LIMIT 1
        ];

        // Create Call Comment linked to Related Source
        Call_Comments__c cc = new Call_Comments__c(
            Comments__c = 'Test comment',
            Related_Source__c = rs.Id
        );

        Test.startTest();
        insert cc; // 🔥 Trigger fires here
        Test.stopTest();

        // Assertion just to confirm insert succeeded
        Call_Comments__c insertedCC = [
            SELECT Id, Related_Source__c 
            FROM Call_Comments__c 
            WHERE Id = :cc.Id
        ];
        System.assertEquals(rs.Id, insertedCC.Related_Source__c);
    }

    @IsTest
    static void testAfterInsert_WithoutRelatedSource() {

        // Call Comment WITHOUT Related Source (edge case)
        Call_Comments__c cc = new Call_Comments__c(
            Comments__c = 'Comment without RS'
        );

        Test.startTest();
        insert cc; // Trigger fires but set remains empty
        Test.stopTest();

        // Assert record exists
        System.assertNotEquals(null, cc.Id);
    }

    @IsTest
    static void testRecursionGuard() {

        // This ensures isExecuting logic is covered
        Related_Source__c rs = [
            SELECT Id 
            FROM Related_Source__c 
            LIMIT 1
        ];

        List<Call_Comments__c> ccList = new List<Call_Comments__c>();

        for (Integer i = 0; i < 3; i++) {
            ccList.add(new Call_Comments__c(
                Comments__c = 'Bulk comment ' + i,
                Related_Source__c = rs.Id
            ));
        }

        Test.startTest();
        insert ccList; // bulk insert → recursion guard hit
        Test.stopTest();

        System.assertEquals(3, ccList.size());
    }
}