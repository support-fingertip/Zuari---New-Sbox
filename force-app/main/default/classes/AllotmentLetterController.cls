public class AllotmentLetterController {
    
    public Booking__c                booking              { get; set; }
    public String                    projectName          { get; set; }
    public String                    projectLogoUrl       { get; set; }
    public String                    unitLabel            { get; set; }
    public String                    grandTotalInWords    { get; set; }
    public String                    totalReceivedInWords { get; set; }
    public String                    pendingAmountInWords { get; set; }
    public Co_Applicant__c           firstCoApplicant     { get; set; }
    public List<Payment_Schedule__c> paymentSchedules     { get; set; }

    private String  bookingId;
    private Boolean addressesLoaded = false;
    private Address permanentAddress;

    // ─── Constructor ──────────────────────────────────────────────────────────
    public AllotmentLetterController(ApexPages.StandardController sc) {

        bookingId = ApexPages.currentPage().getParameters().get('Id');

        if (String.isBlank(bookingId)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 'Booking record Id is missing.'));
            return;
        }

        fetchBookingDetails();
        fetchCoApplicants();
        fetchPaymentSchedules();
        buildWordConversions();
    }

    // ─── Fetch main Booking record ────────────────────────────────────────────
    private void fetchBookingDetails() {
        booking = [
            SELECT  Id,
                    Name,
                    S__c,
                    First_Applicant_Name__c,
                    Booking_Amount__c,
                    GRAND_TOTAL__c,
                    Total_received_Amount__c,
                    Pending_Amount__c,
                    Unit_No__c,
                    Permanent_Address2__c,
                    RecordType.DeveloperName,
                    Quote__r.GRAND_TOTAL__c,
                    Quote__r.Super_Built_UpArea__c,
                    Quote__r.Unit__r.Phase_Detail__c,
                    Quote__r.Unit__r.Tower__c,
                    Quote__r.Unit__r.BHK_Type__c,
                    Project1__r.Name,
                    Project1__r.Project_Logo_Url__c,
                    Project1__r.Project_Type__c,
                    Project1__r.Cheque_Favoring_Name__c,
                    Project1__r.Bank_Name__c,
                    Project1__r.Account_Number__c,
                    Project1__r.Branch__c,
                    Project1__r.IFSC_code__c
            FROM    Booking__c
            WHERE   Id = :bookingId
            LIMIT   1
        ];

        projectName    = booking.Project1__r.Name;
        projectLogoUrl = booking.Project1__r.Project_Logo_Url__c;
        unitLabel      = getUnitLabelFromType(booking.Project1__r.Project_Type__c);
    }

    // ─── Unit Label from Project Type ─────────────────────────────────────────
    // Maps the Project_Type__c picklist value to a human-readable unit label.
    // Add or adjust values below to match your org's picklist entries.
    public static String getUnitLabelFromType(String projectType) {
        if (String.isBlank(projectType)) return 'Unit';

        String pt = projectType.trim().toLowerCase();

        if (pt == 'apartment' || pt == 'flat' || pt == 'residential') {
            return 'Flat';
        } else if (pt == 'plot' || pt == 'plotted development') {
            return 'Plot';
        } else if (pt == 'villa' || pt == 'independent house') {
            return 'Villa';
        } else if (pt == 'commercial') {
            return 'Office';
        } else if (pt == 'shop') {
            return 'Shop';
        } else {
            // Fallback: return the raw value with first letter capitalised
            return projectType.substring(0, 1).toUpperCase()
                   + projectType.substring(1).toLowerCase();
        }
    }

    // ─── Co-applicants ────────────────────────────────────────────────────────
    private void fetchCoApplicants() {
        List<Co_Applicant__c> coApps = [
            SELECT Id, Name, Salutation__c
            FROM   Co_Applicant__c
            WHERE  Booking__c = :bookingId
            ORDER BY CreatedDate ASC
        ];

        if (!coApps.isEmpty()) {
            firstCoApplicant = coApps[0];
        }
    }

    // ─── Payment Schedules ────────────────────────────────────────────────────
    private void fetchPaymentSchedules() {
        paymentSchedules = [
            SELECT Id, Name, S_No__c, Payment_percent__c
            FROM   Payment_Schedule__c
            WHERE  Booking__c = :bookingId
            ORDER BY S_No__c ASC
        ];
    }

    // ─── Number → Words Conversions ───────────────────────────────────────────
    private void buildWordConversions() {
        NumberTOWordConvertion convert = new NumberTOWordConvertion();

        grandTotalInWords    = convertSafe(convert, booking.GRAND_TOTAL__c);
        totalReceivedInWords = convertSafe(convert, booking.Total_received_Amount__c);
        pendingAmountInWords = convertSafe(convert, booking.Pending_Amount__c);
    }

    private String convertSafe(NumberTOWordConvertion convert, Decimal value) {
        if (value == null || value < 0) return 'Zero';
        return convert.getNumberTOWordConvertion(value);
    }

    // ─── Permanent Address ────────────────────────────────────────────────────
    private void loadAddresses() {
        if (addressesLoaded) return;

        Booking__c b = [
            SELECT Permanent_Address2__c
            FROM   Booking__c
            WHERE  Id = :bookingId
            LIMIT  1
        ];

        permanentAddress = b.Permanent_Address2__c;
        addressesLoaded  = true;
    }

    public String getPermanentFullAddress() {
        loadAddresses();
        return formatAddress(permanentAddress);
    }

    private String formatAddress(Address addr) {
        if (addr == null) return '';

        List<String> parts = new List<String>();
        if (!String.isBlank(addr.street))      parts.add(addr.street);
        if (!String.isBlank(addr.city))        parts.add(addr.city);
        if (!String.isBlank(addr.state))       parts.add(addr.state);
        if (!String.isBlank(addr.postalCode))  parts.add(addr.postalCode);
        if (!String.isBlank(addr.country))     parts.add(addr.country);

        return String.join(parts, ', ');
    }
}