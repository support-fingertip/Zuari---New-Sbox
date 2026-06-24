public with sharing class NOCController {
    public Booking__c booking { get; private set; }
    public String amountInWords { get; private set; }
    public Integer emiMonths { get; private set; } 
    public String projectLogoUrl { get; set; }

    public NOCController(ApexPages.StandardController stdController) {
        Id bookingId = stdController.getId();

        if (bookingId == null) {
            booking = new Booking__c();
            amountInWords = 'Amount not available';
            emiMonths = null;
            return;
        }

        booking = [
            SELECT Id, EMI_Months__c, Date_of_Birth1__c,
                   Quote__r.Total_Sales_Consideration__c,Project1__r.Project_Logo_Url__c,GRAND_TOTAL__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];

        emiMonths = (booking.EMI_Months__c != null) ? Integer.valueOf(booking.EMI_Months__c) : null;
		projectLogoUrl = booking.Project1__r.Project_Logo_Url__c;
        Decimal totalSales = (booking.Quote__r != null) ? booking.Grand_Total__c : null;
        if (totalSales != null) {
            NumberTOWordConvertion converter = new NumberTOWordConvertion();
            amountInWords = converter.getNumberTOWordConvertion(totalSales);
        } else {
            amountInWords = 'Amount not available';
        }
    }

    // Calculated integer age property
    public Integer getAge() {
        if (booking == null || booking.Date_of_Birth1__c == null) {
            return null;
        }
        Date dob = booking.Date_of_Birth1__c;
        Date today = Date.today();
        Integer age = today.year() - dob.year();

        // Adjust if birthday hasn’t occurred yet this year
        if (today.month() < dob.month() || 
            (today.month() == dob.month() && today.day() < dob.day())) {
            age--;
        }

        return age;
    }
}