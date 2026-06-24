trigger BookingTrigger on Booking__c (before insert,before update,after insert, after update, after delete, after undelete) {
    List<Plot__c> plo1 = new List<Plot__c>();
    
    if(Trigger.isBefore && Trigger.isUpdate) {
        //  Set<String> restrictedUserIds = new Set<String>(Label.Restricted_User_Ids.split(','));
        
        String currentUserId = UserInfo.getUserId();
        Set<Booking__c> CheckAdvanceAmountList = new Set<Booking__c>();
        
        // Boolean isRestrictedUser = restrictedUserIds.contains(currentUserId);
        
        for (Booking__c booking : Trigger.new) {
            Booking__c oldBooking = Trigger.oldMap.get(booking.Id);
            
            
            if (oldBooking.Stage__c == 'New' && booking.Approval_status__c!='Approved' && booking.Stage__c == 'Booked') {
                booking.addError('Stage cannot be changed to Booked without aproval ');
                
            }
            if (oldBooking.Stage__c == 'New' && booking.Approval_status__c!='Approved' && booking.Stage__c == 'Agreement') {
                booking.addError('Stage cannot be changed to Agreement without approval ');
            } 
           
            if (booking.Stage__c != oldBooking.Stage__c && booking.Stage__c=='Demands & Collections' && booking.Agreement_Execution_Amount1__c > booking.Total_received_Amount__c) {
                booking.addError('Stage cannot be changed to Demands & Collections without paying Agreement Execution Amount ');
            }
            
            if (booking.Stage__c == 'Agreement') {
                if ((booking.Agreement_Status__c == 'Executed' || booking.Agreement_Status__c == 'Executed & Registered') && 
                    booking.Agreement_Status__c != oldBooking.Agreement_Status__c) {
                        booking.Stage__c = 'Demands & Collections';
                    }
            }
            if(booking.Stage__c == 'Booked' && booking.Welcome_Email_Sent_to_Customer__c == true && oldBooking.Welcome_Email_Sent_to_Customer__c != booking.Welcome_Email_Sent_to_Customer__c){
                CheckAdvanceAmountList.add(booking);
            }
        }
        
        if(!CheckAdvanceAmountList.isEmpty()){
            BookingController.moveStageToAgreementTR(CheckAdvanceAmountList);
        }
    }
    
    if(Trigger.isAfter && Trigger.isInsert) {
        Map<Id,String> plotIds = new Map<Id,String>();
        Set<Id> leadIds = new Set<Id>();
        List<Booking__c> preSalesBookings = new List<Booking__c>();
        for(Booking__c books : trigger.new){
            system.debug(books.Plot__c+' hbvhbdbvvdd '+books.Stage__c);
            if(books.Plot__c != null && books.Stage__c == 'New'){
                system.debug('blocjked');
                plotIds.put(books.Plot__c,'Blocked');
            }
        }
        if(plotIds.size()>0){
            //  BookingController.changeUnitStatus(plotIds);
        }
        Set<Id> costSheetIds = new Set<Id>();
        for (Booking__c book : Trigger.new) {
            if (book.Quote__c != null) {
                costSheetIds.add(book.Quote__c);
            }
        }
        /* if (!costSheetIds.isEmpty()) {
Map<Id,List<Payment_schedule__c>> payMap = new Map<Id,List<Payment_schedule__c>>();
for(Quote__c qt : [SELECT Id,Name,(SELECT Id, Name, Booking__c,Payment_Percent__c,Master_Payment_schedule__c, Quote__c FROM Payment_schedules__r) FROM Quote__c WHERE Id IN :costSheetIds]){
if(qt.Payment_schedules__r.size()>0){
payMap.put(qt.Id,qt.Payment_schedules__r);
}
}
List<Payment_schedule__c> paymentSchedulesToUpdate = new List<Payment_schedule__c>();
for (Booking__c book : Trigger.new) {
if (book.Quote__c != null && payMap.containskey(book.Quote__c)) {
Payment_schedule__c ps = new Payment_schedule__c();
for(Payment_schedule__c pay : payMap.get(book.Quote__c)){
paymentSchedulesToUpdate.add(pay);
}
}
}
if (!paymentSchedulesToUpdate.isEmpty()) {
update paymentSchedulesToUpdate;
}
}   */ 
        
        List<Receipt__c> receipts = new List<Receipt__c>();  
        List<Receipt_Line_Item__c> receiptlines = new List<Receipt_Line_Item__c>(); 
        List<Payment_Schedule__c> newPaymentSchedules = new List<Payment_Schedule__c>();
        Set<Id> quoteIds = new Set<Id>();
        
        // Collect Quote__c IDs from the Booking__c records
        for (Booking__c booking : Trigger.new) {
            if(booking.Quote__c != null){
                quoteIds.add(booking.Quote__c);
            }
        }
        List<Payment_Schedule__c> existingPaymentSchedules = new List<Payment_Schedule__c>();
        List<Payment_Schedule__c> BookingPaymentSchedules = new List<Payment_Schedule__c>();
        // Query existing Payment_Schedule__c records related to Quote__c
        if(quoteIds.size() >0){
            existingPaymentSchedules = [
                SELECT Id, Name, Amount__c,Booking__c, Quote__c,Master_Payment_Schedule__r.Status__c,Payment_percent__c,Amount1__c,status__c,S_No__c,Master_Payment_Schedule__c,Include_Interest__c,Last_Payment_Schedule__c  
                FROM Payment_Schedule__c
                WHERE Quote__c IN :quoteIds
            ];
        }
        for (Booking__c booking : Trigger.new) {
            if(existingPaymentSchedules.size() >0 ){
                for (Payment_Schedule__c existingPaymentSchedule : existingPaymentSchedules) {
                    //Payment_Schedule__c pay = existingPaymentSchedule.clone(false,false,false,false);
                    if(existingPaymentSchedule.S_No__c == 1){
                        existingPaymentSchedule.status__c = 'Completed';
                    }
                    else if(existingPaymentSchedule.Master_Payment_Schedule__r.Status__c == 'Completed'){
                        existingPaymentSchedule.status__c = existingPaymentSchedule.Master_Payment_Schedule__r.Status__c;
                    }
                    existingPaymentSchedule.Booking__c= booking.Id;
                    //BookingPaymentSchedules.add(pay);
                }
            } 
        }
        update existingPaymentSchedules;
        //upsert BookingPaymentSchedules;
        
        /*for(Booking__c booking : Trigger.new){
if(booking.Booking_Amount__c != null && booking.Booking_Amount__c != 0.00 && booking.Stage__c == 'New' ){
system.debug('receipt called'+ booking.Booking_Amount__c);
ReceiptController.insertReceiptLineItems111('ponValue', 'remarkValue', '2024-09-03', booking.Id, booking.Booking_Amount__c);
} 
}*/
        update plo1;
        
        //Added on 10-03-2026
        BookingTriggerHandler.afterInsert(Trigger.new);
        
        // Create or link Customer Master for new bookings
        BookingTriggerHandlerPostS.afterInsert(Trigger.new);
        // Added for manual sharing on insert
manulaSharingClass.bookingsToShare(Trigger.new);
        
    } 
    
    if(Trigger.isAfter && Trigger.isUpdate) 
    {
        system.debug('entered isAfter Update');
        
        // Reward creation & Referral status update on Agreement stage
        BookingTriggerHandlerPostS.afterUpdate(Trigger.new, Trigger.oldMap);
         BookingTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
   
        // CC Notification for Booking status change
        CCNotificationTriggerHandler.handleBookingStatusChange(Trigger.new, Trigger.oldMap);
        //Added NEwly on 28/11/2025 For notification for Owner change in booking
        List<Id> ownerChangedBookingIds = new List<Id>();
        Map<Id, Id> oldOwnerMap = new Map<Id, Id>();
        //Only above two List and Map
        Boolean isBooking = false;
        List<Task> tasksToCreateUser = new List<Task>();
        List<Booking__c> cancellationBookings = new List<Booking__c>();
        List<Booking__c> swappingBookings = new List<Booking__c>();
        List<Booking__c> swapUnit = new List<Booking__c>();
        List<Booking__c> OldUnitDetials = new List<Booking__c>();
        List<Id> BookingIds = new List<Id>();
           List<Id> approvedBookingIds = new List<Id>();
        
           List<Id> handoverBookingIds = new List<Id>();

        // ====== NEW: Collect cancelled booking IDs for demand reversal & credit note creation ======
        Set<Id> cancelledBookingIdsForDemandReversal = new Set<Id>();
     
        for (Booking__c booking : Trigger.new) {
            
            Booking__c oldBooking = Trigger.oldMap.get(booking.Id);
            //Added NEwly on 28/11/2025 For notification for Owner change in booking
            // Detect Owner change
            
            System.debug('OWNER CHECK → OLD: ' + oldBooking.OwnerId + ' NEW: ' + booking.OwnerId);
            if (booking.OwnerId != oldBooking.OwnerId) {
              
                ownerChangedBookingIds.add(booking.Id);
                oldOwnerMap.put(booking.Id, oldBooking.OwnerId);
                
            }
              //Ended here
            if(booking.stage__c != Trigger.oldmap.get(booking.Id).stage__c && booking.stage__c == 'Cancellation' && booking.Cancellation_Status__c == 'Approved'){
                cancellationBookings.add(booking);
                BookingIds.add(booking.Id);

                // ====== NEW: Add to demand reversal set ======
                cancelledBookingIdsForDemandReversal.add(booking.Id);
                
            }
            if(booking.Stage__c != Trigger.oldmap.get(booking.Id).Stage__c && booking.Swap_Unit_Status__c == 'Approved' && booking.Swap_Unit__c != null){
                system.debug('hellooo');
                swappingBookings.add(booking);
            }
            
            if(booking.Stage__c != oldBooking.Stage__c && booking.Stage__c == 'Agreement'){
                set<string> userIds = New set<string>();
                userIds.add(booking.OwnerId);
                BookingController.sendCustomNotification(userIds, 'Booking Stage Change Update', 'Your Booking '+ booking.Name +' stage is changed to Agreement ', booking.Id, 'Booking_Notification');
            }
            
            if(booking.Stage__c != oldBooking.Stage__c && booking.Stage__c == 'Demands & Collections'){
                set<string> userIds = New set<string>();
                userIds.add(booking.OwnerId);
                BookingController.sendCustomNotification(userIds, 'Booking Stage Change Update', 'Your Booking '+ booking.Name +' stage is changed to Demands & Collections', booking.Id, 'Booking_Notification');
            }
             if (booking.Stage__c != oldBooking.Stage__c && booking.Stage__c == 'Hand Over') {
                 
                 handoverBookingIds.add(booking.Id);
               //  DocumentandEmailController.sendHandoverEmail(booking.Id);
                
            }
             if (oldBooking.Swap_Applicant_Request_Status__c != 'Approved' && booking.Swap_Applicant_Request_Status__c == 'Approved' && booking.Swap_Applicant_Request__c == true) 
             {
                 approvedBookingIds.add(booking.Id);
             }
            // === 1. Approval Status ===
            if (booking.Approval_status__c != oldBooking.Approval_status__c) {
                BookingController.sendApprovalStatusNotification(
                    booking,
                    'Approval Status',
                    oldBooking.Approval_status__c,
                    booking.Approval_status__c
                );
            }
            
            // === 2. Swap Applicant Request Status ===
            if (booking.Swap_Applicant_Request_Status__c != oldBooking.Swap_Applicant_Request_Status__c) {
                BookingController.sendApprovalStatusNotification(
                    booking,
                    'Swap Applicant Request Status',
                    oldBooking.Swap_Applicant_Request_Status__c,
                    booking.Swap_Applicant_Request_Status__c
                );
            }
            
            // === 3. Swap Unit Status ===
            if (booking.Swap_Unit_Status__c != oldBooking.Swap_Unit_Status__c) {
                BookingController.sendApprovalStatusNotification(
                    booking,
                    'Swap Unit Status',
                    oldBooking.Swap_Unit_Status__c,
                    booking.Swap_Unit_Status__c
                );
            }
            
            // === 4. Cancellation Status ===
            if (booking.Cancellation_Status__c != oldBooking.Cancellation_Status__c) {
                BookingController.sendApprovalStatusNotification(
                    booking,
                    'Cancellation Status',
                    oldBooking.Cancellation_Status__c,
                    booking.Cancellation_Status__c
                );
            }
            
            // === 5. Time Extension Approval Status ===
            if (booking.Time_Extension_Approval_Status__c != oldBooking.Time_Extension_Approval_Status__c) {
                BookingController.sendApprovalStatusNotification(
                    booking,
                    'Time Extension Approval Status',
                    oldBooking.Time_Extension_Approval_Status__c,
                    booking.Time_Extension_Approval_Status__c
                );
            }
           
            
        }
         //Added NEwly on 28/11/2025 For notification for Owner change in booking
         if (!ownerChangedBookingIds.isEmpty()) {
             
                BookingController.sendOwnerChangeNotifications(ownerChangedBookingIds, oldOwnerMap);
             // Added for manual sharing on owner change
List<Booking__c> ownerChangedBookings = new List<Booking__c>();
for(Booking__c bk : Trigger.new){
if(ownerChangedBookingIds.contains(bk.Id)){
ownerChangedBookings.add(bk);
}
}
if(!ownerChangedBookings.isEmpty()){
manulaSharingClass.bookingsToShare(ownerChangedBookings);
}
             
             
            }
        //ended here
        if (cancellationBookings.size() > 0) {
            /* BookingController.bulkSendCancellationApproval(
cancellationBookings,
'Booking cancellation due to non-payment after 30 days of termination notice',
'This cancellation has been automatically generated by the system due to non-receipt of payment within 30 days of the termination notice.',
0
);*/
            BookingController.changeUnitStatus(cancellationBookings);
        }
        if(!handoverBookingIds.isEmpty()){
            System.debug('Called for Handover Mail');
            BookingController.sendHandOverEmailToCustomer(handoverBookingIds);
            
        }
        
        if(swappingBookings.size() >0){
            BookingController.swapUnit(swappingBookings);
        }  
        if(BookingIds.size() >0){
            BookingWelcomeMail.sendEmailToCustomersWithIds(BookingIds,'Cancellation');
        } 

        // ====== NEW: Reverse all demands and create credit notes for cancelled bookings ======
        if (!cancelledBookingIdsForDemandReversal.isEmpty()) {
            BookingCancellationDemandHandler.reverseDemandsAndCreateCreditNotes(cancelledBookingIdsForDemandReversal);
        }
        
               
        if (!approvedBookingIds.isEmpty()) {
            BookingController.swapApplicantData(approvedBookingIds);
        }
        // for Inserting Demand raise once booking status changed to Booked
        List<Demand_Raised__c> lstDemand = new List<Demand_Raised__c>();
        
        // Collect all Booking Ids where Stage changed to "Booked"
        Set<Id> bookedIds = new Set<Id>();
        for (Booking__c bk : Trigger.new) {
            Booking__c oldBk = Trigger.oldMap.get(bk.Id);
            if (oldBk != null && bk.Stage__c != oldBk.Stage__c && bk.Stage__c == 'Booked') {
                bookedIds.add(bk.Id);
            }
        }
        
        if (bookedIds.isEmpty()) return;
        
        // Query all first Payment Schedules for these Bookings
        Map<Id, Payment_schedule__c> bookingToSchedule = new Map<Id, Payment_schedule__c>();
        for (Payment_schedule__c ps : [ SELECT Id,Name , Amount__c, Amount1__c, AmountB__c, Master_Payment_Schedule__c, Booking__c FROM Payment_schedule__c WHERE Booking__c IN :bookedIds AND S_No__c = 1 ]) {
            bookingToSchedule.put(ps.Booking__c, ps);
        }
        
        
        /// updating the payment scheudle completed for Automatic Demand raise
        List<Payment_schedule__c> lstps = [ SELECT Id,Name , Amount__c, Amount1__c, AmountB__c, Master_Payment_Schedule__c, Booking__c FROM Payment_schedule__c WHERE Booking__c IN :bookedIds AND S_No__c != 1];
        List<Payment_schedule__c> updateList = new List<Payment_schedule__c>();
        for (Payment_schedule__c ps : lstps) {
            
            String nameVal = ps.Name != null ? ps.Name.toLowerCase() : '';
            
            if (nameVal.contains('within 30 days from booking date')) {
                ps.Completed_Date_New__c = System.today().addDays(30);
                updateList.add(ps);
            }
            if (nameVal.contains('within 90 days from booking date')) {
                ps.Completed_Date_New__c = System.today().addDays(90);
                updateList.add(ps);
            }
        }
        
        if (!updateList.isEmpty()) {
            update updateList;
        }
        // For Swaping the First Applicant to First Co Applicant  
        
        
        // For Sending the Custom Notification after approval
        List<Booking__c> bklist = new List<Booking__c>();
        
        For(Booking__c bk : Trigger.New){
            
            if (bk.Approval_status__c != Trigger.oldMap.get(bk.Id).Approval_status__c && (bk.Approval_status__c == 'Rejected' || bk.Approval_status__c == 'Approved')) {
                bklist.add(bk);
            }
        }
        if(bklist.size()>0){
            
            BookingController.sendNotificationsFromBooking(bklist);
        }
       // BookingTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
    
    
}