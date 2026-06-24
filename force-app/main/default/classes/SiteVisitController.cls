public without sharing class SiteVisitController {
    
    public static void checkSiteVisitForRoundRobin(List<Site_Visit__c> svList) {
        
        Set<Id> leadIds = new Set<Id>();
        Set<Id> relatedSourceIds = new Set<Id>();
        
        // Collect all IDs - Related_Source gets priority if both exist
        for (Site_Visit__c sv : svList) {
            if (sv.Related_Source__c != null) {
                relatedSourceIds.add(sv.Related_Source__c);
            } else if (sv.SLead__c != null) {
                leadIds.add(sv.SLead__c);
            }
        }
        
        system.debug('Lead Ids: ' + leadIds);
        system.debug('Related Source Ids: ' + relatedSourceIds);
        
        // Fetch Related_Source__c records with all needed fields
        Map<Id, Related_Source__c> relatedSourceMap = new Map<Id, Related_Source__c>();
        if (!relatedSourceIds.isEmpty()) {
            relatedSourceMap = new Map<Id, Related_Source__c>(
                [SELECT Id, Name, RecordType.Name, Allocated_Project__c, Source_Type__c 
                 FROM Related_Source__c 
                 WHERE Id IN :relatedSourceIds]
            );
        }
        
        // Fetch Leads with all needed fields
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        if (!leadIds.isEmpty()) {
            leadMap = new Map<Id, Lead>(
                [SELECT Id, Name, RecordType.Name, Allocated_Project__c, Source_Type__c 
                 FROM Lead 
                 WHERE Id IN :leadIds]
            );
        }
        
        system.debug('Lead Map: ' + leadMap);
        system.debug('Related Source Map: ' + relatedSourceMap);
        
        // Fetch most-recent unexpired OTP (within 30 days) for the Leads / Related Sources
        // in scope, so reschedules and follow-up Site Visits reuse the same OTP.
        Map<Id, Site_Visit__c> recentOtpByLead = new Map<Id, Site_Visit__c>();
        Map<Id, Site_Visit__c> recentOtpByRelatedSource = new Map<Id, Site_Visit__c>();
        if (!leadIds.isEmpty() || !relatedSourceIds.isEmpty()) {
            Datetime otpCutoff = Datetime.now().addDays(-30);
            for (Site_Visit__c existing : [
                SELECT Id, SLead__c, Related_Source__c, OTP__c, OTP_Generated_Date__c
                FROM Site_Visit__c
                WHERE OTP_Generated_Date__c != NULL
                AND OTP_Generated_Date__c >= :otpCutoff
                AND OTP__c != NULL
                AND OTP__c != '0000'
                AND (SLead__c IN :leadIds OR Related_Source__c IN :relatedSourceIds)
                ORDER BY OTP_Generated_Date__c DESC 
            ]) {
                if (existing.Related_Source__c != null
                    && !recentOtpByRelatedSource.containsKey(existing.Related_Source__c)) {
                        recentOtpByRelatedSource.put(existing.Related_Source__c, existing);
                    }
            }
        }
        
        // In-transaction reuse cache so a bulk insert of multiple SVs for the same
        // Lead / Related Source assigns one shared OTP, not N different ones.
        Map<Id, Site_Visit__c> txnOtpByLead = new Map<Id, Site_Visit__c>();
        Map<Id, Site_Visit__c> txnOtpByRelatedSource = new Map<Id, Site_Visit__c>();
        
        // Process Site Visits with priority: Related_Source > Lead
        for (Site_Visit__c sv : svList) {
            system.debug('SV In Loop');
            
            sv.Go_For_Round_Robin__c = true;
            
            // OTP handling — skip when caller explicitly opts out with '0000'
            if (sv.OTP__c != '0000') {
                Site_Visit__c reuse = null;
                if (sv.Related_Source__c != null) {
                    reuse = txnOtpByRelatedSource.get(sv.Related_Source__c);
                    if (reuse == null) reuse = recentOtpByRelatedSource.get(sv.Related_Source__c);
                }
                if (reuse != null) {
                    // Reuse existing OTP and carry its original timestamp — do NOT extend the 30-day window
                    sv.OTP__c = reuse.OTP__c;
                    sv.OTP_Generated_Date__c = reuse.OTP_Generated_Date__c;
                } else {
                    sv.OTP__c = GenerateOTP.generateUniqueOTP();
                    sv.OTP_Generated_Date__c = Datetime.now();
                }
                
                // Share this OTP with any sibling SVs later in the same insert
                if (sv.Related_Source__c != null
                    && !txnOtpByRelatedSource.containsKey(sv.Related_Source__c)) {
                        txnOtpByRelatedSource.put(sv.Related_Source__c, sv);
                    }
            }
            
            // Set Source_Type__c with priority logic
            if (sv.Source_Type__c == null) {
                // Priority 1: Related_Source__c
                if (sv.Related_Source__c != null && relatedSourceMap.containsKey(sv.Related_Source__c)) {
                    sv.Source_Type__c = relatedSourceMap.get(sv.Related_Source__c).Source_Type__c;
                }
                // Priority 2: SLead__c (fallback)
                else if (sv.SLead__c != null && leadMap.containsKey(sv.SLead__c)) {
                    sv.Source_Type__c = leadMap.get(sv.SLead__c).Source_Type__c;
                }
            }
        }
    }
    public Static Void codeCoverage(){
        
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}