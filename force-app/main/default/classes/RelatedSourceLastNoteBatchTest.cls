@IsTest
public class RelatedSourceLastNoteBatchTest {

    @IsTest
    static void testBatchCreatesLastNote() {

        // ================================
        // STEP 1: Create Related Source
        // ================================
        Related_Source__c rs = new Related_Source__c(
          
            Is_Locked__c = false
        );
        insert rs;

        // ================================
        // STEP 2: Create Call Comments
        // ================================
        List<Call_Comments__c> comments = new List<Call_Comments__c>();

        comments.add(new Call_Comments__c(
            Related_Source__c = rs.Id,
            Comments__c = 'First test comment',
            Created_Date__c = System.now()
        ));
        
        comments.add(new Call_Comments__c(
            Related_Source__c = rs.Id,
            Comments__c = 'Call Summary 1: Admin [11-11-25 10:00 AM]: Second test comment',
            Created_Date__c = System.now().addMinutes(5)
        ));

        insert comments;

        // ================================
        // STEP 3: Execute Batch
        // ================================
        Test.startTest();
        Database.executeBatch(new RelatedSourceLastNoteBatch(), 200);
        Test.stopTest();

        // ================================
        // STEP 4: Verify Result
        // ================================
        Related_Source__c updatedRs = [
            SELECT Last_Note__c
            FROM Related_Source__c
            WHERE Id = :rs.Id
        ];

        System.assertNotEquals(
            null,
            updatedRs.Last_Note__c,
            'Last_Note__c should be populated'
        );

        System.assert(
            updatedRs.Last_Note__c.contains('Call Summary 1'),
            'Last_Note__c should contain Call Summary'
        );

        System.assert(
            updatedRs.Last_Note__c.contains('First test comment'),
            'First comment should be present'
        );

        System.assert(
            updatedRs.Last_Note__c.contains('Second test comment'),
            'Formatted comment should be cleaned and present'
        );
    }

    @IsTest
    static void testBatchSkipsLockedRecords() {

        // ================================
        // Create LOCKED Related Source
        // ================================
        Related_Source__c lockedRs = new Related_Source__c(
           
            Is_Locked__c = true
        );
        insert lockedRs;

        // ================================
        // Execute Batch
        // ================================
        Test.startTest();
        Database.executeBatch(new RelatedSourceLastNoteBatch(), 200);
        Test.stopTest();

        // ================================
        // Verify NOT Updated
        // ================================
        Related_Source__c rsCheck = [
            SELECT Last_Note__c
            FROM Related_Source__c
            WHERE Id = :lockedRs.Id
        ];

        System.assertEquals(
            null,
            rsCheck.Last_Note__c,
            'Locked Related Source must not be updated'
        );
    }
}