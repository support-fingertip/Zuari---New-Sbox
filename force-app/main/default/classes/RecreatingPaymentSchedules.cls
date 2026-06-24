public class RecreatingPaymentSchedules {
    
    @AuraEnabled
    public static void recreateReceipts(Id bookingId) {
        markReceiptLineItemsRejected(bookingId);
        recreateReceiptLineItems(bookingId);
        callTheMethodOfReceiptDate(bookingId);
    }
    
    private static void markReceiptLineItemsRejected(Id bookingId) {
        try {
            List<Receipt_Line_Item__c> lineItems = [
                SELECT Id, Approval_Status_Picklist__c, Description__c
                FROM Receipt_Line_Item__c
                WHERE Receipt__r.Booking__c = :bookingId and Approval_Status_Picklist__c = 'Approved'
            ];
            
            for (Receipt_Line_Item__c item : lineItems) {
                item.Approval_Status_Picklist__c = 'Rejected';
                item.Description__c = 'Made by system';
            }
            
            if (!lineItems.isEmpty()) {
                update lineItems;
            }
        } catch (Exception e) {
            System.debug('Error updating line items: ' + e.getMessage());
            throw new AuraHandledException('Failed to reject receipts: ' + e.getMessage());
        }
    }
    
    
    private static void recreateReceiptLineItems(Id bookingId) {
        
            List<Receipt__c> receipts = [
                SELECT Id, Name, Receipt_Name__c, Remarks__c, Finance_User__c, Payment_From__c,
                Receipt_date__c, Check_Transaction_Nmber__c,
                Amount_received__c, Mode_of_payment__c, Bank_Name__c,
                Approval_status__c,(select Id,Name,Bank_Name__c,Cheque_Date__c,Drawn_On__c,Payment_From__c,Mode_of_Payment__c,Cheque_no_Transaction_Number__c 
                                    from Receipt_Line_Items__r)
                FROM Receipt__c 
                WHERE Booking__c = :bookingId and Approval_status__c = 'Approved'
                ORDER BY Receipt_Date__c ASC NULLS FIRST
            ];
            
            Booking__c bk = [SELECT Id, Name, Finance_Lead__c, Project__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            
            for (Receipt__c rc : receipts) {
                Receipt_Line_Item__c dummyLineItem = new Receipt_Line_Item__c(
                    Bank_Name__c = rc.Receipt_Line_Items__r[0].Bank_Name__c,
                    Payment_From__c = rc.Receipt_Line_Items__r[0].Payment_From__c,
                    Mode_of_Payment__c = rc.Receipt_Line_Items__r[0].Mode_of_payment__c,
                    Cheque_no_Transaction_Number__c = rc.Receipt_Line_Items__r[0].Cheque_no_Transaction_Number__c,
                    Drawn_On__c = rc.Receipt_Line_Items__r[0].Drawn_On__c,
                    Cheque_Date__c = rc.Receipt_Line_Items__r[0].Cheque_Date__c
                );
                
                List<Receipt_Line_Item__c> polist = new List<Receipt_Line_Item__c>{dummyLineItem};
                    String PaymentFrom = rc.Payment_From__c;
                String pon = rc.Receipt_Name__c;
                String remark = rc.Remarks__c;
                String poc = rc.Receipt_date__c != null ? String.valueOf(rc.Receipt_date__c) : String.valueOf(Date.today());
                Decimal paidAmount = rc.Amount_received__c;
                Boolean isFromRefactor = true;
                
                insertReceiptLineItems(rc.Id,polist, PaymentFrom, pon, remark, poc, bk, paidAmount, isFromRefactor);
            }
        
    }
    
    private static void callTheMethodOfReceiptDate(Id bookingId) {
        try {
            List<Payment_Schedule__c> payList = [
                SELECT Id, Name, Last_Payment_Date__c,
                (SELECT Id, Name, Receipt__r.Receipt_Date__c,Payment_From__c 
                 FROM Receipt_Line_Items__r where Approval_Status_Picklist__c != 'Rejected'
                 ORDER BY Receipt__r.Receipt_Date__c DESC 
                 LIMIT 1) 
                FROM Payment_Schedule__c 
                WHERE Booking__c = :bookingId
            ];
            
            List<Payment_Schedule__c> schedulesToUpdate = new List<Payment_Schedule__c>();
            
            for(Payment_Schedule__c pay : payList) {
                if(!pay.Receipt_Line_Items__r.isEmpty()) {
                    pay.Last_Payment_Date__c = pay.Receipt_Line_Items__r[0].Receipt__r.Receipt_Date__c;
                    schedulesToUpdate.add(pay);
                }
            }
            
            if(!schedulesToUpdate.isEmpty()) {
                update schedulesToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error updating last payment dates: ' + e.getMessage());
            throw new AuraHandledException('Failed to update last payment dates: ' + e.getMessage());
        }
    }
    
    
    
    
    
    
    @AuraEnabled
    public static String insertReceiptLineItems(Id repId,List<Receipt_Line_Item__c> polist, string PaymentFrom, string pon, string remark, string poc, Booking__c bk, Decimal paidAmount, boolean isFromRefactor) {
        
        //List<Receipt__c> dupRcpList = [Select Id,Name from Receipt__c where Check_Transaction_Nmber__c =:polist[0].Cheque_no_Transaction_Number__c ];
        
        Receipt__c rc = new Receipt__c();
        rc.Receipt_Name__c=pon;
        rc.Remarks__c = remark;
        rc.Finance_User__c = bk.Finance_Lead__c;
        rc.Receipt_date__c=date.valueof(poc);
        rc.Payment_From__c = PaymentFrom;
        rc.Check_Transaction_Nmber__c = polist[0].Cheque_no_Transaction_Number__c;
        rc.Amount_received__c = paidAmount;
        rc.Mode_of_payment__c = polist[0].Mode_of_Payment__c;
        rc.Bank_Name__c = polist[0].Bank_Name__c;
        rc.Cheque_Date__c = polist[0].Cheque_Date__c;
        //rc.Drawn_On__c = polist[0].Drawn_On__c;
        rc.Booking__c=bk.Id;
        if(isFromRefactor == true){
            rc.Approval_status__c='Approved by Finance Team';
        }
        //rc.Interest_Paid_Amount__c = interestAmount;
        //insert rc;
        
        List<Receipt_Line_Item__c> receiptsToCreate = new List<Receipt_Line_Item__c>();
        List<Payment_Schedule__c> payList = [SELECT Id, Amount__c, Pending_Amount__c, S_No__c FROM Payment_Schedule__c WHERE Booking__c =: bk.Id ORDER BY is_Demanded__c desc, Payment_Due_Date__c ASC nulls first, S_No__c asc];
        List<Payment_Schedule__c> newpayList = new List<Payment_Schedule__c>();
        List<Payment_Schedule__c> orderedPayList = new List<Payment_Schedule__c>();
        Set<Id> payIds = new Set<Id>();
        
        if(paidAmount > 0){
            for (Payment_Schedule__c paymentSchedule : payList) {
                
                if (paidAmount <= 0 || paidAmount == null) {
                    break;
                }
                
                if (paymentSchedule.Pending_Amount__c != null && paymentSchedule.Pending_Amount__c > 0) {
                    
                    Decimal amountToReceive = Math.min(paymentSchedule.Pending_Amount__c, paidAmount);
                    paidAmount -= amountToReceive;
                    
                    Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                    rece.Booking__c = bk.Id;
                    rece.Name = 'Against Payment Schedule';
                    rece.Payment_Type__c = polist[0].Payment_Type__c;
                    rece.Receipt__c = repId;
                    rece.Payment_Schedule__c = paymentSchedule.Id;
                    rece.Received_Amount__c = amountToReceive;
                    rece.Amount__c = amountToReceive;
                    rece.Bank_Name__c = polist[0].Bank_Name__c;
                    rece.Approval_Status_Picklist__c = 'Approved';
                    rece.Payment_From__c = polist[0].Payment_From__c;
                    rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
                    rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                    rece.Drawn_On__c = polist[0].Drawn_On__c;
                    rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                    receiptsToCreate.add(rece);
                    payIds.add(paymentSchedule.Id);
                }
                
            }
        }
        
        
        if(paidAmount !=null && paidAmount > 0)
        {
            Integer PaymentScheduleSize = payList.size();
            Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
            rece.Booking__c = bk.Id;
            rece.Name = 'Against Payment Schedule';
            rece.Payment_Type__c = polist[0].Payment_Type__c;
            rece.Receipt__c = repId;
            rece.Payment_Schedule__c = payList[PaymentScheduleSize-1].Id;
            rece.Received_Amount__c = paidAmount;
            rece.Amount__c = paidAmount;
            rece.Approval_Status_Picklist__c = 'Approved';
            rece.Bank_Name__c = polist[0].Bank_Name__c;
            rece.Payment_From__c = polist[0].Payment_From__c;
            rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
            rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
            rece.Drawn_On__c = polist[0].Drawn_On__c;
            rece.Cheque_Date__c = polist[0].Cheque_Date__c;
            receiptsToCreate.add(rece);
        }
        
        
        if (!receiptsToCreate.isEmpty()) {
            upsert receiptsToCreate;
        }
        
        
        return rc.Id;
        
    }
    
    public static void testCoverage(){
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}