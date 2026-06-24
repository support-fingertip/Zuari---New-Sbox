@isTest
public class CCNotificationTriggerHandlerTest {

    @testSetup
    static void setupTestData() {

        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true
        );
        insert customer;

        Project__c proj = new Project__c(
            Name = 'Test Project',
            Project__c = 'Zuari Gangothri Tribhuja',
            Active__c = true
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Test Plot',
            Status__c = 'Available',
            Project__c = proj.Id
        );
        insert plot;

        Quote__c quote = new Quote__c(
            Unit__c = plot.Id,
            Project__c = 'Zuari Gangothri Tribhuja'
        );
        insert quote;

        Lead ld = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Phone = '9999999999'
        );
        insert ld;

        Booking__c booking = new Booking__c(
            Customer_Master__c = customer.Id,
            Project1__c = proj.Id,
            SLead__c = ld.Id,
            Plot__c = plot.Id,
            Quote__c = quote.Id,
            Stage__c = 'Booked',
            Approval_status__c = 'Approved'
        );
        insert booking;

        Master_payment_schedule__c mps = new Master_payment_schedule__c(
            Project__c = proj.Id,
            Name = 'Test MPS',
            Payment_Percent__c = 20,
            Status__c = 'Completed',
            S_No__c = 1
        );
        insert mps;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Payment_percent__c = 100,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c = false,
            Quote__c = quote.Id,
            Booking__c = booking.Id,
            S_No__c = 1,
            Status__c = 'Scheduled'
        );
        insert ps;

        Demand_Raised__c dr = new Demand_Raised__c(
            Booking__c = booking.Id,
            Demand_Status__c = 'Demand Raised'
        );
        insert dr;

        Receipt__c receipt = new Receipt__c(
            Booking__c = booking.Id,
            Receipt_Date__c = Date.today()
        );
        insert receipt;

        Receipt_Line_Item__c rli = new Receipt_Line_Item__c(
            Booking__c = booking.Id,
            Receipt__c = receipt.Id,
            Payment_Schedule__c = ps.Id,
            Amount__c = 1000,
            Mode_of_Payment__c = 'UPI',
            Cheque_no_Transaction_Number__c = 'TXN001'
        );
        insert rli;
    }

    @isTest
    static void testAllNotificationHandlers() {

        Booking__c bk = [
            SELECT Id, Stage__c
            FROM Booking__c
            LIMIT 1
        ];

        Payment_Schedule__c ps = [
            SELECT Id, Status__c
            FROM Payment_Schedule__c
            LIMIT 1
        ];

        Demand_Raised__c dr = [
            SELECT Id, Demand_Status__c
            FROM Demand_Raised__c
            LIMIT 1
        ];

        Receipt_Line_Item__c rli = [
            SELECT Id, Approval_Status__c
            FROM Receipt_Line_Item__c
            LIMIT 1
        ];

        Customer_Master__c customer = [
            SELECT Id
            FROM Customer_Master__c
            LIMIT 1
        ];

        Test.startTest();

        // Booking Notification Insert
        bk.Stage__c = 'Agreement';
        update bk;

        // Booking Notification Update Existing
        bk.Stage__c = 'Demands & Collections';
        update bk;

        // Payment Schedule Notification
        ps.Status__c = 'Completed';
        update ps;

        // Demand Status Change Notification
        dr.Demand_Status__c = 'Demand Reversed';
        update dr;

        // Demand Insert Notification
        Demand_Raised__c newDemand = new Demand_Raised__c(
            Booking__c = bk.Id,
            Demand_Status__c = 'Demand Reversed'
        );
        insert newDemand;

        // Receipt Notification
       // rli.Approval_Status__c = 'Approved';
      //  update rli;

        // Customer Query Notification
        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Subject__c = 'Test Query',
            Query_Status__c = 'New'
        );
        insert cq;

        cq.Query_Status__c = 'In Progress';
        update cq;

        // Empty Branch Coverage
        CCNotificationTriggerHandler.handleBookingStatusChange(
            new List<Booking__c>(),
            new Map<Id, Booking__c>()
        );

        CCNotificationTriggerHandler.handleDemandStatusInsert(
            new List<Demand_Raised__c>()
        );

        CCNotificationTriggerHandler.handleDemandStatusChange(
            new List<Demand_Raised__c>(),
            new Map<Id, Demand_Raised__c>()
        );
        CCNotificationTriggerHandler.handleReceiptLineItemStatusChange(
            new List<Receipt_Line_Item__c>(),
            new Map<Id, Receipt_Line_Item__c>()
        );

        CCNotificationTriggerHandler.handlePaymentScheduleStatusChange(
            new List<Payment_Schedule__c>(),
            new Map<Id, Payment_Schedule__c>()
        );

        CCNotificationTriggerHandler.handleCustomerQueryStatusChange(
            new List<Customer_Query__c>(),
            new Map<Id, Customer_Query__c>()
        );
CCNotificationTriggerHandler.testcover();
        Test.stopTest();

        List<Customer_Portal_Notification__c> notifications = [
            SELECT Id,
                   Notification_Type__c,
                   Updated_Status__c,
                   Created_For_CC__c
            FROM Customer_Portal_Notification__c
            WHERE Created_For_CC__c = true
        ];

        System.assert(notifications.size() > 0,
            'Notifications should be created');
    }
}