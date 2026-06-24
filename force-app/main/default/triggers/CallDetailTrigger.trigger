trigger CallDetailTrigger on Call_Detail__c (after insert, after update, before update, before insert, after delete, after undelete) {
    
    if (Trigger.IsBefore && Trigger.IsInsert) {
        Map<String, Id> mapPhoId = new Map<String, Id>();
        List<User> usList = [SELECT Id, Phone FROM User WHERE Phone != null AND IsActive = true];
        Id adminId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1].Id;
        
        for (User u : usList) {
            mapPhoId.put(u.Phone, u.Id);
        }
        
        for (Call_Detail__c cd : Trigger.New) {
            if (cd.Call_Type__c == 'Outbound Call' && cd.Call_From__c != null) {
                cd.OwnerId = mapPhoId.get(cd.Call_From__c);
            }
            if (cd.Call_Type__c == 'Inbound Call' && cd.Call_To__c != null) {
                cd.OwnerId = mapPhoId.get(cd.Call_To__c);
            }
            if (cd.OwnerId == null) {
                cd.OwnerId = adminId;
            }
        }
    }
    
    Set<Id> ldId = new Set<Id>();
    Set<Id> ldIdforCount = new Set<Id>();
    Set<Id> ownerIds = new Set<Id>();
    Set<Id> rsId = new Set<Id>(); // NEW: Related Source IDs
    Set<Id> rsIdforCount = new Set<Id>(); // NEW: Related Source IDs for count
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUndelete)) {
        for (Call_Detail__c cd : Trigger.New) {
            if (cd.Lead__c != null) {
                ldIdforCount.add(cd.Lead__c);
            }
            if (cd.Status__c != null && cd.Lead__c != null && cd.Call_Type__c == 'Outbound Call') {
                ldId.add(cd.Lead__c);
                ownerIds.add(cd.OwnerId);
            }
            
            // NEW: Handle Related Source
            if (cd.Related_Source__c != null) {
                rsIdforCount.add(cd.Related_Source__c);
            }
            if (cd.Status__c != null && cd.Related_Source__c != null && cd.Call_Type__c == 'Outbound Call') {
                rsId.add(cd.Related_Source__c);
                ownerIds.add(cd.OwnerId);
            }
        }
        
        DateTime d = System.now();
        
        // Follow-up logic for Leads
        List<Follow_up__c> follouplst = [SELECT Id, Status__c, SLead__c 
                                        FROM Follow_up__c 
                                        WHERE SLead__c IN :ldId 
                                        AND Status__c = 'Scheduled' 
                                        AND Scheduled_Date__c <= TODAY 
                                        AND OwnerId IN :ownerIds];
        
        // NEW: Follow-up logic for Related Sources
        List<Follow_up__c> follouplstRS = [SELECT Id, Status__c, Related_Source__c 
                                        FROM Follow_up__c 
                                        WHERE Related_Source__c IN :rsId 
                                        AND Status__c = 'Scheduled' 
                                        AND Scheduled_Date__c <= TODAY 
                                        AND OwnerId IN :ownerIds];
        
        List<Follow_up__c> folw = new List<Follow_up__c>();
        List<Call_Detail__c> upCallD = new List<Call_Detail__c>();
        
        // Call detail update for Leads
        List<Call_Detail__c> calluplst = [SELECT Id, Status__c, Lead__c 
                                        FROM Call_Detail__c 
                                        WHERE Lead__c IN :ldId 
                                        AND (Status__c = 'CONNECTING' OR Status__c = 'Missed')
                                        AND Start_Time__c <= :d];
        
        // NEW: Call detail update for Related Sources
        List<Call_Detail__c> calluplstRS = [SELECT Id, Status__c, Related_Source__c 
                                        FROM Call_Detail__c 
                                        WHERE Related_Source__c IN :rsId 
                                        AND (Status__c = 'CONNECTING' OR Status__c = 'Missed')
                                        AND Start_Time__c <= :d];
        
        for (Call_Detail__c calp : calluplst) {
            calp.Status__c = 'Called Back';
            upCallD.add(calp);
        }
        
        // NEW: Process Related Source calls
        for (Call_Detail__c calp : calluplstRS) {
            calp.Status__c = 'Called Back';
            upCallD.add(calp);
        }
        
        for (Follow_up__c flup : follouplst) {
            flup.Status__c = 'Completed';
            flup.Comments__c  = 'Called The Customer';
            folw.add(flup);
        }
        
        // NEW: Process Related Source follow-ups
        for (Follow_up__c flup : follouplstRS) {
            flup.Status__c = 'Completed';
            flup.Comments__c  = 'Called The Customer';
            folw.add(flup);
        }
        
        if (!folw.isEmpty()) {
            //update folw;
        }
        if (!upCallD.isEmpty()) {
            //update upCallD;
        }
        
        // ========================================
        // LEAD PROCESSING (Original Logic)
        // ========================================
        Set<Id> leadIds = new Set<Id>();
        for (Call_Detail__c cd : Trigger.New) {
            if (cd.Lead__c != null) {
                leadIds.add(cd.Lead__c);
            }
        }
        
        if (!leadIds.isEmpty()) {
            Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, CreatedDate, Pushed_On__c, TAT_for_New_Lead__c, 
                                                        TAT_for_Sales__c, RecordType.Name, Lead_Status__c, 
                                                        First_Presales_Call_Date__c, Last_Presales_Call_Date__c, 
                                                        First_Sales_Call_Date__c, Last_Sales_Call_Date__c, 
                                                        Total_Calls__c 
                                                        FROM Lead 
                                                        WHERE Id IN :leadIds]);
            
            Map<Id, Datetime> firstCallMap = new Map<Id, Datetime>();
            for (AggregateResult ar : [SELECT Lead__c leadId, MIN(CreatedDate) minDate 
                                    FROM Call_Detail__c 
                                    WHERE Lead__c IN :leadIds  
                                    GROUP BY Lead__c]) {
                firstCallMap.put((Id)ar.get('leadId'), (Datetime)ar.get('minDate'));
            }
            
            Map<Id, Datetime> lastCallMap = new Map<Id, Datetime>();
            for (AggregateResult ar : [SELECT Lead__c leadId, MAX(CreatedDate) maxDate 
                                    FROM Call_Detail__c 
                                    WHERE Lead__c IN :leadIds  
                                    GROUP BY Lead__c]) {
                lastCallMap.put((Id)ar.get('leadId'), (Datetime)ar.get('maxDate'));
            }
            
            Map<Id, Integer> totalCallsMap = new Map<Id, Integer>();
            for (AggregateResult ar : [SELECT Lead__c leadId, COUNT(Id) totalCalls 
                                    FROM Call_Detail__c 
                                    WHERE Lead__c IN :leadIds 
                                    GROUP BY Lead__c]) {
                totalCallsMap.put((Id)ar.get('leadId'), (Integer)ar.get('totalCalls'));
            }
            
            List<Lead> leadsToUpdate = new List<Lead>();
            List<Site_Visit__c> siteVisitsToUpdate = new List<Site_Visit__c>();
            
            for (Call_Detail__c call : Trigger.New) {
                if (call.Lead__c == null) continue;
                Lead lead = leadMap.get(call.Lead__c);
                if (lead == null) continue;
                
                Boolean updateNeeded = false;
                
                if (lead.RecordType.Name == 'Pre Sales') {
                    Datetime firstCall = firstCallMap.get(lead.Id);
                    Datetime lastCall = lastCallMap.get(lead.Id);
                    
                    if (lead.First_Presales_Call_Date__c == null && firstCall != null && call.CreatedDate == firstCall) {
                        lead.First_Presales_Call_Date__c = call.CreatedDate;
                        updateNeeded = true;
                    }
                    
                    if (lastCall != null && call.CreatedDate == lastCall) {
                        lead.Last_Presales_Call_Date__c = call.CreatedDate;
                        updateNeeded = true;
                    }
                }
                
                if (lead.RecordType.Name == 'Sales') {
                    Datetime firstCall = firstCallMap.get(lead.Id);
                    Datetime lastCall = lastCallMap.get(lead.Id);
                    
                    if (lead.First_Sales_Call_Date__c == null && firstCall != null && call.CreatedDate == firstCall) {
                        lead.First_Sales_Call_Date__c = call.CreatedDate;
                        updateNeeded = true;
                    }
                    
                    if (lastCall != null && call.CreatedDate == lastCall) {
                        lead.Last_Sales_Call_Date__c = call.CreatedDate;
                        updateNeeded = true;
                    }
                }
                
                Integer totalCalls = totalCallsMap.get(lead.Id);
                if (totalCalls != null && lead.Total_Calls__c != totalCalls) {
                    lead.Total_Calls__c = totalCalls;
                    updateNeeded = true;
                }
                
                if (lead.TAT_for_New_Lead__c == null) {
                    Datetime firstCall = firstCallMap.get(lead.Id);
                    if (firstCall != null && call.CreatedDate == firstCall) {
                        lead.TAT_for_New_Lead__c = 
                            (call.CreatedDate.getTime() - lead.CreatedDate.getTime()) / (1000 * 60);
                        updateNeeded = true;
                    }
                }
                
                if (lead.TAT_for_Sales__c == null) {
                    if (call.CreatedDate > lead.Pushed_On__c) {
                        Datetime earliestSalesCall = null;
                        
                        for (Call_Detail__c c : [SELECT CreatedDate FROM Call_Detail__c
                                                WHERE Lead__c = :lead.Id AND CreatedDate > :lead.Pushed_On__c
                                                ORDER BY CreatedDate ASC LIMIT 1]) {
                            earliestSalesCall = c.CreatedDate;
                        }
                        
                        if (earliestSalesCall != null && call.CreatedDate == earliestSalesCall) {
                            lead.TAT_for_Sales__c = 
                                (call.CreatedDate.getTime() - lead.Pushed_On__c.getTime()) / (1000 * 60);
                            updateNeeded = true;
                        }
                    }
                    else if (lead.RecordType.Name == 'Sales') {
                        Datetime firstSalesCallDate = firstCallMap.get(lead.Id);
                        if (firstSalesCallDate != null && call.CreatedDate == firstSalesCallDate) {
                            lead.TAT_for_Sales__c =
                                (call.CreatedDate.getTime() - lead.CreatedDate.getTime()) / (1000 * 60);
                            updateNeeded = true;
                        }
                    }
                }
                
                if (lead.Lead_Status__c == 'Site Visit Schedule') {
                    List<Site_Visit__c> siteVisits = [SELECT Id, Date__c, Call_to_Site_Visit__c 
                                                    FROM Site_Visit__c 
                                                    WHERE SLead__c = :lead.Id];
                    for (Site_Visit__c siteVisit : siteVisits) {
                        if (siteVisit.Date__c != null && siteVisit.Date__c.date() == call.CreatedDate.date()) {
                            siteVisit.Call_to_Site_Visit__c = true;
                            siteVisitsToUpdate.add(siteVisit);
                        }
                    }
                }
                
                if (updateNeeded) {
                    leadsToUpdate.add(lead);
                }
            }
            
            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate;
            }
            
            if (!siteVisitsToUpdate.isEmpty()) {
                update siteVisitsToUpdate;
            }
        }
        
        // ========================================
        // NEW: RELATED SOURCE PROCESSING (Same Logic as Lead)
        // ========================================
        Set<Id> relatedSourceIds = new Set<Id>();
        for (Call_Detail__c cd : Trigger.New) {
            if (cd.Related_Source__c != null) {
                relatedSourceIds.add(cd.Related_Source__c);
            }
        }
        
        if (!relatedSourceIds.isEmpty()) {
            Map<Id, Related_Source__c> rsMap = new Map<Id, Related_Source__c>([
                SELECT Id, CreatedDate, Transfered_On__c, TAT_for_New_Lead__c, 
                       TAT_for_Sales__c, RecordType.Name, Lead_Status__c, 
                       First_Presales_Call_Date__c, Last_Presales_Call_Date__c, 
                       First_Sales_Call_Date__c, Last_Sales_Call_Date__c, 
                       Total_Calls__c 
                FROM Related_Source__c 
                WHERE Id IN :relatedSourceIds
            ]);
            
            Map<Id, Datetime> firstCallMapRS = new Map<Id, Datetime>();
            for (AggregateResult ar : [SELECT Related_Source__c rsId, MIN(CreatedDate) minDate 
                                    FROM Call_Detail__c 
                                    WHERE Related_Source__c IN :relatedSourceIds  
                                    GROUP BY Related_Source__c]) {
                firstCallMapRS.put((Id)ar.get('rsId'), (Datetime)ar.get('minDate'));
            }
            
            Map<Id, Datetime> lastCallMapRS = new Map<Id, Datetime>();
            for (AggregateResult ar : [SELECT Related_Source__c rsId, MAX(CreatedDate) maxDate 
                                    FROM Call_Detail__c 
                                    WHERE Related_Source__c IN :relatedSourceIds  
                                    GROUP BY Related_Source__c]) {
                lastCallMapRS.put((Id)ar.get('rsId'), (Datetime)ar.get('maxDate'));
            }
            
            Map<Id, Integer> totalCallsMapRS = new Map<Id, Integer>();
            for (AggregateResult ar : [SELECT Related_Source__c rsId, COUNT(Id) totalCalls 
                                    FROM Call_Detail__c 
                                    WHERE Related_Source__c IN :relatedSourceIds 
                                    GROUP BY Related_Source__c]) {
                totalCallsMapRS.put((Id)ar.get('rsId'), (Integer)ar.get('totalCalls'));
            }
            
            List<Related_Source__c> rsToUpdate = new List<Related_Source__c>();
            List<Site_Visit__c> siteVisitsToUpdateRS = new List<Site_Visit__c>();
            
            for (Call_Detail__c call : Trigger.New) {
                if (call.Related_Source__c == null) continue;
                Related_Source__c rs = rsMap.get(call.Related_Source__c);
                if (rs == null) continue;
                
                Boolean updateNeeded = false;
                
                if (rs.RecordType.Name == 'Pre Sales') {
                    Datetime firstCall = firstCallMapRS.get(rs.Id);
                    Datetime lastCall = lastCallMapRS.get(rs.Id);
                    
                    if (rs.First_Presales_Call_Date__c == null && firstCall != null && call.CreatedDate == firstCall) {
                        rs.First_Presales_Call_Date__c = call.CreatedDate;
                        updateNeeded = true;
                    }
                    
                    if (lastCall != null && call.CreatedDate == lastCall) {
                        rs.Last_Presales_Call_Date__c = call.CreatedDate;
                        updateNeeded = true;
                    }
                }
                
                if (rs.RecordType.Name == 'Sales') {
                    Datetime firstCall = firstCallMapRS.get(rs.Id);
                    Datetime lastCall = lastCallMapRS.get(rs.Id);
                    
                    if (rs.First_Sales_Call_Date__c == null && firstCall != null && call.CreatedDate == firstCall) {
                        rs.First_Sales_Call_Date__c = call.CreatedDate;
                        updateNeeded = true;
                    }
                    
                    if (lastCall != null && call.CreatedDate == lastCall) {
                        rs.Last_Sales_Call_Date__c = call.CreatedDate;
                        updateNeeded = true;
                    }
                }
                
                Integer totalCalls = totalCallsMapRS.get(rs.Id);
                if (totalCalls != null && rs.Total_Calls__c != totalCalls) {
                    rs.Total_Calls__c = totalCalls;
                    updateNeeded = true;
                }
                
                if (rs.TAT_for_New_Lead__c == null) {
                    Datetime firstCall = firstCallMapRS.get(rs.Id);
                    if (firstCall != null && call.CreatedDate == firstCall) {
                        rs.TAT_for_New_Lead__c = 
                            (call.CreatedDate.getTime() - rs.CreatedDate.getTime()) / (1000 * 60);
                        updateNeeded = true;
                    }
                }
                
                if (rs.TAT_for_Sales__c == null) {
                    if (rs.Transfered_On__c != null && call.CreatedDate > rs.Transfered_On__c) {
                        Datetime earliestSalesCall = null;
                        
                        for (Call_Detail__c c : [SELECT CreatedDate FROM Call_Detail__c
                                                WHERE Related_Source__c = :rs.Id AND CreatedDate > :rs.Transfered_On__c
                                                ORDER BY CreatedDate ASC LIMIT 1]) {
                            earliestSalesCall = c.CreatedDate;
                        }
                        
                        if (earliestSalesCall != null && call.CreatedDate == earliestSalesCall) {
                            rs.TAT_for_Sales__c = 
                                (call.CreatedDate.getTime() - rs.Transfered_On__c.getTime()) / (1000 * 60);
                            updateNeeded = true;
                        }
                    }
                    else if (rs.RecordType.Name == 'Sales') {
                        Datetime firstSalesCallDate = firstCallMapRS.get(rs.Id);
                        if (firstSalesCallDate != null && call.CreatedDate == firstSalesCallDate) {
                            rs.TAT_for_Sales__c =
                                (call.CreatedDate.getTime() - rs.CreatedDate.getTime()) / (1000 * 60);
                            updateNeeded = true;
                        }
                    }
                }
                
                if (rs.Lead_Status__c == 'Site Visit Schedule') {
                    List<Site_Visit__c> siteVisits = [SELECT Id, Date__c, Call_to_Site_Visit__c 
                                                    FROM Site_Visit__c 
                                                    WHERE Related_Source__c = :rs.Id];
                    for (Site_Visit__c siteVisit : siteVisits) {
                        if (siteVisit.Date__c != null && siteVisit.Date__c.date() == call.CreatedDate.date()) {
                            siteVisit.Call_to_Site_Visit__c = true;
                            siteVisitsToUpdateRS.add(siteVisit);
                        }
                    }
                }
                
                if (updateNeeded) {
                    rsToUpdate.add(rs);
                }
            }
            
            if (!rsToUpdate.isEmpty()) {
                update rsToUpdate;
            }
            
            if (!siteVisitsToUpdateRS.isEmpty()) {
                update siteVisitsToUpdateRS;
            }
        }
    }
    
    if (Trigger.isUpdate || Trigger.isDelete) {
        for (Call_Detail__c con : Trigger.old) {
            if (con.Lead__c != null) {
                ldIdforCount.add(con.Lead__c);
            }
            // NEW: Handle Related Source on update/delete
            if (con.Related_Source__c != null) {
                rsIdforCount.add(con.Related_Source__c);
            }
        }
    }
    
    // Update Lead call counts
    if (!ldIdforCount.isEmpty()) {
        List<Lead> accList = [SELECT Id, Number_Of_Calls__c, 
                                (SELECT Id, CreatedDate FROM Call_Details__r ORDER BY CreatedDate DESC) 
                                FROM Lead WHERE Id IN :ldIdforCount];
        
        if (!accList.isEmpty()) {
            List<Lead> updateAccList = new List<Lead>();
            for (Lead acc : accList) {
                Lead objAcc = new Lead(
                    Id = acc.Id, 
                    Number_Of_Calls__c = acc.Call_Details__r.size(), 
                    Last_Outbound_Call_Date__c = !acc.Call_Details__r.isEmpty() ? acc.Call_Details__r[0].CreatedDate : null
                );
                updateAccList.add(objAcc);
            }
            
            if (!updateAccList.isEmpty()) {
                update updateAccList;
            }
        }
    }
    
    // NEW: Update Related Source call counts
    if (!rsIdforCount.isEmpty()) {
        List<Related_Source__c> rsList = [SELECT Id, Number_Of_Calls__c, 
                                (SELECT Id, CreatedDate FROM Call_Details__r ORDER BY CreatedDate DESC) 
                                FROM Related_Source__c WHERE Id IN :rsIdforCount];
        
        if (!rsList.isEmpty()) {
            List<Related_Source__c> updateRSList = new List<Related_Source__c>();
            for (Related_Source__c rs : rsList) {
                Related_Source__c objRS = new Related_Source__c(
                    Id = rs.Id, 
                    Number_Of_Calls__c = rs.Call_Details__r.size(), 
                    Last_Outbound_Call_Date__c = !rs.Call_Details__r.isEmpty() ? rs.Call_Details__r[0].CreatedDate : null
                );
                updateRSList.add(objRS);
            }
            
            if (!updateRSList.isEmpty()) {
                update updateRSList;
            }
        }
    }
}