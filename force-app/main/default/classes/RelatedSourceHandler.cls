public without sharing class RelatedSourceHandler {
    
    public static Boolean bypassTrigger = false;  // Added By Siddaling On 09/06/2026
    
    public static List<Lead> deleteList = new List<Lead>();
    public static List<Lead> updateList = new List<Lead>();
    public static List<Related_source__c> rsList = new List<Related_source__c>();
    public static Map<Id,Lead> matchedMap = new  Map<Id,Lead>();
    public static datetime startTime;
    public static datetime endTime;
    public static void cpmethod (list<Lead> ldlst){
        Map<String, Channel_partner__c> cpMap = new Map<String, Channel_partner__c>();
        
        // Populate the map with active channel partners
        for(Channel_partner__c cp : [SELECT Id, OwnerId, Sourcing_RM__c,ContactPerson__c, Active__c FROM Channel_partner__c WHERE Active__c = true]) {
            cpMap.put(cp.Id, cp);
        }
        
        // Iterate through each lead and update Sub_Source__c
        for(Lead ld : ldlst) {
            // Ensure that the Channel_partner__c field is not null and exists in the map
            if (ld.Channel_partner__c != null && cpMap.containsKey(ld.Channel_partner__c)) {
                ld.Sub_Source__c = cpMap.get(ld.Channel_partner__c).ContactPerson__c;
                if(cpMap.get(ld.Channel_partner__c).Sourcing_RM__c != null){
                    ld.OwnerId = cpMap.get(ld.Channel_partner__c).Sourcing_RM__c;
                }
                else{
                    ld.OwnerId = cpMap.get(ld.Channel_partner__c).OwnerId;
                }
            } else {
                // Handle the case where there's no corresponding Channel Partner
                // Optionally, you can set a default value or log it
                ld.Sub_Source__c = 'Default Value'; // Or handle as needed
            }
        }
    }
    public static void campaignMethod(List<Lead> ldList) {
        // Filter leads that need campaign lookup
        Set<String> campIds = new Set<String>();
        for (Lead ld : ldList) {
            if (ld.Campaign__c != null && ld.Campaign_std__c == null) {
                campIds.add(ld.Campaign__c);
            }
        }
        
        if (campIds.isEmpty()) return; // Early exit if nothing to process
        
        // Single map handles both Name and Campaign_ID__c lookups
        Map<String, Id> campLookup = new Map<String, Id>();
        for (Campaign cam : [
            SELECT Id, Name, Campaign_ID__c
            FROM Campaign
            WHERE (Name IN :campIds OR Campaign_ID__c IN :campIds)
            AND IsActive = true
        ]) {
            if (cam.Name != null)           campLookup.put(cam.Name, cam.Id);
            if (cam.Campaign_ID__c != null) campLookup.put(cam.Campaign_ID__c, cam.Id);
        }
        
        if (campLookup.isEmpty()) return; // Early exit if no matching campaigns
        
        // Assign matched campaign IDs to leads
        for (Lead ld : ldList) {
            if (ld.Campaign__c != null && ld.Campaign_std__c == null) {
                ld.Campaign_std__c = campLookup.get(ld.Campaign__c);
            }
        }
    }
    public static void cpRelatedSourcemethod (list<Related_Source__c> ldlst){
        Map<String, Channel_partner__c> cpMap = new Map<String, Channel_partner__c>();
        for(Channel_partner__c cp : [SELECT Id, OwnerId, ContactPerson__c, Active__c FROM Channel_partner__c WHERE Active__c = true]) {
            cpMap.put(cp.Id, cp);
        }
        for(Related_Source__c ld : ldlst) {
            if (ld.Channel_partner1__c != null && cpMap.containsKey(ld.Channel_partner1__c)) {
                //ld.Sub_Source__c = cpMap.get(ld.Channel_partner__c).ContactPerson__c;
                ld.OwnerId = cpMap.get(ld.Channel_partner1__c).OwnerId;
            } else {
                //ld.Sub_Source__c = 'Default Value'; // Or handle as needed
            }
        }
    }
    
    public static void checkMobileNumber2(List<Lead> newRecordsList) {
        Map<String, String> countryCodeMap = Utility.getAllCountryCodeMappings(true);
        Map<String, String> localeMap = Utility.getAllCountryLocaleMapping(); // ADD THIS
        for (Lead contact : newRecordsList) { 
            processPhoneNumber(contact, countryCodeMap, localeMap, true); // PASS IT
        }
    }
    
    private static void processPhoneNumber(Lead contact, Map<String, String> countryCodeMap, Map<String, String> localeMap, Boolean isPrimary) {
        String phoneField = isPrimary ? contact.Phone__c : contact.Secondary_Phone__c;
        if (phoneField == null) return;
        phoneField = phoneField.replaceAll('\\s+', '');
        phoneField = contactFormatter.getformated(phoneField); 
        if (!phoneField.startsWith('+')) {
            phoneField = ensureTenDigitNumber(phoneField);
            if (isPrimary) {
                contact.Country_Code__c = '91';
                contact.Country__c = countryCodeMap.get('91');
                contact.Locale__c = localeMap.get('91'); // ADD THIS
                contact.Phone__c = phoneField;
            } else {
                contact.Secondary_Country_Code__c = '91';
                contact.Secondary_Country__c = countryCodeMap.get('91');
                contact.Secondary_Phone__c = phoneField;
            }
            return;
        }
        phoneField = phoneField.replace('+', '');
        for (String countryCode : countryCodeMap.keySet()) {
            if (phoneField.startsWith(countryCode)) {
                phoneField = phoneField.replaceFirst('^' + countryCode, '');
                phoneField = ensureCorrectPhoneLength(phoneField, countryCode);
                if (isPrimary) {
                    contact.Country_Code__c = countryCode;
                    contact.Country__c = countryCodeMap.get(countryCode);
                    contact.Locale__c = localeMap.get(countryCode); // ADD THIS
                    contact.Phone__c = phoneField;
                } else {
                    contact.Secondary_Country_Code__c = countryCode;
                    contact.Secondary_Country__c = countryCodeMap.get(countryCode);
                    contact.Secondary_Phone__c = phoneField;
                }
                return;
            }
        }
        phoneField = ensureTenDigitNumber(phoneField);
        system.debug(phoneField);
        if (isPrimary) {
            contact.Country_Code__c = '91';
            contact.Country__c = countryCodeMap.get('91');
            contact.Locale__c = localeMap.get('91'); // ADD THIS
            contact.Phone__c = phoneField;
        } else {
            contact.Secondary_Country_Code__c = '91';
            contact.Secondary_Country__c = countryCodeMap.get('91');
            contact.Secondary_Phone__c = phoneField;
        }
    }
    
    // Ensures the phone number is exactly 10 digits long (for India)
    private static String ensureTenDigitNumber(String phone) {
        if (phone.length() > 10) {
            return phone.substring(phone.length() - 10); // Keep last 10 digits
        }
        return phone;
    }
    
    // Ensures phone length based on country (modify for other country rules if needed)
    private static String ensureCorrectPhoneLength(String phone, String countryCode) {
        if (countryCode == '91' && phone.length() > 10) {
            return phone.substring(phone.length() - 10); // For India, keep last 10 digits
        }
        return phone; 
    }
    
    public static void duplicateCheck2(List<Lead> ldList){
        Set <String> PhoneSet = new Set<String>();
        Set <String> mailSet = new Set<String>();
        for(Lead ld : ldList){
            string allocatedProject='';
            if(ld.Allocated_project__c !=null){
                allocatedProject = ld.Allocated_project__c;
            }
            if(ld.Phone__c !=null){
                PhoneSet.add(ld.Phone__c+allocatedProject);
            }
            if(ld.Secondary_Phone__c !=null){
                PhoneSet.add(ld.Secondary_Phone__c+allocatedProject);
            }
            
        }
        List<Lead> oldLeadList = [SELECT Id,PhoneProject__c,Secondary_Phone_Project__c,SecondaryEmailProject__c,EmailProject__c,Phone,Email,Secondary_phone__c,Secondary_Email__c,Phone__c FROM Lead WHERE (PhoneProject__c IN : PhoneSet OR Secondary_Phone_Project__c IN :PhoneSet/* OR EmailProject__c IN :mailSet OR SecondaryEmailProject__c IN:mailSet*/) ORDER BY CreatedDate ASC];
        if(oldLeadList.size()>0){
            Map<string,Lead> emailMap = new Map<string,Lead>();
            Map<string,Lead> PhoneMap = new Map<string,Lead>();
            for(Lead old : oldLeadList){
                if(old.PhoneProject__c !=null){
                    PhoneMap.put(old.PhoneProject__c,old);
                }
                if(old.Secondary_Phone_Project__c !=null){
                    PhoneMap.put(old.Secondary_Phone_Project__c,old);
                }
            }
            for(Lead nld : ldList){
                string allocatedProject='';
                if(nld.Allocated_Project__c!=null){
                    allocatedProject = nld.Allocated_Project__c;
                }
                if(nld.Phone__c !=null && PhoneMap.containsKey(nld.Phone__c+allocatedProject)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = PhoneMap.get(nld.Phone__c+allocatedProject).Id;
                }else if(nld.Secondary_phone__c !=null && PhoneMap.containsKey(nld.Secondary_phone__c+allocatedProject)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = PhoneMap.get(nld.Secondary_phone__c+allocatedProject).Id;
                }
            } 
        }else{
            List<Related_Source__c> oldList = [SELECT Id,Name,SecondaryEmailProject__c,PhoneProject__c,SecondaryPhoneProject__c,EmailProject__c,SLead__c FROM Related_Source__c 
                                               WHERE (PhoneProject__c IN : PhoneSet OR SecondaryPhoneProject__c IN :PhoneSet/* OR EmailProject__c IN : mailSet OR SecondaryEmailProject__c IN : mailSet*/) AND SLead__c!=null ORDER BY CreatedDate ASC];
            Map<string,Related_Source__c> emailMap = new Map<string,Related_Source__c>();
            Map<string,Related_Source__c> PhoneMap = new Map<string,Related_Source__c>();
            if(oldList.size() >0){
                for(Related_Source__c old : oldList){
                    if(old.PhoneProject__c !=null){
                        PhoneMap.put(old.PhoneProject__c,old);
                    }
                    if(old.SecondaryPhoneProject__c !=null){
                        PhoneMap.put(old.SecondaryPhoneProject__c,old);
                    }
                }
                for(Lead nld : ldList){
                    string allocatedProject='';
                    if(nld.Allocated_project__c !=null){
                        allocatedProject = nld.Allocated_project__c;
                    }
                    if(nld.Phone__c !=null && PhoneMap.containsKey(nld.Phone__c+allocatedProject)){
                        nld.Delete_Lead__c = true;
                        nld.Main_Lead__c = PhoneMap.get(nld.Phone__c+allocatedProject).SLead__c;
                    }else if(nld.Secondary_phone__c !=null && PhoneMap.containsKey(nld.Secondary_phone__c+allocatedProject)){
                        nld.Delete_Lead__c = true;
                        nld.Main_Lead__c = PhoneMap.get(nld.Secondary_phone__c+allocatedProject).SLead__c;
                    }
                } 
            }
        }
    }
    
    public static void afterinsertLogic(List<Lead> ldList){
        //user u = [SELECT Id,Name,Profile.Name FROM user WHERE Id=:userinfo.getUserId()];
        Map<string,Lead> newemailMap = new Map<string,Lead>();
        Map<string,Lead> newPhoneMap = new Map<string,Lead>();
        set<string> cpIds = new set<string>();
        if(ldList.size()>1){
            for(Lead fnld : ldList){
                if(fnld.Email !=null && !newemailMap.containsKey(fnld.Email)){
                    newemailMap.put(fnld.Email,fnld);
                }
                if(fnld.Phone__c !=null && !newPhoneMap.containsKey(fnld.Phone__c)){
                    newPhoneMap.put(fnld.Phone,fnld);
                }
                if(fnld.Secondary_Email__c !=null && !newemailMap.containsKey(fnld.Secondary_Email__c)){
                    newemailMap.put(fnld.Secondary_Email__c,fnld);
                }
                if(fnld.Secondary_phone__c !=null && !newPhoneMap.containsKey(fnld.Secondary_phone__c)){
                    newPhoneMap.put(fnld.Secondary_phone__c,fnld);
                }
            }
        }
        for(Lead nld : ldList){
            if(nld.Delete_Lead__c && nld.Main_Lead__c !=null){
                addRelatedSource(nld);
            }else if(nld.Phone__c !=null && NewPhoneMap.containsKey(nld.Phone__c) && nld.Id !=NewPhoneMap.get(nld.Phone__c).Id){
                addRelatedSource2(nld,NewPhoneMap.get(nld.Phone__c));
            }else if(nld.Email !=null && newemailMap.containsKey(nld.Email) && nld.Id !=newemailMap.get(nld.Email).Id){
                addRelatedSource2(nld,newemailMap.get(nld.Email));
            }else if(nld.Secondary_phone__c !=null && NewPhoneMap.containsKey(nld.Secondary_phone__c) && nld.Id !=NewPhoneMap.get(nld.Secondary_phone__c).Id){
                addRelatedSource2(nld,NewPhoneMap.get(nld.Secondary_phone__c));
            }else if(nld.Secondary_Email__c !=null && newemailMap.containsKey(nld.Secondary_Email__c)  && nld.Id !=newemailMap.get(nld.Secondary_Email__c).Id){
                addRelatedSource2(nld,newemailMap.get(nld.Secondary_Email__c));
            }else{
                /*Related_source__c rs = new Related_source__c();
                rs.SLead__c = nld.Id;
                rs.Source__c = nld.Lead_source__c;
                rs.Sub_Source__c = nld.Sub_Source__c;
                rs.Phone__c = nld.Phone__c;
                rs.Country_Code__c = nld.Country_Code__c;
                rs.Secondary_Phone__c = nld.Secondary_Phone__c;
                rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
                rs.Email__c = nld.Email;
                rs.Secondary_Email__c = nld.Secondary_Email__c;
                rs.Description__c = nld.Last_Comment__c;
                rs.Allocated_Project__c = nld.Allocated_Project__c;
                rs.Campaign__c = nld.Campaign__c;
                rs.type_of_lead__c = nld.Type_of_lead__c;*/
                Related_Source__c rs = mapLeadToRelatedSource(nld,'','');
                rsList.add(rs);
                if(!matchedMap.containsKey(nld.Id)){
                    system.debug(nld.Id);
                    Lead ld = new Lead();
                    ld.Id = nld.Id;
                    ld.Last_Source_Of_Enquiry__c =nld.Lead_source__c;
                    ld.Last_Sub_Source__c =  nld.Sub_Source__c;
                    ld.First_Source_Of_Enquiry__c = nld.Lead_source__c;
                    ld.First_Sub_Source__c =  nld.Sub_Source__c;
                    ld.First_Contatced_On__c = system.now();
                    ld.First_Campaign__c = nld.Campaign__c;
                    ld.Last_Campagin__c = nld.Campaign__c;
                    
                }
            }
        }
        if(rsList.size() >0){
            insert rsList;
            rsList.clear();
        }
        if(matchedMap.size() >0){
            updateList = matchedMap.values();
            update updateList;
            matchedMap.clear();
            updateList.clear();
        }
        if(deleteList.size() >0){
            if(!test.isRunningTest()){
                delete deleteList;
            }
            deleteList.clear();
        }
    }
    
    /**
* @description : After lead is inserted this method is called to handle the related source
* @param : ldList list of newly inserted leads.
* @return : none.
* @lastModifiedBy : Arun Kumar N 19/11/2025
*/
    public static void afterinsertLogic2(List<Lead> ldList){
        Map<string,Lead> newemailMap = new Map<string,Lead>();
        Map<string,Lead> newPhoneMap = new Map<string,Lead>();
        if(ldList.size()>1){
            for(Lead fnld : ldList){
                string allocatedProject='';
                if(fnld.Allocated_project__c !=null){
                    allocatedProject = fnld.Allocated_project__c;
                }
                if(fnld.Email !=null && !newemailMap.containsKey(fnld.Email+allocatedProject)){
                    newemailMap.put(fnld.Email+allocatedProject,fnld);
                }
                if(fnld.Phone__c !=null && !newPhoneMap.containsKey(fnld.Phone__c+allocatedProject)){
                    newPhoneMap.put(fnld.Phone__c+allocatedProject,fnld);
                }
                if(fnld.Secondary_Email__c !=null && !newemailMap.containsKey(fnld.Secondary_Email__c+allocatedProject)){
                    newemailMap.put(fnld.Secondary_Email__c+allocatedProject,fnld);
                }
                if(fnld.Secondary_phone__c !=null && !newPhoneMap.containsKey(fnld.Secondary_phone__c+allocatedProject)){
                    newPhoneMap.put(fnld.Secondary_phone__c+allocatedProject,fnld);
                }
            }
        }
        
        for(Lead nld : ldList){
            string allocatedProject='';
            if(nld.Allocated_project__c !=null){
                allocatedProject = nld.Allocated_project__c;
            }
            if(nld.Delete_Lead__c && nld.Main_Lead__c !=null){
                addRelatedSource(nld);
            }else if(nld.Phone__c !=null && NewPhoneMap.containsKey(nld.Phone__c+allocatedProject) && nld.Id !=NewPhoneMap.get(nld.Phone__c+allocatedProject).Id){
                addRelatedSource2(nld,NewPhoneMap.get(nld.Phone__c+allocatedProject));
            }else if(nld.Email !=null && newemailMap.containsKey(nld.Email+allocatedProject) && nld.Id !=newemailMap.get(nld.Email+allocatedProject).Id){
                addRelatedSource2(nld,newemailMap.get(nld.Email+allocatedProject));
            }else if(nld.Secondary_phone__c !=null && NewPhoneMap.containsKey(nld.Secondary_phone__c+allocatedProject) && nld.Id !=NewPhoneMap.get(nld.Secondary_phone__c+allocatedProject).Id){
                addRelatedSource2(nld,NewPhoneMap.get(nld.Secondary_phone__c+allocatedProject));
            }else if(nld.Secondary_Email__c !=null && newemailMap.containsKey(nld.Secondary_Email__c+allocatedProject)  && nld.Id !=newemailMap.get(nld.Secondary_Email__c+allocatedProject).Id){
                addRelatedSource2(nld,newemailMap.get(nld.Secondary_Email__c+allocatedProject));
            }else{
                system.debug('=== NLD Record === ' + nld);
                system.debug('=== NLD Id === ' + nld.Id);
                 System.debug('mapLeadToRelatedSource is calling.........');
               Related_Source__c rs = mapLeadToRelatedSource(nld,'','New Lead');
                System.debug('mapLeadToRelatedSource is called.........');
               
                rsList.add(rs);
                if(!matchedMap.containsKey(nld.Id)){
                    Lead ld = new Lead();
                    ld.Id = nld.Id;
                    ld.Last_Source_Of_Enquiry__c =nld.Lead_source__c;
                    ld.Last_Sub_Source__c =  nld.Sub_Source__c;
                    ld.First_Source_Of_Enquiry__c = nld.Lead_source__c;
                    ld.First_Sub_Source__c =  nld.Sub_Source__c;
                    ld.First_Contatced_On__c = system.now();
                    ld.First_Campaign__c = nld.Campaign__c;
                    ld.Last_Campagin__c = nld.Campaign__c;
                    matchedMap.put(nld.Id,ld);
                }
            }
        }
        if(rsList.size() >0){
            insert rsList;
            rsList.clear();
        }
        if(matchedMap.size() >0){
            updateList = matchedMap.values();
            update updateList;
            matchedMap.clear();
            updateList.clear();
        }
        if(deleteList.size() >0){
            delete deleteList;
            deleteList.clear();
        }
    }
    
    public static void addRelatedSource(Lead nld){
        Related_Source__c rs = mapLeadToRelatedSource(nld,'Main Lead','');
       
        if(nld.Main_lead_status__c == 'Closed Lost' || nld.Main_lead_status__c == 'Booked'|| nld.Main_lead_status__c =='Unqualified'){
            rs.Lead_Type__c = 'Re-Opened';
        }else{
            rs.Lead_Type__c = 'Re-Engaged';
        }
        rsList.add(rs);
        deleteList.add(new Lead(Id=nld.Id));
        Lead ld = new Lead();
        ld.Id=nld.Main_Lead__c;
        ld.Last_Source_Of_Enquiry__c =nld.Lead_source__c;
        ld.Last_Sub_Source__c =  nld.Sub_Source__c;
        ld.Last_Campagin__c = nld.Campaign__c;
        if( nld.Main_lead_status__c == 'Booked'|| nld.Main_lead_status__c =='Unqualified' || nld.Main_lead_status__c == 'Closed Lost'){
            string RecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
            ld.Lead_status__c ='New';
            ld.Lead_Assigned__c=false;
            ld.Lead_Transfered__c = false;
            ld.Type_of_lead__c = 'Direct Lead';
            ld.Lead_Type__c ='Re-Opened';
            ld.Assigment_count__c ='0';
            ld.No_Of_Times_Unqualified__c=0;
            ld.Allocated_Project__c = nld.Allocated_Project__c;
            ld.Last_Re_Opened_Date__c = system.now();
            ld.Re_assigned_date__c=null;
            ld.RNR_date__c=null;
            ld.status_change_date__c=null;
            ld.Last_comment__c = '';
            ld.Site_Visit_Schedule_Date__c=null;
            ld.Site_visit_Project__c = null;
            ld.Reassigned_By__c=null;
            ld.Site_Visit_Feedback__c=null;
            ld.Followup_Subject__c=null;
            ld.Next_follow_up_Date__c=null;
            ld.Next_Site_visit_Date__c=null;
            ld.Closed_Lost_Reason__c=null;
            ld.Remark_for_Closed_Lost__c=null;
            ld.RecordTypeId=RecTypeId;
        }
        
        else{
            ld.Lead_Type__c ='Re-Engaged';
            ld.Re_Engaged_Date__c = system.now();
        }
        matchedMap.put(nld.Main_Lead__c,ld);
        
    }
    public static void addRelatedSource2(Lead nld, Lead mainContact){
       Related_Source__c rs = mapLeadToRelatedSource(nld,'','');
       
        rsList.add(rs);
        Lead ld = new Lead();
        ld.Id=mainContact.Id;
        ld.First_Source_Of_Enquiry__c = mainContact.Lead_source__c;
        ld.First_Sub_Source__c = mainContact.Sub_Source__c;
        ld.Last_Source_Of_Enquiry__c =nld.Lead_source__c;
        ld.Last_Sub_Source__c =  nld.Sub_Source__c;
        ld.Last_Campagin__c = nld.Campaign__c;
        ld.Last_Re_Engaged_Date__c	 = system.now();
    }  
    
    
    
    /*public static void reassignUnqualifiedLead(List<Lead> leadsToProcess) {
        List<Lead_Assignment_Config__mdt> assignmentOrder = [SELECT User_Indentifier__c  FROM Lead_Assignment_Config__mdt ];
        Set<String> identifiers = new Set<String>();
        for (Lead_Assignment_Config__mdt mdt : assignmentOrder) {
            identifiers.add(mdt.User_Indentifier__c);
        }
        Map<String, Id> identifierToUserId = new Map<String, Id>();
        for (User u : [ SELECT Id, Username, Alias  FROM User  WHERE Username IN :identifiers OR Alias IN :identifiers ]) {
            identifierToUserId.put(u.Username, u.Id);
            identifierToUserId.put(u.Alias, u.Id);
        }
        List<Id> allSalesUserIds = new List<Id>();
        for (Lead_Assignment_Config__mdt cfg : assignmentOrder) {
            allSalesUserIds.add(identifierToUserId.get(cfg.User_Indentifier__c));
        }
        for (Lead ld : leadsToProcess) {
            Integer times = ld.No_Of_Times_Unqualified__c == null ? 0 : Integer.valueOf(ld.No_Of_Times_Unqualified__c);
            List<Id> availableUsers = new List<Id>();
            for (Id uId : allSalesUserIds) {
                if (uId != ld.OwnerId) {
                    availableUsers.add(uId);
                }
            }
            if (!availableUsers.isEmpty()) {
                Integer idx = Math.mod(times, availableUsers.size());
                ld.OwnerId = availableUsers[idx];
            }
        }
    }*/
    public static void reassignUnqualifiedLead1(List<Related_Source__c> leadsToProcess) {
        
        System.debug('===== START reassignUnqualifiedLead1() =====');
        
        // Fetch CMDT Records
        List<Lead_Assignment_Config__mdt> assignmentOrder = [SELECT User_Indentifier__c  FROM Lead_Assignment_Config__mdt];
       
        Set<String> identifiers = new Set<String>();
        for (Lead_Assignment_Config__mdt mdt : assignmentOrder) {
            identifiers.add(mdt.User_Indentifier__c);
        }
        System.debug('Identifiers Set: ' + identifiers);
        
        // Fetch users matching CMDT identifiers
        Map<String, Id> identifierToUserId = new Map<String, Id>();
        List<User> matchedUsers = [
            SELECT Id, Username, Alias  
            FROM User  
            WHERE Username IN :identifiers OR Alias IN :identifiers
        ];
        System.debug('Matched Users Count: ' + matchedUsers.size());
        
        for (User u : matchedUsers) {
            System.debug('Matched User → Id: ' + u.Id + ' | Username: ' + u.Username + ' | Alias: ' + u.Alias);
            identifierToUserId.put(u.Username, u.Id);
            identifierToUserId.put(u.Alias, u.Id);
        }
        
        System.debug('Identifier → UserId Map: ' + identifierToUserId);
        
        // Prepare list according to CMDT order
        List<Id> allSalesUserIds = new List<Id>();
        for (Lead_Assignment_Config__mdt cfg : assignmentOrder) {
            Id uid = identifierToUserId.get(cfg.User_Indentifier__c);
            System.debug('CMDT → ' + cfg.User_Indentifier__c + ' mapped to UserId: ' + uid);
            allSalesUserIds.add(uid);
        }
        
        System.debug('Final Ordered User IDs: ' + allSalesUserIds);
        
        // Process Each Lead
        for (Related_Source__c rs : leadsToProcess) {
            System.debug('----- Processing Lead: ' + rs.Id + ' -----');
            System.debug('Current OwnerId: ' + rs.OwnerId);
            
            Integer times = rs.No_Of_Times_Unqualified__c == null
                ? 0 
                : Integer.valueOf(rs.No_Of_Times_Unqualified__c);
            System.debug('Times Unqualified: ' + times);
            
            // Filter out current owner
            List<Id> availableUsers = new List<Id>();
            for (Id uId : allSalesUserIds) {
                if (uId != rs.OwnerId) {
                    availableUsers.add(uId);
                }
            }
            
            System.debug('Available Users: ' + availableUsers);
            
            if (!availableUsers.isEmpty()) {
                Integer idx = Math.mod(times, availableUsers.size());
                Id newOwner = availableUsers[idx];
                System.debug('Assigning new Owner using index ' + idx + ': ' + newOwner);
                
                rs.OwnerId = newOwner;
            } else {
                System.debug('⚠️ No available users to assign!');
            }
            
            System.debug('New OwnerId Set: ' + rs.OwnerId);
        }
        
        System.debug('===== END reassignUnqualifiedLead1() =====');
    }
    
    public static void SourceHandlingMethod(List<Related_Source__c> relSouList){
        List<Source_Bifurcation__c> sourceList = [Select Id,Name,Type__c,Source__c from Source_Bifurcation__c];
        Map<String,List<String>> typeWithSource = New Map<String,List<String>>();
        if(sourceList.size() >0){
            for(Source_Bifurcation__c source : sourceList){
                List<String> sources = source.Source__c.split(';');
                typeWithSource.put(source.Type__c,sources);
            }
        }

		Set<Id> leadIds = New Set<Id>();        
        for(Related_Source__c relSource : relSouList){
            if(relSource.SLead__c != null){
                leadIds.add(relSource.SLead__c);
            }
        }
        
        List<Related_Source__c> relatedSourceList = [Select Id,Name,Source__c from Related_Source__c where SLead__c in:leadIds];
        for(Related_Source__c relSource : relatedSourceList){
            
        }
    }
    
    // Method to map Lead to Related_Source__c
    public static Related_Source__c mapLeadToRelatedSource(Lead nld,String leadType, String typeOfLead) {
        /*
       RecordType leadRT = [
            SELECT DeveloperName
            FROM RecordType
            WHERE Id = :nld.RecordTypeId
        ];
        
        RecordType rsRT = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Related_Source__c'
            AND DeveloperName = :leadRT.DeveloperName
            LIMIT 1
        ];
        */
        // Fetch custom label value
        String sourceType = System.Label.RelatedSource_RecordType; // Example label: "PreSales" or "Sales"
        
        // Determine the DeveloperName of the Related_Source__c record type
        String rsDevName;
         RecordType rsRT;
        if (sourceType == 'Sales') {
            rsDevName = 'Sales';
            rsRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Related_Source__c' 
            AND DeveloperName = :rsDevName
            LIMIT 1
        ];
           
        }
        
       
       
        String fullName = 
            (nld.Salutation != null ? nld.Salutation + ' ' : '') +
            (nld.FirstName != null ? nld.FirstName + ' ' : '') +
            (nld.LastName != null ? nld.LastName : '');
        
        system.debug('=== FULL NAME === ' + fullName);
       
        Related_Source__c rs = new Related_Source__c();
        if(leadType == 'Main Lead'){
            rs.SLead__c = nld.Main_Lead__c;
        }
        else{
            rs.SLead__c = nld.Id;
        }
        
        
        rs.Main_Lead__c =nld.Id;
        rs.Locale__c = nld.Locale__c;
        rs.Source__c = nld.Lead_source__c;
        rs.Sub_Source__c = nld.Sub_Source__c;
        rs.Country_Code__c = nld.Country_Code__c;
        rs.Secondary_Phone__c = nld.Secondary_Phone__c;
        rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
        rs.Email__c = nld.Email;
        rs.Secondary_Email__c = nld.Secondary_Email__c;
        rs.Description__c = nld.Last_Comment__c;
        rs.Allocated_Project__c = nld.Allocated_Project__c;
        rs.Campaign__c = nld.Campaign__c;
        rs.type_of_lead__c = nld.Type_of_lead__c;
        rs.Campaign_Std__c = nld.Campaign_Std__c;
        rs.Campaign__c = nld.Campaign__c;
        rs.sfleadcaphfprod_External_Lead_ID__c = nld.sfleadcaphfprod__External_Lead_ID__c;
        //rs.scheck__c = nld.scheck__c;
        rs.Zone_Preferred__c = nld.Zone_Preferred__c;
        rs.Whatsapp_number__c = nld.Whatsapp_number__c;
        rs.WhatsApp_Message_Status__c = nld.WhatsApp_Message_Status__c;
        rs.WhatsApp_Message_Id__c = nld.WhatsApp_Message_Id__c;
        rs.Welcome_Code_Used__c = nld.Welcome_Code_Used__c;
        rs.Website__c = nld.Website;
        rs.Walking_Lead_Form__c = nld.Walking_Lead_Form__c;
        rs.Verified_Phone__c = nld.tdc_tsw__Verified_Phone__c;
        rs.Verified_Number__c = nld.Verified_Number__c;
        rs.Vehicle_Model__c = nld.Vehicle_Model__c;
        rs.Unqualified_Reason__c = nld.Unqualified_Reason__c;
        rs.Unit_Preference__c = nld.Unit_Preference__c;
        rs.UTM_Term__c = nld.UTM_Term__c;
        rs.Chat_Conversation__c = nld.Chat_Conversation__c;
        rs.UTM_Source__c = nld.UTM_Source__c;
        rs.UTM_Placement__c = nld.UTM_Placement__c;
        rs.UTM_Medium__c = nld.UTM_Medium__c;
        rs.UTM_Campaign__c = nld.UTM_Campaign__c;
        rs.UTM_Device__c = nld.UTM_Device__c;
        rs.Type__c = nld.tdc_tsw__Type__c;
        rs.UTM_Adgroup__c = nld.UTM_Adgroup__c;
        rs.Transfered_On__c = nld.Pushed_On__c;
        rs.Transfered_By__c = nld.Pushed_By__c;
        rs.Total_Calls__c = nld.Total_Calls__c;
        rs.Title__c = nld.Title;
        rs.Tertiary_Source__c = nld.Tertiary_Source__c;
        rs.Team_Lead_Rating__c = nld.Team_Lead_Rating__c;
        rs.TL_Rating__c = nld.TL_Rating__c;
        rs.TL_RHS_Review__c = nld.TL_RHS_Review__c;
        rs.TL_RHS_Count__c = nld.TL_RHS_Count__c;
        rs.TAT_For_Sales__c = nld.TAT_For_Sales__c;
        rs.TAT_for_New_Lead__c = nld.TAT_for_New_Lead__c;
        rs.Sv_Designation__c = nld.Sv_Designation__c;
        rs.Sv_Designation_of_Customer__c = nld.Sv_Designation_of_Customer__c;
        //rs.Submission_Date__c = nld.Submission_Date__c;
        rs.Sub_Source__c = nld.Sub_Source__c;
        //rs.Status1__c = nld.Status;
        rs.Status_Change_Date__c = nld.Status_Change_Date__c;
        rs.State__c = nld.State__c;
        rs.Spouse_Working__c = nld.Spouse_Working__c;
        rs.Spouse_Designation__c = nld.Spouse_Designation__c;
        rs.Spouse_Company_Name__c = nld.Spouse_Company_Name__c;
        rs.Source_of_Funding__c = nld.Source_of_Funding__c;
        //rs.Lead_Source__c = nld.LeadSource;
        rs.Source_URL__c = nld.Source_URL__c;
        rs.Source_Type__c = nld.Source_Type__c;
        rs.Source_Manager_Id_s__c = nld.Source_Manager_Id_s__c;
        rs.Site_visit_Project__c = nld.Site_visit_Project__c;
        rs.Site_Visit_Schedule_Date__c = nld.Site_Visit_Schedule_Date__c;
        rs.Site_Visit_Feedback__c = nld.Site_Visit_Feedback__c;
        //rs.Site_Visit_Completed__c = nld.Site_Visit_Completed__c;
        rs.Share_Project_Deta__c = nld.Share_Project_Deta__c;
        rs.Select_Your_Preferred_Plot_Size__c = nld.Select_Your_Preferred_Plot_Size_With_Pri__c;
        rs.Secondary_source__c = nld.Lead_source__c;
        rs.Secondary_Phone__c = nld.Secondary_Phone__c;
        // rs.Secondary_Phone1__c = nld.Secondary_Phone1__c;
        // rs.Secondary_Phone_Project__c = nld.Secondary_Phone_Project__c;
        rs.Secondary_Email__c = nld.Secondary_Email__c;
        rs.Secondary_Country__c = nld.Secondary_Country__c;
        rs.Secondary_Country_Code__c = nld.Secondary_Country_Code__c;
        rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
        // rs.SecondaryPhoneProject__c = nld.SecondaryPhoneProject__c;
        // rs.SecondaryEmailProject__c = nld.SecondaryEmailProject__c;
        rs.Search_Sourcing_Manager__c = nld.Search_Sourcing_Manager__c;
        rs.Search_Closing_Manager__c = nld.Search_Closing_Manager__c;
        rs.Sales_User__c = nld.Sales_User__c;
        rs.Sales_Rating__c = nld.Sales_Rating__c;
        rs.SV_pipeline__c = nld.SV_pipeline__c;
        rs.Sales_Feedback__c = nld.Sales_Feedback__c;
        rs.SV_User__c = nld.SV_User__c;
        rs.SV_Entry_Time__c = nld.SV_Entry_Time__c;
        rs.SV_Drive_Team__c = nld.SV_Drive_Team__c;
        rs.STM2__c = nld.STM2__c;
        rs.SMS_Opt_out__c = nld.tdc_tsw__SMS_Opt_out__c;
       
        rs.Round_Robin_Off__c = nld.Round_Robin_Off__c;
        rs.Result__c = nld.tdc_tsw__Result__c;
        rs.Residential_Status__c = nld.Residential_Status__c;
        rs.Remark_for_Closed_Lost__c = nld.Remark_for_Closed_Lost__c;
        rs.Remark__c = nld.Remark__c;
        rs.Relationship_to_referred_Person__c = nld.Relationship_to_referred_Person__c;
        rs.Rejection_Date__c = nld.Rejection_Date__c;
        rs.Referred_Employee__c = nld.Referred_Employee__c;
         if (sourceType == 'Sales') {
             rs.RecordTypeId = rsRT.id;
         }
        rs.Reassigned_By__c = nld.Reassigned_By__c;
        rs.Reasons_in_Detail__c = nld.Reasons_in_Detail__c;
        rs.Reason_For_Rejection__c = nld.Reason_For_Rejection__c;
        rs.Reason_For_Purchase__c = nld.Reason_For_Purchase__c;
        //rs.Realated_Lead_Time__c = nld.Realate_Lead_Time__c;
        rs.Re_engaged_Count__c = nld.Re_engaged_Count__c;
        rs.Re_assigned_date__c = nld.Re_assigned_date__c;
        rs.Re_Engaged_Date__c = nld.Re_Engaged_Date__c;
        rs.Re_Enagaged_Leads__c = nld.Re_Enagaged_Leads__c;
        rs.Rating__c = nld.Rating;
        rs.RNR_Date__c = nld.RNR_Date__c;
        rs.RM_Event_Confirmation__c = nld.RM_Event_Confirmation__c;
        rs.RM_CP_Name__c = nld.User__c;
        rs.REAP_Name__c = nld.REAP_Name__c;
        rs.Purchase_Type__c = nld.Purchase_Type__c;
        rs.Pronouns__c = nld.Pronouns;
        rs.Purchase_Timeline__c = nld.Purchase_Timeline__c;
        rs.Projects_of_other_builders_recently_visi__c = nld.Projects_of_other_builders_recently_visi__c;
        rs.Project_Status__c = nld.Project_Status__c;
        rs.Project_Interested__c = nld.Project_Interested__c;
        rs.Profession__c = nld.Profession__c;
        rs.Primary_Source__c = nld.Source_Type__c;
        rs.Primary_Phone__c = nld.Phone__c;
        rs.Phone__c = nld.Phone__c;
        rs.Pre_Sales_User__c = nld.Pre_Sales_User__c;
        rs.Preferred_Project_location__c = nld.Preferred_Project_location__c;
        rs.Pre_Sales_Rating__c = nld.Pre_Sales_Rating__c;
        rs.Possession__c = nld.Possession__c;
        rs.Possession_Timeline__c = nld.Possession_Timeline__c;
        rs.Pincode__c = nld.Pincode__c;
        rs.Phone_Verification_Status__c = nld.tdc_tsw__Phone_Verification_Status__c;
        //rs.Phone_Status__c = nld.tdc_tsw__Phone_Status__c;
        //rs.PhoneProject__c = nld.PhoneProject__c;
        rs.Partner_Account__c = nld.PartnerAccountId;
        rs.Organization_Pincode__c = nld.Organization_Pincode__c;
        //rs.OwnerId = nld.OwnerId;
        // // ================= OWNER HANDLING =================
        if (nld.Lead_Assigned__c == true) {
            
            // Lead is upload-assigned → skip RR completely
            if (nld.backup_user_Field__c != null) {
                rs.OwnerId = nld.backup_user_Field__c;
            } else {
                // Safety fallback (Admin stays owner)
                rs.OwnerId = nld.OwnerId;
            }
            
        } else {
            // Normal system flow (RR / existing owner logic)
            rs.OwnerId = nld.OwnerId;
        }
        rs.Organization_Name__c = nld.Organization_Name__c;
        rs.Organization_Address__c = nld.Organisation_Address__c;
        rs.Opportunity__c = nld.ConvertedOpportunityId;
        rs.Open_Reason__c = nld.Open_Reason__c;
        rs.Offer_Scheme_interested__c = nld.Offer_Scheme_interested__c;
        rs.Occupation__c = nld.Occupation__c;
        rs.OTP__c = nld.OTP__c;
        rs.Number_of_members_in_the_family__c = nld.Number_of_members_in_the_family__c;
        rs.Number_of_homes_Owned__c = nld.Number_of_homes_Owned__c;
        rs.Number_Verify_Result_Msg__c = nld.tdc_tsw__Phone_Verify_Result_Msg__c;
        rs.Number_Of_Calls__c = nld.Number_Of_Calls__c;
        rs.Not_open_to_share__c = nld.Not_open_to_share__c;
        rs.Not_Responded__c = nld.Not_Responded__c;
        rs.No_of_Site_Visit__c = nld.No_of_Site_Visit__c;
        rs.No_of_Employees__c = nld.NumberOfEmployees;
        rs.No_of_Children__c = nld.No_of_Children__c;
        rs.No_Of_Times_Unqualified__c = nld.No_Of_Times_Unqualified__c;
        rs.No_Of_Homes_Owned__c = nld.No_Of_Homes_Owned__c;
        rs.Next_follow_up_Date__c = nld.Next_follow_up_Date__c;
        rs.Next_Site_visit_Date__c = nld.Next_Site_visit_Date__c;
        //rs.Name = nld.Name;
         system.debug('=== fullName === ' + fullName);
        rs.Name__c = fullName;
        rs.NRI_Prospect__c = nld.NRI_Prospect__c;
        rs.Mother_tongue__c = nld.Mother_tongue__c;
        rs.Mode_of_Enquiry__c = nld.Mode_of_Enquiry__c;
        rs.MobilePhone__c = nld.MobilePhone;
        rs.Medium__c = nld.UTM_Medium__c;
        rs.Maximum_Investment_in_Lakhs__c = nld.Maximum_Investment_in_Lakhs_c__c;
        rs.Maximum_Budget__c = nld.Maximum_Budget__c;
        rs.Marketing_Campaign__c = nld.Marketing_Campaign__c;
        rs.Mark_Unqualified__c = nld.Mark_Unqualified__c;
        rs.Marital_Status__c = nld.Marital_Status__c;
        rs.Make_of_Vehicle__c = nld.Make_of_Vehicle__c;
        // rs.Main_lead_status__c = nld.Main_lead_status__c;
        //  rs.Main_Pre_Sales_User__c = nld.Main_Pre_Sales_User__c;
        rs.Main_Lead__c = nld.Main_Lead__c;
        rs.Lost_Reason__c = nld.Lost_Reason__c;
        rs.Location_Preferred__c = nld.Location__c;
        rs.LiveChat_URL__c = nld.LiveChat_URL__c;
        rs.LinkedIn_Question__c = nld.LinkedIn_Question__c;
        //rs.Lead_status1__c = nld.Lead_Status__c;
       //rs.Lead_status1__c = 'New';
        rs.LinkedIn_Answer__c = nld.LinkedIn_Answer__c;
        if(typeOfLead == ''){
            if(nld.Main_lead_status__c == 'Rejected' || nld.Main_lead_status__c == 'Booked'|| nld.Main_lead_status__c =='Closed Lost' || nld.Main_lead_status__c =='Unqualified'){
                rs.Lead_Type__c = 'Re-Opened';
            }else{
                rs.Lead_Type__c = 'Re-Engaged';
            }
        }
        
        rs.Lead_Transfered__c = nld.Lead_Transfered__c;
        rs.Lead_Transfer_Note__c = nld.Lead_Transfer_Note__c;
        //rs.Lead_Status__c = nld.Lead_Status__c;
        //rs.Lead_Source__c = nld.LeadSource;
        //rs.Lead_Score__c = nld.Lead_Score__c;
        // rs.Lead_Record_Type__c = nld.Lead_Record_Type__c;
        rs.Lead_OwnerSecondary__c = nld.Lead_OwnerSecondary__c;
        //rs.Lead_Id__c = nld.Lead_ID__c;
        rs.Lead_Assigned__c = nld.Lead_Assigned__c;
        // rs.Lead_Age_Days__c = nld.Lead_Age__c;
        rs.Last_Unqualified_by__c = nld.Last_Unqualified_by__c;
        rs.Last_Unqualified_At__c = nld.Last_Unqualified_At__c;
        rs.Last_Site_Visit_Date_Time__c = nld.Last_Site_Visit_Date_Time__c;
        rs.Last_Source_Of_Enquiry__c = nld.Last_Source_Of_Enquiry__c;
        rs.Last_Sub_Source__c = nld.Last_Sub_Source__c;
        rs.Last_Sales_Call_Date__c = nld.Last_Sales_Call_Date__c;
        rs.Last_Re_Opened_Date__c = nld.Last_Re_Opened_Date__c;
        rs.Last_Presales_Call_Date__c = nld.Last_Presales_Call_Date__c;
        rs.Last_Re_Engaged_Date__c = nld.Last_Re_Engaged_Date__c;
        rs.Last_Outbound_Call_Date__c = nld.Last_Outbound_Call_Date__c;
        rs.Last_Note__c = nld.Last_Note__c;
        rs.Last_Comment__c = nld.Last_Comment__c;
        rs.Last_Campagin__c = nld.Last_Campagin__c;
        rs.Last_Call_Status__c = nld.Last_Call_Status__c;
        rs.LastTransferDate__c = nld.LastTransferDate;
        rs.Kids__c = nld.Kids__c;
        rs.Jigsaw__c = nld.Jigsaw;
        rs.Is_your_spouse_working__c = nld.Is_your_spouse_working__c;
        rs.Is_this_your_First_Home__c = nld.Is_this_your_First_Home__c;
        // rs.Is_Site_Visit_Mandatory__c = nld.Is_Site_Visit_Mandatory__c;
        rs.Is_Site_Visit_Created__c = nld.Is_Site_Visit_Created__c;
        // rs.Is_Locked__c = nld.Is_Locked__c;
        // rs.Is_Current_User__c = nld.Is_Current_User__c;
        rs.IsPushed__c = nld.IsPushed__c;
        //rs.IsConverted__c = nld.IsConverted;
        rs.Investment_Range__c = nld.Investment_Range__c;
        rs.Interested_in_event_Reconfirmation__c = nld.Interested_in_event_Reconfirmation__c;
        //rs.Interested_Project__c = nld.Interested_Project__c;
        rs.Interest_In_Other_Project__c = nld.Interest_In_Other_Project__c;
        rs.Interested_In_Event__c = nld.Interested_In_Event__c;
        rs.Industry__c = nld.Industry;
        rs.IndividualId__c = nld.IndividualId;
        rs.How_soon_do_you_intend_to_buy_it__c = nld.How_soon_do_you_intend_to_buy_it__c;
        rs.How_long_you_are_in_the_city_in_years__c = nld.How_long_you_are_in_the_city_in_years__c;
        rs.How_long_have_you_been_looking_for_a_hom__c = nld.How_long_have_you_been_looking_for_a_hom__c;
        rs.How_are_you_financing_your_dream_home__c = nld.How_are_you_financing_your_dream_home__c;
        rs.How_did_you_get_to_know_about_our_Projec__c = nld.How_did_you_get_to_know_about_our_Projec__c;
        rs.Hoarding_Details__c = nld.Hoarding_Details__c;
        rs.HasOptedOutOfFax__c = nld.HasOptedOutOfFax;
        rs.Head_Count__c = nld.Head_Count__c;
        rs.Have_you_visited_any_Zuari_Project_recen__c = nld.Have_you_visited_any_Zuari_Project_recen__c;
        rs.HasOptedOutOfEmail__c = nld.HasOptedOutOfEmail;
        rs.GenderIdentity__c = nld.GenderIdentity;
        rs.Followup_Subject__c = nld.Followup_Subject__c;
        rs.Follow_Up_Description__c = nld.Follow_Up_Description__c;
        rs.Follow_Up_Comment__c = nld.Follow_Up_Comment__c;
        rs.First_Source_Of_Enquiry__c = nld.First_Source_Of_Enquiry__c;
        rs.First_Sub_Source__c = nld.First_Sub_Source__c;
        rs.Flat_Preference__c = nld.Flat_Preference__c;
        rs.First_Site_Visit_Date_Time__c = nld.First_Site_Visit_Date_Time__c;
        rs.First_Sales_Call_Date__c = nld.First_Sales_Call_Date__c;
        rs.First_Presales_Call_Date__c = nld.First_Presales_Call_Date__c;
        rs.First_Contatced_On__c = nld.First_Contatced_On__c;
        rs.First_Campaign__c = nld.First_Campaign__c;
        // rs.Expired_On__c = nld.Expired_On__c;
        rs.Fax__c = nld.Fax;
        rs.Execuive_Count__c = nld.Execuive_Count__c;
        rs.Enquiry_Category__c = nld.Enquiry_Category__c;
        rs.Event_Name__c = nld.Event_Name__c;
        rs.Enquired_At__c = nld.Enquired_At__c;
        rs.Email__c = nld.Email;
        // rs.EmailProject__c = nld.EmailProject__c;
        rs.EOI_Collected__c = nld.EOI_Collected__c;
        //rs.Dubble__c = nld.Dubble__c;
        rs.Do_You_have_Kids__c = nld.Do_You_have_Kids__c;
        rs.Do_Not_Call__c = nld.DoNotCall;
        rs.Description__c = nld.Description;
        rs.Designation__c = nld.Designation__c;
        rs.Delete_Lead__c = nld.Delete_Lead__c;
        rs.Date_of_Attendence__c = nld.Date_of_Attendence__c;
        rs.Date_of_Enquiry__c = nld.Date_of_Enquiry__c;
        rs.Date_of_Attendance__c = nld.Date_of_Attendance__c;
        rs.Customer_s_Unit_No__c = nld.Customer_s_Unit_No__c;
        rs.Customer_Project_Name__c = nld.Customer_Project_Name__c;
        rs.Customer_Place_Visit_Date__c = nld.Customer_Place_Visit_Date__c;
        rs.Customer_Name__c = nld.Customer_Name__c;
        rs.Current_Residence__c = nld.Current_Residence__c;
        rs.Current_Residence_Typology__c = nld.Current_Residence_Typology__c;
        rs.Current_Company_Address__c = nld.Current_Company_Address__c;
        // rs.Created_Date__c = nld.CreatedDate;
        rs.Current_Accommodation__c = nld.Current_Accommodation__c;
        // rs.Created_Date_C__c = nld.Created_Datec__c;
        rs.Country__c = nld.Country__c;
        rs.Country_Code__c = nld.Country_Code__c;
        rs.Country1__c = nld.Country1__c;
        rs.Convert_Date__c = nld.Convert_Date__c;
        rs.Consent__c = nld.Consent__c;
        rs.Consent_Time__c = nld.Created_Datec__c;// UPdated on 02-02-2026 by Praveen
         rs.Consent_Lead__c = nld.Consent_Lead__c;// UPdated on 02-02-2026 by Praveen
        rs.Source_of_Consent__c = nld.Source_of_Consent__c;// UPdated on 02-02-2026 by Praveen
       
        rs.Company_Name__c = nld.Company_Name__c;
        rs.Confirmation_Email__c = nld.Confirmation_Email__c;
        rs.Company__c = nld.Company;
        rs.Closed_Lost_Reason__c = nld.Closed_Lost_Reason__c;
        rs.Club_Memberships__c = nld.Club_Memberships__c;
        rs.Client_Status__c = nld.Client_Status__c;
        rs.Client_Place__c = nld.Client_Place__c;
        rs.City__c = nld.City__c;
        rs.Cilent_Place__c = nld.Cilent_Place__c;
        //rs.Channel_Partner__c = nld.Channel_Partner__c;
        //rs.Channel_Partner_Email__c = nld.Channel_Partner_Email__c;
        rs.Channel_Partner1__c = nld.Channel_Partner__c;
        rs.Campaign__c = nld.Campaign__c;
        rs.Capture_Re_Engaged_Date__c = nld.Capture_Re_Engaged_Date__c;
        rs.Campaign_Name__c = nld.Campaign__c;
        rs.Calling_Region__c = nld.Calling_Region__c;
        rs.Campaign_Lookup__c = nld.Campaign_std__c;
        //rs.CP_RM_PAN__c = nld.CP_RM_PAN__c;
        //rs.CP_Owner_ID__c = nld.CP_Owner_ID__c;
        //rs.CP_Manager_s_Email_Id__c = nld.CP_Manager_s_Email_Id__c;
        rs.CP_Lookup__c = nld.Channel_Partner__c;
        rs.CP_Id__c = nld.CP_Id__c;
        rs.Budget__c = nld.Budget__c;
        rs.Assign_To__c = nld.Assign_To__c;
        rs.Assigment_count__c = nld.Assigment_count__c;
        rs.Are_you_a_Native_of_the_City__c = nld.Are_you_a_Native_of_the_City__c;
        rs.Any_relatives_friends_Abroad__c = nld.Any_relatives_friends_Abroad__c;
        rs.Annual_Revenue__c = nld.AnnualRevenue;
        rs.Allocator__c = nld.Allocator__c;
        rs.Allocated_Reason__c = nld.Allocated_Reason__c;
        rs.Allocated_Project__c = nld.Allocated_Project__c;
        rs.Age_of_Elder_Child__c = nld.Age_of_Elder_Child__c;
        rs.Age_of_Younger_Child__c = nld.Age_of_Younger_Child__c;
        rs.Address__c = nld.Address__c;
        rs.Age__c = nld.Age__c;
        rs.Address_Work__c = nld.Address_Work__c;
        rs.Ad_set_Name__c = nld.Ad_set_Name__c;
        rs.Ad_Name__c = nld.Ad_Name__c;
        
        return rs;
    }
    
    
    public static void sendCustomNotification(Set<String> recepientIds, String title, String body, Id recId, String notificationName){
        CustomNotificationType closedWonNotification = [
            SELECT Id, DeveloperName 
            FROM CustomNotificationType 
            WHERE DeveloperName = :notificationName 
            LIMIT 1
        ]; 
        
        Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
        Notification.setNotificationTypeId(closedWonNotification.Id); 
        Notification.setSenderId(UserInfo.getUserId()); 
        Notification.setBody(body); 
        Notification.setTitle(title); 
        Notification.setTargetId(recId);
        
        try {
            Notification.send(recepientIds);
        } catch (Exception e) {
            System.debug('Notification Error: ' + e.getMessage());
        }
    }
    
    public static void FillCPManage(List<Related_Source__c> rsLsit){
        for(Related_Source__c rs : rsLsit){
            if(rs.Channel_Partner1__c != null){
                rs.OwnerId = rs.Channel_Partner1__r.OwnerId;
            }
            
        }
    }

    public static void sendReassignNotifications(
        List<Related_Source__c> newList,
        Map<Id, Related_Source__c> oldMap
    ) {
        for (Related_Source__c newRS : newList) {
            Related_Source__c oldRS = oldMap.get(newRS.Id);
            
            // ✔ Send notification only when Owner changed
            if (oldRS.OwnerId != newRS.OwnerId && newRS.OwnerId != null) {
                
                // Title & Body
                String title = 'Related Source Assigned: ' + newRS.Name;
                String body = 'A Related Source record has been assigned/transferred to you.';
                
                // Prepare recipients
                Set<String> recipients = new Set<String>();
                recipients.add(String.valueOf(newRS.OwnerId));
                
                // Call your notification method
               if (!Test.isRunningTest()) {
                sendCustomNotification(
                    recipients,
                    title,
                    body,
                    newRS.Id,
                    'Related_source_Notification'   // your DeveloperName of notification type
                );
               }
            }
        }
    }
    /**
 * @description
 * Handler class responsible for creating Notification__c records
 *
 * This class is invoked from the RelatedSourceTrigger during the
 * after update context and detects lead status field changes
 * to initiate notification creation.
 *
 * Business Rules Implemented:
 * - Detects change in Lead_status1__c field
 * - Verifies Channel_Partner1__c lookup is populated
 * - Creates a Notification__c record when both conditions are satisfied
 *
 *
 * @usage
 * Called from RelatedSourceTrigger (after update context).
 *
 * @author
 * Praveen Kumar
 *
 

    public static void createNotificationRecords(List<Related_Source__c> newList, Map<Id, Related_Source__c> oldMap  ) {

        List<Notification__c> notificationsToInsert = new List<Notification__c>();

        for (Related_Source__c newRec : newList) {

            Related_Source__c oldRec = oldMap.get(newRec.Id);

            // ✅ Condition 1: Lead status changed
            Boolean isStatusChanged =
                newRec.Lead_status1__c != oldRec.Lead_status1__c;

            // ✅ Condition 2: Channel Partner exists
            Boolean hasChannelPartner = newRec.Channel_Partner1__c != null;

            if (isStatusChanged && hasChannelPartner) {

                Notification__c noti = new Notification__c();
                noti.Related_Source__c = newRec.Id;
                noti.Notification_Type__c = 'Lead Notification';
                noti.Notification_Heading__c = 'Lead Status Changed';
                noti.Notification_Content__c = 'Status has been updated by this Lead Owner';
                noti.IsActive__c = true;
                noti.Channel_Partner__c = newRec.Channel_Partner1__c;
                noti.Notification_Redirect_Id__c= newRec.Lead_Id__c;
                noti.IsNotificationSent__c = false;
                noti.Notification_Category__c='User Specific';

                notificationsToInsert.add(noti);
            }
        }

        if (!notificationsToInsert.isEmpty()) {
            insert notificationsToInsert;
        }
    }
*/
     /**
     * Use Case #4: Lost After Site Visit
     * Fires when Lead_status1__c becomes 'Closed Lost' AND the record has had at least one
     * completed Site Visit (No_of_Site_Visit__c > 0).
     * Recipients: CP Manager (Channel_Partner1__r.Sourcing_RM__c) + CP Head users + Sales Head (STM2__c).
     */
    public static void handleLeadLostAfterSV(
        List<Related_Source__c> newList,
        Map<Id, Related_Source__c> oldMap
    ) {
        if (newList == null || newList.isEmpty() || oldMap == null) return;

        Set<Id> rsIds = new Set<Id>();
        for (Related_Source__c rs : newList) {
            Related_Source__c oldRs = oldMap.get(rs.Id);
            if (oldRs == null) continue;

            Boolean becameLost = rs.Lead_status1__c == 'Closed Lost'
                              && oldRs.Lead_status1__c != 'Closed Lost';
            Boolean hadSV = rs.No_of_Site_Visit__c != null && rs.No_of_Site_Visit__c > 0;

            if (becameLost && hadSV) rsIds.add(rs.Id);
        }

        if (rsIds.isEmpty()) return;
System.debug(rsIds);
        Map<Id, Related_Source__c> rsMap = new Map<Id, Related_Source__c>([
            SELECT Id, Name, STM2__c, Channel_Partner1__c,
                   Channel_Partner1__r.Sourcing_RM__c
            FROM Related_Source__c
            WHERE Id IN :rsIds
        ]);
System.debug(rsMap);
        Set<Id> cpHeadUserIds = new Set<Id>();
        for (User u : [
            SELECT Id FROM User WHERE Profile.Name = 'CP Head' AND IsActive = true
        ]) {
            cpHeadUserIds.add(u.Id);
        }

        Id lostTypeId = SiteVisitTriggerHandler.getCustomNotificationTypeId('SV_Lost_After_Visit');
System.debug(lostTypeId);
        Set<Id> allRecipients = new Set<Id>();
        Map<Id, Set<Id>> rsToRecipients = new Map<Id, Set<Id>>();

        for (Related_Source__c rs : rsMap.values()) {
            Set<Id> recipients = new Set<Id>();
            if (rs.Channel_Partner1__c != null
                && rs.Channel_Partner1__r != null
                && rs.Channel_Partner1__r.Sourcing_RM__c != null) {
                recipients.add(rs.Channel_Partner1__r.Sourcing_RM__c);
            }
            if (rs.STM2__c != null) recipients.add(rs.STM2__c);
            recipients.addAll(cpHeadUserIds);

            if (!recipients.isEmpty()) {
                rsToRecipients.put(rs.Id, recipients);
                allRecipients.addAll(recipients);
            }
        }

        if (allRecipients.isEmpty()) return;
System.debug(allRecipients);
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Email FROM User WHERE Id IN :allRecipients AND IsActive = true
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Related_Source__c rs : rsMap.values()) {
            Set<Id> recipients = rsToRecipients.get(rs.Id);
            if (recipients == null || recipients.isEmpty()) continue;
            SiteVisitTriggerHandler.sendBell(lostTypeId, rs, recipients, 'Lost', rs.Name);
            SiteVisitTriggerHandler.buildEmails(emails, rs, rs.Name, recipients, userMap, 'Lost');
        }

        if (!emails.isEmpty() && !Test.isRunningTest()) {
            System.debug('sent');
            Messaging.sendEmail(emails, false);
        }
    }
    
    public static void enqueueMarketingCloudOTT(List<Related_Source__c> records) {
        if (Label.SFMC_OTT_Trigger_Toggle != 'TRUE') return;

        List<Related_Source__c> eligible = new List<Related_Source__c>();
        for (Related_Source__c r : records) {
            if (String.isNotBlank(r.Phone__c) && r.Allocated_Project__c == 'Zuari Gangothri Tribhuja') eligible.add(r);
        }
        if (eligible.isEmpty() || Test.isRunningTest()) return;

        System.enqueueJob(new MarketingCloudOTTSender(eligible));
    }
}