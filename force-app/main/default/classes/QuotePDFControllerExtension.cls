public class QuotePDFControllerExtension {
    private final Quote__c quote;
    
    public QuotePDFControllerExtension(ApexPages.StandardController stdController) {
        // Add all required fields
        if (!Test.isRunningTest()) { 
        stdController.addFields(new List<String>{'GRAND_TOTAL__c', 'Grand_Total1__c', 'Discount__c', 'SLead__r.Name', 'Project__c', 'BHK_Type__c', 'Unit__r.Name', 'Super_Built_UpArea__c','Carpet_Area__c', 'Balcony_Area_Sq_ft__c', 'Rate_per_sqft__c','Agreement_Value_Before_GST__c', 'GST_On_agreement_Value_Actual__c','Stamp_Paper_Franking_charges__c', 'Water_Electricity_Charges__c','Clubhouse_Charges__c', 'Generator_Charges__c', 'Piped_Gas_Charges__c','Legal_Fees__c', 'Sub_Total_Of_Other_Charges__c','GST_On_Other_Charges_Actual__c', 'Rate_Sq_ft_on_SBUA1__c','Agreement_Value_Before_GST1__c', 'On_Possession__c','Discount_Amount__c', 'Unit__r.Super_Built_up_Area_Sq_Mt__c','Unit__r.Carpet_Area_Sq_mt__c', 'Unit__r.Balcony_Area_Sq_ft__c','Unit__r.Terrace_Area_Sq_ft__c', 'Unit__r.SitOut_Area_Sq_ft__c','Type_of_Car_Parking__c', 'Floor_Rise_Charges_Rate__c','Rate_sq_Ft__c', 'Rate_sq_Ft_Discount__c', 'Base_Value__c','Base_Value_Discount__c', 'Terrace_Value__c', 'Sit_out_Value__c','Agreement_Value_after_GST__c', 'Agreement_Value_after_GST_Discount__c','Other_Charges_after_GST__c', 'Grand_Total_Discount__c','Guideline_Value__c', 'Total_Maintenance_Charge__c','Other_Payables__c', 'On_Booking__c', 'Payment_Required_on_Booking__c','Payment_Required_on_Booking_Discount__c', 'TDS_Amount__c','TDS_Amount_Discount__c', 'Franking_Charges__c','Franking_Charges_Discount__c', 'Balance_Payable__c','Upon_Agreement__c', 'Upon_Agreement_Discount__c', 'On_Possession_Discount__c', 'Block_Lookup__r.Name','Balance_Payable_Discount__c'});
        }
        this.quote = (Quote__c)stdController.getRecord();
    }
    
    // Format any currency field
    public String formatCurrency(Decimal value) {
        if(value == null) return '';
        return  value.setScale(2).format();
    }
    /*
    // Individual getters for all currency fields
    public String formattedGrandTotal { get { return formatCurrency(quote.GRAND_TOTAL__c); } }
    public String formattedDiscountedTotal { get { return formatCurrency(quote.Grand_Total1__c); } }
    public String formattedRatePerSqft { get { return formatCurrency(quote.Rate_per_sqft__c); } }
    public String formattedAgreementValue { get { return formatCurrency(quote.Agreement_Value_Before_GST__c); } }
    public String formattedGSTAgreement { get { return formatCurrency(quote.GST_On_agreement_Value_Actual__c); } }
    public String formattedStampCharges { get { return formatCurrency(quote.Stamp_Paper_Franking_charges__c); } }
    public String formattedWaterElectricity { get { return formatCurrency(quote.Water_Electricity_Charges__c); } }
    public String formattedClubCharges { get { return formatCurrency(quote.Clubhouse_Charges__c); } }
    public String formattedGeneratorCharges { get { return formatCurrency(quote.Generator_Charges__c); } }
    public String formattedGasCharges { get { return formatCurrency(quote.Piped_Gas_Charges__c); } }
    public String formattedLegalFees { get { return formatCurrency(quote.Legal_Fees__c); } }
    public String formattedSubTotal { get { return formatCurrency(quote.Sub_Total_Of_Other_Charges__c); } }
    public String formattedGSTOther { get { return formatCurrency(quote.GST_On_Other_Charges_Actual__c); } }
    public String formattedRatePerSqft1 { get { return formatCurrency(quote.Rate_Sq_ft_on_SBUA1__c); } }
    public String formattedAgreementValue1 { get { return formatCurrency(quote.Agreement_Value_Before_GST1__c); } }
    public String formattedOnPossession { get { return formatCurrency(quote.On_Possession__c); } }
    
    // Additional formatted fields from VF page
    public String formattedFloorRiseCharges { get { return formatCurrency(quote.Floor_Rise_Charges_Rate__c); } }
    public String formattedRateSqFt { get { return formatCurrency(quote.Rate_sq_Ft__c); } }
    public String formattedRateSqFtDiscount { get { return formatCurrency(quote.Rate_sq_Ft_Discount__c); } }
    public String formattedBaseValue { get { return formatCurrency(quote.Base_Value__c); } }
    public String formattedBaseValueDiscount { get { return formatCurrency(quote.Base_Value_Discount__c); } }
    public String formattedTerraceValue { get { return formatCurrency(quote.Terrace_Value__c); } }
    public String formattedSitOutValue { get { return formatCurrency(quote.Sit_out_Value__c); } }
    public String formattedAgreementValueAfterGST { get { return formatCurrency(quote.Agreement_Value_after_GST__c); } }
    public String formattedAgreementValueAfterGSTDiscount { get { return formatCurrency(quote.Agreement_Value_after_GST_Discount__c); } }
    public String formattedOtherChargesAfterGST { get { return formatCurrency(quote.Other_Charges_after_GST__c); } }
    public String formattedGrandTotalDiscount { get { return formatCurrency(quote.Grand_Total_Discount__c); } }
    public String formattedGuidelineValue { get { return formatCurrency(quote.Guideline_Value__c); } }
    public String formattedTotalMaintenanceCharge { get { return formatCurrency(quote.Total_Maintenance_Charge__c); } }
    public String formattedOtherPayables { get { return formatCurrency(quote.Other_Payables__c); } }
    public String formattedOnBooking { get { return formatCurrency(quote.On_Booking__c); } }
    public String formattedPaymentRequiredOnBooking { get { return formatCurrency(quote.Payment_Required_on_Booking__c); } }
    public String formattedPaymentRequiredOnBookingDiscount { get { return formatCurrency(quote.Payment_Required_on_Booking_Discount__c); } }
    public String formattedTDSAmount { get { return formatCurrency(quote.TDS_Amount__c); } }
    public String formattedTDSAmountDiscount { get { return formatCurrency(quote.TDS_Amount_Discount__c); } }
    public String formattedFrankingCharges { get { return formatCurrency(quote.Franking_Charges__c); } }
    public String formattedFrankingChargesDiscount { get { return formatCurrency(quote.Franking_Charges_Discount__c); } }
    public String formattedBalancePayable { get { return formatCurrency(quote.Balance_Payable__c); } }
    public String formattedBalancePayableDiscount { get { return formatCurrency(quote.Balance_Payable_Discount__c); } }
    public String formattedUponAgreement { get { return formatCurrency(quote.Upon_Agreement__c); } }
    public String formattedUponAgreementDiscount { get { return formatCurrency(quote.Upon_Agreement_Discount__c); } }
    public String formattedOnPossessionDiscount { get { return formatCurrency(quote.On_Possession_Discount__c); } }
    */
}