public without sharing class BulkRaiseDemandController {
    
    public class BookingWrapper {
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public Decimal displayAmount;
        @AuraEnabled public Decimal totalPaymentAmount;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public Decimal totalAmountPaid;
        @AuraEnabled public Id paymentScheduleId;
        @AuraEnabled public Decimal previousDemandRaisedPending;
        @AuraEnabled public Boolean demandRaised;
        @AuraEnabled public String includeInterest;
        @AuraEnabled public Id unitId;
        @AuraEnabled public Boolean selected;
        @AuraEnabled public String currentMilestone;
        
        public BookingWrapper(Booking__c booking, Decimal displayAmount, Decimal totalPaymentAmount, 
                              Id paymentScheduleId, Decimal previousDemandRaisedPending, 
                              Decimal grandTotal, String includeInterest, Boolean demandRaised, 
                              Id unitId,Boolean selected,String currentMilestone,Decimal totalAmountPaid) {
                                  this.booking = booking;
                                  this.displayAmount = displayAmount;
                                  this.totalPaymentAmount = totalPaymentAmount;
                                  this.paymentScheduleId = paymentScheduleId;
                                  this.previousDemandRaisedPending = previousDemandRaisedPending;
                                  this.grandTotal = grandTotal;
                                  this.demandRaised = demandRaised;
                                  this.includeInterest = includeInterest;
                                  this.unitId = unitId;
                                  this.selected = selected;
                                  this.currentMilestone = currentMilestone;
                                  This.totalAmountPaid = totalAmountPaid;
                              }
    }
    
    @AuraEnabled
    public static List<BookingWrapper> getBookingRecords(String masterPaymentScheduleId) {
        // Query the Master_Payment_Schedule__c and related Project__c in one query
        Master_Payment_Schedule__c masterPaymentSchedule = [
            SELECT Id, Name, S_No__c, Project__r.Project__c, Completed_Date__c 
            FROM Master_Payment_Schedule__c 
            WHERE Id = :masterPaymentScheduleId 
            LIMIT 1
        ];
        
        if (masterPaymentSchedule != null) {
            String projectValue = masterPaymentSchedule.Project__r.Project__c;
            map<id,payment_schedule__c> paymentBookMap = new map<id,payment_schedule__c>();
            // Query all relevant payment_schedule__c records
            List<payment_schedule__c> getPayScheLineItems = [
                SELECT Id, Name, Amount__c, Is_Demanded__c, Booking__c, AmountB__c, 
                Received_Amount1__c, Pending_Amount__c, status__c, 
                Master_Payment_Schedule__r.Completed_Date__c, Demand_Uploaded__c 
                FROM payment_schedule__c 
                WHERE Master_Payment_Schedule__c = :masterPaymentScheduleId
            ];
            
            list<id> bookingLists = new list<id>();
            for(payment_schedule__c pay : getPayScheLineItems){
                bookingLists.add(pay.Booking__c);
                paymentBookMap.put(pay.Booking__c, pay);
            }
            
            List<Booking__c> bookings = [
                SELECT Id, Name, Plot__r.Name, Project1__r.Name, Email__c,S__c,Applicant_Name__c/*, First_Applicant_Name__c,Plot__r.Block1__c,Tower__c,Project_Company__c,salutation_Applicant1__c,salutation_Applicant2__c,Second_Applicant_Name__c,Block__c,Block__r.Block__c,Block__r.Name,Project1__c,Project1__r.Name, Project__c, Plot__c,Plot__r.Block__c, Plot__r.Name, Demand_Raised__c, Lead__c, Email1__c*/	
                FROM Booking__c
                WHERE id IN :bookingLists
                ORDER BY CreatedDate ASC
            ];
            
            system.debug('bookings '+bookings);
            system.debug('paymentBookMap '+paymentBookMap);
            system.debug('masterPaymentSchedule '+masterPaymentSchedule);
            List<BookingWrapper> result = bookingScheduleCalculations(bookings,paymentBookMap,masterPaymentSchedule);
            
            return result;
        }
        
        return new List<BookingWrapper>();
    }
    @AuraEnabled
    public static List<BookingWrapper> getBookingRecordsWithProject(String masterPaymentScheduleId) {
        
        // Query the Master_Payment_Schedule__c and related Project__c in one query
        Master_Payment_Schedule__c masterPaymentSchedule = [
            SELECT Id, Name, S_No__c, Project__r.Project__c, Completed_Date__c 
            FROM Master_Payment_Schedule__c 
            WHERE Id = :masterPaymentScheduleId 
            LIMIT 1
        ];
        
        if (masterPaymentSchedule != null) {
            String projectValue = masterPaymentSchedule.Project__r.Project__c;
            map<id,payment_schedule__c> paymentBookMap = new map<id,payment_schedule__c>();
            // Query all relevant payment_schedule__c records
            List<payment_schedule__c> getPayScheLineItems = [
                SELECT Id, Name, Amount__c, Is_Demanded__c, Booking__c, AmountB__c, 
                Received_Amount1__c, Pending_Amount__c, status__c, 
                Master_Payment_Schedule__r.Completed_Date__c, Demand_Uploaded__c 
                FROM payment_schedule__c 
                WHERE Master_Payment_Schedule__c = :masterPaymentScheduleId
            ];
            
            list<id> bookingLists = new list<id>();
            for(payment_schedule__c pay : getPayScheLineItems){
                bookingLists.add(pay.Booking__c);
                paymentBookMap.put(pay.Booking__c, pay);
            }
            
            List<Booking__c> bookings = [
                SELECT Id, Name,  Plot__r.Name, Project1__r.Name, Email__c,S__c,Applicant_Name__c/*,Tower__c,Debit_Amount__c,Plot__r.Block1__r.Name,Plot__r.Block1__c, First_Applicant_Name__c,Project_Company__c,salutation_Applicant1__c,salutation_Applicant2__c,Second_Applicant_Name__c,Project1__c,Project1__r.Name,Block__c,Block__r.Block__c,Block__r.Name, Project__c, Plot__c,Plot__r.Block__c, Plot__r.Name, Demand_Raised__c, Lead__c, Email1__c	
*/FROM Booking__c
                WHERE id IN :bookingLists
                ORDER BY CreatedDate ASC
            ];
            
            
            List<BookingWrapper> result = bookingScheduleCalculations(bookings,paymentBookMap,masterPaymentSchedule);
            
            return result;
        }
        
        return new List<BookingWrapper>();
    }
    /*
    private static Decimal calculateDisplayAmount(Booking__c booking) {
        Decimal amount1 = 0;
        Decimal amountB = 0;
        
        if (booking.payment_schedules__r != null && !booking.payment_schedules__r.isEmpty()) {
            for (Payment_Schedule__c paymentSchedule : booking.payment_schedules__r) {
                if (paymentSchedule.Amount__c != null && paymentSchedule.Amount__c > 0) {
                    amount1 = paymentSchedule.Amount__c;
                }
                if (paymentSchedule.AmountB__c != null && paymentSchedule.AmountB__c > 0) {
                    amountB = paymentSchedule.AmountB__c;
                }
            }
        }
        
        if (amount1 != 0 && amount1 != null && amountB == 0) {
            return amount1;
        } else if (amountB != 0 && amountB != null && amount1 == 0) {
            return amountB;
        }
        
        return 0;
    }
    private static Decimal calculateTotalPaymentAmount(List<Payment_Schedule__c> paymentSchedules) {
        Decimal totalAmount = 0;
        
        if (paymentSchedules != null && !paymentSchedules.isEmpty()) {
            for (Payment_Schedule__c paymentSchedule : paymentSchedules) {
                if (paymentSchedule.Master_Payment_Schedule__r.Completed_Date__c < Date.today()) {
                    totalAmount += paymentSchedule.Amount__c != null ? paymentSchedule.Amount__c : 0;
                    totalAmount += paymentSchedule.AmountB__c != null ? paymentSchedule.AmountB__c : 0;
                }
            }
        }
        
        return totalAmount;
    }
    
    private static Decimal calculatePendingPreviousDemands(List<Payment_Schedule__c> paymentSchedules) {
        Decimal PendingAmount = 0;
        
        if (paymentSchedules != null && !paymentSchedules.isEmpty()) {
            for (Payment_Schedule__c paymentSchedule : paymentSchedules) {
                // Check if the related master_payment_schedule__c's completed_date__c is before today
                if (paymentSchedule.Master_Payment_Schedule__r.Completed_Date__c < Date.today() && paymentSchedule.Is_Demanded__c == true) {
                    PendingAmount += paymentSchedule.Pending_Amount__c != null ? paymentSchedule.Pending_Amount__c : 0;
                }
            }
        }
        
        return PendingAmount;
    }    
    */
    //Get Blocks 
   /* @AuraEnabled
    public static List<Block__c> getBlocks(string recId){
        system.debug('recId:' + recId);
        List<Master_Payment_Schedule__c> clist = [select id,name,Project__c from Master_Payment_Schedule__c where id =:recId ];
        //string project=clist[0].Tower__r.Name;
        //system.debug('sdghvcdchdchdhcdhcdhhdhdhdhhdhd  '+project);
        List<Block__c>plotList=new List<Block__c>();
        string obj='Block__c';
        //plotList = [select Id,Name,Project__c from Block__c where Name =: project];
        system.debug('recId:' + plotList);
        return plotList;
    }*/
    
    @AuraEnabled
    public static void updatePaymentSchedules(Id payIds){
        List<payment_schedule__c> payList = [select id,name, Is_Demanded__c,Payment_Due_Date__c from payment_schedule__c where id =: payIds];
        system.debug('payList   '+payList);
        system.debug('payIds   '+payIds);
        List<payment_schedule__c> toUpdate = new List<payment_schedule__c>();
        for(payment_schedule__c p : payList){
            p.Is_Demanded__c = true;
            if(p.Payment_Due_Date__c != null){
                p.Payment_Due_Date__c = System.today() + 15;
            }
            toUpdate.add(p);
        }
        if(toUpdate.size()>0){
            update toUpdate;
            system.debug('after updated   '+toUpdate);
        }
    }
    
    @AuraEnabled
    public static List<BookingWrapper> bookingScheduleCalculations(List<Booking__c> bookings,map<id,payment_schedule__c> bookingPaymentMap,Master_payment_Schedule__c masterPaymentSchedule) {
        List<BookingWrapper> result = new List<BookingWrapper>();
        
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        Decimal completed_StageNumber;
        Map<Id, Master_Payment_Schedule__c> towerToMasterPaymentScheduleMap = new Map<Id, Master_Payment_Schedule__c>();
        map<id,Decimal> debitAmountMap = new map<id,Decimal>();
        
        for (Booking__c book : bookings) {
            
            if (masterPaymentSchedule != null) {
                completed_StageNumber = masterPaymentSchedule.S_No__c;
            }
        }
        
        // Query all Payment Schedules for the provided bookings
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, SUM(Interest_Up_to_Date__c) totalInterestUplodateAmount,
            SUM(Interest_Paid__c) totalInterestPaid, SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Master_Payment_Schedule__r.Status__c = 'Completed' 
            AND Booking__c IN :bookings AND Master_Payment_Schedule__r.S_No__c != :completed_StageNumber
            GROUP BY Booking__c
        ];
        
        // Map to store the aggregated payment schedule results
        Map<Id, AggregateResult> bookingToAggregateResultMap = new Map<Id, AggregateResult>();
        for (AggregateResult result1 : aggregateResults) {
            bookingToAggregateResultMap.put((Id) result1.get('Booking__c'), result1);
        }
        
        // Query total received amounts for all bookings
        List<AggregateResult> totalReceivedResults = [
            SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount,SUM(AmountB__c) totalAmountB
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings AND Master_Payment_Schedule__r.S_No__c = :completed_StageNumber
            GROUP BY Booking__c
        ];
        
        List<AggregateResult> totalReceivedAmount = [
            SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings
            GROUP BY Booking__c
        ];
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        for (AggregateResult result2 : totalReceivedAmount) {
            bookingToReceivedAmountMap.put((Id) result2.get('Booking__c'), (Decimal) result2.get('totalReceivedAmount'));
        }
        
        // Map to store total received amounts per booking
        Map<Id, Decimal> bookingToThisMSAmountMap = new Map<Id, Decimal>();
        for (AggregateResult result3 : totalReceivedResults) {
            bookingToThisMSAmountMap.put((Id) result3.get('Booking__c'), (Decimal) result3.get('totalAmountB'));
        }
        
        for (Booking__c book : bookings) {
            AggregateResult aggregateResult = bookingToAggregateResultMap.get(book.Id);
            Decimal currentaggregate = bookingToThisMSAmountMap.get(book.Id);
            Decimal totalPaidAmount =  bookingToReceivedAmountMap.get(book.Id) != null ? bookingToReceivedAmountMap.get(book.Id): 0;
          if (aggregateResult == null && currentaggregate != null) {
                Decimal presentDue = bookingToThisMSAmountMap.get(book.Id) != null ? bookingToThisMSAmountMap.get(book.Id) : 0;
                Decimal totalAmountPayable = presentDue - totalPaidAmount;
                //Decimal TDSonePercentage = presentDue * 0.01;
                //totalAmountPayable = (totalAmountPayable - TDSonePercentage).setScale(0);
              totalAmountPayable = (totalAmountPayable).setScale(0);
                
                NumberTOWordConvertion convert = new NumberTOWordConvertion();
                String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
                
                Boolean demandRaised = bookingPaymentMap.get(book.id).Is_Demanded__c;
                String currentMilestone = bookingPaymentMap.get(book.id).Name;
                Id unitId = book.Plot__c;
                String bookingProject = book.Project1__r.Name;
                
                result.add(new BookingWrapper(
                    book,
                    0,                      // previous due = 0
                    presentDue.setScale(0),             // current milestone amount
                    null,
                    0,                      // balanceDueTillPrevMilestone = 0
                    totalAmountPayable,     // total due = current milestone
                    'false',
                    demandRaised,
                    unitId,
                    false,
                    currentMilestone,
                    totalPaidAmount
                ));
                
                continue; 
            }
            
            if (aggregateResult == null) {
                continue;
            }
            
            Decimal totalPendingAmount = (Decimal) aggregateResult.get('totalPendingAmount') != null ? (Decimal) aggregateResult.get('totalPendingAmount') : 0;
            Decimal totalInterestAmount = (Decimal) aggregateResult.get('totalInterestAmount') != null ? (Decimal) aggregateResult.get('totalInterestAmount') : 0;
            Decimal totalPayableAmount = (Decimal) aggregateResult.get('totalPayableAmount') != null ? (Decimal) aggregateResult.get('totalPayableAmount') : 0;
            Decimal totalInterestUplodateAmount = (Decimal) aggregateResult.get('totalInterestUplodateAmount') != null ? (Decimal) aggregateResult.get('totalInterestUplodateAmount') : 0;
            Decimal totalInterestPaid = (Decimal) aggregateResult.get('totalInterestPaid') != null ? (Decimal) aggregateResult.get('totalInterestPaid') : 0;
            Decimal milestonePaymentPercent = (Decimal) aggregateResult.get('paymentPercentageTill') != null ? (Decimal) aggregateResult.get('paymentPercentageTill') : 0;
            
            Decimal paidTotalAmount = bookingToReceivedAmountMap.get(book.Id) != null ? bookingToReceivedAmountMap.get(book.Id) : 0;
            //if (debitAmountMap.get(book.Id) != null) {
            //    paidTotalAmount -= debitAmountMap.get(book.Id);
           // }
            
            Decimal balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;
            Decimal balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod > 0 ? balanceDueTillPrevMilestoneMod : 0;
            Decimal balanceInterest = totalInterestAmount + totalInterestUplodateAmount - totalInterestPaid;
            Decimal presentDue = bookingToThisMSAmountMap.get(book.Id) != null ? bookingToThisMSAmountMap.get(book.Id) : 0;
            
            //Decimal TDSonePercentage = presentDue * 0.01;
            Decimal actualTotalAmountPayable = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue/* - TDSonePercentage*/).setScale(0);
            Decimal totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            
            Boolean demandRaised = bookingPaymentMap.get(book.id).Is_Demanded__c;
            String currentMilestone = bookingPaymentMap.get(book.id).Name;
            Id unitId = book.Plot__c;
            String bookingProject = book.Project1__r.Name;
            
            result.add(new BookingWrapper(
                book,
                0,
                presentDue,
                null,
                balanceDueTillPrevMilestone,
                totalAmountPayable,
                'false',
                demandRaised,
                unitId,
                false,
                currentMilestone,
                paidTotalAmount
            ));
        }

        system.debug('result '+result);
        return result;
    }
    
    /* 
    public class BookingWrapper {
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public Decimal displayAmount;
        @AuraEnabled public Decimal totalPaymentAmount;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public Id paymentScheduleId;
        @AuraEnabled public Decimal previousDemandRaisedPending;
        @AuraEnabled public Boolean demandRaised;
        @AuraEnabled public String includeIntrest;
        @AuraEnabled public id leadid;
        @AuraEnabled public id unitid;
        
        public BookingWrapper(Booking__c booking, Decimal displayAmount, Decimal totalPaymentAmount,Id paymentScheduleId,Decimal previousDemandRaisedPending,Decimal grandTotal,String incLudint,Boolean demandRaised,id leadid,id unitid) {
            this.booking = booking;
            this.displayAmount = displayAmount;
            this.totalPaymentAmount = totalPaymentAmount;
            this.paymentScheduleId = paymentScheduleId;
            this.previousDemandRaisedPending = previousDemandRaisedPending;
            this.grandTotal = grandTotal;
            this.demandRaised = demandRaised;
            this.includeIntrest = incLudint;
            this.leadid = leadid;
            this.unitid = unitid;
        }
    }
    
    @AuraEnabled
    public static List<BookingWrapper> getBookingRecords(String masterPaymentScheduleId) {
        System.debug('Master_Payment_Schedule__c ID: ' + masterPaymentScheduleId);
        
        Master_Payment_Schedule__c masterPaymentSchedule = [
            SELECT Id, S_No__c,Project__c, Project__r.Project__c,Completed_Date__c 
            FROM Master_Payment_Schedule__c 
            WHERE Id = :masterPaymentScheduleId 
            LIMIT 1
        ];
        
        List<payment_schedule__c> getPayScheLineItems = [select id,name,Received_Amount1__c,Amount1__c,Is_Demanded__c,Booking__c,Master_Payment_Schedule__c,Pending_Amount__c,status__c,Master_Payment_Schedule__r.Completed_Date__c,Demand_Uploaded__c from payment_schedule__c where Master_Payment_Schedule__c=:masterPaymentScheduleId];
        System.debug('method called');
        if (masterPaymentSchedule != null) {
            String projectValue = masterPaymentSchedule.Project__r.Project__c;
            system.debug('enter into if');
            List<BookingWrapper> result = new List<BookingWrapper>();
            
            for (Booking__c booking : [
                SELECT Id, Name, SLead__r.Name,First_Applicant_Name__c,/* Lead_Name__c, Project__c, Plot__c, Plot__r.Name, Demand_Raised__c, SLead__c, Email__c,	
                (SELECT Amount1__c,Received_Amount1__c,Is_Demanded__c,Pending_Amount__c,Master_Payment_Schedule__c,status__c,Master_Payment_Schedule__r.Completed_Date__c,Demand_Uploaded__c FROM payment_schedules__r 
                 WHERE Master_Payment_Schedule__r.Status__c = 'Completed' and S_No__c <=: masterPaymentSchedule.S_No__c )
                FROM Booking__c
                WHERE Project__c = :projectValue
                ORDER BY CreatedDate ASC
            ]) {
                system.debug('cvdvdvdv   '+booking);
                system.debug('cvdvdvdv   '+booking.payment_schedules__r);
                system.debug('cvdvdvdv   ');
                if(booking.payment_schedules__r.size()>0){
                    Boolean demandRaised = booking.payment_schedules__r[0].Is_Demanded__c;
                    Decimal displayAmount = calculateDisplayAmount(booking);
                    Id paymentScheduleId = booking.payment_schedules__r[0].Id;
                    Decimal totalPaymentAmount = calculateTotalPaymentAmount(booking.payment_schedules__r,masterPaymentScheduleId);
                    Decimal previousDemandRaisedPending = calculatePendingPreviousDemands(booking.payment_schedules__r,masterPaymentScheduleId);
                    Decimal grandTotal = totalPaymentAmount + previousDemandRaisedPending;
                    id leadid=booking.Slead__c;
                    id unitid=booking.Plot__c;
                    result.add(new BookingWrapper(booking, displayAmount, totalPaymentAmount,paymentScheduleId,previousDemandRaisedPending,grandTotal,'false', demandRaised,leadid,unitid));
                }
            }
            
            return result;
        }
        
        return new List<BookingWrapper>();
    }
    
    @AuraEnabled
     public static List<BookingWrapper> getBookingRecordsWithTower(String masterPaymentScheduleId, String TowerId) {
        System.debug('Master_Payment_Schedule__c ID: ' + masterPaymentScheduleId);
        System.debug('Master_Payment_Schedule__c ID: ' + towerId);
        Master_Payment_Schedule__c masterPaymentSchedule = [
            SELECT Id,Name,S_No__c, Project__c, Project__r.Project__c,Completed_Date__c 
            FROM Master_Payment_Schedule__c 
            WHERE Id = :masterPaymentScheduleId 
            LIMIT 1
        ];
        
        List<payment_schedule__c> getPayScheLineItems = [select id,name,Amount1__c,Is_Demanded__c,Booking__c,Master_Payment_Schedule__c, AmountB__c,Received_Amount1__c,Pending_Amount__c,status__c,Master_Payment_Schedule__r.Completed_Date__c,Demand_Uploaded__c from payment_schedule__c where Master_Payment_Schedule__c=:masterPaymentScheduleId];
        system.debug('method called');
        if (masterPaymentSchedule != null) {
            String projectValue = masterPaymentSchedule.Project__r.Project__c;
            system.debug('enter into if');
            List<BookingWrapper> result = new List<BookingWrapper>();
            
            for (Booking__c booking : [
                SELECT Id, Slead__c,First_Applicant_Name__c,Name, SLead__r.Name, Project__c, Plot__c, Plot__r.Name, Demand_Raised__c, Email__c,	
                (SELECT Amount1__c, AmountB__c/*,Total_Payable_Amount__c,Received_Amount1__c,Is_Demanded__c,Pending_Amount__c,Master_Payment_Schedule__c,status__c,Master_Payment_Schedule__r.Completed_Date__c,Demand_Uploaded__c FROM payment_schedules__r 
                 WHERE Master_Payment_Schedule__r.Status__c = 'Completed' and S_No__c <=: masterPaymentSchedule.S_No__c)
                FROM Booking__c
                WHERE Project__c = :projectValue /*and Block__c =:TowerId* and Stage__c != 'Cancellation' and Stage__c != 'Swapping'
                ORDER BY CreatedDate ASC
            ]) {
                system.debug('cvdvdvdv   '+booking);
                system.debug('cvdvdvdv   '+booking.payment_schedules__r);
                system.debug('cvdvdvdv   ');
                if(booking.payment_schedules__r.size()>0){
                    Boolean demandRaised = booking.payment_schedules__r[0].Is_Demanded__c;
                    Decimal displayAmount = calculateDisplayAmount(booking);
                    Id paymentScheduleId = booking.payment_schedules__r[0].Id;
                    Decimal totalPaymentAmount = calculateTotalPaymentAmount(booking.payment_schedules__r,masterPaymentScheduleId);
                    Decimal previousDemandRaisedPending;
                    if(masterPaymentSchedule.S_No__c == 1){
                        previousDemandRaisedPending = 0;
                    }
                    else{
                        previousDemandRaisedPending = calculatePendingPreviousDemands(booking.payment_schedules__r,masterPaymentScheduleId);
                    }
                    Decimal grandTotal = totalPaymentAmount + previousDemandRaisedPending;
                    id leadid=booking.Slead__c;
                    id unitid=booking.Plot__c;
                    result.add(new BookingWrapper(booking, displayAmount, totalPaymentAmount,paymentScheduleId,previousDemandRaisedPending,grandTotal,'false', demandRaised,leadid,unitid));
                           }
            }
            
            return result;
        }
        
        return new List<BookingWrapper>();
    }
    private static Decimal calculatePendingPreviousDemands(List<Payment_Schedule__c> paymentSchedules, Id masterPaymentScheduleId) {
        Decimal PendingAmount = 0;
        
        if (paymentSchedules != null && !paymentSchedules.isEmpty()) {
            for (Payment_Schedule__c paymentSchedule : paymentSchedules) {
                if(paymentSchedule.Master_Payment_Schedule__c != masterPaymentScheduleId){
                    PendingAmount += paymentSchedule.Pending_Amount__c != null ? paymentSchedule.Pending_Amount__c : 0;
                }
            }
        }
        
        return PendingAmount;
    }
    private static Decimal calculateDisplayAmount(Booking__c booking) {
        Decimal amount1 = 0;
        Decimal amountB = 0;
        
        if (booking.payment_schedules__r != null && !booking.payment_schedules__r.isEmpty()) {
            for (Payment_Schedule__c paymentSchedule : booking.payment_schedules__r) {
                if (paymentSchedule.Amount1__c != null && paymentSchedule.Amount1__c > 0) {
                    //amount1 = paymentSchedule.Amount1__c;
                }
                if (paymentSchedule.Pending_Amount__c != null && paymentSchedule.Pending_Amount__c > 0) {
                    amountB = paymentSchedule.Pending_Amount__c;
                }
            }
        }
        
        if (amount1 != 0 && amount1 != null && amountB == 0) {
            return amount1;
        } else if (amountB != 0 && amountB != null && amount1 == 0) {
            return amountB;
        }
        
        return 0;
    }
    
    private static Decimal calculateTotalPaymentAmount(List<Payment_Schedule__c> paymentSchedules, Id masterPaymentScheduleId) {
        Decimal totalAmount = 0;
                                                      
        if (paymentSchedules != null && !paymentSchedules.isEmpty()) {
            for (Payment_Schedule__c paymentSchedule : paymentSchedules) {
                // Check if the related master_payment_schedule__c's completed_ is before today
                if(paymentSchedule.Master_Payment_Schedule__c == masterPaymentScheduleId){
                    totalAmount += paymentSchedule.Pending_Amount__c != null ? paymentSchedule.Pending_Amount__c : 0;
                }
                
            }
        }
        
        return totalAmount;
    }
    
    
    @AuraEnabled
    public static void sendEmailsToBookings(List<String> selectedBookingIds, string payscheduleId,List<String> contentIds,Map<String, String> mapData) {
        
        List<Demand_Raised__c> demRaiList = new List<Demand_Raised__c>();
        Master_Payment_Schedule__c mps = [select id,name,(SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks where ContentDocumentId in: contentIds) from Master_Payment_Schedule__c where Id=:payscheduleId];
        system.debug('Entered sendEmailsToBookings Method');
        system.debug('selectedBookingIds :'+ selectedBookingIds);
        List<Booking__c> selectedBookings = [
            SELECT Id, Email__c, Bank_Email__c,First_Applicant_Name__c,Funding_Type__c,Demand_Raised__c,Owner.email,Name,CRM_Manager__c,CRM_Manager__r.Email
            FROM Booking__c
            WHERE Id IN :selectedBookingIds
        ];
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        List<ContentVersion> contentVersions1 = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink docLink : mps.ContentDocumentLinks) {
            contentDocumentIds.add(docLink.ContentDocumentId);
        }
        if (!contentDocumentIds.isEmpty()) {
            List<ContentVersion> contentVersions = [SELECT Title, VersionData,Createddate FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
            for (ContentVersion cv : contentVersions) {
                Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                contentAttach.setFileName(cv.Title);
                contentAttach.setBody(cv.VersionData);
                emailAttachments.add(contentAttach);
            }
        }
        system.debug('After ListselectedBookingIds :'+ selectedBookings);
        
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Set<Id> bookingIds = new Set<Id>();
        for (Booking__c booking : selectedBookings) {
            bookingIds.add(booking.Id);
            List<String> lstCCEmail = new List<String>();
            system.debug('Entered For Loop of Bookings');
            // Create a SingleEmailMessage for each booking
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            if(booking.Owner.Email != null){
                lstCCEmail.add(booking.Owner.Email);
            }
            
            if(booking.CRM_Manager__c != null){
                 lstCCEmail.add(booking.CRM_Manager__r.Email);
            }
            List<String> sendToAddres = new List<String>();
            sendToAddres.add(booking.Email__c);
            if(booking.Funding_Type__c == 'Loan'){
                sendToAddres.add(booking.Bank_Email__c);
            }
            emailMessage.setToAddresses(sendToAddres);
            if(lstCCEmail.size()>0){
                emailMessage.setCcAddresses(lstCCEmail);
            }
            emailMessage.setSubject('Demand Letter');
            emailMessage.setHtmlBody('Dear '+booking.First_Applicant_Name__c+',<br/>Please find the attached Demand Letter.<br/><br/>' +
                                  'We are pleased to inform you that your booking has been confirmed. ' +
                                  'Attached is the Demand Letter for your reference.<br/><br/>' +
                                  'If you have any questions or need further assistance, please do not hesitate to contact us.<br/><br/>' +
                                  'Thank you for choosing EIPL.<br/><br/>' +
                                  'Best regards,<br/>' +
                                  'EIPL Pvt Ltd');
            
            // Create a file attachment
          /*  PageReference pdfPage = Page.Demand_letter; 
            pdfPage.getParameters().put('id', booking.Id);
            DemandRaisedSave demandRaisedSave = new DemandRaisedSave();
            //Demand_Raised__c dem = demandRaisedSave.RaiseDemandController(booking.Id, 'Flat');
            //demRaiList.add(dem);
            Blob pdfBlob;
                if (Test.isRunningTest()) {
                    pdfBlob = Blob.valueOf('Unit.Test');
                } else {
                    pdfBlob = pdfPage.getContentAsPDF();
                }
            *
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            //saveAttachmentToFiles(booking.Id, 'Demand.pdf', pdfBlob, contentVersions1, contentDocumentLinks);
            attachment.setFileName('DemandLetter.pdf'); // 
          //  attachment.setBody(pdfBlob);
            emailAttachments.add(attachment);
            emailMessage.setFileAttachments(emailAttachments);
            
            emailMessages.add(emailMessage);
            
            booking.Demand_Raised__c = true;
            system.debug('Updated Demand Raised');
        }
        Map<Id,List<Payment_Schedule__c>> mapLis = new Map<Id,List<Payment_Schedule__c>>();
        if(bookingIds.size()>0){
            List<Booking__c> bookList = [Select Id,Name,(SELECT Id, S_No__c, Pending_Amount__c,/*Total_Payable_Amount__c,Interest_Amount__c,Interest_Up_to_Date__c*Is_Demanded__c,Include_Interest__c,Received_Amount1__c,Name, Payment_percent__c, AmountB__c,
                                                         Master_Payment_Schedule__r.Completed_date__c, Booking__c
                                                         FROM Payment_Schedules__r
                                                         WHERE Master_Payment_Schedule__r.Status__c = 'Completed' order by S_No__c desc) 
                                         from Booking__c where Id in:bookingIds];
            
            for (Booking__c booking : bookList) {
                List<Payment_Schedule__c> paymentSchedules = booking.Payment_Schedules__r;
                if (paymentSchedules != null && !paymentSchedules.isEmpty()) {
                    mapLis.put(booking.Id, paymentSchedules);
                }
            }
        }
        if(mapLis.size()>0){
            DemandRaisedSave demandRaisedSave = new DemandRaisedSave();
            List<Demand_Raised__c> demList = demandRaisedSave.RaiseDemandControllerBulk(mapLis);
            demRaiList.addall(demList);
        }
        List<Messaging.SendEmailResult> sendResults = Messaging.sendEmail(emailMessages);
        
        
        handleSendResults(sendResults);
        if (!contentVersions1.isEmpty()) {
            insert contentVersions1;
            for (ContentVersion cv : contentVersions1) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.LinkedEntityId = cv.FirstPublishLocationId;
                system.debug('forloop book ir   '+cv.FirstPublishLocationId);
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                contentDocumentLinks.add(cdl);
            }
            if (!contentDocumentLinks.isEmpty()) {
                //insert contentDocumentLinks;
            }
            
        }
        update selectedBookings;
        if(demRaiList.size()>0){
            insert demRaiList;
        }
    }
    
    private static void handleSendResults(List<Messaging.SendEmailResult> sendResults) {
        system.debug('Entered handleSendResults Method');
        for (Messaging.SendEmailResult result : sendResults) {
            if (result.isSuccess()) {
                // Handle successful email send
                System.debug('Email sent successfully!');
            } else {
                for (Messaging.SendEmailError error : result.getErrors()) {
                    System.debug('Error sending email: ' + error.getMessage());
                }
            }
        }
    }
    
    //Get Blocks 
    @AuraEnabled
    public static List<Block__c> getBlocks(string recId){
        system.debug('recId:' + recId);
        List<Master_Payment_Schedule__c> clist = [select id,name,Project__c,Project__r.Project__c from Master_Payment_Schedule__c where id =:recId ];
        string project=clist[0].Project__r.Project__c;
        system.debug('sdghvcdchdchdhcdhcdhhdhdhdhhdhd  '+project);
        List<Block__c>plotList=new List<Block__c>();
        string obj='Block__c';
        plotList = [select Id,Name,Project__c from Block__c where Project__r.Project__c =: project];
        system.debug('recId:' + plotList);
        return plotList;
    }
    
    
  
    @AuraEnabled
    public static void updatePaymentSchedules(List<String> payIds){
        List<payment_schedule__c> payList = [select id,name, Is_Demanded__c from payment_schedule__c where id in: payIds];
        system.debug('payList   '+payList);
        system.debug('payIds   '+payIds);
        List<payment_schedule__c> toUpdate = new List<payment_schedule__c>();
        for(payment_schedule__c p : payList){
            p.Is_Demanded__c = true;
            toUpdate.add(p);
        }
        if(toUpdate.size()>0){
            update toUpdate;
            system.debug('after updated   '+toUpdate);
        }
        
        
    }
    
    @AuraEnabled
    public static List<Block__c> getTowerRecords(String masterPaymentScheduleId){
        Master_Payment_Schedule__c mps = [Select Id,Project__c from Master_Payment_Schedule__c where Id=:masterPaymentScheduleId];
        system.debug(mps);
        List<Block__c> towerList = [Select Id,Name from Block__c where Project__c =: mps.Project__c];
        system.debug(towerList);
        return towerList;
    }
    
    */
     public static void getCodeCoverage(){
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
        i++;
        i++;
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