@isTest
public class getQuoteDataTest {
    
    @testSetup
    static void setupData() {
        // Create a Quote record
        Quote__c quote = new Quote__c(
         
        );
        insert quote;
        
        // Create related Payment Schedule records
        List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>();
        schedules.add(new Payment_Schedule__c(
            Name = 'PS1',
            Quote__c = quote.Id,
            Payment_percent__c = 40,
            S_No__c = 1
        ));
        schedules.add(new Payment_Schedule__c(
            Name = 'PS2',
            Quote__c = quote.Id,
            Payment_percent__c = 60,
            S_No__c = 2
        ));
        insert schedules;
    }
    
    @isTest
    static void testGetQuoteDataConstructor() {
        // Fetch test data
        Quote__c testQuote = [SELECT Id FROM Quote__c LIMIT 1];
        
        // Simulate passing ID via page parameter
        Test.setCurrentPage(Page.Costsheet); // Replace with actual VF page name
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate the controller
        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        getQuoteData controller = new getQuoteData(sc);
        
    }
}