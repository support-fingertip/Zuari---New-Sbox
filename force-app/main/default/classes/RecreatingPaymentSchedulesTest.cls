@isTest
public class RecreatingPaymentSchedulesTest {

@isTest
    static void tstingsetup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User user1 = new User(
            Alias = 'Fin',
            Email = 'FinanceUser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'FinanceUser664323@example.com',
            ContactId = null,
            FirstName = 'User',
            LastName = 'One'
        );
        insert user1;
        
        User user2 = new User(
            Alias = 'Leg',
            Email = 'LegalUser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'LegalUser00965@example.com',
            ContactId = null,
            FirstName = 'Legal',
            LastName = 'User'
        );
        insert user2;
        
        User user3 = new User(
            Alias = 'Res',
            Email = 'ReservationUser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'ReservationUser22123@example.com',
            ContactId = null,
            FirstName = 'Reservation',
            LastName = 'User'
        );
        insert user3;
        User user4 = new User(
            Alias = 'CRM',
            Email = 'CRMManager@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'CRMManager665434@example.com',
            ContactId = null,
            FirstName = 'CRM',
            LastName = 'Manager'
        );
        insert user4;
        // Create Projects
        
     

            
            
            
            // Create Booking
            Booking__c booking = new Booking__c(
                Stage__c = 'New'
            );
        insert booking;
        
      
        
        // Create Receipt
        Receipt__c receipt = new Receipt__c(Booking__c = booking.Id,Finance_User__c= user1.Id, Approval_status__c = 'Approved',Receipt_date__c = system.today(),Amount_received__c = 1000);
        insert receipt;
        
        Master_payment_schedule__c mpy = new Master_payment_schedule__c ();
        mpy.Status__c = 'Completed';
        
        Master_payment_schedule__c mpy1 = new Master_payment_schedule__c ();
        mpy1.Status__c = 'Progress';
        
        Payment_schedule__c pys = new Payment_schedule__c();
        pys.Payment_Percent__c=100;
        pys.Payment_Due_Date__c = system.today()-10;
        pys.Booking__c = booking.id;
        pys.Master_Payment_Schedule__c = mpy .Id;
        pys.name ='on booking';
        pys.Interest_Percent__c=20;
        insert pys;
      
        
        // Create Receipt Line Item
        Receipt_Line_Item__c receiptLineItem = new Receipt_Line_Item__c(
            Name = 'Receipt Line Item 1',
            Receipt__c = receipt.Id,
            Booking__c = booking.Id,
            Amount__c = 1000,
            Payment_schedule__c = pys.Id,
            Cheque_no_Transaction_Number__c = '11223555555'
        );
        
        insert receiptLineItem;
        
        
        RecreatingPaymentSchedules.recreateReceipts(booking.Id);
        RecreatingPaymentSchedules.testCoverage();
    }
    
}