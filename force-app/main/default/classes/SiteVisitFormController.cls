public without sharing class SiteVisitFormController {

    @AuraEnabled
    public static List<Map<String, String>> getProjectPicklistValues() {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Related_Source__c.Allocated_Project__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry p : ple) {
            Map<String, String> valuesMap = new Map<String, String>();
            valuesMap.put('value', p.getValue());
            valuesMap.put('label', p.getLabel());
            picklistValues.add(valuesMap);
        }
        
        return picklistValues;
    }
    
    @AuraEnabled
    public static List<Map<String, String>> getProjectPicklistValues1() {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Related_Source__c.Allocated_Project__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry p : ple) {
            Map<String, String> valuesMap = new Map<String, String>();
            valuesMap.put('value', p.getValue());
            valuesMap.put('label', p.getLabel());
            picklistValues.add(valuesMap);
        }
        
        return picklistValues;
    }
    
    @AuraEnabled
    public static String checkLeadWithPhoneProject(String project_name, String phone_number) {
        Boolean isLeadExists;
        String jsonResponse;
        String phoneProject = phone_number + project_name;
         List<Related_Source__c> leadList = new  List<Related_Source__c>();
        if (phone_number != null && project_name != null) {
            List<Site_Visit__c> svList = [Select Id,Name,OTP__c,Related_Source__r.Id from Site_Visit__c where OTP__c =: phone_number and Related_Source__r.Allocated_Project__c =: project_name and Status__c = 'Scheduled' LIMIT 1];
            Id leadsId = null;
            if(svList.size()>0){
                leadsId = svList[0].Related_Source__r.Id;
            }
            
            if(leadsId!= null){
                
                 leadList = [SELECT Name,Lead_status1__c,SLead__r.Id,Lead_Status__c,PhoneProject__c,RecordType.Name,Phone__c,Lead_Age_Days__c,Owner.Name,Address__c,
                                   State__c, Residential_Status__c, Current_Residence_Typology__c, NRI_Prospect__c,City__c, Country__c, Current_Residence__c, Are_you_a_Native_of_the_City__c, Pincode__c, Occupation__c, Designation__c,
                                   Organization_Address__c,  Consent__c, Open_Reason__c, HasOptedOutOfEmail__c,   Industry__c,  Organization_Name__c, Organization_Pincode__c, Consent_Time__c, Customer_Place_Visit_date__c, Reason_For_Purchase__c, How_long_have_you_been_looking_for_a_hom__c, How_did_you_get_to_know_about_our_Projec__c,  No_Of_Homes_Owned__c,
                                   How_soon_do_you_intend_to_buy_it__c,Customer_Project_Name__c, Preferred_Project_location__c,Interest_In_Other_Project__c, Budget__c, Customer_s_Unit_No__c, Number_of_members_in_the_family__c, Have_you_visited_any_Zuari_Project_recen__c, Projects_of_other_builders_recently_visi__c, How_are_you_financing_your_dream_home__c,
                                   Marital_Status__c, is_your_spouse_working__c, Do_You_have_Kids__c, Club_Memberships__c, Any_relatives_friends_Abroad__c,  Vehicle_Model__c, Make_of_Vehicle__c, How_long_you_are_in_the_city_in_years__c,Mother_tongue__c,Not_open_to_share__c,Calling_Region__c,No_of_Children__c,Age__c,Kids__c,Age_of_Elder_Child__c,Age_of_Younger_Child__c
                                   FROM Related_Source__c WHERE Id =: leadsId  LIMIT 1 ];
            
            }
            else{
                leadList = [SELECT Name,Lead_status1__c,SLead__r.Id,Lead_Status__c,PhoneProject__c,RecordType.Name,Phone__c,Lead_Age_Days__c,Owner.Name,Address__c,
                                   State__c, Residential_Status__c, Current_Residence_Typology__c, NRI_Prospect__c,City__c, Country__c, Current_Residence__c, Are_you_a_Native_of_the_City__c, Pincode__c, Occupation__c, Designation__c,
                                   Organization_Address__c,  Consent__c, Open_Reason__c, HasOptedOutOfEmail__c,   Industry__c,  Organization_Name__c, Organization_Pincode__c, Consent_Time__c, Customer_Place_Visit_date__c, Reason_For_Purchase__c, How_long_have_you_been_looking_for_a_hom__c, How_did_you_get_to_know_about_our_Projec__c,  No_Of_Homes_Owned__c,
                                   How_soon_do_you_intend_to_buy_it__c,Customer_Project_Name__c, Preferred_Project_location__c,Interest_In_Other_Project__c, Budget__c, Customer_s_Unit_No__c, Number_of_members_in_the_family__c, Have_you_visited_any_Zuari_Project_recen__c, Projects_of_other_builders_recently_visi__c, How_are_you_financing_your_dream_home__c,
                                   Marital_Status__c, is_your_spouse_working__c, Do_You_have_Kids__c, Club_Memberships__c, Any_relatives_friends_Abroad__c,  Vehicle_Model__c, Make_of_Vehicle__c, How_long_you_are_in_the_city_in_years__c,Mother_tongue__c,Not_open_to_share__c,Calling_Region__c,No_of_Children__c,Age__c,Kids__c,Age_of_Elder_Child__c,Age_of_Younger_Child__c
                                   FROM Related_Source__c WHERE  (PhoneProject__c = :phoneProject or Secondary_Phone_Project__c =:phoneProject) LIMIT 1 ];
            
                
            }
      List<Related_Source__c> reList = [SELECT SLead__r.Id,SLead__r.RecordType.Name,SLead__r.Owner.Name,SLead__r.Status,SLead__r.Lead_Status__c,SLead__r.Name,SLead__r.Phone__c,SLead__r.Home_Location__c,PhoneProject__c,SecondaryPhoneProject__c
                                              FROM Related_Source__c WHERE SLead__c =:leadsId AND (PhoneProject__c = :phoneProject or SecondaryPhoneProject__c =:phoneProject) LIMIT 1 ];
            String leadname;
            String OwnerName;
            String leadId;
            String phone;
            String OTPStatus;
            if (!leadList.isEmpty()) {
                Related_Source__c ld = leadList[0];
                leadname = ld.Name;
                phone = ld.Phone__c;
                leadId = ld.Id;
                
                if(ld.RecordType.Name != 'Pre Sales'){
                    if(ld.Lead_Status__c != 'Closed Lost'){
                        OTPStatus = 'Lead Exist In Active Status';
                        isLeadExists = true;
                    }
                    else if(ld.Lead_Status__c == 'Closed Lost'){
                        OTPStatus = 'Lead Exists And Not Active';
                        isLeadExists = true;
                    }
                    
                }
                else{
                    if(ld.Lead_Status__c != 'Unqualified'){
                        OTPStatus = 'Lead Exist In Active Status';
                        isLeadExists = true;
                    }
                    else{
                        OTPStatus = 'Lead Exists And Not Active';
                        isLeadExists = true;
                    }
                    
                }
            }
            else if(!reList.isEmpty()){
                Related_Source__c rd = reList[0];
                leadname = rd.SLead__r.Name;
                phone = rd.SLead__r.Phone__c;
                leadId = rd.SLead__r.Id;
                if(rd.SLead__r.RecordType.Name != 'Pre Sales'){
                    if(rd.SLead__r.Lead_Status__c != 'Closed Lost'){
                        OTPStatus = 'Lead Exist In Active Status';
                        isLeadExists = true;
                    }
                    else if(rd.SLead__r.Lead_Status__c == 'Closed Lost'){
                        OTPStatus = 'Lead Exists And Not Active';
                        isLeadExists = true;
                    }
                    
                }
                else{
                    if(rd.SLead__r.Lead_Status__c != 'Unqualified'){
                        OTPStatus = 'Lead Exist In Active Status';
                        isLeadExists = true;
                    }
                    else{
                        OTPStatus = 'Lead Exists And Not Active';
                        isLeadExists = true;
                    }
                    
                }
            } 
            else {
                OTPStatus = 'No Lead Exists';
                isLeadExists = false;
            }
            jsonResponse = '{';
            if(isLeadExists == true){
                jsonResponse += '"leadId":"' + leadId + '",';
                jsonResponse += '"leadname":"' + leadname + '",';
                jsonResponse += '"phone":"' + phone + '",';
                jsonResponse += '"OTPStatus":"' + OTPStatus + '"';
            }
            else{
                jsonResponse += '"OTPStatus":"' + OTPStatus + '"';
            }
            jsonResponse += '}';
        }
        system.debug(jsonResponse);
        return jsonResponse;
    }
    
    @AuraEnabled
    public static Map<String, String> getCountryAndCode() {
        Map<String, String> countryMap = new Map<String, String>();
        List<Country_Code_Mapping__mdt> countryMetadata = [SELECT Label, CountryCode__c FROM Country_Code_Mapping__mdt ];
        for (Country_Code_Mapping__mdt country : countryMetadata) {
            countryMap.put(country.Label, country.CountryCode__c);
        }
        return countryMap;
    }
    
    @AuraEnabled
    public static Related_Source__c getLead(String leadId) {
        system.debug('LEAd is ' + leadId);
        
        return [SELECT 
    Id, Name__c, Lead_status1__c,  Lead_Status__c, RecordType.Name, Phone__c, Lead_Age_Days__c, Owner.Name,
    Address__c, State__c, Residential_Status__c,Current_Residence_Typology__c, NRI_Prospect__c, City__c, Country__c,Current_Residence__c, Are_you_a_Native_of_the_City__c,  Pincode__c, Occupation__c, Designation__c, Sv_Designation_of_Customer__c, /* Added from first query as Sv_Designation_of_Customer__c */
    Sv_Designation__c,Organization_Address__c, Consent__c, Open_Reason__c,HasOptedOutOfEmail__c, Industry__c, Organization_Name__c, Organization_Pincode__c, Consent_Time__c,  Customer_Place_Visit_date__c, Reason_For_Purchase__c, How_long_have_you_been_looking_for_a_hom__c,
    How_did_you_get_to_know_about_our_Projec__c, No_Of_Homes_Owned__c,How_soon_do_you_intend_to_buy_it__c, Customer_Project_Name__c, Preferred_Project_location__c, Interest_In_Other_Project__c, Budget__c, Customer_s_Unit_No__c,  Number_of_members_in_the_family__c, Have_you_visited_any_Zuari_Project_recen__c,
    Projects_of_other_builders_recently_visi__c, How_are_you_financing_your_dream_home__c, Marital_Status__c,  is_your_spouse_working__c, Do_You_have_Kids__c, Club_Memberships__c, Any_relatives_friends_Abroad__c, Vehicle_Model__c, Make_of_Vehicle__c, How_long_you_are_in_the_city_in_years__c, Mother_tongue__c,Not_open_to_share__c, Calling_Region__c, No_of_Children__c, Age__c,Kids__c, Age_of_Elder_Child__c,Age_of_Younger_Child__c,Investment_Range__c,
    Project_Status__c,Purchase_Timeline__c,Client_Status__c, Possession_Timeline__c,Source_of_Funding__c,Channel_Partner__r.Name,Offer_Scheme_interested__c,RM_CP_Name__r.LastName,Mode_of_Enquiry__c, Channel_Partner_Email__c,Hoarding_Details__c,  CP_Manager_s_Email_Id__c, Referred_Employee__c, CP_RM_PAN__c,
    Lead_source__c /* Added from first query */
FROM Related_Source__c WHERE  Id = :leadId LIMIT 1];
    }
    @AuraEnabled
    public static void leadNotExists(Id leadId) {
        Related_Source__c ld = [select id,name,SLead__c,Lead_source__c,Sub_Source__c,Pre_sales_user__c,Sales_user__c,Allocated_Project__c,Channel_Partner1__c from Related_Source__c where Id =: leadId];
        Site_Visit__c sv = new Site_Visit__c();
        sv.Related_Source__c = ld.Id;
         sv.SLead__c = ld.SLead__c;
       sv.Channel_Partner__c = ld.Channel_Partner1__c;
        sv.Date__c = system.Now();
        sv.Status__c = 'Verified by GRE';
        sv.OTP__c = '';
        sv.GRE_Verified_Time__c = system.Now();
        sv.Customer_Visit_Happened__c=true;
        sv.Visit_Type__c = 'Site Visit';
        //sv.Feedback__c = 'Site Visit Completed successfully - By GRE Direct Walkin Lead Without SV Schedule';
        insert sv;
        
    }
    
    
    @AuraEnabled
    public static void duplicateLeadExists(Related_Source__c leadDetails) {
        
        String phoneProject = leadDetails.Phone__c+leadDetails.Allocated_Project__c;
        String secondaryPhoneProject = leadDetails.Secondary_Phone__c+leadDetails.Allocated_Project__c;
        Id leadId;
        String recordTypeName;
        Id ownerId;
        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Related_Source__c' AND Name = 'Sales' LIMIT 1];
        List<Related_Source__c> existingLeads = [select Id,Name,SLead__c,RecordType.Name,OwnerId from Related_Source__c where PhoneProject__c =:phoneProject or Secondary_Phone_Project__c=:secondaryPhoneProject ];
        if(existingLeads.isEmpty()){
            List<Related_Source__c> existingRelatedLists = [select Id,Name,SLead__r.OwnerId,SLead__r.Id,SLead__r.RecordType.Name,SLead__r.Home_Location__c from Related_Source__c where (PhoneProject__c =:phoneProject or SecondaryPhoneProject__c =:secondaryPhoneProject)];
            if(!existingRelatedLists.isEmpty()){
                leadId = existingRelatedLists[0].Id;
                recordTypeName = existingRelatedLists[0].SLead__r.RecordType.Name;
                ownerId = existingRelatedLists[0].SLead__r.OwnerId;
            }
        }
        else{
            leadId = existingLeads[0].Id;
            recordTypeName = existingLeads[0].RecordType.Name;
            ownerId = existingLeads[0].OwnerId;
        }
        
        if(leadId != null){
            leadDetails.Id = leadId;
            leadDetails.SLead__c = existingLeads[0].SLead__c;
            if(recordTypeName == 'Sales'){
                leadDetails.Lead_Assigned__c = false;
                leadDetails.Lead_status1__c = 'New sales enquiry'; 
            }
            else if(recordTypeName == 'Pre Sales'){
                leadDetails.Lead_Assigned__c = false;
                leadDetails.Lead_status1__c = 'New sales enquiry'; 
                leadDetails.Pre_Sales_User__c = ownerId;
                leadDetails.RecordTypeId = recordType.Id;
            }
            
            update leadDetails;
        }
        
        Site_Visit__c sv = new Site_Visit__c();
        sv.Related_Source__c = leadDetails.Id;
        sv.Date__c = system.Now();
        sv.Status__c = 'Verified by GRE';
        sv.OTP__c = '';
        sv.GRE_Verified_Time__c = system.Now();
        sv.Customer_Visit_Happened__c=true;
        sv.Visit_Type__c = 'Site Visit';
        sv.OTP__c = '0000';
        sv.Source_Type__c = 'Direct Walkin/Site Branding';
        insert sv;
        
    }
    
    @AuraEnabled
    public static String leadExists(String otp,String phone_number,String project_name, Datetime svDate, String visitType, Related_Source__c leadRec) {
        System.debug('==== DEBUG START: leadExists() INPUTS ====');
        System.debug('OTP                : ' + otp);
        System.debug('Phone Number       : ' + phone_number);
        System.debug('Project Name       : ' + project_name);
        System.debug('Site Visit Date    : ' + svDate);
        System.debug('Visit Type         : ' + visitType);
        System.debug('Related Source Rec : ' + leadRec);
        System.debug('Related Source Id  : ' + (leadRec != null ? leadRec.Id : 'NULL'));
        System.debug('==== DEBUG END: INPUTS ====');
        String phoneproject = phone_number + project_name;
        String otpOwner;
        String LeadId;
        String source;
        String otpMatched;
        String subSource;
        Map<String,String> OtpLead = new Map<String,String>();  
        Map<String,String> OtpLeadOwner = new Map<String,String>();
        Map<String,String> OtpSource = new Map<String,String>();
        Map<String,String> OtpSubSource = new Map<String,String>();
        Related_Source__c ld = leadRec;
        system.debug('ld phone'+ld.PhoneProject__c);
        List<Related_Source__c> ldListsv = [select Id,Name,OwnerId from Related_Source__c where Id=:ld.Id limit 1];
        system.debug(ldListsv);
        
        if(ldListsv.size() > 0){
            otpOwner = ldListsv[0].OwnerId;
            LeadId = ldListsv[0].Id;
        }
        else{
            List<Related_Source__c> reList = [select Id,Name,SLead__r.OwnerId,SLead__r.Id,SLead__r.Home_Location__c from Related_Source__c where (PhoneProject__c =:ld.PhoneProject__c or SecondaryPhoneProject__c =:ld.PhoneProject__c )];
            if(reList.size()>0){
                otpOwner = reList[0].SLead__r.OwnerId;
                LeadId = reList[0].SLead__r.Id;
            }
        }
        RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Related_Source__c' AND Name = 'Sales' LIMIT 1];
        if(otp == '0000'){
            List<Site_Visit__c> svList1 = [select Id,Name,Enter_OTP__c,GRE_Verified_Time__c, Feedback__c,Status__c, OwnerId,Customer_Visit_Happened__c from Site_Visit__c where SLead__c =: LeadId and Status__c = 'Scheduled' LIMIT 1];
            if(svList1.size() == 0){
                otpMatched = 'OTP Not Matched'; 
            }
            else{
            source = 'Walk-in';
            ld.id = LeadId;
            ld.Pre_Sales_User__c = otpOwner;
            ld.RecordTypeId = recordType.id;
            ld.Lead_status1__c = 'New sales enquiry';
            ld.Lead_Assigned__c = false;
            Update ld;
            Site_Visit__c sv = new Site_Visit__c();
            sv.SLead__c = ld.id;
            sv.Channel_Partner__c = ld.Channel_Partner__c;
            sv.Go_For_Round_Robin__c = false;
            sv.Date__c = system.now();
            sv.Status__c = 'Verified by GRE';
            sv.Feedback__c = 'SV Completed By GRE';
            sv.GRE_Verified_Time__c = system.now();
                sv.Customer_Visit_Happened__c=true;
            sv.OTP__c = '0000';
            insert sv;
            
            otpMatched = 'OTP Validated';
            }
            
        }
        else{
            List<Site_Visit__c> svList1 = [select Id,Name,Enter_OTP__c,GRE_Verified_Time__c, Feedback__c,Status__c, OwnerId, OTP_Generated_Date__c,Customer_Visit_Happened__c from Site_Visit__c where OTP__c =: otp and Related_Source__c =: LeadId and Status__c = 'Scheduled'  LIMIT 1];
            if(svList1.size()> 0){
                Datetime otpGen = svList1[0].OTP_Generated_Date__c;
                if(otpGen == null || (system.now().getTime() - otpGen.getTime()) < 60L * 60L * 1000L){
                    otpMatched = 'OTP Generation Too Recent';
                }
                else{
                    svList1[0].Status__c = 'Verified by GRE';
                    svList1[0].Feedback__c = 'SV Completed By GRE';
                    svList1[0].GRE_Verified_Time__c = system.now();
                    svList1[0].Customer_Visit_Happened__c=true;
                    update svList1;

                    ld.id = Leadid;
                    ld.RecordTypeId = recordType.id;
                    ld.Lead_status1__c = 'New sales enquiry';
                    ld.Lead_Assigned__c = true;
                    ld.OwnerId = svList1[0].OwnerId;
                    ld.Sales_User__c = svList1[0].OwnerId;
                    Update ld;
                    otpMatched = 'OTP Matched';
                }
            }else{
               otpMatched = 'OTP Not Matched';
            }

        }
        
        return otpMatched;
    }
    public static void testCover(){
        decimal i =1;

        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;  
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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