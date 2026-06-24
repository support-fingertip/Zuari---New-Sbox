public class SendSMSQueueable implements Queueable, Database.AllowsCallouts {

    String phone;
    String name;
    String otp;

    public SendSMSQueueable(String phone, String name, String otp) {
        this.phone = phone;
        this.name = name;
        this.otp = otp;
    }

    public void execute(QueueableContext context) {
          Apex_Log__c log = new Apex_Log__c();
      
        try {
            // Fetch values from Custom Labels
            String apiKey = Label.SMS_API_KEY;
            String senderName = Label.SMS_SENDER_NAME;
            String entityId = Label.SMS_ENTITY_ID;
            String templateId = Label.SMS_TEMPLATE_ID;
            String apiUrl = Label.SMS_API_URL;
 String body = 'Dear ' + name + ', Kindly share the OTP: ' + otp + ' to our sales executive at project site once you arrive for a seamless visit. Zuari Infraworld';

            // Prepare request payload
            Map<String, Object> payload = new Map<String, Object>{
            'key' => Label.SMS_API_Key,
            'from' => 'ZUARIN',
            'to' => new List<String>{phone},
            'body' => body,
            'templateid' => Label.SMS_Template_Id,
            'entityid' => Label.SMS_Entity_Id,
            'custref1' => name,
            'custref2' => otp
        };
            // Convert to JSON
            String requestBody = JSON.serialize(payload);
 log.Request__c=requestBody;
                log.Request_Type__c ='SendSMSQueueable';
               
            // Send HTTP POST
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('SMS Response Status: ' + res.getStatus());
            System.debug('SMS Response Body: ' + res.getBody());
              log.response__c =  res.getStatus()+' ' +res.getBody();
                    log.Status__c ='SUCCESS';
            Insert log;
                  
        } catch (Exception e) {
             log.response__c =  e.getMessage();
                    log.Status__c ='FAILED';
            Insert log;
             
            System.debug('SMS Send Failed: ' + e.getMessage());
        }
    }
}