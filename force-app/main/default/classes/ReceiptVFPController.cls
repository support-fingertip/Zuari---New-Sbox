public class ReceiptVFPController {
    public Id receiptId { get; set; }
    public String amountInWords { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public String plotName { get; set; }
    public String permanentFullAddress { get; set; }
    private Boolean bookingAddressesLoaded = false;
    private Id bookingId;
    public List<Receipt_Line_Item__c> receiptLineItems { get; set; }
    public Decimal totalReceivedAmount { get; set; }
    public String projectLogoUrl { get; set; }
    public String unitLabel { get; set; }
    public String projectName { get; set; }
    public String projectAddress { get; set; }
    public String projectGSTNo { get; set; }

    // Constructor
    public ReceiptVFPController(ApexPages.StandardController stdController) {
        receiptId = stdController.getId();

        // Retrieve Receipt record
        Receipt__c receiptRecord = [
            SELECT Total_Received_Amount__c, Bank_Name__c, Booking__c,
                   Booking__r.Plot__r.Name, CreatedDate,
                   Booking__r.Project1__r.Name,
            Booking__r.Project1__r.Project_Address__c,
            Booking__r.Project1__r.GSTIN__c,
                   Booking__r.Project1__r.Project_Logo_Url__c,
                   Booking__r.Project1__r.Project_Type__c
            FROM Receipt__c
            WHERE Id = :receiptId
        ];
        bookingId = receiptRecord.Booking__c;
        projectName = receiptRecord.Booking__r.Project1__r.Name;
        projectAddress = receiptRecord.Booking__r.Project1__r.Project_Address__c;
        projectGSTNo = receiptRecord.Booking__r.Project1__r.GSTIN__c;
        projectLogoUrl = receiptRecord.Booking__r.Project1__r.Project_Logo_Url__c;
        unitLabel = CancellationLetterVFPController.getUnitLabelFromType(receiptRecord.Booking__r.Project1__r.Project_Type__c);

        // Convert number to words
        NumberTOWordConvertion conversion = new NumberTOWordConvertion();
        amountInWords = conversion.getNumberTOWordConvertion(receiptRecord.Total_Received_Amount__c);

        // Plot name assignment
        plotName = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.Plot__r != null)
            ? receiptRecord.Booking__r.Plot__r.Name
            : null;

        // Initialize lists
        receiptLineItems = new List<Receipt_Line_Item__c>();
        totalReceivedAmount = 0;

        // Fetch related data only if Booking exists
        if (receiptRecord.Booking__c != null) {
            // Load addresses
            loadBookingAddresses();
            
            // Co-applicants
            List<Co_Applicant__c> coApplicants = [  
                SELECT Name, Salutation__c, Date_of_Birth__c, Spouse_Date_Of_Birth_coapp__c, Spouse_Name__c,
                       Permanent_Address__c, Communication_Address__c, Pincode_office__c, Other_Qualification__c,
                       Qualification__c, Pincode_commmunication__c, Pincode_permanent__c, Other_Industry__c,
                       Office_Address__c, Anniverssary_Date__c, Son_Daughter_Wife_of__c,
                       Nationality__c, Co_Applicant__c.Aadhar_Number__c, Alternate_Contact_No__c, Country_of_Residence__c,
                       Passport_Number__c, PAN_Number__c, Email__c, Primary_Phone__c, Office_Pincode__c,
                       Residential_Status__c, Profession__c, Industry__c, Employeed_at__c, Designation__c
                FROM Co_Applicant__c 
                WHERE Booking__c = :receiptRecord.Booking__c   
                ORDER BY CreatedDate ASC   
                LIMIT 1  
            ];
            
            if (!coApplicants.isEmpty()) {
                firstCoApplicant = coApplicants[0];
            }
            
            // Receipt line items
            receiptLineItems = [
                SELECT Payment_Type__c, Mode_Of_Payment__c, Cheque_no_Transaction_Number__c, 
                       Received_Amount__c, Branch__c, Drawn_On__c, Bank_Name__c, Payment_schedule__r.Name
                FROM Receipt_Line_Item__c   
                WHERE Booking__c = :receiptRecord.Booking__c AND Receipt__c = :receiptId
            ];

            // Calculate total received amount
            for (Receipt_Line_Item__c item : receiptLineItems) {
                if (item.Received_Amount__c != null) {
                    totalReceivedAmount += item.Received_Amount__c;
                }
            }
        }
    }
    
    public String getPermanentFullAddress() {
        return permanentFullAddress;
    }
   
    private String formatAddress(String street, String city, String state, String postalCode, String country) {
        List<String> parts = new List<String>();
        
        if (!String.isBlank(street))      parts.add(street);
        if (!String.isBlank(city))        parts.add(city);
        if (!String.isBlank(state))       parts.add(state);
        if (!String.isBlank(postalCode))  parts.add(postalCode);
        if (!String.isBlank(country))     parts.add(country);
        
        return String.join(parts, ', ');
    }
    
    private void loadBookingAddresses() {
        if (bookingAddressesLoaded) return;
        
        // Query the address field components instead of the compound field itself
        Booking__c b = [
            SELECT Permanent_Address2__Street__s,
                   Permanent_Address2__City__s,
                   Permanent_Address2__StateCode__s,
                   Permanent_Address2__PostalCode__s
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
        
        // Format the address from components
        permanentFullAddress = formatAddress(
            b.Permanent_Address2__Street__s,
            b.Permanent_Address2__City__s,
            b.Permanent_Address2__StateCode__s,
            b.Permanent_Address2__PostalCode__s,
            null
        );
        
        bookingAddressesLoaded = true;
    }
}