public without sharing class MakeCallController {

    @auraEnabled
    public static List<string> readContacts( String recordId){ 
        
        Id recId;
        Id sObjId = recordId;
        String objectName = sObjId.getSObjectType().getDescribe().getName();
        List<string>  phones = new  List<string>();
        if(objectName == 'Related_Source__c'){
            Related_Source__c rs = [Select Id,Slead__c from Related_Source__c where Id =:sObjId ];
            recId = rs.Slead__c;
        }
        else if(objectName == 'Lead'){
            recId = sObjId;
        }
         
            
            for(Related_Source__c rs: [select id,name,Phone__c,Secondary_Phone__c,Country_Code__c,Secondary_Contry_Code__c  from Related_Source__c where Id=:recordId]){
                
                if(!phones.contains('+'+rs.Country_Code__c+' '+rs.Phone__c) && rs.Phone__c!=null){
                    phones.add('+'+rs.Country_Code__c+' '+rs.Phone__c);
                }
                if(!phones.contains('+'+rs.Secondary_Contry_Code__c+' '+rs.Secondary_Phone__c) && rs.Secondary_Phone__c!=null){
                    phones.add('+'+rs.Secondary_Contry_Code__c+' '+rs.Secondary_Phone__c);
                }
            }

        return phones;
     } 
    
     @AuraEnabled
    public static boolean callCustomer(String recordId, string phone) {
        
        User user = [ SELECT Phone FROM User WHERE Id = : UserInfo.getUserId() LIMIT 1 ];
        Id myId = Id.valueOf(recordId);
         String sObjName = myId.getSObjectType().getDescribe().getName();
        Id recId;
        String projectName;
        if(sObjName == 'Related_Source__c'){
            Related_Source__c rs = [Select Id,Slead__c,Allocated_Project__c from Related_Source__c where Id =:myId ];
            recId = rs.Slead__c;
            projectName = rs.Allocated_Project__c;
        }
        else if(sObjName == 'Lead'){
            recId = myId;
        }
       
         String phonenum = '';
         String countrycode = '';
        if(user != null){
           
            system.debug('Mcube_Phone__c: ' + user.Phone);
            if(user.Phone != null){
                phonenum = user.Phone;
            }
            else{
                phonenum = user.Phone;
            }
            system.debug('phonenum:' + phonenum );
         /*   user.mobilePhone = user.mobilePhone.replace('+91','')  ; 
        user.mobilePhone = user.mobilePhone.replace('+','')  ;  
        user.mobilePhone=  user.mobilePhone.replaceAll('\\(', '');
        user.mobilePhone=  user.mobilePhone.replaceAll('\\)', '');
        user.mobilePhone=  user.mobilePhone.replaceAll(' ', '');
            user.mobilePhone=  user.mobilePhone.replaceAll('-', '');*/
        }
        
        if(phone != null && phone.contains('+91')){
                phone= phone.replace('+91','')  ; 
                phone=  phone.replaceAll('\\(', '');
                phone=  phone.replaceAll('\\)', ''); 
                phone=  phone.replaceAll(' ', ''); 
             phone=  phone.replaceAll('', ''); 
            countrycode='+91';
        }else if(phone != null && phone.contains('+')){
            list<string> phones=phone.split(' ');
            if(phones.size()>0){
              countrycode=phones[0];
                phone=phones[1];
            }
          phone=  phone.replaceAll('\\(', '');
                phone=  phone.replaceAll('\\)', ''); 
                phone=  phone.replaceAll(' ', ''); 
             phone=  phone.replaceAll('', '');   
        }
        if(sObjName=='Lead' || sObjName=='Related_Source__c'){  
            //string qr = 'select id, name,OwnerId from '+sObjName+' where id='+'\'' + recId + '\'';
            //List<lead> oppr = Database.query(qr);  
            Id profileId= userinfo.getProfileId();
            String profileName=[Select Id,Name from Profile where Id=:profileId].Name;  
           system.debug(countrycode+','+phonenum+','+phone+','+recId);
                //return CallHandlerService.makeCall(user.CTI_Mobile_Number__c,phone,recordId);
               return mCubeController.clickToCall(recId,myId,projectName);  
            // return mCubeController.clickToCalllatest(recordId,phone,countrycode);   
            
            
         }
        return null;
    } 
   
    @AuraEnabled
    public static void updateLastNote(String leadId, String newNote, Boolean isPrimary, Boolean isSecondary, datetime followUpDate, String followUpSubject, datetime siteVisitScheduledDate) {
        Related_Source__c leadRecord = [SELECT Id,Last_Note__c,Allocated_Project__c FROM Related_Source__c WHERE Id = :leadId LIMIT 1];
        system.debug('newNote'+newNote);
        system.debug('isPrimary' + isPrimary);
        User us = [select id,name,Profile.Name from User where id =: userInfo.getUserId()];
        // ================================
        // Current datetime in IST
        // ================================
        Datetime dt = Datetime.now();
        String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a', 'Asia/Kolkata');
        
        System.debug(' Current Datetime (System): ' + dt);
        System.debug(' Formatted IST Datetime: ' + strTimeInAMorPM);
        
        // ================================
        // Handle numbering
        // ================================
        Integer noteCount = 1;
        System.debug(' Initial noteCount: ' + noteCount);
        System.debug(' Existing Last_Note__c BEFORE update: ' + leadRecord.Last_Note__c);
        
        if (leadRecord.Last_Note__c == null) {
            System.debug(' Last_Note__c is NULL, initializing to empty string');
            leadRecord.Last_Note__c = '';
        } 
        else if (!leadRecord.Last_Note__c.trim().equals('')) {
            List<String> notes = leadRecord.Last_Note__c.split('\n');
            noteCount = notes.size() + 1;
            
            System.debug(' Existing notes count: ' + notes.size());
            System.debug(' Updated noteCount: ' + noteCount);
        } 
        else {
            System.debug(' Last_Note__c exists but is EMPTY after trim');
        }
        
        // ================================
        // Update fields
        // ================================
        //leadRecord.Execuive_Count__c = noteCount;
        System.debug(' Execuive_Count__c set to: ' + noteCount);
        
        String noteToAppend =
            '\nCall Summary ' + noteCount + ': ' +
            us.Name + ' [' + strTimeInAMorPM + ']: ' +
            newNote;
        
        System.debug(' Note being appended: ' + noteToAppend);
        
        leadRecord.Last_Note__c += noteToAppend;
        
        System.debug(' Last_Note__c AFTER update: ' + leadRecord.Last_Note__c);
        // Create Call_Comments__c record
        Call_Comments__c comment = new Call_Comments__c();
        comment.Comments__c = newNote;
        comment.User_Profile__c = us.Profile.Name;
        comment.Related_Source__c = leadRecord.Id;
        comment.Created_User__c = us.Id;
        comment.Created_Date__c = System.now();
        insert comment;
          //}
       /* if(isSecondary == true){
            Integer noteCount = 1;
            if (leadRecord.CommentsSecondary__c == null) {
                leadRecord.CommentsSecondary__c = '';
            } else if (!leadRecord.CommentsSecondary__c.trim().equals('')) {
                List<String> notes = leadRecord.CommentsSecondary__c.split('\n');
                noteCount = notes.size() + 1;
            }
            
            leadRecord.CommentsSecondary__c += '\nNote ' + noteCount + ': ('+us.Name+')' + ' - (' + strTimeInAMorPM + ') :      ' + newNote;
        }*/
        system.debug('is follou Up created');
        if(followUpDate != null){
            system.debug('is follou Up created');
            Follow_up__c fp = new Follow_up__c();
            if(followUpSubject == '' || followUpSubject == null){
                fp.Subject__c = 'call';
            }
            else{
                fp.Subject__c = followUpSubject;
            }
            fp.Scheduled_Date__c = followUpDate.addMinutes(1);
            
            fp.Related_Source__c = leadId;
            insert fp;
        }
            update leadRecord;
        
         if(siteVisitScheduledDate != null){
             system.debug('is follou Up created');
             Site_Visit__c fp = new Site_Visit__c();
             fp.Project__c = leadRecord.Allocated_Project__c;
             fp.Date__c = siteVisitScheduledDate.addMinutes(1);
             fp.Related_Source__c = leadId;
             insert fp;
        }
    }
    
    
       @auraEnabled
    public static boolean readstatus( String  recordId){  
        //user u = [select LastRecordCalled__c  from user where id =: userinfo.getUserId()];   
        //if(u.LastRecordCalled__c == recordId ){ 
            return true;
        //}else{
           // return false;
        //}
    }
    /*
     @auraEnabled
    public static string saveCallSummary( String  taskId, string summary ){  
        Task t =  new task();
        t.id = taskId;
        t.Description   = summary;
        update t;
        return 'success'; 
    }   
    */
    @AuraEnabled
    public static Map<String, Object> getInitialValues(Id recordId) {
        Map<String, Object> result = new Map<String, Object>();
        
        Related_Source__c rs = [
            SELECT Id,
            Lead_status1__c, Lead_quality__c
            FROM Related_Source__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        result.put('showLeadQuality', rs.Lead_quality__c != null);
        
        return result;
    }

}