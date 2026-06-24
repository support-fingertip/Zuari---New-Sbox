public class DemandInvioceController {
    public Booking__c book {get; set;} 
    public Booking__c booking { get; set; }
    public String bookingId {get; set;}
    public String formattedPin {Get; set;}
    public String paymentscheudlename {Get; set;}
    public String formattedPostalCode {get; set;}
    public Decimal totAmtDueTillPrevMilestone { get; set; }
    public Decimal paidTillPrevMilestone { get; set; }
    public Decimal balanceDueTillPrevMilestone { get; set; }
    public Decimal interestDelayTillPrevious { get; set; }
    public Decimal interestPaidTillPrevious { get; set; }
    public Decimal presentDue { get; set; }
    public Decimal balanceInterest { get; set; }
    public Decimal totalAmountPayable { get; set; }
    public String totalAmountPayableInWords { get; set; }
    public String currentCompletedStage { get; set; }
    public Date currentCompletedStageDate { get; set; }
    public String currentMilestoneNumber { get; set; }
    public String milestoneAmountInWords { get; set; }
    public Date demandDueDate { get; set; }
    public Decimal currentMilestonePaymentPercent { get; set; }
    public Decimal milestonePaymentPercentTill { get; set; }
    public Decimal TDSonePercentage { get; set; }
    public Boolean showGSTBreakdown { get; set; }
    public Decimal appliedGstRate { get; set; }

    public String SANHSNCode { get; set; }

    public Decimal totalAmountWithoutInterest { get; set; }
    public Decimal valueOfSupply { get; set; }
    public Decimal landCost { get; set; }
    public Decimal taxableValue { get; set; }
    public Decimal cgst { get; set; }
    public Decimal sgst { get; set; }
    public Decimal interestAmount { get; set; }
    public String  formattedCurrentDate {get; set;}

    public List<Co_Applicant__c> coapplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public String grandTotalInWords { get; set; }
    public Decimal grandTotalAmount { get; set; }
    public String totalReceivedInWords { get; set; }
    public Decimal totalReceivedAmount { get; set; }
    public String pendingAmountInWords { get; set; }
    public Decimal pendingAmount { get; set; }
    public List<Payment_Schedule__c> paymentSchedules { get; set; }
    public String projectLogoUrl { get; set; }
    public String unitLabel { get; set; }
    public String projectName { get; set; }


    private Boolean bookingAddressesLoaded = false;
    private Address permanentAddress;

    public static Map<Integer, String> daySuffixMap = new Map<Integer, String>{1 => 'st', 2 => 'nd', 3 => 'rd', 21 => 'st', 22 => 'nd', 23 => 'rd', 31 => 'st'};

    public DemandInvioceController(ApexPages.StandardController controller) {

        totAmtDueTillPrevMilestone = 0;
        paidTillPrevMilestone = 0;
        balanceDueTillPrevMilestone = 0;
        interestDelayTillPrevious = 0;
        presentDue = 0;
        totalAmountPayable = 0;
        TDSonePercentage = 0;
        interestPaidTillPrevious = 0;
        totalAmountWithoutInterest = 0;
        valueOfSupply = 0;
        landCost = 0;
        taxableValue = 0;
        cgst = 0;
        sgst = 0;
        appliedGstRate = 0;
        showGSTBreakdown = false;

        DateTime dt = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        formattedCurrentDate = dt.format('MMM dd, yyyy');
        Id bookingRecordId = ApexPages.currentPage().getParameters().get('Id');
        if (bookingRecordId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Booking record Id is null.'));
            return;
        }
        bookingId = bookingRecordId;

        fetchBookingDetails();
        Booking__c book = [SELECT Id, Name, Project__c, Project1__r.Name, GRAND_TOTAL__c, Total_received_Amount__c,
                           Pending_Amount__c, GST__c, Total__c, RecordType.DeveloperName,
                           Quote__r.Agreement_Value_Before_GST__c,
                           Quote__r.GST_For_Other_Charges__c,
                           Quote__r.With_GST__c
                           FROM Booking__c WHERE Id = :bookingRecordId];

        paymentSchedules = [SELECT S_No__c, Name, Payment_percent__c 
                            FROM Payment_Schedule__c 
                            WHERE Booking__c = :bookingRecordId 
                            ORDER BY S_No__c ASC];

        coapplicants = [
            SELECT Name, Salutation__c
            FROM Co_Applicant__c WHERE Booking__c = :bookingId];

        if (!coapplicants.isEmpty()) {
            firstCoApplicant = coapplicants[0];
        }

        NumberTOWordConvertion convert = new NumberTOWordConvertion();

        grandTotalAmount = book.GRAND_TOTAL__c;
        grandTotalInWords = convert.getNumberTOWordConvertion(grandTotalAmount);

        totalReceivedAmount = book.Total_received_Amount__c;
        totalReceivedInWords = convert.getNumberTOWordConvertion(totalReceivedAmount);

        pendingAmount = book.Pending_Amount__c;
        pendingAmountInWords = convert.getNumberTOWordConvertion(pendingAmount);

        apartmentScheduleCalculations(book);
    }

    private void apartmentScheduleCalculations(Booking__c book) {

        list<Payment_Schedule__c> psRecordList = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c, Last_Payment_Schedule__c,
                   Milestone_Amount_Without_GST__c, AmountB__c, SAC_HSN_Code__c,
                   Is_Clubhouse_Charges__c, Is_Infrastructure_Charges__c, Is_Maintenance_Charges__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c = :book.Id
            ORDER BY S_No__c DESC
        ];

        if (psRecordList.isEmpty()) {
            currentCompletedStage = 'No milestone completed';
            currentCompletedStageDate = null;
            demandDueDate = null;
            currentMilestonePaymentPercent = 0;
            currentMilestoneNumber = null;
            totalAmountPayableInWords = 'Zero';

            System.debug('No milestone completed for the booking.');
            return;
        }

        Payment_Schedule__c psRecord = psRecordList[0]; 
        paymentscheudlename = psRecord.Name;
        SANHSNCode = psRecord.SAC_HSN_Code__c;

        if (psRecord != null) {
            currentCompletedStage = psRecord.Name;
            currentCompletedStageDate = psRecord.Completed_Date__c;
            demandDueDate = System.today().addDays(7);
            currentMilestonePaymentPercent = psRecord.Payment_percent__c != null ? psRecord.Payment_percent__c.setScale(0) : 0;

            Decimal stNumber = psRecord.S_No__c;
            if (stNumber != null) {
                currentMilestoneNumber = getMilestoneLabel(stNumber.intValue());
            }

            // Get previous milestones data (excluding current)
            AggregateResult[] aggregateResults = [
                SELECT SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
                SUM(AmountB__c) totalPayableAmount,
                SUM(Interest_Up_to_Date__c) totalInterestUplodate, SUM(Interest_Paid__c) totalInterestPaid,
                SUM(Payment_percent__c) paymentPercentageTill,
                SUM(Received_Amount1__c) totalReceivedAmount
                FROM Payment_Schedule__c
                WHERE Status__c = 'Completed' 
                AND S_No__c < :psRecord.S_No__c 
                AND Booking__c = :book.Id
            ];

            // Get total pending INCLUDING current milestone (from Pending_Amount__c field)
            AggregateResult[] totalPendingIncludingCurrent = [
                SELECT SUM(Pending_Amount__c) totalPendingWithCurrent
                FROM Payment_Schedule__c
                WHERE Status__c = 'Completed' 
                AND S_No__c <= :psRecord.S_No__c 
                AND Booking__c = :book.Id
            ];

            system.debug('aggregateResults' + aggregateResults);
            Decimal totalPendingAmount = 0;
            Decimal totalInterestAmount = 0;
            Decimal totalPayableAmount = 0;
            Decimal totalReceivedAmount = 0;
            Decimal totalInterestUplodateAmount = 0;
            Decimal totalInterestPaid = 0;
            Decimal milestonePaymentPercent = 0;
            Decimal milestonePaymentPercentResult = 0;
            Decimal totalPendingWithCurrent = 0;

            if (!aggregateResults.isEmpty()) {
                totalPendingAmount = (Decimal) aggregateResults[0].get('totalPendingAmount') != null ? (Decimal) aggregateResults[0].get('totalPendingAmount') : 0;
                totalInterestAmount = (Decimal) aggregateResults[0].get('totalInterestAmount') != null ? (Decimal) aggregateResults[0].get('totalInterestAmount') : 0;
                totalPayableAmount = (Decimal) aggregateResults[0].get('totalPayableAmount') != null ? (Decimal) aggregateResults[0].get('totalPayableAmount') : 0;
                totalInterestUplodateAmount = (Decimal) aggregateResults[0].get('totalInterestUplodate') != null ? (Decimal) aggregateResults[0].get('totalInterestUplodate') : 0;
                totalInterestPaid = (Decimal) aggregateResults[0].get('totalInterestPaid') != null ? (Decimal) aggregateResults[0].get('totalInterestPaid') : 0;
                milestonePaymentPercent = aggregateResults[0].get('paymentPercentageTill') != null ? (Decimal) aggregateResults[0].get('paymentPercentageTill') : 0;
                totalReceivedAmount = (Decimal) aggregateResults[0].get('totalReceivedAmount') != null ? (Decimal) aggregateResults[0].get('totalReceivedAmount') : 0;
            }

            if (!totalPendingIncludingCurrent.isEmpty()) {
                totalPendingWithCurrent = (Decimal) totalPendingIncludingCurrent[0].get('totalPendingWithCurrent') != null ? 
                                         (Decimal) totalPendingIncludingCurrent[0].get('totalPendingWithCurrent') : 0;
            }

            totAmtDueTillPrevMilestone = totalPayableAmount;
            interestPaidTillPrevious = totalInterestPaid;
            interestDelayTillPrevious = (totalInterestUplodateAmount > 0) ? (totalInterestUplodateAmount) : totalInterestAmount;

            // Get present due for current milestone - using AmountB__c
            AggregateResult presentDueResult = [
                SELECT SUM(AmountB__c) totalAmountB, SUM(Payment_percent__c) paymentPercentageTill
                FROM Payment_Schedule__c
                WHERE S_No__c = :psRecord.S_No__c
                AND Booking__c = :book.Id
            ];

            Decimal presentDueAmount = 0;
            if (presentDueResult != null && presentDueResult.get('totalAmountB') != null) {
                presentDueAmount = (Decimal) presentDueResult.get('totalAmountB');
            }
            if (presentDueResult != null && presentDueResult.get('paymentPercentageTill') != null) {
                milestonePaymentPercentResult = milestonePaymentPercent + currentMilestonePaymentPercent;
            }

            // Current milestone's own pending = (sum incl current) - (sum of previous)
            Decimal currentMilestonePending = totalPendingWithCurrent - totalPendingAmount;

            // Previous pending from actual Pending_Amount__c field (previous milestones only).
            // Negatives and tiny rounding residuals (e.g. +/- 1) are collapsed to zero.
            balanceDueTillPrevMilestone = cleanAmount(totalPendingAmount);

            milestonePaymentPercentTill = milestonePaymentPercentResult.setScale(0);
            presentDue = nonNegative(presentDueAmount); // AmountB of the current milestone (taxable base, GST excluded)

            // ---------------------------------------------------------------
            // Record type
            // ---------------------------------------------------------------
            Boolean isPlot = (book.RecordType.DeveloperName == 'Plots');

            // TDS Calculation - 1% of current milestone payment percent of Agreement Value Before GST if > 50 lakhs
            Decimal totalSalesConsideration = book.Quote__r.Agreement_Value_Before_GST__c != null ? 
                                             book.Quote__r.Agreement_Value_Before_GST__c : 0;
            TDSonePercentage = totalSalesConsideration > 5000000 ? 
                (totalSalesConsideration * (currentMilestonePaymentPercent / 100) * 0.01).setScale(0) : 0;

            balanceInterest = cleanAmount(interestDelayTillPrevious - interestPaidTillPrevious);

            // Total amount payable = clamped previous pending + clamped current milestone pending.
            // cleanAmount() drops rounding residuals (e.g. the +/- 1 left over on a fully paid milestone).
            totalAmountWithoutInterest = cleanAmount(balanceDueTillPrevMilestone + cleanAmount(currentMilestonePending));

            System.debug('totalAmountWithoutInterest (from Pending_Amount__c): ' + totalAmountWithoutInterest);

            // ---------------------------------------------------------------
            // GST LOGIC
            //   Apartment -> GST on every milestone (rate = Booking.GST__c)
            //   Plots     -> GST only on "other charges":
            //                  Clubhouse / Maintenance -> always taxable
            //                  Infrastructure          -> taxable only if Quote.With_GST__c = true
            //                  rate = Quote.GST_For_Other_Charges__c
            //   GST is calculated ON TOP of AmountB (AmountB is the taxable base).
            // ---------------------------------------------------------------
            Decimal otherChargesGstRate = (book.Quote__r != null && book.Quote__r.GST_For_Other_Charges__c != null)
                                          ? book.Quote__r.GST_For_Other_Charges__c : 0;
            Boolean quoteWithGst = (book.Quote__r != null && book.Quote__r.With_GST__c == true);

            Boolean applyGst = false;
            Decimal gstRateToUse = 0;

            if (isPlot) {
                if (psRecord.Is_Clubhouse_Charges__c == true || psRecord.Is_Maintenance_Charges__c == true) {
                    applyGst = true;
                    gstRateToUse = otherChargesGstRate;
                } else if (psRecord.Is_Infrastructure_Charges__c == true) {
                    // Infrastructure is taxable ONLY when the Quote's With_GST__c is true
                    applyGst = quoteWithGst;
                    gstRateToUse = otherChargesGstRate;
                }
                // else -> pure plot/land cost: applyGst stays false
            } else {
                // Apartment: every milestone is taxable
                applyGst = true;
                gstRateToUse = (book.GST__c != null) ? book.GST__c : 0;
            }

            showGSTBreakdown = applyGst;
            appliedGstRate = applyGst ? gstRateToUse : 0;

            if (showGSTBreakdown) {
                // AmountB (presentDue) is the taxable base; GST is added ON TOP
                taxableValue = presentDue.setScale(2);
                Decimal totalGST = (taxableValue * gstRateToUse / 100).setScale(2);
                cgst = (totalGST / 2).setScale(2);
                sgst = (totalGST / 2).setScale(2);

                // line / current-invoice total now includes GST
                presentDue = (taxableValue + totalGST).setScale(2);

                System.debug('GST Breakdown - Taxable: ' + taxableValue + ', Rate: ' + gstRateToUse
                             + ', CGST: ' + cgst + ', SGST: ' + sgst + ', Total(incl GST): ' + presentDue);
            } else {
                taxableValue = presentDue.setScale(2);
                cgst = 0;
                sgst = 0;

                System.debug('No GST Breakdown - Milestone Value: ' + presentDue);
            }

            totalAmountPayable = totalAmountWithoutInterest;

            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            if (totalAmountPayable != null && totalAmountPayable > -1) {
                totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            }
            if (presentDue != null && presentDue > -1) {
                milestoneAmountInWords = convert.getNumberTOWordConvertion(presentDue);
            }

            System.debug('=== CALCULATION SUMMARY ===');
            System.debug('isPlot: ' + isPlot);
            System.debug('applyGst: ' + applyGst);
            System.debug('appliedGstRate: ' + appliedGstRate);
            System.debug('showGSTBreakdown: ' + showGSTBreakdown);
            System.debug('AmountB (base): ' + taxableValue);
            System.debug('presentDue (incl GST if applicable): ' + presentDue);
            System.debug('Previous Payable: ' + totalPayableAmount);
            System.debug('Previous Received: ' + totalReceivedAmount);
            System.debug('Previous Pending (from field): ' + balanceDueTillPrevMilestone);
            System.debug('Total Pending (All Milestones): ' + totalPendingWithCurrent);
            System.debug('Total Amount Payable: ' + totalAmountPayable);
            System.debug('TDS: ' + TDSonePercentage);
            System.debug('cgst: ' + cgst);
            System.debug('sgst: ' + sgst);
        }
    }

    public static String getMilestoneLabel(Integer sNo) {
        if (sNo == null) {
            return 'Invalid milestone';
        }
        String suffix = daySuffixMap.containsKey(sNo) ? daySuffixMap.get(sNo) : 'th';

        return sNo + suffix;
    }

    // Residual amounts at or below this many rupees are treated as rounding noise (e.g. +/- 1).
    private static final Decimal ROUNDING_TOLERANCE = 10;

    // For gross values (e.g. a milestone's AmountB): only floor negatives to zero.
    private static Decimal nonNegative(Decimal value) {
        return (value == null || value < 0) ? 0 : value;
    }

    // For net "still owed" amounts: floor negatives AND collapse tiny rounding residuals to zero.
    private static Decimal cleanAmount(Decimal value) {
        if (value == null) return 0;
        if (value.abs() <= ROUNDING_TOLERANCE) return 0;
        return value < 0 ? 0 : value;
    }

    public void fetchBookingDetails() {
        booking = [SELECT Id,
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
                   RecordType.DeveloperName,
                   Project1__r.Name,
                   Project1__r.Project_Logo_Url__c,
                   Project1__r.Project_Type__c
                   FROM Booking__c WHERE Id = :bookingId];
        projectName = booking.Project1__r.Name;
        projectLogoUrl = booking.Project1__r.Project_Logo_Url__c;
        unitLabel = CancellationLetterVFPController.getUnitLabelFromType(booking.Project1__r.Project_Type__c);
    }

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

    public String getPermanentFullAddress() {
        loadBookingAddresses();
        return formatAddress(permanentAddress);
    }

    private String formatAddress(Address addr) {
        if (addr == null) return '';

        List<String> parts = new List<String>();

        if (!String.isBlank(addr.street))      parts.add(addr.street);
        if (!String.isBlank(addr.city))        parts.add(addr.city);
        if (!String.isBlank(addr.state))       parts.add(addr.state);
        if (!String.isBlank(addr.postalcode))  parts.add(addr.postalcode);
        if (!String.isBlank(addr.country))     parts.add(addr.country);

        return String.join(parts, ', ');
    }
}