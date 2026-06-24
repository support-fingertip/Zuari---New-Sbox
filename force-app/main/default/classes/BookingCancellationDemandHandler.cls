public class BookingCancellationDemandHandler {

    /**
     * When Booking is cancelled:
     * 1. All Demand_Raised__c for the booking → Demand_Status__c = 'Demand Reversed'
     * 2. For each reversed demand → create a child Demand_Raised__c with SAME values,
     *    Parent_Demand__c = parent Id, Demand_Type__c = 'Credit Note'
     */
    public static void reverseDemandsAndCreateCreditNotes(Set<Id> bookingIds) {
        if (bookingIds == null || bookingIds.isEmpty()) return;

        // Query all active Demand_Raised__c for cancelled bookings
        List<Demand_Raised__c> parentDemands = [
            SELECT Id, Name, Booking__c, Current_Demand_amount__c, Previous_pendings__c,
                   Amount_Demanded__c, Grand_Total__c, GST__c, Demand_Status__c,
                   Demand_No__c, Demand_Name__c, Due_Date__c, Demanded_Date__c,
                   Payment_schedule__c, Milestone_Percentage__c, Include_Interest__c,
                   Interest_Till_Now__c, Total_Interest__c, Total_Interest_Paid__c,
                   Total_Amount_Paid__c, Demand_Email_Content__c, Demand_Email_Send__c,
                   Total_Percentage_till_Current_Milestone__c, Project__c, Is_Last__c,
                   Booking_Name__c, Disable_Demand_Mail__c, Grand_Total_in_Words__c
            FROM Demand_Raised__c
            WHERE Booking__c IN :bookingIds
              AND Demand_Status__c != 'Demand Reversed'
              AND Demand_Status__c != 'Demand Cancelled'
              AND Demand_Status__c != 'Credit Note Issued'
        ];

        if (parentDemands.isEmpty()) return;

        // Step 1: Update parent demands to 'Demand Reversed'
        for (Demand_Raised__c parent : parentDemands) {
            parent.Demand_Status__c = 'Demand Reversed';
        }
        update parentDemands;

        // Step 2: Create Credit Note child demands — SAME values as parent
        List<Demand_Raised__c> creditNotes = new List<Demand_Raised__c>();

        for (Demand_Raised__c parent : parentDemands) {
            Demand_Raised__c creditNote = new Demand_Raised__c();

            // === Self-lookup to parent ===
            creditNote.Parent_Demand__c = parent.Id;

            // === Copy ALL values from parent (same to same) ===
            creditNote.Booking__c                              = parent.Booking__c;
            //creditNote.Project__c                              = parent.Project__c;
            creditNote.Payment_schedule__c                     = parent.Payment_schedule__c;
            creditNote.Current_Demand_amount__c                = parent.Current_Demand_amount__c;
            creditNote.Previous_pendings__c                    = parent.Previous_pendings__c;
            creditNote.Amount_Demanded__c                      = parent.Amount_Demanded__c;
            creditNote.Grand_Total__c                          = parent.Grand_Total__c;
            //creditNote.GST__c                                  = parent.GST__c;
            creditNote.Interest_Till_Now__c                    = parent.Interest_Till_Now__c;
            creditNote.Total_Interest__c                       = parent.Total_Interest__c;
            creditNote.Total_Interest_Paid__c                  = parent.Total_Interest_Paid__c;
            creditNote.Total_Amount_Paid__c                    = parent.Total_Amount_Paid__c;
            creditNote.Milestone_Percentage__c                 = parent.Milestone_Percentage__c;
            creditNote.Total_Percentage_till_Current_Milestone__c = parent.Total_Percentage_till_Current_Milestone__c;
            creditNote.Include_Interest__c                     = parent.Include_Interest__c;
            //creditNote.Is_Last__c                              = parent.Is_Last__c;
            creditNote.Demand_Name__c                          = parent.Demand_Name__c;

            // === Credit Note specific fields ===
            creditNote.Demand_Type__c       = 'Credit Note';
            creditNote.Demand_Status__c     = 'Credit Note Issued';
            creditNote.Demanded_Date__c     = Date.today();
            creditNote.Due_Date__c          = Date.today();
            creditNote.Demand_Email_Send__c = false;

            creditNotes.add(creditNote);
        }

        if (!creditNotes.isEmpty()) {
            insert creditNotes;
        }
    }
}