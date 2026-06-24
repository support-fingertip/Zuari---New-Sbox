/**
 * @lastModified  2026-05-25 — wired CPEmailNotificationService.sendFirstBookingClosed in afterUpdate (one-shot bundle deploy)
 */
public class BookingTriggerHandler {
    
    /* ================= AFTER INSERT ================= */
    public static void afterInsert(List<Booking__c> newBookings) {
        updateLeadBookingDate(newBookings);
        handleCommissionCreation(newBookings, null, true);

        // Update Channel Partner Booking Count
        Set<Id> cpIdsForBookingCount = new Set<Id>();
        for (Booking__c bk : newBookings) {
            if (bk.Channel_Partner__c != null) {
                cpIdsForBookingCount.add(bk.Channel_Partner__c);
            }
        }
        if (!cpIdsForBookingCount.isEmpty()) {
            ChannelPartnerCountHelper.updateBookingCount(cpIdsForBookingCount);
        }
    }
    
    /* ================= AFTER UPDATE ================= */
    public static void afterUpdate(List<Booking__c> newBookings,  Map<Id, Booking__c> oldMap ) {
        handleCommissionCreation(newBookings, oldMap, false);
        CPEmailNotificationService.sendFirstBookingClosed(newBookings, oldMap);
    }
    
    /* ================= MAIN LOGIC ================= */
    private static void handleCommissionCreation(List<Booking__c> bookings,Map<Id, Booking__c> oldMap,Boolean isInsert ) {
        
        
        
        /* ----------  FILTER ELIGIBLE BOOKINGS ---------- */
        List<Booking__c> eligibleBookings = new List<Booking__c>();
        Set<Id> channelPartnerIds = new Set<Id>();
        Set<String> projectNames = new Set<String>();
        
        for (Booking__c bk : bookings) {
            Boolean shouldCreate = isInsert? bk.Sale_Agreement_Completed__c: (bk.Sale_Agreement_Completed__c && !oldMap.get(bk.Id).Sale_Agreement_Completed__c);
                
                if (shouldCreate) {
                    eligibleBookings.add(bk);
                    
                    if (bk.Channel_Partner__c != null) {
                        channelPartnerIds.add(bk.Channel_Partner__c);
                    } else {
                        System.debug('️ Channel_Partner__c is NULL');
                    }
                    
                    if (bk.Project__c != null) {
                        projectNames.add(bk.Project__c);
                    } else {
                        System.debug('️ Project__c (picklist) is NULL');
                    }
                }
        }
        
        
        
        if (eligibleBookings.isEmpty()) {
            System.debug('No eligible bookings. EXIT');
            return;
        }
        
        /* ----------  FETCH PROJECTS ---------- */
        Map<String, Project__c> projectMap = new Map<String, Project__c>();
        
        for (Project__c prj : [SELECT Id, Name, Cp_Gst__c, Cp_Tds__c FROM Project__c  WHERE Name IN :projectNames]) {
            projectMap.put(prj.Name, prj);
        }
        
        
        
        /* ---------- ️⃣ BOOKING COUNT PER CHANNEL PARTNER ---------- */
        Map<Id, Integer> cpBookingCountMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [ SELECT Channel_Partner__c cpId, COUNT(Id) cnt  FROM Booking__c WHERE Channel_Partner__c IN :channelPartnerIds  GROUP BY Channel_Partner__c]) {
            cpBookingCountMap.put( (Id) ar.get('cpId'),(Integer) ar.get('cnt'));
        }
        
        
        
        /* ----------  FETCH COMMISSION SLABS ---------- */
        Set<Id> projectIds = new Set<Id>();
        for (Project__c p : projectMap.values()) {
            projectIds.add(p.Id);
        }
        
        
        
        Map<Id, List<Commission_Slab__c>> slabMap = new Map<Id, List<Commission_Slab__c>>();
        
        for (Commission_Slab__c slab : [SELECT Id,Project__c, Booking_Criteria__c, Commission_Factor__c FROM Commission_Slab__c WHERE Project__c IN :projectIds  ORDER BY Booking_Criteria__c ASC  ]) {
            
            if (!slabMap.containsKey(slab.Project__c)) {
                slabMap.put(slab.Project__c, new List<Commission_Slab__c>());
            }
            slabMap.get(slab.Project__c).add(slab);
        }
        
        
        
        /* ----------  CREATE COMMISSION RECORDS ---------- */
        List<Commission_Earned__c> commissionsToInsert = new List<Commission_Earned__c>();
        
        for (Booking__c bk : eligibleBookings) {
            
            
            
            Project__c prj = projectMap.get(bk.Project__c);
            
            if (prj == null) {
                
                continue;
            }
            
            Integer bookingCount = cpBookingCountMap.containsKey(bk.Channel_Partner__c) ? cpBookingCountMap.get(bk.Channel_Partner__c): 0;
            
            
            
            Decimal commissionPercent = getCommissionPercent(prj.Id,bookingCount,slabMap );
            
            System.debug(' Commission Percent = ' + commissionPercent);
            
            Commission_Earned__c ce = new Commission_Earned__c();
            ce.Booking__c = bk.Id;
            ce.Project__c = prj.Id;
            ce.Channel_Partner__c = bk.Channel_Partner__c;
            ce.Gst__c = prj.Cp_Gst__c;
            ce.Tds__c = prj.Cp_Tds__c;
            ce.commission_percentage__c = commissionPercent;
            
            commissionsToInsert.add(ce);
        }
        
        
        
        if (!commissionsToInsert.isEmpty()) {
            insert commissionsToInsert;
            System.debug(' Commission records inserted successfully');
        } else {
            System.debug(' No commission records to insert');
        }
    }
    
    /* ================= SLAB SELECTION LOGIC ================= */
    private static Decimal getCommissionPercent( Id projectId,Integer bookingCount, Map<Id, List<Commission_Slab__c>> slabMap   ) {
        
        if (!slabMap.containsKey(projectId)) {
            System.debug(' No slabs found for project');
            return 0;
        }
        
        Decimal selectedFactor;
        Integer selectedPriority = 999; // lower = higher priority
        
        for (Commission_Slab__c slab : slabMap.get(projectId)) {
            
            Decimal factor = slab.Commission_Factor__c;
            Integer priority;
            
            
            
            // Convert Booking_Criteria__c (String) to Integer
            Integer slabCriteria;
            try {
                slabCriteria = Integer.valueOf(slab.Booking_Criteria__c);
            } catch(Exception e) {
                
                continue; // skip this slab
            }
            
            // Check if bookingCount falls under this slab
            if (bookingCount <= slabCriteria) {
                priority = slabCriteria;
                
                // Pick best match:
                if (priority < selectedPriority || (priority == selectedPriority && factor < selectedFactor)) {
                    
                    selectedPriority = priority;
                    selectedFactor = factor;
                    
                    
                }
            }
        }
        
        if (selectedFactor != null) {
            
            return selectedFactor;
        }
        
        
        return 0;
    }

    /* ================= LEAD BOOKING DATE UPDATE ================= */
    private static void updateLeadBookingDate(List<Booking__c> bookings) {
        Map<Id, DateTime> leadToLatestVisitDate = new Map<Id, DateTime>();
        Set<Id> ldId = new Set<Id>();

        for (Booking__c bk : bookings) {
            if (bk.SLead__c != null && bk.Booking_Date__c != null) {
                if (!leadToLatestVisitDate.containsKey(bk.SLead__c) || bk.Booking_Date__c > leadToLatestVisitDate.get(bk.SLead__c)) {
                    leadToLatestVisitDate.put(bk.SLead__c, bk.Booking_Date__c);
                    ldId.add(bk.SLead__c);
                }
            }
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        for (Id leadId : ldId) {
            Lead ld = new Lead();
            ld.Id = leadId;
            if (leadToLatestVisitDate.containsKey(leadId)) {
                ld.Booking_Date__c = leadToLatestVisitDate.get(leadId);
            }
            leadsToUpdate.add(ld);
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}