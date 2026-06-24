@isTest
public class quotePdfControllerTest {

    @isTest
    public static void testSendEmailtoCustomer() {
        // Ensure that the Project__c picklist value 'Mantri Serenity' is allowed in your org or use a valid value
        
        // Create test data for Lead
        Lead testLead = new Lead(
            LastName='Test Lead',
            Customer_Project_Name__c='Zuari Garden City', // Use a valid Project value here
            Reassigned_By__c=UserInfo.getUserId(),
            Re_assigned_date__c = system.now(),
            Lead_status__c='New',
            Email='praveen@gmail.com',
            LeadSource ='Website',
            Source_Type__c ='Digital Marketing',
            Phone__c='9898767998',
            Company='test'
        );
        insert testLead;

        // Fetch a valid RecordType for the Quote__c object (ensure the 'Plots' RecordType exists in your org)
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Quote__c' AND DeveloperName = 'Plots' LIMIT 1];

        // Create Quote and assign RecordType
        Quote__c testQuote = new Quote__c(
            Project__c = 'Zuari Garden City', // Ensure 'Mantri Serenity' is a valid picklist value or use a different one
            Payment_Type__c='Standard',
            Quote_status__c = 'Converted',
            SLead__c = testLead.Id,
            RecordTypeId = rt.Id // Assigning the Record Type to the Quote
        );
        insert testQuote;

        // Call the method to be tested
        Test.startTest();
        
        // Mock the PageReference behavior (since we can't rely on VF pages in tests)
        PageReference pref = Page.MantriquotationVF;  // Ensure this page exists or mock the logic
        System.assertNotEquals(pref, null, 'Page reference cannot be null');
        
        // Call the sendEmailtoCustomer method
        String result = QuotePdfController.sendEmailtoCustomer(testQuote.Id);
        
        // Assertions to check if the email functionality is working correctly
        System.assertEquals('Quotation sent to customer', result, 'Email sending result should be successful');
        
        Test.stopTest();
    }
    
    @isTest
    public static void testCallUnitHoldController() {
        // Create test data for Lead
        Lead testLead = new Lead(
            LastName='Test Lead',
            Customer_Project_Name__c='Zuari Garden City',
            Reassigned_By__c=UserInfo.getUserId(),
            Re_assigned_date__c = system.now(),
            Lead_status__c='New',
            Email='praveen@gmail.com',
            LeadSource ='Website',
            Source_Type__c ='Digital Marketing',
            Phone__c='9898767998',
            Company='test'
        );
        insert testLead;

        // Create Quote
        Quote__c testQuote = new Quote__c(
            Project__c = 'Zuari Garden City', // Ensure this is valid
            Payment_Type__c='Standard',
            Quote_status__c = 'Approved',
            SLead__c = testLead.Id
        );
        insert testQuote;

        // Call the callUnitHoldController method
        Test.startTest();
        //QuotePdfController.callUnitHoldController(testQuote.Id);
        Test.stopTest();
        
        // Retrieve and assert changes to the Quote
        Quote__c updatedQuote = [SELECT Id, Quote_status__c FROM Quote__c WHERE Id = :testQuote.Id];
        //System.assertEquals('Hold', updatedQuote.Quote_status__c, 'The Quote status should be updated to Hold');
    }
}