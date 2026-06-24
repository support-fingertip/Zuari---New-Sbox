@isTest
public class Demand_Note_send_Controller_Test {
    
    @isTest
    static void testControllerWithGST() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create RecordType for Apartments
        RecordType apartmentRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Booking__c' AND DeveloperName = 'Apartments' LIMIT 1];
        
        // Create Quote__c with GST
        Quote__c quote = new Quote__c(
            Quote_date__c = System.today(),
            With_GST__c = true
           // Agreement_Value_Before_GST__c = 6000000 // > 50 lakhs for TDS
        );
        insert quote;
        
        // Create Booking__c with GST
        Booking__c booking = new Booking__c(
            Bank_Name__c = 'Test Booking',
            Quote__c = quote.Id,
            //GST__c = 18,
            RecordTypeId = apartmentRT.Id
        );
        insert booking;
        
        // Create Payment_schedule__c
        Payment_schedule__c ps = new Payment_schedule__c(
            Name = 'Test Payment Schedule',
            Booking__c = booking.Id,
           Last_Payment_Schedule__c = true
        );
        insert ps;
        
        // Create Demand_Raised__c
        Demand_Raised__c demand = new Demand_Raised__c(
            Demand_Name__c = 'Test Demand',
            Booking__c = booking.Id,
            Payment_schedule__c = ps.Id,
            Current_Demand_amount__c = 118000,
            Grand_Total__c = 118000
          // GST__c = 18
        );
        insert demand;
        
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/Demand_Note_send?Id=' + demand.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(demand);
        Demand_Note_send_Controller controller = new Demand_Note_send_Controller(sc);
        Test.stopTest();
        
    
    }
    
    @isTest
    static void testControllerPlotsLastPayment() {
        // Create RecordType for Plots
        RecordType plotRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Booking__c' AND DeveloperName = 'Plots' LIMIT 1];
        
        // Create Quote__c with GST
        Quote__c quote = new Quote__c(
            Quote_date__c = System.today(),
            With_GST__c = true
            //Agreement_Value_Before_GST__c = 4000000 // < 50 lakhs for TDS test
        );
        insert quote;
        
        // Create Booking__c for Plots
        Booking__c booking = new Booking__c(
            Bank_Name__c = 'Test Booking Plot',
            Quote__c = quote.Id,
          //  GST__c = 18,
            RecordTypeId = plotRT.Id
        );
        insert booking;
        
        // Create Payment_schedule__c - Last Payment
        Payment_schedule__c ps = new Payment_schedule__c(
            Name = 'Test Payment Schedule Last',
            Booking__c = booking.Id
           // Last_Payment_Schedule__c = true
        );
        insert ps;
        
        // Create Demand_Raised__c
        Demand_Raised__c demand = new Demand_Raised__c(
            Demand_Name__c = 'Test Demand Plot',
            Booking__c = booking.Id,
            Payment_schedule__c = ps.Id,
            Current_Demand_amount__c = 50000
        );
        insert demand;
        
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/Demand_Note_send?Id=' + demand.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(demand);
        Demand_Note_send_Controller controller = new Demand_Note_send_Controller(sc);
        Test.stopTest();
        

    }
    
    @isTest
    static void testControllerPlotsNonLastPayment() {
        // Create RecordType for Plots
        RecordType plotRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Booking__c' AND DeveloperName = 'Plots' LIMIT 1];
        
        // Create Quote__c with GST
        Quote__c quote = new Quote__c(
            Quote_date__c = System.today(),
            With_GST__c = true
          //  Agreement_Value_Before_GST__c = 3000000
        );
        insert quote;
        
        // Create Booking__c for Plots
        Booking__c booking = new Booking__c(
            Bank_Name__c = 'Test Booking Plot Regular',
            Quote__c = quote.Id,
           // GST__c = 12,
            RecordTypeId = plotRT.Id
        );
        insert booking;
        
        // Create Payment_schedule__c - NOT Last Payment
        Payment_schedule__c ps = new Payment_schedule__c(
            Name = 'Test Payment Schedule Regular',
            Booking__c = booking.Id
          //  Last_Payment_Schedule__c = false
        );
        insert ps;
        
        // Create Demand_Raised__c
        Demand_Raised__c demand = new Demand_Raised__c(
            Demand_Name__c = 'Test Demand Plot Regular',
            Booking__c = booking.Id,
            Payment_schedule__c = ps.Id,
            Current_Demand_amount__c = 30000
        );
        insert demand;
        
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/Demand_Note_send?Id=' + demand.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(demand);
        Demand_Note_send_Controller controller = new Demand_Note_send_Controller(sc);
        Test.stopTest();
        
      
    }
    
    @isTest
    static void testControllerWithoutGST() {
        // Create Quote__c WITHOUT GST
        Quote__c quote = new Quote__c(
            Quote_date__c = System.today(),
            With_GST__c = false
            //Agreement_Value_Before_GST__c = 2000000
        );
        insert quote;
        
        // Create Booking__c
        Booking__c booking = new Booking__c(
            Bank_Name__c = 'Test Booking No GST',
            Quote__c = quote.Id
        );
        insert booking;
        
        // Create Payment_schedule__c
        Payment_schedule__c ps = new Payment_schedule__c(
            Name = 'Test Payment Schedule',
            Booking__c = booking.Id
        );
        insert ps;
        
        // Create Demand_Raised__c
        Demand_Raised__c demand = new Demand_Raised__c(
            Demand_Name__c = 'Test Demand No GST',
            Booking__c = booking.Id,
            Payment_schedule__c = ps.Id,
            Current_Demand_amount__c = 100000
        );
        insert demand;
        
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/Demand_Note_send?Id=' + demand.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(demand);
        Demand_Note_send_Controller controller = new Demand_Note_send_Controller(sc);
        Test.stopTest();
       
    }
}