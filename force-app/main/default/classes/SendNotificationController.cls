public class SendNotificationController {
    @AuraEnabled
    public static void sendNotification(String recordId) {
        if(recordId!=null){
            
            List<Notification__c> nclist = [SELECT Id,Name,Notification_Content__c,Notification_Date__c,Notification_Time__c,IsNotificationSent__c,IsActive__c,Channel_Partner__c,Notification_Category__c,
                                  Related_Source__c,Follow_up__c,Site_Visit__c,Payment__c,
                                  (SELECT Id,Name,Channel_Partner__c,Notification__c FROM Notification_Subscribers__r)
                                  FROM Notification__c WHERE Id=:recordId limit 1];
            if(nclist.isEmpty()){
                
                System.debug('Notification not fount'+ recordId);
                return;
            }
            Notification__c nc = nclist[0];
            
            set<Id> customerIds = new set<Id>();
            for(Notification_Subscriber__c nrc : nc.Notification_Subscribers__r){
                customerIds.add(nc.Channel_Partner__c);
            }
            List<Channel_Partner__c> cmList = new List<Channel_Partner__c>();
            
            if(nc.Notification_Category__c=='User Specific' && nc.Channel_Partner__c!=null){
                cmList = [ SELECT Id, Email__c, Password__c,Name  FROM Channel_Partner__c  where Active__c = TRUE AND Id=:nc.Channel_Partner__c];
            }
            if(nc.Notification_Category__c=='User Specific' && !customerIds.contains(nc.Channel_Partner__c)){
                cmList = [ SELECT Id, Email__c, Password__c,Name  FROM Channel_Partner__c  where Active__c = TRUE AND Id=:nc.Channel_Partner__c];
            }else{
                System.debug('hll');
                cmList = [ SELECT Id, Email__c, Password__c,Name  FROM Channel_Partner__c  where Active__c = TRUE /*AND Id NOT IN : customerIds*/];
            }
            System.debug(cmList.Size());
            List<Notification_Subscriber__c> lstntrc = new List<Notification_Subscriber__c>();
            set<Id> customerId = new  set<Id>();
            For(Channel_Partner__c cr : cmList){
                customerId.add(cr.id);
                Notification_Subscriber__c ntrc = new Notification_Subscriber__c();
                ntrc.Channel_Partner__c = cr.id;
                ntrc.Notification__c =nc.id;
                ntrc.isRead__c = false;
                lstntrc.add(ntrc);
            }
            set<string> deviceId = new set<string>();
            if(customerId.size()>0){
                List<Logged_in_Device__c> deviceList = new List<Logged_in_Device__c>();
                deviceList = [SELECT Id,Device_Id__c FROM Logged_in_Device__c WHERE Channel_Partner__c IN :customerId AND Status__c='Active' AND Device_Id__c!=null];
                for(Logged_in_Device__c div : deviceList){
                    deviceId.add(div.Device_Id__c);
                    // deviceId.add('d950514c-c587-42f2-a357-d85fa6a7760d');
                }
                
            }
            try{
                if(!lstntrc.isEmpty()){
                    insert lstntrc;
                    pushOneSignalNotification(recordId,deviceId);
                    
                    
                } 
            }catch (Exception e){
                
                system.debug('Exception' + e.getMessage());
                
            }
            
            
        }
    }
    
    @future (callout=true)
    public static void pushOneSignalNotification(String recordId, set<string> playerIds){
        System.debug(playerIds);
        Notification__c noti = [SELECT Id,Name,Updated_Status__c,Notification_Redirect_Id__c,Notification_Content__c,Notification_Date__c,Notification_Category__c,Notification_Time__c,IsNotificationSent__c,IsActive__c,Channel_Partner__c,One_signal_Notifcation_Id__c,Notification_Heading__c,Notification_Type__c FROM Notification__c WHERE Id=:recordId];
        string appId = System.Label.app_id;
        string oneSignalAccessToken = System.Label.oneSignalAccessToken;
        // List<string> playerIDs = new List<string>();
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'Mobile App - push OneSignal Notification';
        
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setHeader('Content-Type', 'application/json');
            
            request.setHeader('Authorization', 'Bearer '+oneSignalAccessToken );
            request.setEndpoint('https://onesignal.com/api/v1/notifications');
            //String payload = '{"app_id": "a82ed698-77db-43f2-b4e1-cb12aba8e75d", "contents": {"en": "' + message + '"}, "include_player_ids": ["' + playerIDs + '"]}';
            
            //String payload = '{"app_id": "'+appId+'", "contents": {"en": "' + noti.Notification_Description__c + '"}, "include_player_ids": ' + playerIDs + ',"ios_sound": "your_custom_ios_sound.wav","android_sound": "your_custom_android_sound.mp3"   }  ';
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('app_id', appId);
            payload.put('include_player_ids', playerIds);
            /*
if(noti.Notification_Category__c !='User Specific'){
payload.put('included_segments', new List<String>{'All'});
}else{
payload.put('include_player_ids', playerIds);
}
*/
            payload.put('headings', new Map<String, String>{'en' => noti.Notification_Heading__c});
            payload.put('contents', new Map<String, String>{'en' => noti.Notification_Content__c});
            Map<String, Object> dataPayload = new Map<String, Object>();
            dataPayload.put('statusCode', noti.Updated_Status__c);        // or Integer 3
            dataPayload.put('leadId', noti.Notification_Redirect_Id__c);       // dynamic lead id
            dataPayload.put('screen', noti.Notification_Type__c); // navigation key
            
            payload.put('data', dataPayload);
            
            //payload.put('large_icon', 'https://cdn-icons-png.flaticon.com/512/733/733585.png');
            //payload.put('big_picture', noti.ImageUrl__c);
            String body = JSON.serialize(payload);
            
            
            request.setBody(body);   
            log.Request__c = body;
            request.setMethod('POST');
            if(!test.isRunningTest()){
                HttpResponse response = http.send(request);
                System.debug('response==>'+response.getBody());
                String var= response.getBody() ;
                log.response__c = var.length()<100000?var:'Long Response';
                
                OneSignalWrapper osWrap = (OneSignalWrapper)JSON.deserialize(var, OneSignalWrapper.class);
                
                
                System.debug('==>'+osWrap);
                System.debug(response.getStatusCode());
                if(response.getStatusCode()==200){
                    log.Status__c = 'Success';
                    System.debug(osWrap.id);
                    if(osWrap.id!=null)
                        noti.One_signal_Notifcation_Id__c = osWrap.id;
                    noti.IsNotificationSent__c = true;
                    noti.Notification_Time__c = system.now();
                    
                }else{//Handler the Error
                    log.Status__c = 'One Signal : Error';
                    System.debug('can\'t establish the connection with the API'+osWrap);
                }
            }
        }   catch(Exception e){
            log.Status__c = 'SF : Error';
            log.Error_Message__c =  e.getMessage();
            System.debug('Something went wrong'+e.getMessage());
        } 
        update noti;
        insert log;
    }
    public class OneSignalWrapper {
        public String id;
        public String external_id;
        public Errors errors;
    }
    
    public class Errors {
        public List<String> invalid_player_ids;
    }
}