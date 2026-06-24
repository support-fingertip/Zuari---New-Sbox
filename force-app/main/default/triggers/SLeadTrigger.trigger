trigger SLeadTrigger on Lead (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    if(label.Enable_Trigger=='TRUE'){
        system.debug(utility.runLeadTrigger);
        if(Utility.runLeadTrigger  != false){
            
            if (Trigger.isBefore) {
                if (Trigger.isInsert) {  
                    Id adminUserId;
                    
                    List<User> adminUsers = [
                        SELECT Id 
                        FROM User 
                        WHERE Profile.Name = 'System Administrator'
                        AND IsActive = true
                        ORDER BY CreatedDate ASC
                        LIMIT 1
                    ];
                    
                    if (!adminUsers.isEmpty()) {
                        adminUserId = adminUsers[0].Id;
                    }
                    
                    list<Lead> ldlist = new list<Lead>();
                    for (Lead led : Trigger.new) {
                        // FORCE ADMIN OWNER IF LEAD IS ALREADY ASSIGNED
                        if (led.Lead_Assigned__c == true && adminUserId != null) {
                             led.backup_user_Field__c = led.OwnerId;
                             System.debug('Owner passed from data upload Lead: ' + led.backup_user_Field__c);
                            led.OwnerId = adminUserId;
                            System.debug('Owner forced to Admin for Lead: ' + led.Id +'user' + adminUserId);
                            continue; // skip other owner logic if needed
                        }
                        if (led.Channel_Partner__c != null) {
                            ldlist.add(led);
                        }
                        led.Company = 'Zuari';
                        led.Consent_Lead__c=true;
                        if(led.Allocated_Project__c == 'Zuari Garden City - Plots'){
                            led.Allocated_Project__c = 'Zuari Garden City';
                        }
                    }
                    
                    // Ensure ldlist is not empty before calling cpmethod
                    if (ldlist != null && ldlist.size() > 0) {
                        system.debug('Callcpmethod');
                        RelatedSourceHandler.cpmethod(ldlist); 
                    }
                    
                    
                    
                    user u = [SELECT Id,Name,Profile.Name FROM user WHERE Id=:userinfo.getUserId()];
                    Map<String,Id> cpMap = new  Map<String,Id>();
                    Map<String,Id> cpMap2 = new  Map<String,Id>();
                    //  RelatedSourceHandler.checkMobileNumber(trigger.new
                    RelatedSourceHandler.campaignMethod(trigger.new);
                    RelatedSourceHandler.checkMobileNumber2(trigger.new);
                    // RelatedSourceHandler.addCountryCode(trigger.new);
                    RelatedSourceHandler.duplicateCheck2(trigger.new);
                    // RelatedSourceHandler.cpmethod(trigger.new);
                    list<Lead> PreSalesLeads = new list<Lead>();
                    list<Lead> WalkinLeads = new list<Lead>();
                    
                    // if leads are creating by admin then it will go to roundrobin, if lead is creating by other user it will assign same user.
                    if(u.Profile.Name =='System Administrator' || u.Profile.Name == 'WebsiteLead Profile' || u.Profile.Name == 'API MCube Profile' ||
                      u.Profile.Name =='GRE')
                    {
                        for(Lead ld : trigger.new){
                            
                            if(ld.Walking_Lead_Form__c){
                                system.debug('Inside the Walking- In Leads');
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                                ld.Lead_Status__c='Sv Completed';
                                if(ld.Round_Robin_Off__c){
                                    
                                }
                                else{
                                    
                                    WalkinLeads.add(ld); 
                                }
                            }
                            else{
                                PreSalesLeads.add(ld);
                            }
                        }
                        
                        if(PreSalesLeads.size()>0){
                            //RoundRobinHandler.assignLead(PreSalesLeads,false,'Pre Sales'); 
                        }
                        if(WalkinLeads.size()>0){
                            //RoundRobinHandler.assignLead(WalkinLeads,false,'Sales'); 
                        }
                        
                    }
                    else{
                        for(Lead ld : trigger.new){
                            ld.Lead_Assigned__c = true;
                            ld.Reassigned_By__c = UserInfo.getUserId();
                            ld.Re_assigned_date__c = system.now();
                            if(u.Profile.Name == 'Sales'){
                                ld.Sales_User__c =UserInfo.getUserId();
                                ld.Lead_Assigned__c = true;
                                ld.Lead_Transfered__c = true;
                                ld.SV_User__c=UserInfo.getUserId();
                                
                                ld.Pre_sales_user__c =UserInfo.getUserId();// added due to Sales is working as pre Sales user
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                                //  ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                            }else if(u.Profile.Name == 'Pre sales'){
                                ld.Pre_sales_user__c =UserInfo.getUserId();
                                ld.Lead_Assigned__c = true;
                                ld.Lead_Transfered__c = true;
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                            }
                            if(ld.Lead_source__c =='Walk-In'){
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                                ld.Lead_Status__c='New sales enquiry';
                                
                            }
                        }
                        
                        
                    }
                    
                    
                    
                } 
                
                if (Trigger.isUpdate) {
                    system.debug('on update');
                    //User u = [SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name = 'System Administrator' and IsActive=true LIMIT 1];
                    /*  RelatedSourceHandler.duplicateCheckOnUpdate(trigger.new);*/
                    List<Lead> preSalesLdList = new List<Lead>();
                    List<Lead> salesLdList = new List<Lead>();
                    
                    //------------------------------------------------------------------------------------
                    Set<String> phonePrjSet = new Set<String>();
                    
                    //-----------For Checking Duplicate while edit the Primary Phone or Secondary Phone
                    For(Lead ld : Trigger.New){
                        if ((ld.Phone__c!= Trigger.oldmap.get(ld.Id).Phone__c && ld.Phone__c != null) || (ld.Allocated_Project__c!= Trigger.oldmap.get(ld.Id).Allocated_Project__c && ld.Allocated_Project__c != null)) {
                            phonePrjSet.add(ld.Phone__c+ld.Allocated_Project__c);
                        }
                        else if ((ld.Secondary_Phone__c!= Trigger.oldmap.get(ld.Id).Secondary_Phone__c && ld.Secondary_Phone__c != null) || (ld.Allocated_Project__c!= Trigger.oldmap.get(ld.Id).Allocated_Project__c && ld.Allocated_Project__c != null)) {
                            phonePrjSet.add(ld.Secondary_Phone__c+ld.Allocated_Project__c);
                        }
                        
                        
                    }
                    List<Lead> unqalifiedlead = new List<Lead>();
                    
                    for(Lead ld : Trigger.new){
                        if (ld.Lead_status__c != Trigger.oldmap.get(ld.Id).Lead_status__c && ld.Lead_status__c=='New' && !ld.Lead_Assigned__c && !ld.Lead_Transfered__c){
                            preSalesLdList.add(ld);
                        }else if(ld.Lead_status__c=='New sales enquiry'&& !ld.Lead_Assigned__c){
                            salesLdList.add(ld);
                        }else if(ld.Mark_Unqualified__c && LeadStatusController.markleadUnqualified && !ld.Lead_Assigned__c && ld.Lead_status__c=='New'&& ld.No_Of_Times_Unqualified__c <= 2){
                            // system.debug(ld.Mark_Unqualified__c+'=='+ LeadStatusController.markleadUnqualified +'=='+ ld.Lead_Assigned__c +'==='+ ld.Lead_status__c+'===='+ ld.No_Of_Times_Unqualified__c );
                            unqalifiedlead.add(ld);
                        }
                        
                        //  else if(ld.Lead_status__c=='Not Interested'&& ld.RecordTypeId=='012C1000000mLjhIAE' && ld.Unqualified_Reason__c==null) {
                        
                        // ld.addError('Please fill the Not Interested Reason');
                        // }
                        // else if(ld.Lead_status__c=='Closed Lost'&& ld.RecordTypeId=='012C1000000mLjiIAE' && ld.Closed_Lost_Reason__c==null) {
                        
                        // ld.addError('Please fill the Closed Lost Reason');
                        // }
                    }
                    
                    if(preSalesLdList.size()>0){
                        //RoundRobinHandler.assignLead(preSalesLdList,false,'Pre Sales');
                        
                    }
                    if(salesLdList.size()>0){
                        //RoundRobinHandler.assignLead(salesLdList,false,'Sales');
                    }
                    /*if(unqalifiedlead.Size()>0){
                        // system.debug('Called for unqalification lead');
                        RelatedSourceHandler.reassignUnqualifiedLead(unqalifiedlead);
                    }*/
                    
                    if(phonePrjSet.size()>0 ){
                        
                        List<Lead> oldLeadList = [SELECT Id,Lead_ID__c, Phone__c, Secondary_Phone__c, Email, Secondary_Email__c,Allocated_Project__c,PhoneProject__c,Secondary_Phone_Project__c  FROM Lead 
                                                  WHERE ( PhoneProject__c IN :phonePrjSet OR Secondary_Phone_Project__c IN :phonePrjSet) 
                                                  ORDER BY CreatedDate ASC];
                        // Map to store old leads based on phone and email
                        Map<String, Lead> phonePrjMap = new Map<String, Lead>();
                        for (Lead old : oldLeadList) {
                            
                            if (old.Phone__c != null) {
                                phonePrjMap.put(old.PhoneProject__c, old);
                            }
                            if (old.Secondary_Phone__c != null) {
                                phonePrjMap.put(old.Secondary_Phone_Project__c, old);
                            }
                            
                        }
                        for (Lead nld : trigger.new) { 
                            string phone = nld.Phone__c+nld.Allocated_Project__c;
                            string secPhone = nld.Secondary_Phone__c+nld.Allocated_Project__c;
                            
                            if (phonePrjMap.containsKey(phone) && phonePrjMap.get(phone).Id != nld.Id) {
                                nld.addError('Lead with the same phone number and project already exists: ' + phonePrjMap.get(phone).Lead_ID__c);
                            }else if (phonePrjMap.containsKey(secPhone) && phonePrjMap.get(secPhone).Id != nld.Id) {
                                nld.addError('Lead with the same phone number and project already exists: ' + phonePrjMap.get(secPhone).Lead_ID__c);
                            } 
                        }
                        
                    }
                    //--------------Validation for Checking site visit before updating the lead status to site Visit Schedule---------------
                    List<Lead> leadListforSiteVisit = new List<Lead>();
                    
                    For(Lead ld : Trigger.new){
                        /* String oldStatus = Trigger.oldMap.get(ld.Id).Lead_Status__c;

if (ld.Lead_Status__c != oldStatus && ld.Lead_Status__c == 'Site Visit Schedule' && oldStatus != 'Closed Lost') {
// leadListforSiteVisit.add(ld);
}
*/
                        if(ld.Lead_Status__c!=Trigger.oldmap.get(ld.Id).Lead_Status__c && ld.Lead_Status__c == 'Site Visit Schedule'){
                            leadListforSiteVisit.add(ld);
                        }
                    }
                    /*  Map<Id, site_visit__c> siteVisitMap = new Map<Id, site_visit__c>();

if (!ldId.isEmpty()) {
for (site_visit__c sv : [  SELECT Id, SLead__c    FROM site_visit__c  WHERE SLead__c IN :ldId AND status__c = 'Scheduled' ]) {
siteVisitMap.put(sv.SLead__c, sv);
}
}*/
                    
                    if(!leadListforSiteVisit.isEmpty()){
                        String returnMessage = ValidationHandler.CheckScheduleSiteVist(leadListforSiteVisit);  
                        system.debug('returnMessage'+returnMessage); 
                        if(returnMessage!=null){
                            leadListforSiteVisit[0].addError(returnMessage);
                        }
                        
                    }
                    //-----------------------------------------------------------------------------------
                    
                    
                    
                    //for Unqualified Lead- If any lead is unqualified in the 3rd round it should be assigned to Pre sales Head/ Manager.
                    
                    for (Lead ld : Trigger.new) {
                        Lead oldLd = Trigger.oldMap.get(ld.Id);
                        
                        if (ld.Last_Unqualified_by__c != oldLd.Last_Unqualified_by__c && ld.No_Of_Times_Unqualified__c >2) {
                            Id userId = oldLd.Last_Unqualified_by__c;
                            User u = [select id ,ManagerId from User where Id =:userId];
                            if (u.ManagerId != null) {
                                ld.OwnerId = u.ManagerId;
                                ld.Lead_Status__c = 'New';
                                ld.Lead_Assigned__c = true;
                                
                            }
                        }
                    }
                    
                    
                    
                }
                if (Trigger.isDelete) {
                    Set<Id> leadIds = new Set<Id>();
                    for (Lead l : Trigger.old) {
                        leadIds.add(l.Id);
                    }
                    
                    Map<Id, Boolean> leadWithChildMap = new Map<Id, Boolean>();
                    for (Related_Source__c rs : [SELECT Id, SLead__c FROM Related_Source__c WHERE SLead__c IN :leadIds ]) {
                        leadWithChildMap.put(rs.SLead__c, true);
                    }
                    for (Site_Visit__c sv : [ SELECT Id, SLead__c FROM Site_Visit__c WHERE SLead__c IN :leadIds]) {
                        leadWithChildMap.put(sv.SLead__c, true);
                    }
                    for (Call_Detail__c cd : [ SELECT Id, Lead__c FROM Call_Detail__c WHERE Lead__c IN :leadIds]) {
                        leadWithChildMap.put(cd.Lead__c, true);
                    }
                    for (Quote__c qt : [SELECT Id, SLead__c FROM Quote__c WHERE SLead__c IN :leadIds]) {
                        leadWithChildMap.put(qt.SLead__c, true);
                    }
                    for (Follow_Up__c fu : [SELECT Id, SLead__c FROM Follow_Up__c WHERE SLead__c IN :leadIds ]) {
                        leadWithChildMap.put(fu.SLead__c, true);
                    }
                    for (Booking__c bk : [ SELECT Id, SLead__c FROM Booking__c WHERE SLead__c IN :leadIds ]) {
                        leadWithChildMap.put(bk.SLead__c, true);
                    }
                    for (Lead l : Trigger.old) {
                        if (leadWithChildMap.containsKey(l.Id)) {
                            l.addError('You cannot delete this Lead because child records exist.');
                        }
                    }
                }
            }
            
            if (Trigger.isAfter) {
                if (Trigger.isInsert) {
                    //  WhatsAppTriggerHandler.processNewLeads(Trigger.new);//Call the WhatsAppTriggerHandler
                    List<account> accList = new List<account>();
                    RelatedSourceHandler.afterinsertLogic2(trigger.new);
                    
                } 
                if (Trigger.isUpdate) {
                    
                    Set<Id> lostWinLeads = new Set<Id>();
                    Set<Id> ownerChange = new Set<Id>();
                    List<Lead> ldList = new List<Lead>();
                    List<Lead> toshare = new List<Lead>();
                    for(Lead con : Trigger.new){
                        system.debug(Trigger.oldmap.get(con.Id).lead_status__c );
                        system.debug(con.Lead_status__c );
                        if(con.Lead_status__c!=Trigger.oldmap.get(con.Id).lead_status__c && (con.Lead_status__c=='Unqualified' || con.Lead_status__c=='Closed Lost')){
                            lostWinLeads.add(con.Id);
                        }
                        if(con.OwnerId!=Trigger.oldmap.get(con.Id).OwnerId && con.Lead_status__c!='Unqualified' && con.Lead_status__c!='Closed Lost'){
                            ownerChange.add(con.Id);
                        }
                        // adding to List to update account owner
                        if(con.OwnerId!=Trigger.oldmap.get(con.Id).OwnerId && con.Lead_Status__c=='New sales enquiry'){
                            ldList.add(con);
                        }
                    }
                    /* Map<Id,Id> svsharelist = New Map<Id,Id>();
if(ldList.size()>0){
List<site_visit__c> sivList = new List<site_visit__c>();
sivList = [SELECT Id, Name, status__c, SLead__r.OwnerId FROM site_visit__c WHERE SLead__c IN : ldList];
if(sivList.size()>0){
for(site_visit__c siv : sivList){
svsharelist.put(siv.Id,siv.SLead__r.OwnerId);
}
}
}*/
                    if(lostWinLeads.size()>0){
                        List<site_visit__c> svList = new List<site_visit__c>();
                        svList = [SELECT Id,Name,status__c,Canceled_Reason__c FROM site_visit__c WHERE SLead__c IN : lostWinLeads and status__c='Scheduled'];
                        if(svList.size()>0){
                            for(site_visit__c sv : svList){
                                sv.status__c='Cancelled';
                                sv.Canceled_Reason__c = 'System Cancelled';
                            }
                            Update svList;
                        }
                        List<Follow_up__c> svList1 = new List<Follow_up__c>();
                        svList1 = [SELECT Id,Name,status__c FROM Follow_up__c WHERE SLead__c IN : lostWinLeads and status__c='Scheduled'];
                        if(svList1.size()>0){
                            for(Follow_up__c sv1 : svList1){
                                sv1.status__c='Missed';
                            }
                            Update svList1;
                        }
                    }
                    if(ownerChange.size()>0){
                        List<Follow_up__c> fwList = new List<Follow_Up__c>();
                        fwList = [SELECT Id,Name,OwnerId,SLead__r.ownerId FROM Follow_Up__c WHERE SLead__c IN: ownerChange and status__c='Scheduled'];
                        if(fwList.size()>0){
                            for(Follow_Up__c fw : fwList){
                                fw.ownerId = fw.SLead__r.OwnerId;
                            }
                            Update fwList;
                        }
                        List<site_visit__c> fwList1 = new List<site_visit__c>();
                        Map<Id,Id> ldMap = new Map<Id,Id>();
                        Map<Id,Id> SvMap = new Map<Id,Id>();
                        fwList1 = [SELECT Id,Name,OwnerId,SLead__r.ownerId,SLead__c,SLead__r.Id,SLead__r.Pre_sales_user__c FROM site_visit__c WHERE SLead__c IN: ownerChange];
                        if(fwList1.size()>0){
                            for(site_visit__c fw1 : fwList1){
                                ldMap.put(fw1.SLead__r.Id,fw1.SLead__r.Pre_sales_user__c);
                                SvMap.put(fw1.Id,fw1.SLead__r.Pre_sales_user__c);
                                fw1.ownerId = fw1.SLead__r.OwnerId;
                            }
                            Update fwList1;
                        }
                        if (!ldMap.isEmpty()) {
                            Boolean res = manulaSharingClass.manualShareLeadVisit(ldMap);
                            system.debug('=='+res);
                            if(res == true){
                                manulaSharingClass.manualShareSiteVisit(SvMap);
                            }
                        }
                    }
                    
                    if(ldList.size()>0){
                        manulaSharingClass.shareAnyRecordPreSales(ldList, 'Read');
                    }
                    
                }
                // delete account
                if (Trigger.isDelete) {
                    //accountController.upsertAccount(trigger.old, 'delete');
                }
                // create account
                if (Trigger.isUndelete) {
                    //accountController.upsertAccount(trigger.new, 'undelete');
                }
            } 
            
        }
        
    }
    
    
}