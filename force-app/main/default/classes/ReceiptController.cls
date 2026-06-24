public without sharing class ReceiptController {
    
    // ✅ NEW CLASS: Wrapper for validation response
    public class ValidationResponse {
        @AuraEnabled
        public Boolean hasApprovedReceipts { get; set; }
        @AuraEnabled
        public Decimal bookingAmount { get; set; }
        
        public ValidationResponse(Boolean hasReceipts, Decimal amount) {
            this.hasApprovedReceipts = hasReceipts;
            this.bookingAmount = amount;
        }
    }
    
    public class databox{
        @AuraEnabled
        public List<Receipt_Line_Item__c> rcList;
        @AuraEnabled
        public Decimal grandTotal;
    }
    
    public class wrapperprod{
        @AuraEnabled
        public List<Payment_schedule__c> pysch{get;set;}
    } 
    
    // ✅ NEW METHOD: Validate first receipt amount against booking amount
    @AuraEnabled
    public static ValidationResponse validateFirstReceiptAmount(String bookingId) {
        try {
            // Get the Booking record with Booking Amount field
            // NOTE: Replace 'Booking_Amount__c' with your actual field API name
            Booking__c booking = [
                SELECT Id, Booking_Amount__c 
                FROM Booking__c 
                WHERE Id = :bookingId 
                LIMIT 1
            ];
            
            // Check if there are any approved receipts for this booking
            List<Receipt__c> approvedReceipts = [
                SELECT Id 
                FROM Receipt__c 
                WHERE Booking__c = :bookingId 
                AND Approval_status__c = 'Approved'
                LIMIT 1
            ];
            
            Boolean hasApprovedReceipts = !approvedReceipts.isEmpty();
            Decimal bookingAmount = booking.Booking_Amount__c != null ? booking.Booking_Amount__c : 0;
            
            return new ValidationResponse(hasApprovedReceipts, bookingAmount);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error validating receipt: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Decimal getInterestAmount(string recId){
        Decimal InterestAmount = 0;
        List<Payment_Schedule__c> payList = [select id,name,Interest_Up_To_Date__c from Payment_schedule__c where Booking__c =: recId];
        for(Payment_Schedule__c pay : payList){
            InterestAmount = InterestAmount+ pay.Interest_Up_to_Date__c;
        }
        System.debug(InterestAmount);
        return InterestAmount;
    }
    
    @AuraEnabled
    public static Booking__c getBookingDetails(string recid){
        return [select id,name,Project__c,TOTAL__c,Flat_no__c,Unit_No__c,Pending_Amount__c,GRAND_TOTAL__c,Project_Type__c from Booking__c where id=: recid];
    }
    
    @AuraEnabled
    public static List<Additional_Charges__c> getAddChar(string recid){
        return [select id,name,Pending_Amount__c from Additional_Charges__c where Booking__c =: recid and Pending_Amount__c	> 0];
    }
    
    @AuraEnabled
    public static String getLastReiptApprovalStatus(string recid){ 
        List<Receipt__c> lastReceipt = [Select id,Approval_status__c from Receipt__c where Booking__c =:recid Order By CreatedDate DESC limit 1];
        
        String receiptApprovalStatus;
        if(!lastReceipt.isEmpty()){
            receiptApprovalStatus  = lastReceipt[0].Approval_status__c;
        }
        else{
            receiptApprovalStatus='No Receipt Found';
        }
        return receiptApprovalStatus;
    }
    
    @AuraEnabled
    public static wrapperprod getpaymentsc(string recid){ 
        
        wrapperprod wrpdata=new wrapperprod();
        List<Payment_schedule__c> lstschdules = [SELECT Id,Name,Payment_percent__c,Payment_Due_Date__c,Recived_Per__c,Amount__c,Amount1__c,S_No__c,status__c,Booking__c,Quote__c FROM Payment_schedule__c WHERE Booking__c =:recid ORDER BY S_No__c ASC];
        
        wrpdata.pysch=lstschdules;
        
        system.debug(wrpdata);
        return wrpdata; 
    }
    
    @AuraEnabled
    public static  Decimal gettdsamout(Id recid){
        Booking__c bk = [Select Id,Name,Agreement_Value_Before_GST__c from Booking__c where Id=:recid];
        Decimal tdsAmount = (bk.Agreement_Value_Before_GST__c * 0.01).setScale(0, RoundingMode.HALF_UP);
        
        return tdsAmount;
       
    }
    
    @AuraEnabled
    public static databox Rcitemlist(String recid){ 
        system.debug('mfrid---'+recid);                                                   
        databox db = new databox();
        List<Receipt_Line_Item__c> rcptitmlst =  [SELECT Id,Name,Receipt__c,Drawn_On__c,Branch__c,Payment_schedule__c,Received_Amount__c,Receipt__r.Booking__c,Booking__c,Amount__c FROM Receipt_Line_Item__c where  Booking__c =:recid ];
        system.debug(rcptitmlst);
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Id=:recid];
        system.debug('---'+rcptitmlst);
        db.rcList = rcptitmlst;
        return db;                                      
    } 
    
    @AuraEnabled
    public static void deleteProduct(string prId){
        DELETE [SELECT Id FROM 	Receipt_Line_Item__c WHERE Id=:prId];
    }
    
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Receipt_Line_Item__c.Mode_of_Payment__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues1() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Funding_Type__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues2() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Receipt_Line_Item__c.Payment_Type__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static Id insertReceiptLineItems(List<Receipt_Line_Item__c> polist,string PaymentFrom, string pon,string remark,string poc, string recid, Decimal paidAmount, Decimal interestAmount){
        
        Booking__c bk = [SELECT Id, Name,Finance_Lead__c, Project__c FROM Booking__c WHERE Id = :recid LIMIT 1];
        system.debug(bk);
        
        Receipt__c rc = new Receipt__c();
        rc.Receipt_Name__c = 'Receipt For '+bk.Name;
        rc.Remarks__c = remark;
        rc.Receipt_date__c = Date.valueOf(poc);
        if(PaymentFrom == 'Swapped Booking'){
            rc.Approval_Status__c = 'Approved';
        }
        rc.Booking__c = recid;
        rc.Payment_Type__c = polist[0].Payment_Type__c;
        rc.Finance_User__c = bk.Finance_Lead__c;
        rc.Cheque_Date__c = polist[0].Cheque_Date__c;
        rc.Check_Transaction_Nmber__c = polist[0].Cheque_no_Transaction_Number__c;
        rc.Mode_Of_Payment__c = polist[0].Mode_of_Payment__c;
        rc.Payment_From__c = polist[0].Payment_From__c;
        insert rc;
        system.debug(rc);
        
        Payment_Schedule__c payment = [Select Id, Name From Payment_Schedule__c where name = 'Additional Charge'];
        List<Payment_Schedule__c> payList = [SELECT Id, Amount1__c,Is_Demanded__c,Villa_Flat_Amount_Pending__c, Interest_Pending_Amount__c,Pending_Amount__c, S_No__c FROM Payment_Schedule__c WHERE Pending_Amount__c > 0 and Booking__c = :bk.Id ORDER BY S_No__c ASC];
        system.debug(payList);
        system.debug(polist);
        
        Set<Id> payIds = new Set<Id>();
        Map<Id,Decimal> paymentScheduleToPendingAmount = new Map<Id,Decimal>();
        for(Payment_Schedule__c pay : payList){
            paymentScheduleToPendingAmount.put(pay.Id,pay.Pending_Amount__c);
        }
        
        Map<Integer, Receipt_Line_Item__c> receiptLineItemMap = new Map<Integer, Receipt_Line_Item__c>();
        for (Integer i = 0; i < polist.size(); i++) {
            if(polist[i].Payment_Type__c != 'Additional Charges' && (polist[i].Payment_Type__c == 'Flat Amount' || polist[i].Payment_Type__c == 'Villa Amount' || polist[i].Payment_Type__c == 'Plot Amount' || polist[i].Payment_Type__c == 'TDS')){
                receiptLineItemMap.put(i + 1, polist[i]);
            }
        }
        
        List<Receipt_Line_Item__c> receiptsToCreate = new List<Receipt_Line_Item__c>();
        for(Payment_Schedule__c payIt : payList){
            if(paymentScheduleToPendingAmount.get(payIt.Id) > 0){
                for(Integer inte : receiptLineItemMap.keySet()){
                    if(receiptLineItemMap.get(inte).Received_Amount__c > 0 && paymentScheduleToPendingAmount.get(payIt.Id) > 0){
                        Decimal amountToReceive = Math.min(paymentScheduleToPendingAmount.get(payIt.Id), receiptLineItemMap.get(inte).Received_Amount__c);
                        Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                        system.debug('test');
                        rece.Booking__c = bk.Id;
                        rece.Name = receiptLineItemMap.get(inte).Payment_Type__c;
                        rece.Receipt__c = rc.Id;
                        rece.Payment_Schedule__c = payIt.Id;
                        rece.Received_Amount__c = amountToReceive;
                        rece.Amount__c = amountToReceive;
                        if(PaymentFrom == 'Swapped Booking'){
                            rece.Approval_Status_Picklist__c = 'Approved';
                        }
                        rece.Bank_Name__c = receiptLineItemMap.get(inte).Bank_Name__c;
                        rece.Cheque_Date__c = receiptLineItemMap.get(inte).Cheque_Date__c;
                        rece.Branch__c = receiptLineItemMap.get(inte).Branch__c;
                        rece.Drawn_On__c = receiptLineItemMap.get(inte).Drawn_On__c;
                        rece.Payment_Type__c = receiptLineItemMap.get(inte).Payment_Type__c;
                        rece.Mode_of_Payment__c = receiptLineItemMap.get(inte).Mode_of_Payment__c;
                        rece.Payment_From__c = receiptLineItemMap.get(inte).Payment_From__c;
                        rece.Cheque_no_Transaction_Number__c = receiptLineItemMap.get(inte).Cheque_no_Transaction_Number__c;
                        receiptsToCreate.add(rece);
                        system.debug(rece);
                        paymentScheduleToPendingAmount.put(payIt.Id, paymentScheduleToPendingAmount.get(payIt.Id) - amountToReceive);
                        
                        Receipt_Line_Item__c updatedReceiptLineItem = receiptLineItemMap.get(inte);
                        system.debug('test1');
                        updatedReceiptLineItem.Received_Amount__c -= amountToReceive;
                        receiptLineItemMap.put(inte, updatedReceiptLineItem);
                        system.debug('test2');
                    }
                }
            }
        }
        
        Map<Id,Decimal> paymentScheduleToPendingAmountGST = new Map<Id,Decimal>();
        for(Payment_Schedule__c pay : payList){
            // paymentScheduleToPendingAmountGST.put(pay.Id,pay.GST_Amount_Pending__c);
        }
        
        Map<Integer, Receipt_Line_Item__c> receiptLineItemMapGST = new Map<Integer, Receipt_Line_Item__c>();
        for (Integer i = 0; i < polist.size(); i++) {
            if(polist[i].Payment_Type__c != 'Additional Charges' && polist[i].Payment_Type__c == 'GST Amount'){
                receiptLineItemMapGST.put(i + 1, polist[i]);
            }
        }
        
        for(Payment_Schedule__c payIt : payList){
            if(paymentScheduleToPendingAmountGST.get(payIt.Id) > 0){
                for(Integer inte : receiptLineItemMapGST.keySet()){
                    if(receiptLineItemMapGST.get(inte).Received_Amount__c > 0 && paymentScheduleToPendingAmountGST.get(payIt.Id) > 0){
                        system.debug('test3');
                        Decimal amountToReceive = Math.min(paymentScheduleToPendingAmountGST.get(payIt.Id), receiptLineItemMapGST.get(inte).Received_Amount__c);
                        Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                        rece.Booking__c = bk.Id;
                        rece.Name = receiptLineItemMapGST.get(inte).Payment_Type__c;
                        rece.Receipt__c = rc.Id;
                        rece.Payment_Schedule__c = payIt.Id;
                        rece.Received_Amount__c = amountToReceive;
                        rece.Amount__c = amountToReceive;
                        if(PaymentFrom == 'Swapped Booking'){
                            rece.Approval_Status_Picklist__c = 'Approved';
                        }
                        rece.Bank_Name__c = receiptLineItemMapGST.get(inte).Bank_Name__c;
                        rece.Cheque_Date__c = receiptLineItemMap.get(inte).Cheque_Date__c;
                        rece.Branch__c = receiptLineItemMap.get(inte).Branch__c;
                        rece.Drawn_On__c = receiptLineItemMap.get(inte).Drawn_On__c;
                        rece.Payment_Type__c = receiptLineItemMapGST.get(inte).Payment_Type__c;
                        rece.Mode_of_Payment__c = receiptLineItemMapGST.get(inte).Mode_of_Payment__c;
                        system.debug(rece);
                        rece.Cheque_no_Transaction_Number__c = receiptLineItemMapGST.get(inte).Cheque_no_Transaction_Number__c;
                        receiptsToCreate.add(rece);
                        system.debug('test4');
                        paymentScheduleToPendingAmountGST.put(payIt.Id, paymentScheduleToPendingAmountGST.get(payIt.Id) - amountToReceive);
                        
                        Receipt_Line_Item__c updatedReceiptLineItem = receiptLineItemMapGST.get(inte);
                        updatedReceiptLineItem.Received_Amount__c -= amountToReceive;
                        receiptLineItemMapGST.put(inte, updatedReceiptLineItem);
                    }
                }
            }
        }
        
        for (Receipt_Line_Item__c lineItem : polist) {
            system.debug('test5');
            if (lineItem.Payment_Type__c == 'Additional Charges') {
                system.debug('test6');
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against Additional Charges';
                rece.Receipt__c = rc.Id;
                rece.Received_Amount__c = lineItem.Received_Amount__c;
                rece.Amount__c = lineItem.Received_Amount__c;
                rece.Payment_schedule__c = payment.Id;
                if(PaymentFrom == 'Swapped Booking'){
                    rece.Approval_Status_Picklist__c = 'Approved';
                }
                rece.Additional_Charges__c = lineItem.Additional_Charges__c;
                rece.Bank_Name__c = lineItem.Bank_Name__c;
                rece.Cheque_Date__c = lineItem.Cheque_Date__c;
                rece.Payment_Type__c = lineItem.Payment_Type__c;
                rece.Mode_of_Payment__c = lineItem.Mode_of_Payment__c;
                system.debug(rece);
                receiptsToCreate.add(rece);
            }
        }
        
        for(Payment_Schedule__c paymentSchedule : payList){
            if (interestAmount <= 0 || interestAmount == null) {
                break;
            }
            if( (interestAmount != 0 || interestAmount != null) &&  paymentSchedule.Interest_Pending_Amount__c != null && paymentSchedule.Interest_Pending_Amount__c > 0 ){
                Decimal amountToReceive = Math.min(paymentSchedule.Interest_Pending_Amount__c, interestAmount);
                interestAmount -= amountToReceive;
                
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against Interest';
                rece.Payment_Type__c = 'Interest';
                rece.Receipt__c = rc.Id;
                rece.Payment_Schedule__c = paymentSchedule.Id;
                rece.Received_Amount__c = amountToReceive;
                rece.Amount__c = amountToReceive;
                rece.Bank_Name__c = polist[0].Bank_Name__c;
                rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
                rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                if(amountToReceive > 0){
                    receiptsToCreate.add(rece);
                }
            }
        }
        
        if(interestAmount !=null && interestAmount !=0) {
            system.debug('Interest');
            Integer PaymentScheduleSize = payList.size();
            Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
            rece.Booking__c = bk.Id;
            rece.Name = 'Against Interest';
            rece.Payment_Type__c = 'Interest';
            rece.Receipt__c = rc.Id;
            rece.Payment_Schedule__c = payList[PaymentScheduleSize-1].Id;
            rece.Received_Amount__c = interestAmount;
            rece.Amount__c = interestAmount;
            rece.Bank_Name__c = polist[0].Bank_Name__c;
            rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
            rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
            rece.Cheque_Date__c = polist[0].Cheque_Date__c;
            receiptsToCreate.add(rece);
        }
        
        // Insert all Receipt Line Items
        if (!receiptsToCreate.isEmpty()) {
            insert receiptsToCreate;
        }
        
        return rc.Id;
    }
    
    public static void approvedReceiptsHandler(Set<Id> receiptIds) {
        
        list<Receipt_Line_Item__c> recLinIds = [SELECT id,Payment_schedule__c FROM Receipt_Line_Item__c WHERE Receipt__c IN : receiptIds];
        list<id> paymentIds = new list<id>();
        
        for(Receipt_Line_Item__c recl :recLinIds){
            paymentIds.add(recl.Payment_schedule__c);
        }
        
        List<Payment_schedule__c> payList1 = [SELECT id,name,Last_Payment_Time__c,Booking__c,Payment_Due_Date__c,Last_Payment_Date__c,Include_Interest__c,Interest_Percent__c,Interest_Amount__c,Pending_Amount__c FROM Payment_schedule__c WHERE id in:paymentIds ];
        List<Interest_Amount_Line_Item__c> IntAmtLiEs = new List<Interest_Amount_Line_Item__c>();
        
        for(Payment_schedule__c pay : payList1){
            if (pay.Include_Interest__c == true && pay.Interest_Amount__c != null && pay.Interest_Amount__c > 0) {
                Interest_Amount_Line_Item__c IntLine = new Interest_Amount_Line_Item__c();
                IntLine.Interest_Amount__c = pay.Interest_Amount__c;
                if(pay.Last_Payment_Date__c == null){
                    IntLine.Interest_Start_Date__c = pay.Payment_Due_Date__c;
                }
                else{
                    IntLine.Interest_Start_Date__c = pay.Last_Payment_Date__c;
                }
                IntLine.Interest_End_Date__c = system.today();
                IntLine.Interest_Percent__c = pay.Interest_Percent__c;
                IntLine.Payment_Schedule__c = pay.id;
                IntLine.Booking__c = pay.Booking__c;
                IntLine.Principal_Amount__c = pay.Pending_Amount__c;
                IntAmtLiEs.add(IntLine);
            }
            pay.Last_Payment_Date__c = system.today();
            pay.Last_Payment_Time__c = system.now();
        }
        
        if(IntAmtLiEs.size()>0){
            insert IntAmtLiEs;
        }
        
        update payList1;
    }
}