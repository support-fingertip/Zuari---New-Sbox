public class DemandLetterVFP {
    public Id bookingId { get; set; }
    public List<Co_Applicant__c> coApplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public Booking__c book { get; set; }
    public Booking__c booking { get; set; }

    private Boolean bookingAddressesLoaded = false;
    private Address permanentAddress;

    // Constructor to initialize the Apex class with the StandardController parameter
    public DemandLetterVFP(ApexPages.StandardController controller) {
        // Get the record ID from the standard controller
        Additional_Charges__c additionalCharge = (Additional_Charges__c)controller.getRecord();
        
        // Set the bookingId from the related Booking record
        this.bookingId = additionalCharge.Booking__c;
        
        // Fetch booking details
        fetchBookingDetails();
    }

    // Method to fetch the booking details
    public void fetchBookingDetails() {
        if (bookingId == null) {
            throw new AuraHandledException('Booking ID is not provided.');
        }

        List<Booking__c> bookings = [
            SELECT Id,
                   First_Applicant_Name__c,
                   Agreement_Execution_Date__c,
                   S__c,
                   Son_Daughter_Wife_of1__c,
                   PAN_Number__c,
                   Agreement_Executed_Date__c,
                   Aadhar_No__c,
                   Address__c,
                   Date_of_Birth1__c,
                   Son_Daughter_Wife_of__c,
                   Booking_Amount__c,
                   GRAND_TOTAL__c,
                   Permanent_Address1__c,
                   Correspondence_Address__Street__s,
                   Correspondence_Address__City__s,
                   Correspondence_Address__PostalCode__s,
                   Correspondence_Address__StateCode__s,
                   Pincode1__c,
                   Permanent_Address2__c,
                   Plot__c,
                   RecordType.DeveloperName
            FROM Booking__c 
            WHERE Id = :bookingId
            LIMIT 1
        ];

        if (bookings.isEmpty()) {
            throw new AuraHandledException('No Booking found with the provided Booking ID.');
        }
        
        booking = bookings[0];  // Assign the first booking record
    }

    // Method to load the addresses (if not already loaded)
    private void loadBookingAddresses() {
        if (bookingAddressesLoaded) return;

        Booking__c b = [
            SELECT Permanent_Address2__c,
                   Correspondence_Address__c,
                   Office_Address1__c
            FROM Booking__c
            WHERE Id = :booking.Id
            LIMIT 1
        ];

        permanentAddress = b.Permanent_Address2__c;

        bookingAddressesLoaded = true;
    }

    // Method to get the formatted permanent address
    public String getPermanentFullAddress() {
        loadBookingAddresses();
        return formatAddress(permanentAddress);
    }

    // Helper method to format the address
    private String formatAddress(Address addr) {
        if (addr == null) return '';
        
        List<String> parts = new List<String>();

        if (!String.isBlank(addr.street))  parts.add(addr.street);
        if (!String.isBlank(addr.city))    parts.add(addr.city);
        if (!String.isBlank(addr.state))   parts.add(addr.state);
        if (!String.isBlank(addr.postalcode)) parts.add(addr.postalcode);
        if (!String.isBlank(addr.country)) parts.add(addr.country);

        return String.join(parts, ', ');
    }
}