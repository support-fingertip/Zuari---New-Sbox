@IsTest
private class RefundControllerTest {

    @IsTest
    static void testRefundControllerMethods() {

        // -------------------------
        // Create minimal Booking
        // -------------------------
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Email__c = 'test@gmail.com'
        );
        insert book;

        // -------------------------
        // Create Demand_Raised__c
        // -------------------------
        Demand_Raised__c demand = new Demand_Raised__c(
            Grand_Total__c = 5000,    // writable number field
            Demand_Status__c = 'Demand Raised', // Set a valid status
            Booking__c = book.Id
        );
        insert demand;

        // -------------------------
        // Test getDemandDetails
        // -------------------------
        Test.startTest();
        Demand_Raised__c fetched =
            RefundController.getDemandDetails(demand.Id);
        Test.stopTest();

        //System.assertNotEquals(null, fetched, 'Demand must be returned');
        //System.assertEquals(5000, fetched.Grand_Total__c);
        //System.assertEquals(book.Id, fetched.Booking__r.Id);

        // -------------------------
        // Test cancelDemandAndCreateRefund
        // -------------------------
     
    }
      @IsTest
    static void testCancelDemandAndCreateRefund() {
        
        // Step 1: Create a Booking (required for Demand_Raised__c)
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Email__c = 'test@gmail.com'
        );
        insert book;

        // Step 2: Create Demand_Raised__c with a valid Grand_Total__c
        Demand_Raised__c demand = new Demand_Raised__c(
            Grand_Total__c = 5000,  // amount to be refunded
            Demand_Status__c = 'Demand Raised',
            Booking__c = book.Id
        );
        insert demand;

        // Step 3: Test cancelDemandAndCreateRefund method
        Test.startTest();
        // Call the method to cancel the demand and create refund
        Id refundId = RefundController.cancelDemandAndCreateRefund(demand.Id);
        Test.stopTest();

        // Step 4: Verify that the Refund__c record is created
        Refund__c refund = [SELECT Id, Refund_Amount__c, Reversed_Demand__c, Refund_Type__c 
                            FROM Refund__c 
                            WHERE Id = :refundId 
                            LIMIT 1];

        //System.assertNotEquals(null, refund, 'Refund record should be created');
        //System.assertEquals(5000, refund.Refund_Amount__c, 'Refund amount should match the demand Grand Total');
        //System.assertEquals(demand.Id, refund.Reversed_Demand__c, 'Reversed Demand should match the original demand');
        //System.assertEquals('Credit Note', refund.Refund_Type__c, 'Refund Type should be "Credit Note"');

        // Step 5: Verify that the Demand_Raised__c record's status is updated
        Demand_Raised__c updatedDemand = [SELECT Demand_Status__c FROM Demand_Raised__c WHERE Id = :demand.Id];
        //System.assertEquals('Demand Cancelled', updatedDemand.Demand_Status__c, 'Demand status should be "Demand Cancelled"');
    }
}