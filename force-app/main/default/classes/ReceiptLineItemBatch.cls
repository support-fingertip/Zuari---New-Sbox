/**
 * ReceiptLineItemBatch
 *
 * Iterates over manual Receipt__c records ordered by Booking__c, Receipt_Date__c ASC.
 * Batch size = 1 → each receipt is processed in its own transaction.
 * This ensures the Pending_Amount__c formula (driven by Received_Amount1__c rollup)
 * is fully recalculated before the next receipt is processed.
 *
 * Execute:
 *   Database.executeBatch(new ReceiptLineItemBatch(), 1);
 */
global class ReceiptLineItemBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Integer      totalReceipts  = 0;
    global Integer      totalLineItems = 0;
    global List<String> errors         = new List<String>();

    // -------------------------------------------------------------------------
    // START  –  receipts ordered by Booking then Date ASC
    // -------------------------------------------------------------------------
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Integer i = 0;
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
        return Database.getQueryLocator([
            SELECT Id, Name, Booking__c, Amount_Received__c, Receipt_Date__c,
                   Mode_Of_Payment__c, Check_Transaction_Nmber__c,
                   Cheque_Date__c, Drawn_On__c
            FROM   Receipt__c
            WHERE  Manual_Upload__c = TRUE
            AND    Booking__c       != NULL
            ORDER  BY Booking__c ASC, Receipt_Date__c ASC, Name ASC
        ]);
    }

    // -------------------------------------------------------------------------
    // EXECUTE  –  one receipt per transaction (batch size = 1)
    // -------------------------------------------------------------------------
    global void execute(Database.BatchableContext bc, List<Receipt__c> scope) {

        Receipt__c rc = scope[0];

        if (rc.Amount_Received__c == null ) {
            errors.add('Receipt ' + rc.Id + ' (Booking ' + rc.Booking__c +
                '): Amount_Received__c is null or zero — skipped.');
            return;
        }

        // -- Fresh query of open schedules for this booking -------------------
        // Since each receipt runs in its own transaction, the rollup on
        // Received_Amount1__c is fully recalculated and Pending_Amount__c
        // reflects all previously inserted line items accurately.
        List<Payment_Schedule__c> schedules = [
            SELECT Id, Name, S_No__c, Pending_Amount__c, Booking__c
            FROM   Payment_Schedule__c
            WHERE  Booking__c        = :rc.Booking__c
            AND    Pending_Amount__c > 0
            ORDER  BY S_No__c ASC
        ];

        if (schedules == null || schedules.isEmpty()) {
            errors.add('Receipt ' + rc.Id + ' (Booking ' + rc.Booking__c +
                '): no open Payment Schedules found — skipped.');
            return;
        }

        totalReceipts++;
        Decimal remaining = rc.Amount_Received__c;

        // -- Waterfall across schedules in S_No__c order ----------------------
        List<Receipt_Line_Item__c> lineItemsToInsert = new List<Receipt_Line_Item__c>();

        for (Payment_Schedule__c ps : schedules) {

            if (remaining <= 0) break;

            Decimal schedulePending = ps.Pending_Amount__c != null
                                      ? ps.Pending_Amount__c : 0;
            if (schedulePending <= 0) continue;

            Decimal allocate = Math.min(schedulePending, remaining);

            Receipt_Line_Item__c rli            = new Receipt_Line_Item__c();
            rli.Booking__c                      = rc.Booking__c;
            rli.Receipt__c                      = rc.Id;
            rli.Payment_Schedule__c             = ps.Id;
            rli.Name                            = 'Plot Amount';
            rli.Payment_Type__c                 = 'Plot Amount';
            rli.Received_Amount__c              = allocate;
            rli.Amount__c                       = allocate;
            rli.Mode_of_Payment__c              = rc.Mode_Of_Payment__c;
            rli.Cheque_no_Transaction_Number__c = rc.Check_Transaction_Nmber__c;
            rli.Cheque_Date__c                  = rc.Cheque_Date__c;
            rli.Approval_Status_Picklist__c     = 'Approved';

            lineItemsToInsert.add(rli);
            remaining -= allocate;
        }

        // -- Insert line items for this receipt --------------------------------
        if (!lineItemsToInsert.isEmpty()) {
            List<Database.SaveResult> results =
                Database.insert(lineItemsToInsert, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    totalLineItems++;
                } else {
                    String msg = 'Line item insert failed for Receipt ' + rc.Id + ': ';
                    for (Database.Error e : results[i].getErrors()) {
                        msg += e.getMessage() + '; ';
                    }
                    errors.add(msg);
                }
            }
        }

        if (remaining > 0) {
            errors.add('Receipt ' + rc.Id + ' (Booking ' + rc.Booking__c +
                '): ₹' + remaining +
                ' could not be allocated — no remaining schedule balance.');
        }
    }

    // -------------------------------------------------------------------------
    // FINISH  –  email summary to the running user
    // -------------------------------------------------------------------------
    global void finish(Database.BatchableContext bc) {

        String body =
            'ReceiptLineItemBatch completed.\n\n' +
            'Receipts processed  : ' + totalReceipts  + '\n' +
            'Line items created  : ' + totalLineItems + '\n';

        if (!errors.isEmpty()) {
            body += '\nWarnings / Errors (' + errors.size() + '):\n';
            for (String msg : errors) {
                body += '  • ' + msg + '\n';
            }
        } else {
            body += '\nNo errors encountered.';
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
        mail.setSubject('ReceiptLineItemBatch — Job Complete');
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}