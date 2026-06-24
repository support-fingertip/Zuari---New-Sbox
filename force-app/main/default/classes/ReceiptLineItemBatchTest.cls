@isTest
private class ReceiptLineItemBatchTest {

    @isTest
    static void testBatchExecutes() {

        Booking__c booking = new Booking__c();
        insert booking;

        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Booking__c          = booking.Id;
        ps.S_No__c             = 1;
        insert ps;

        Receipt__c rc             = new Receipt__c();
        rc.Booking__c             = booking.Id;
        rc.Manual_Upload__c       = true;
        rc.Receipt_Date__c        = Date.newInstance(2024, 1, 1);
        rc.Amount_Received__c     = 50000;
        rc.Mode_Of_Payment__c     = 'NEFT';
        rc.Check_Transaction_Nmber__c = 'TXN001';
        insert rc;

        Test.startTest();
        Database.executeBatch(new ReceiptLineItemBatch(), 10);
        Test.stopTest();
    }

    @isTest
    static void testBatchWithMultipleReceipts() {

        Booking__c booking = new Booking__c();
        insert booking;

        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Booking__c          = booking.Id;
        ps.S_No__c             = 1;
        insert ps;

        Date baseDate = Date.newInstance(2024, 1, 1);
        List<Receipt__c> receipts = new List<Receipt__c>();
        for (Integer i = 0; i < 3; i++) {
            Receipt__c rc             = new Receipt__c();
            rc.Booking__c             = booking.Id;
            rc.Manual_Upload__c       = true;
            rc.Receipt_Date__c        = baseDate.addDays(i);
            rc.Amount_Received__c     = 10000;
            rc.Mode_Of_Payment__c     = 'Cheque';
            rc.Check_Transaction_Nmber__c = 'TXN00' + i;
            rc.Cheque_Date__c         = baseDate.addDays(i);
            receipts.add(rc);
        }
        insert receipts;

        Test.startTest();
        Database.executeBatch(new ReceiptLineItemBatch(), 10);
        Test.stopTest();
    }

    @isTest
    static void testBatchNoReceipts() {

        Booking__c booking = new Booking__c();
        insert booking;

        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Booking__c          = booking.Id;
        ps.S_No__c             = 1;
        insert ps;

        Test.startTest();
        Database.executeBatch(new ReceiptLineItemBatch(), 10);
        Test.stopTest();
    }

    @isTest
    static void testBatchNoSchedules() {

        Booking__c booking = new Booking__c();
        insert booking;

        Receipt__c rc             = new Receipt__c();
        rc.Booking__c             = booking.Id;
        rc.Manual_Upload__c       = true;
        rc.Receipt_Date__c        = Date.newInstance(2024, 1, 1);
        rc.Amount_Received__c     = 10000;
        rc.Mode_Of_Payment__c     = 'Cheque';
        insert rc;

        Test.startTest();
        Database.executeBatch(new ReceiptLineItemBatch(), 10);
        Test.stopTest();
    }

    @isTest
    static void testBatchMultipleBookings() {

        List<Booking__c> bookings = new List<Booking__c>{
            new Booking__c(),
            new Booking__c()
        };
        insert bookings;

        List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>{
            new Payment_Schedule__c(Booking__c = bookings[0].Id, S_No__c = 1),
            new Payment_Schedule__c(Booking__c = bookings[1].Id, S_No__c = 1)
        };
        insert schedules;

        List<Receipt__c> receipts = new List<Receipt__c>{
            new Receipt__c(Booking__c = bookings[0].Id, Manual_Upload__c = true,
                           Receipt_Date__c = Date.newInstance(2024, 1, 1),
                           Amount_Received__c = 20000, Mode_Of_Payment__c = 'NEFT'),
            new Receipt__c(Booking__c = bookings[1].Id, Manual_Upload__c = true,
                           Receipt_Date__c = Date.newInstance(2024, 1, 1),
                           Amount_Received__c = 30000, Mode_Of_Payment__c = 'NEFT')
        };
        insert receipts;

        Test.startTest();
        Database.executeBatch(new ReceiptLineItemBatch(), 10);
        Test.stopTest();
    }
}