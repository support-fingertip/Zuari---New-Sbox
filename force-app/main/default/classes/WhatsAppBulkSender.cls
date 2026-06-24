/****************************************************************
* Class Name   : WhatsAppBulkSender
* Company      : Fingertipplus
* Created Date : 01-08-2025
* @description : This Queueable class is used for Call Mcube API For sending the Whatsapp message and updating the whatsapp status
* @author      : Praveen Kumar

* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author 			| 	  Date 		| Description
* -----------------------------------------------------------------------------
* 1.0 | Praveen Kumar 	| 01-08-2025 	| Initial version
* -----------------------------------------------------------------------------
**************************************************************/
public class WhatsAppBulkSender implements Queueable, Database.AllowsCallouts {
    
    private List<Lead> leads;
    
    public WhatsAppBulkSender(List<Lead> leads) {
        this.leads = leads;
    }
    
    public void execute(QueueableContext context) {
        Apex_Log__c log = new Apex_Log__c();
        
        for (Lead l : leads) {
            try {
                // Call API for each lead
                HttpRequest req = new HttpRequest();
               // req.setEndpoint('https://rengage.mcube.com/api/wpbox/sendtemplatemessage');
               req.setEndpoint(Label.WhatsApp_Endpoint_URL);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
               // req.setHeader('Authorization', 'Bearer DGw6K3278c1e4y9aF0veYYt5uC90tk7wEVHDJk4G9270b2c2');
                req.setHeader('Authorization', Label.WhatsApp_Auth_Token);
                String LeadName= l.FirstName+' '+ l.LastName;
                Map<String, Object> requestBody = new Map<String, Object>{
                    'phone' => l.Phone__c,
                        'template_name' => 'intenal_language',
                        'template_language' => 'en_US',
                        'components' => new List<Object>{
                            new Map<String, Object>{
                                'type' => 'body',
                                    'parameters' => new List<Object>{
                                        new Map<String, Object>{
                                            'type' => 'text',
                                                'text' => LeadName
                                                }
                                    }
                            }
                        }
                };
                    
                    req.setBody(JSON.serialize(requestBody));
                log.Request__c=JSON.serialize(requestBody);
                log.Request_Type__c ='WhatsAppBulkSender';
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    Map<String, Object> messageIdMap = (Map<String, Object>) resMap.get('message_id');
                    List<Object> messages = (List<Object>) messageIdMap.get('messages');
                    log.response__c = resMap.ToString();
                    log.Status__c ='SUCCESS';
                    
                    if (!messages.isEmpty()) {
                        Map<String, Object> msgDetails = (Map<String, Object>) messages[0];
                        String messageId = (String) msgDetails.get('id');
                        String messageStatus = (String) msgDetails.get('message_status');
                        
                        // Update lead with message data
                        Lead updatedLead = new Lead(
                            Id = l.Id,
                            WhatsApp_Message_Id__c = messageId,
                            WhatsApp_Message_Status__c = messageStatus
                        );
                        update updatedLead;
                    }
                } else {
                    log.response__c = 'API failed: ' + res.getStatusCode() + ' -> ' + res.getBody();
                    log.Status__c ='FAIL';
                    log.Error_Message__c = 'API failed: ' + res.getStatusCode() + ' -> ' + res.getBody();
                    
                    System.debug('API failed: ' + res.getStatusCode() + ' -> ' + res.getBody());
                }
                
            } catch (Exception ex) {
                log.response__c = ex.getStackTraceString();
                log.Status__c ='FAIL';
                log.Error_Message__c = ex.getMessage();
                
                System.debug('Error sending WhatsApp: ' + ex.getMessage());
            }
        }
        
        insert log;
    }
}