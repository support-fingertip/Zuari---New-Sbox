@isTest
private class DataUpdateBatchTest {
    
    @TestSetup
    static void setupData() {
        // Create test bookings - adjust required fields based on your Booking__c schema
        List<Booking__c> bookings = new List<Booking__c>();
        for (Integer i = 0; i < 10; i++) {
            bookings.add(new Booking__c(

            ));
        }
        insert bookings;
    }
    
    @isTest
    static void testBatchExecution() {
        // Verify setup data exists
        List<Booking__c> bookings = [SELECT Id, CreatedById FROM Booking__c];
        System.assertEquals(10, bookings.size(), 'Test bookings should be created');
        
        Test.startTest();
        DataUpdateBatch batch = new DataUpdateBatch();
        Id jobId = Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify job completed
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob 
            WHERE Id = :jobId
        ];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
    }
    
    @isTest
    static void testBatchWithNoRecords() {
        // Delete all bookings to test empty scope
        delete [SELECT Id FROM Booking__c];
        
        Test.startTest();
        DataUpdateBatch batch = new DataUpdateBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Batch should run without errors even with no records
        AsyncApexJob job = [
            SELECT Status FROM AsyncApexJob 
            WHERE JobType = 'BatchApex' 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        System.assertEquals('Completed', job.Status);
    }
}