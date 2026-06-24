public with sharing class BookingTriggerHandlerPostS {
   
    
    /* ================= AFTER INSERT ================= */
    public static void afterInsert(List<Booking__c> newBookings) {
      //  handleCommissionCreation(newBookings, null, true);
        handleCustomerMasterCreation(newBookings);
    }

    /* ================= CUSTOMER MASTER CREATION ON BOOKING INSERT ================= */
    public static void handleCustomerMasterCreation(List<Booking__c> newBookings) {
        // 1. Collect mobile numbers from bookings that don't have Customer_Master__c
        Set<String> mobileNumbers = new Set<String>();
        List<Booking__c> bookingsToProcess = new List<Booking__c>();
        for (Booking__c bk : newBookings) {
            if (bk.Customer_Master__c == null && String.isNotBlank(bk.Mobile__c)) {
                mobileNumbers.add(bk.Mobile__c);
                bookingsToProcess.add(bk);
            }
        }

        if (bookingsToProcess.isEmpty()) {
            return;
        }

        // 2. Check if active Customer_Master__c already exists with the same phone number
        Map<String, Customer_Master__c> phoneToCustomerMap = new Map<String, Customer_Master__c>();
        for (Customer_Master__c cm : [SELECT Id, Phone_Number__c FROM Customer_Master__c WHERE Phone_Number__c IN :mobileNumbers AND Active__c = true]) {
            phoneToCustomerMap.put(cm.Phone_Number__c, cm);
        }

        // 3. Separate bookings: link existing customer OR create new
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        List<Customer_Master__c> customersToInsert = new List<Customer_Master__c>();
        Map<String, List<Booking__c>> phoneToBookingsMap = new Map<String, List<Booking__c>>();

        for (Booking__c bk : bookingsToProcess) {
            if (phoneToCustomerMap.containsKey(bk.Mobile__c)) {
                // Existing customer found — just link
                bookingsToUpdate.add(new Booking__c(
                    Id = bk.Id,
                    Customer_Master__c = phoneToCustomerMap.get(bk.Mobile__c).Id
                ));
            } else {
                // No customer found — create new
                Customer_Master__c newCust = new Customer_Master__c(
                    Customer_Name__c = bk.First_Applicant_Name__c,
                    Phone_Number__c = bk.Mobile__c,
                    Email__c = bk.Email__c,
                    Aadhaar_Number__c = bk.Aadhar_No__c,
                    PAN_Number__c = bk.PAN_Number__c,
                    Password__c = generatePassword(),
                    Active__c = true
                );
                customersToInsert.add(newCust);

                if (!phoneToBookingsMap.containsKey(bk.Mobile__c)) {
                    phoneToBookingsMap.put(bk.Mobile__c, new List<Booking__c>());
                }
                phoneToBookingsMap.get(bk.Mobile__c).add(bk);
            }
        }

        // 4. Insert new customers and link to bookings
        if (!customersToInsert.isEmpty()) {
            insert customersToInsert;
            for (Customer_Master__c cm : customersToInsert) {
                if (phoneToBookingsMap.containsKey(cm.Phone_Number__c)) {
                    for (Booking__c bk : phoneToBookingsMap.get(cm.Phone_Number__c)) {
                        bookingsToUpdate.add(new Booking__c(
                            Id = bk.Id,
                            Customer_Master__c = cm.Id
                        ));
                    }
                }
            }
        }

        // 5. Update bookings with Customer_Master__c
        if (!bookingsToUpdate.isEmpty()) {
            update bookingsToUpdate;
        }
    }

    /* ================= PASSWORD GENERATOR ================= */
    public static String generatePassword() {
        String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        String lower = 'abcdefghijklmnopqrstuvwxyz';
        String nums = '0123456789';
        String special = '!@#$%&*';

        List<String> pwdChars = new List<String>();
        // Guaranteed 1 of each type
        Integer ui = Math.mod(Math.abs(Crypto.getRandomInteger()), upper.length());
        pwdChars.add(upper.substring(ui, ui + 1));
        Integer li = Math.mod(Math.abs(Crypto.getRandomInteger()), lower.length());
        pwdChars.add(lower.substring(li, li + 1));
        Integer ni = Math.mod(Math.abs(Crypto.getRandomInteger()), nums.length());
        pwdChars.add(nums.substring(ni, ni + 1));
        Integer si = Math.mod(Math.abs(Crypto.getRandomInteger()), special.length());
        pwdChars.add(special.substring(si, si + 1));

        // Fill remaining 2 chars from all characters
        String allChars = upper + lower + nums + special;
        for (Integer i = 0; i < 2; i++) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), allChars.length());
            pwdChars.add(allChars.substring(idx, idx + 1));
        }

        // Shuffle to randomize position
        String pwd = '';
        while (!pwdChars.isEmpty()) {
            Integer ri = Math.mod(Math.abs(Crypto.getRandomInteger()), pwdChars.size());
            pwd += pwdChars.remove(ri);
        }
        return pwd;
    }
    
    /* ================= AFTER UPDATE ================= */
    public static void afterUpdate(List<Booking__c> newBookings,  Map<Id, Booking__c> oldMap ) {
       // handleCommissionCreation(newBookings, oldMap, false);
        handleAgreementStageRewards(newBookings, oldMap);
    }

    /* ================= AGREEMENT STAGE → Reward + Referral Update ================= */
    public static void handleAgreementStageRewards(List<Booking__c> newBookings, Map<Id, Booking__c> oldMap) {
        // 1. Collect bookings whose Stage changed to 'Agreement'
        List<Booking__c> agreementBookings = new List<Booking__c>();
        for (Booking__c bk : newBookings) {
            Booking__c oldBk = oldMap.get(bk.Id);
            if (bk.Stage__c == 'Agreement' && oldBk.Stage__c != 'Agreement') {
                agreementBookings.add(bk);
            }
        }

        if (agreementBookings.isEmpty()) {
            return;
        }

        // 2. Collect Project Ids, Lead Ids, and Customer Master Ids
        Set<Id> projectIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> customerMasterIds = new Set<Id>();
        for (Booking__c bk : agreementBookings) {
            if (bk.Project1__c != null) projectIds.add(bk.Project1__c);
            if (bk.SLead__c != null) leadIds.add(bk.SLead__c);
            if (bk.Customer_Master_Lead__c != null) customerMasterIds.add(bk.Customer_Master_Lead__c);
        }

        // 2a. Fetch Leads and verify they belong to the booking's Customer Master
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        if (!leadIds.isEmpty()) {
            for (Lead ld : [SELECT Id, Customer_Master__c FROM Lead WHERE Id IN :leadIds AND Customer_Master__c IN :customerMasterIds]) {
                leadMap.put(ld.Id, ld);
            }
        }

        // 3. Fetch Reward Criteria by Project and Type 'Booking'
        Map<Id, Reward_Criteria__c> rewardCriteriaMap = new Map<Id, Reward_Criteria__c>();
        if (!projectIds.isEmpty()) {
            for (Reward_Criteria__c rc : [SELECT Id, Reward_Type__c, Project__c, Referral_Amount__c FROM Reward_Criteria__c WHERE Reward_Type__c = 'Booking' AND Project__c IN :projectIds]) {
                rewardCriteriaMap.put(rc.Project__c, rc);
            }
        }

        // 4. Create Reward records
        List<Reward__c> rewardsToInsert = new List<Reward__c>();
        for (Booking__c bk : agreementBookings) {
            if (bk.Customer_Master_Lead__c != null && bk.Project1__c != null) {
                Reward_Criteria__c rc = rewardCriteriaMap.get(bk.Project1__c);
                if (rc != null) {
                        // Find Referral__c for this Booking's Lead
                        Referral__c referral = null;
                        if (bk.SLead__c != null) {
                            List<Referral__c> referralList = [SELECT Id FROM Referral__c WHERE Lead__c = :bk.SLead__c LIMIT 1];
                            if (!referralList.isEmpty()) {
                                referral = referralList[0];
                            }
                        }
                        // Map Reward_Criteria__c lookup
                        Id rewardCriteriaId = rc.Id;
                    rewardsToInsert.add(new Reward__c(
                      Name = 'Rewards for Booking '+ bk.Name,
                        Customer_Master__c = bk.Customer_Master_Lead__c,
                        Reward_Type__c = rc.Reward_Type__c,
                        Reward_Amount__c = rc.Referral_Amount__c,
                            Referral__c = referral != null ? referral.Id : null,
                            Reward_Criteria__c = rewardCriteriaId
                    ));
                }
            }
        }
        if (!rewardsToInsert.isEmpty()) {
            insert rewardsToInsert;
        }

        // 5. Update Referral status to 'Booked' only for leads that belong to the customer master
        Set<Id> validLeadIds = new Set<Id>();
        for (Booking__c bk : agreementBookings) {
            if (bk.SLead__c != null && leadMap.containsKey(bk.SLead__c)) {
                Lead ld = leadMap.get(bk.SLead__c);
                if (ld.Customer_Master__c == bk.Customer_Master_Lead__c) {
                    validLeadIds.add(bk.SLead__c);
                }
            }
        }
        if (!validLeadIds.isEmpty()) {
            // Map Project Id to Referral_Amount__c from Reward_Criteria__c
            Map<Id, Decimal> projectToReferralAmount = new Map<Id, Decimal>();
            for (Id projId : rewardCriteriaMap.keySet()) {
                projectToReferralAmount.put(projId, rewardCriteriaMap.get(projId).Referral_Amount__c);
            }
            List<Referral__c> referralsToUpdate = new List<Referral__c>();
            for (Referral__c ref : [SELECT Id, Status__c, Reward_Amount__c, Lead__c FROM Referral__c WHERE Lead__c IN :validLeadIds]) {
                if (ref.Status__c != 'Booked') {
                    ref.Status__c = 'Booked';
                    // Find the booking for this lead
                    Id leadId = ref.Lead__c;
                    Booking__c booking = null;
                    for (Booking__c bk : agreementBookings) {
                        if (bk.SLead__c == leadId) {
                            booking = bk;
                            break;
                        }
                    }
                    Decimal addAmount = 0;
                    if (booking != null && booking.Project1__c != null && projectToReferralAmount.containsKey(booking.Project1__c)) {
                        addAmount = projectToReferralAmount.get(booking.Project1__c);
                    }
                    ref.Reward_Amount__c = (ref.Reward_Amount__c != null ? ref.Reward_Amount__c : 0) + (addAmount != null ? addAmount : 0);
                    referralsToUpdate.add(ref);
                }
            }
            if (!referralsToUpdate.isEmpty()) {
                update referralsToUpdate;
            }
        }
    }
    
}