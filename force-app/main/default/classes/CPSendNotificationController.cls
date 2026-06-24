public without sharing class CPSendNotificationController {

    @AuraEnabled
    public static void sendNotification(String recordId) {
        if(recordId!=null){

            Customer_Portal_Notification__c nc = [SELECT Id,Name,Notification_Content__c,Notification_Time__c,IsNotificationSent__c,IsActive__c,Customer_Master__c,
                                                                    (SELECT Id,Name,Customer_Master__c,Customer_Portal_Notification__c FROM Customer_Portal_Notification_Subscribers__r)
                                  FROM Customer_Portal_Notification__c WHERE Id=:recordId];

            set<Id> customerIds = new set<Id>();
            for(Customer_Portal_Notification_Subscriber__c nrc : nc.Customer_Portal_Notification_Subscribers__r){
                if (nrc.Customer_Master__c != null) {
                    customerIds.add(nrc.Customer_Master__c);
                }
            }
            List<Customer_Master__c> cmList = new List<Customer_Master__c>();
                System.debug('hll');
                cmList = [ SELECT Id, Email__c, Password__c,Name  FROM Customer_Master__c  where Active__c = TRUE];

            System.debug(cmList.Size());
            List<Customer_Portal_Notification_Subscriber__c> lstntrc = new List<Customer_Portal_Notification_Subscriber__c>();
            set<Id> customerId = new  set<Id>();
            For(Customer_Master__c cr : cmList){
                customerId.add(cr.id);
                Customer_Portal_Notification_Subscriber__c ntrc = new Customer_Portal_Notification_Subscriber__c();
                ntrc.Customer_Master__c = cr.id;
                ntrc.Customer_Portal_Notification__c =nc.id;
                ntrc.isRead__c = false;
                lstntrc.add(ntrc);
            }
            set<string> deviceId = new set<string>();
            if(customerId.size()>0){
                List<Logged_in_Device__c> deviceList = new List<Logged_in_Device__c>();
                deviceList = [SELECT Id,Device_Id__c FROM Logged_in_Device__c WHERE Customer_Master__c IN :customerId AND Status__c='Active' AND Device_Id__c!=null];
                for(Logged_in_Device__c div : deviceList){
                    deviceId.add(div.Device_Id__c);
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
        Customer_Portal_Notification__c noti = [SELECT Id,Name,Updated_Status__c,Notification_Redirect_Id__c,Notification_Content__c,Notification_Time__c,IsNotificationSent__c,IsActive__c,Customer_Master__c,One_signal_Notifcation_Id__c,Notification_Heading__c,Notification_Type__c FROM Customer_Portal_Notification__c WHERE Id=:recordId];
        string appId = System.Label.ccAppId;
        string oneSignalAccessToken = System.Label.CConeSignalAccessToken;
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'Mobile App - push OneSignal CP Notification';

        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setHeader('Content-Type', 'application/json');

            request.setHeader('Authorization', 'Bearer '+oneSignalAccessToken );
            request.setEndpoint('https://onesignal.com/api/v1/notifications');

            Map<String, Object> payload = new Map<String, Object>();
            payload.put('app_id', appId);
            payload.put('include_player_ids', playerIds);
            payload.put('headings', new Map<String, String>{'en' => noti.Notification_Heading__c});
            payload.put('contents', new Map<String, String>{'en' => noti.Notification_Content__c});
            Map<String, Object> dataPayload = new Map<String, Object>();
            dataPayload.put('statusCode', noti.Updated_Status__c);
            dataPayload.put('leadId', noti.Notification_Redirect_Id__c);
            dataPayload.put('screen', noti.Notification_Type__c);

            payload.put('data', dataPayload);

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

                }else{
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