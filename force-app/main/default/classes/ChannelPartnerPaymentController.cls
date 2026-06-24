public with sharing class ChannelPartnerPaymentController {

    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoices(Id recId) {
        
        if (recId == null) {
            throw new AuraHandledException('Channel Partner Id is required');
        }
        
        return [
            SELECT Id,Name,Agreement_Amount__c,Commission_Amount__c,Cancelled_Booking_Amount__c, TDS__c,GST__c,Channel_Partner__c,Net_Invoice_Amount__c,Invoice_Date__c,
            Project_Name1__c,
            Invoice_Status__c,
            Commsison_Percentage__c,
            Net_Investment_Amount__c
            FROM Invoice__c
            WHERE Channel_Partner__c = :recId AND Invoice_Status__c = 'Pending' ORDER BY CreatedDate DESC
        ];
    }

    /* Create Payment + Line Items */
    /* Create Payment + Line Items */
   @AuraEnabled
public static Id createPayment(
    String baseName,
    Date paymentDate,
    String utrNumber,
    String status,
    String paymentMethod,
    List<Id> invoiceIds,
    Id recId
) {
    System.debug('=== createPayment START ===');

    if (invoiceIds == null || invoiceIds.isEmpty()) {
        throw new AuraHandledException('No invoices selected');
    }

    /* ================= CREATE PAYMENT ================= */
    Payment__c payment = new Payment__c(
        Channel_Partner__c = recId,
        Payment_Status__c  = status
    );
    insert payment;

    /* ================= FETCH INVOICE LINE ITEMS ================= */
    List<Invoice_Line_Item__c> invoiceLineItems = [
        SELECT Id,Invoice__c, Invoice_Date__c, Project_Name__c, Commission_Amount__c, Cancelled_Booking_Commission_Amount__c, Agreement_Value__c, Booking__c
        FROM Invoice_Line_Item__c
        WHERE Invoice__c IN :invoiceIds
    ];

    if (invoiceLineItems.isEmpty()) {
        throw new AuraHandledException('No Invoice Line Items found');
    }

    List<Payment_Line_Item__c> paymentLineItems = new List<Payment_Line_Item__c>();
    Decimal totalAmount = 0;

    /* ================= CREATE PAYMENT LINE ITEMS ================= */
    Integer count = 1;
    for (Invoice_Line_Item__c ili : invoiceLineItems) {

        paymentLineItems.add(new Payment_Line_Item__c(
             Name                    = baseName + ' - ' + count,
            Payment__c              = payment.Id,
            Invoice_Line_Item__c    = ili.Id,          
            Payment_Method__c       = paymentMethod,
            Channel_Partner__c      = recId,
            Project_name__c         = ili.Project_Name__c,
            Processing_date__c      = Date.today(),
            Booking__c              = ili.Booking__c,
            Invoice__c              = ili.invoice__c,
            Payament_Status__c      = status,
            Transcantion_Number__c  = utrNumber,
            Commission_Amount__c       = ili.Commission_Amount__c
        ));
         count++;
    }

    insert paymentLineItems;

    /* ================= OPTIONAL TOTAL UPDATE ================= */
    // payment.Processed_Amount__c = totalAmount;
    // update payment;

    System.debug('=== createPayment END ===');

    return payment.Id;
}

}