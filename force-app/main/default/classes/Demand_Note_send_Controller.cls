public class Demand_Note_send_Controller {
    public Decimal cgst { get; set; }
    public Decimal sgst { get; set; }
    public Decimal taxableValue { get; set; }
    public String demandId { get; set; }
    public Demand_Raised__c demand { get; set; }
    public Decimal TDSonePercentage { get; set; }
    public Boolean showGSTBreakdown { get; set; }
    
    public String SANHSNCode { get; set; }
    
    public Demand_Note_send_Controller(ApexPages.StandardController controller) {
        TDSonePercentage = 0;
        taxableValue = 0;
        cgst = 0;
        sgst = 0;
        showGSTBreakdown = false;
        
        demandId = ApexPages.currentPage().getParameters().get('Id');
        
        List<Demand_Raised__c> dmList = [
            SELECT Id, Grand_Total__c, GST__c, Current_Demand_amount__c, Milestone_Percentage__c,
            Booking__r.Quote__r.With_GST__c, Booking__r.Quote__r.Agreement_Value_Before_GST__c, 
            Booking__r.GST__c, Booking__r.RecordType.DeveloperName,
            Payment_schedule__r.Last_Payment_Schedule__c,
            Payment_schedule__r.AmountB__c,
            Payment_schedule__r.Milestone_Amount_Without_GST__c,Payment_schedule__r.SAC_HSN_Code__c
            FROM Demand_Raised__c 
            WHERE Id = :demandId 
            LIMIT 1
        ];
        
        System.debug('dmList: ' + dmList);
        
        if (!dmList.isEmpty()) {
            demand = dmList[0];
            SANHSNCode = demand.Payment_schedule__r.SAC_HSN_Code__c;
            // FIXED: Get both amounts
            Decimal presentDue = demand.Current_Demand_amount__c != null ? demand.Current_Demand_amount__c : 0;
            Decimal milestoneAmountWithoutGST = demand.Payment_schedule__r.Milestone_Amount_Without_GST__c != null ? 
                                               demand.Payment_schedule__r.Milestone_Amount_Without_GST__c : 0;
            
            Decimal gstPercentage = (demand.Booking__r.GST__c != null) ? demand.Booking__r.GST__c / 100 : 0;
            Decimal currentMilestonePaymentPercent = demand.Milestone_Percentage__c != null ? demand.Milestone_Percentage__c : 0;
            
            Boolean isPlot = (demand.Booking__r.RecordType.DeveloperName == 'Plots');
            Boolean isLastPayment = (demand.Payment_schedule__r.Last_Payment_Schedule__c == true);
            Boolean hasGST = (demand.Booking__r.Quote__r.With_GST__c == true);
            
            // FIXED: Match DemandInvoiceController logic
            // Calculate taxable value and GST for CURRENT MILESTONE only
            // GST breakdown should ONLY show on LAST PAYMENT for both Plots and Apartments
            if (presentDue != null && presentDue > 0) {
                if (isLastPayment ) {
                    // Only process GST breakdown on last payment with GST
                    showGSTBreakdown = false;
                    
                    if (isPlot) {
                        // For Plots: Show GST breakdown on last payment
                        showGSTBreakdown = true;
                    } else {
                        // For Apartments: Show GST breakdown on last payment
                        showGSTBreakdown = true;
                    }
                    
                    if (showGSTBreakdown) {
                        // Calculate GST breakdown
                        // presentDue (AmountB__c) includes GST on last payment
                        // Reverse calculate to get base amount
                        taxableValue = demand.Payment_schedule__r.Milestone_Amount_Without_GST__c;
                        cgst = ((demand.Payment_schedule__r.AmountB__c - demand.Payment_schedule__r.Milestone_Amount_Without_GST__c) / 2).setScale(2);
                        sgst = ((demand.Payment_schedule__r.AmountB__c - demand.Payment_schedule__r.Milestone_Amount_Without_GST__c) / 2).setScale(2);
                        
                        // Validation: taxableValue should match milestoneAmountWithoutGST
                        System.debug('Calculated taxableValue: ' + taxableValue);
                        System.debug('Milestone_Amount_Without_GST__c: ' + milestoneAmountWithoutGST);
                    } else {
                        // No GST breakdown
                        taxableValue = milestoneAmountWithoutGST;
                        cgst = 0;
                        sgst = 0;
                    }
                } else {
                    // Not last payment OR no GST - no GST breakdown
                    // AmountB__c = Milestone_Amount_Without_GST__c in this case
                    taxableValue = milestoneAmountWithoutGST;
                    cgst = 0;
                    sgst = 0;
                }
            } else {
                // No present due amount
                taxableValue = 0;
                cgst = 0;
                sgst = 0;
            }
            
            // TDS Calculation - 1% of current milestone payment percent of Agreement Value Before GST if > 50 lakhs
            Decimal totalSalesConsideration = demand.Booking__r.Quote__r.Agreement_Value_Before_GST__c != null ? 
                                             demand.Booking__r.Quote__r.Agreement_Value_Before_GST__c : 0;
            TDSonePercentage = totalSalesConsideration > 5000000 ? 
                (totalSalesConsideration * (currentMilestonePaymentPercent / 100) * 0.01).setScale(0) : 0;
            
            System.debug('isPlot: ' + isPlot);
            System.debug('isLastPayment: ' + isLastPayment);
            System.debug('hasGST: ' + hasGST);
            System.debug('showGSTBreakdown: ' + showGSTBreakdown);
            System.debug('presentDue (AmountB__c): ' + presentDue);
            System.debug('milestoneAmountWithoutGST: ' + milestoneAmountWithoutGST);
            System.debug('taxableValue: ' + taxableValue);
            System.debug('cgst: ' + cgst);
            System.debug('sgst: ' + sgst);
            System.debug('currentMilestonePaymentPercent: ' + currentMilestonePaymentPercent);
            System.debug('TDSonePercentage: ' + TDSonePercentage);
            System.debug('totalSalesConsideration: ' + totalSalesConsideration);
        }
    }
}