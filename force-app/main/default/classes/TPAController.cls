public with sharing class TPAController {
    public Booking__c booking { get; private set; }
    public String amountInWords { get; private set; }

    public TPAController(ApexPages.StandardController stdController) {
        Id bookingId = stdController.getId();

        if (bookingId == null) {
            booking = new Booking__c();
            amountInWords = 'Amount not available';
            return;
        }

        booking = [
            SELECT Id,
                   Loan_amount__c, Date_of_Birth1__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];

        if (booking.Loan_amount__c != null) {
            NumberTOWordConvertion converter = new NumberTOWordConvertion();
            amountInWords = converter.getNumberTOWordConvertion(booking.Loan_amount__c);
        } else {
            amountInWords = 'Amount not available';
        }
    }

    // Getter to calculate age in years as integer
    public Integer getAge() {
        if (booking == null || booking.Date_of_Birth1__c == null) {
            return null;
        }

        Date dob = booking.Date_of_Birth1__c;
        Date today = Date.today();
        Integer years = today.year() - dob.year();

        // Adjust if the birthday this year hasn't arrived yet
        if (today.month() < dob.month() || 
            (today.month() == dob.month() && today.day() < dob.day())) {
            years--;
        }

        return years;
    }
}