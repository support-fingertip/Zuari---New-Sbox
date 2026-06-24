@IsTest
private class QuotePDFControllerExtensionTest {

  @IsTest
    static void testController() {

        // Create test Quote
        Quote__c q = new Quote__c(
            
        );
        insert q;

        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        QuotePDFControllerExtension ext =
            new QuotePDFControllerExtension(sc);

        // Call method to cover logic
        String formatted = ext.formatCurrency(1234.5);
    

       

        Test.stopTest();
    }
}