public class ZGTstatementOfAccountsController {
    
    public Booking__c booking { get; set; }
    public String permanentFullAddress { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public String projectName { get; set; }
    public String projectLogoUrl { get; set; }
    public String unitLabel { get; set; }
    public List<Receipt__c> receiptList { get; set; }
    public Decimal totalReceiptAmount { get; set; }
    
    public List<Payment_Schedule__c> paymentScheduleList { get; set; }
    public Map<Id, Receipt_Line_Item__c> receiptLineItemMap { get; set; }
    public Decimal totalCostOfFlat { get; set; }
    public Decimal totalOtherCharges { get; set; }
    
    public ZGTstatementOfAccountsController(ApexPages.StandardController stdController) {
        Id bookingId = stdController.getId();
        
        booking = [
            SELECT Id, Name, First_Applicant_Name__c, S__c, Son_Daughter_Wife_of1__c,
            Mobile__c, Email__c, Aadhar_No__c, PAN_Number__c,
            Booking_Date__c, Agreement_Executed_Date__c, Agreement_Value__c, GRAND_TOTAL__c,
            Plot__r.Name, Plot__r.Block_Lookup__c, Plot__r.Carpet_Area_in_SqMtrs__c,
            Plot__r.Block_Lookup__r.Name, Plot__r.Carpet_Area__c, Plot__r.Floor__c,
            Plot__r.BHK_Type__c, Plot__r.Phase_Detail__c, Plot__r.Super_Built_up_Area_Sq_Mt__c,Plot__r.Super_Built_up_Area__c,
            Plot__r.Carpet_Area_in_SFT__c,Project1__r.Name, Project1__r.Project_Logo_Url__c, Project1__r.Project_Type__c,
            Quote__r.Total_Sales_Consideration__c,
           // Quote__r.Grand_Total__c,
            Quote__r.GRAND_TOTAL__c,
            Quote__r.GST_for_Agreement_value_Formula__c,
            Quote__r.GST_On_agreement_Value_Actual__c,
            Quote__r.GST_for_other_charges_Formula__c,
            Quote__r.GST_On_Other_Charges_Actual__c,
            Quote__r.Total_Other_Charges__c,
            Quote__r.Total_Maintenance_Amount__c,
            Quote__r.Legal_Documentation_Charges__c,
            Quote__r.Total_Corpus_Fund__c,
            Correspondence_Address__c,
            Permanent_Address2__Street__s, Permanent_Address2__City__s,
            Permanent_Address2__StateCode__s, Permanent_Address2__PostalCode__s,
            Permanent_Address2__CountryCode__s
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
        
        Decimal agreementValue = booking.Agreement_Value__c != null ? booking.Agreement_Value__c : 0;
        Decimal gstAgreementPercent = booking.Quote__r.GST_for_Agreement_value_Formula__c != null ? booking.Quote__r.GST_for_Agreement_value_Formula__c : 0;
        Decimal otherCharges = booking.Quote__r.Total_Other_Charges__c != null ? booking.Quote__r.Total_Other_Charges__c : 0;
        Decimal gstOtherPercent = booking.Quote__r.GST_for_other_charges_Formula__c != null ? booking.Quote__r.GST_for_other_charges_Formula__c : 0;
        
        Decimal gstOnAgreement = agreementValue * (gstAgreementPercent / 100);
        Decimal gstOnOther = otherCharges * (gstOtherPercent / 100);
        
        totalCostOfFlat = agreementValue + gstOnAgreement + otherCharges + gstOnOther;

        // Total Other Charges = Maintenance + Legal Documentation + Corpus Fund
        Decimal maintenanceAmt = booking.Quote__r.Total_Maintenance_Amount__c != null ? booking.Quote__r.Total_Maintenance_Amount__c : 0;
        Decimal legalDocAmt = booking.Quote__r.Legal_Documentation_Charges__c != null ? booking.Quote__r.Legal_Documentation_Charges__c : 0;
        Decimal corpusFundAmt = booking.Quote__r.Total_Corpus_Fund__c != null ? booking.Quote__r.Total_Corpus_Fund__c : 0;
        totalOtherCharges = maintenanceAmt + legalDocAmt + corpusFundAmt;
        
        projectName = booking.Project1__r.Name;
        projectLogoUrl = booking.Project1__r.Project_Logo_Url__c;
        unitLabel = CancellationLetterVFPController.getUnitLabelFromType(booking.Project1__r.Project_Type__c);
        
        String stateFull = getStateFullName(booking.Permanent_Address2__StateCode__s);
        String countryFull = getCountryFullName(booking.Permanent_Address2__CountryCode__s);
        
        permanentFullAddress = formatAddress(
            booking.Permanent_Address2__Street__s,
            booking.Permanent_Address2__City__s,
            booking.Permanent_Address2__PostalCode__s,
            stateFull,
            countryFull
        );
        
        // Fetch Payment Schedule
        paymentScheduleList = [
            SELECT S_No__c, Name, Payment_percent__c, Total_Payable_Amount__c, Received_Amount1__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId
            ORDER BY S_No__c ASC
        ];
        
        // Fetch Receipts
        totalReceiptAmount = 0;
        receiptList = [
            SELECT Id, Name, Check_Transaction_Nmber__c,
            Bank_Name__c, Receipt_Date__c, Total_Received_Amount__c
            FROM Receipt__c
            WHERE Booking__c = :bookingId
            ORDER BY Receipt_Date__c ASC
        ];
        
        for (Receipt__c r : receiptList) {
            if (r.Total_Received_Amount__c != null) {
                totalReceiptAmount += r.Total_Received_Amount__c;
            }
        }
        
        // Fetch Receipt Line Items
        receiptLineItemMap = new Map<Id, Receipt_Line_Item__c>();
        List<Receipt_Line_Item__c> lineItems = [
            SELECT Id, Receipt__c, Bank_Name__c
            FROM Receipt_Line_Item__c
            WHERE Receipt__c IN :receiptList
            ORDER BY CreatedDate ASC
        ];
        
        for (Receipt_Line_Item__c rli : lineItems) {
            if (!receiptLineItemMap.containsKey(rli.Receipt__c)) {
                receiptLineItemMap.put(rli.Receipt__c, rli);
            }
        }
        
        // Fetch first co-applicant
        List<Co_Applicant__c> coApplicants = [
            SELECT Name, Salutation__c, Son_Daughter_Wife_of__c,
            Primary_Phone__c, Email__c, PAN_Number__c, Aadhar_Number__c,
            Permanent_Address__c, Communication_Address__c
            FROM Co_Applicant__c
            WHERE Booking__c = :bookingId
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        
        if (!coApplicants.isEmpty()) {
            firstCoApplicant = coApplicants[0];
        }
    }
    
    public String getPermanentFullAddress() {
        return permanentFullAddress;
    }
    
    private String formatAddress(String street, String city, String postalCode, String state, String country) {
        String result = '';
        if (!String.isBlank(street)) result += street + ',\n';
        if (!String.isBlank(city) || !String.isBlank(postalCode)) {
            String cityLine = '';
            if (!String.isBlank(city)) cityLine += city;
            if (!String.isBlank(postalCode)) cityLine += ' ' + postalCode;
            result += cityLine + ',\n';
        }
        if (!String.isBlank(state)) result += state + ',\n';
        if (!String.isBlank(country)) result += country;
        return result;
    }
    
    private String getStateFullName(String stateCode) {
        if (String.isBlank(stateCode)) return '';
        Map<String, String> stateMap = new Map<String, String>{
            'AN' => 'Andaman and Nicobar Islands', 'AP' => 'Andhra Pradesh', 'AR' => 'Arunachal Pradesh',
                'AS' => 'Assam', 'BR' => 'Bihar', 'CH' => 'Chandigarh', 'CT' => 'Chhattisgarh',
                'DD' => 'Daman and Diu', 'DL' => 'Delhi', 'DN' => 'Dadra and Nagar Haveli',
                'GA' => 'Goa', 'GJ' => 'Gujarat', 'HP' => 'Himachal Pradesh', 'HR' => 'Haryana',
                'JH' => 'Jharkhand', 'JK' => 'Jammu and Kashmir', 'KA' => 'Karnataka', 'KL' => 'Kerala',
                'LA' => 'Ladakh', 'LD' => 'Lakshadweep', 'MH' => 'Maharashtra', 'ML' => 'Meghalaya',
                'MN' => 'Manipur', 'MP' => 'Madhya Pradesh', 'MZ' => 'Mizoram', 'NL' => 'Nagaland',
                'OR' => 'Odisha', 'PB' => 'Punjab', 'PY' => 'Puducherry', 'RJ' => 'Rajasthan',
                'SK' => 'Sikkim', 'TN' => 'Tamil Nadu', 'TS' => 'Telangana', 'TR' => 'Tripura',
                'UK' => 'Uttarakhand', 'UP' => 'Uttar Pradesh', 'WB' => 'West Bengal'
                };
                    return stateMap.containsKey(stateCode.toUpperCase()) ? stateMap.get(stateCode.toUpperCase()) : stateCode;
    }
    
    private String getCountryFullName(String countryCode) {
        if (String.isBlank(countryCode)) return '';
        Map<String, String> countryMap = new Map<String, String>{
            'IN' => 'India', 'US' => 'United States', 'GB' => 'United Kingdom',
                'AE' => 'United Arab Emirates', 'SG' => 'Singapore', 'AU' => 'Australia',
                'CA' => 'Canada', 'DE' => 'Germany', 'FR' => 'France', 'JP' => 'Japan',
                'SA' => 'Saudi Arabia', 'QA' => 'Qatar', 'KW' => 'Kuwait', 'OM' => 'Oman',
                'BH' => 'Bahrain', 'MY' => 'Malaysia', 'NZ' => 'New Zealand'
                };
                    return countryMap.containsKey(countryCode.toUpperCase()) ? countryMap.get(countryCode.toUpperCase()) : countryCode;
    }
}