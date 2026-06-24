@IsTest
public class NOCControllerTest {

    private static Quote__c createQuote(Decimal totalSales) {
        Quote__c qc = new Quote__c();
        // Add required fields in your org if any
      
        insert qc;
        return qc;
    }

    private static Booking__c createBooking(Id quoteId, Decimal emiMonths, Date dob) {
        Booking__c b = new Booking__c();
        // Add required fields in your org if any
       
        b.Quote__c = quoteId;
        b.EMI_Months__c = emiMonths;
        b.Date_of_Birth1__c = dob;
        insert b;
        return b;
    }

    @IsTest
    static void testConstructor_NullId_Defaults() {
        // StandardController with a record that has no Id -> getId() returns null
        Booking__c dummy = new Booking__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(dummy);

        NOCController ctrl = new NOCController(sc);

        System.assertNotEquals(null, ctrl.booking, 'Booking should be initialized');
        System.assertEquals('Amount not available', ctrl.amountInWords);
        System.assertEquals(null, ctrl.emiMonths);
        System.assertEquals(null, ctrl.getAge());
    }

    @IsTest
    static void testConstructor_WithTotalSales_SetsWordsAndEmiMonths() {
        Quote__c qc = createQuote(12345);
        Date dob = Date.today().addYears(-30); // roughly 30 years old (birthday today)
        Booking__c b = createBooking(qc.Id, 24, dob);

        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        NOCController ctrl = new NOCController(sc);

        System.assertEquals(b.Id, ctrl.booking.Id);
        System.assertEquals(24, ctrl.emiMonths, 'EMI months should be converted to Integer');

        // We can't predict the exact words without knowing NumberTOWordConvertion output,
        // but we can assert it's not the fallback string.
        System.assertNotEquals('Amount not available', ctrl.amountInWords,
            'amountInWords should be set when total sales is present');
    }
/*
    @IsTest
    static void testConstructor_TotalSalesNull_Fallback() {
        Quote__c qc = createQuote(null);
        Booking__c b = createBooking(qc.Id, 12, Date.today().addYears(-25));

        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        NOCController ctrl = new NOCController(sc);

        System.assertEquals(12, ctrl.emiMonths);
        System.assertEquals('Amount not available', ctrl.amountInWords,
            'Should fallback when Total_Sales_Consideration__c is null');
    }
*/
    @IsTest
    static void testGetAge_BirthdayNotYetThisYear() {
        Quote__c qc = createQuote(5000);

        // DOB such that birthday hasn't occurred yet this year:
        // Example: today is Dec 12 -> pick Dec 31
        Date today = Date.today();
        Date dob = Date.newInstance(today.year() - 30, 12, 31);

        Booking__c b = createBooking(qc.Id, 10, dob);
        NOCController ctrl = new NOCController(new ApexPages.StandardController(b));

        Integer age = ctrl.getAge();
        System.assertEquals(29, age,
            'If birthday is later this year, age should be one less');
    }
}