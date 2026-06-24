/****************************************************************
* Class Name   : MarketingCloudOTTSender
* Company      : Fingertipplus
* @description : Queueable that fetches an SFMC bearer token and
*                sends an OTT (over-the-top) welcome message per
*                Related_Source__c record passed in. Two-step:
*                  1) POST to auth endpoint for access_token + rest_instance_url
*                  2) POST to {rest_instance_url}/messaging/v1/ott/messages/
**************************************************************/
public class MarketingCloudOTTSender implements Queueable, Database.AllowsCallouts {

    private List<Related_Source__c> records;

    public MarketingCloudOTTSender(List<Related_Source__c> records) {
        this.records = records;
    }

    public void execute(QueueableContext context) {
        List<Apex_Log__c> logs = new List<Apex_Log__c>();

        TokenResult token = fetchAccessToken(logs);
        if (token == null || String.isBlank(token.accessToken) || String.isBlank(token.restInstanceUrl)) {
            if (!logs.isEmpty()) insert logs;
            return;
        }

        Map<Id, User> allocatorPhones = loadAllocatorPhones();

        for (Related_Source__c rs : records) {
            sendOneMessage(rs, token, allocatorPhones, logs);
        }

        if (!logs.isEmpty()) insert logs;
    }

    private TokenResult fetchAccessToken(List<Apex_Log__c> logs) {
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'MarketingCloudOTTSender:Token';

        try {
            Map<String, Object> body = new Map<String, Object>{
                'grant_type'    => 'client_credentials',
                'client_id'     => Label.SFMC_Client_Id,
                'client_secret' => Label.SFMC_Client_Secret,
                'account_id'    => Label.SFMC_Account_Id
            };
            String bodyJson = JSON.serialize(body);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(Label.SFMC_Auth_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(bodyJson);
            req.setTimeout(60000);

            log.Request__c = bodyJson;

            HttpResponse res = new Http().send(req);
            log.Response__c = res.getBody();

            if (res.getStatusCode() == 200) {
                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                TokenResult t = new TokenResult();
                t.accessToken    = (String) resMap.get('access_token');
                t.restInstanceUrl = (String) resMap.get('rest_instance_url');
                log.Status__c = 'SUCCESS';
                logs.add(log);
                return t;
            }

            log.Status__c = 'FAIL';
            log.Error_Message__c = 'Token call failed: ' + res.getStatusCode() + ' -> ' + res.getBody();
            logs.add(log);
        } catch (Exception ex) {
            log.Status__c = 'FAIL';
            log.Error_Message__c = ex.getMessage();
            log.Response__c = ex.getStackTraceString();
            logs.add(log);
        }
        return null;
    }

    private Map<Id, User> loadAllocatorPhones() {
        Set<Id> allocatorIds = new Set<Id>();
        for (Related_Source__c rs : records) {
            if (rs.OwnerId != null) allocatorIds.add(rs.OwnerId);
        }
        Map<Id, User> phones = new Map<Id, User>();
        if (allocatorIds.isEmpty()) return phones;
        for (User u : [SELECT Id, Name, MobilePhone FROM User WHERE Id IN :allocatorIds]) {
            phones.put(u.Id, u);
        }
        return phones;
    }

    private void sendOneMessage(Related_Source__c rs, TokenResult token, Map<Id, User> allocatorPhones, List<Apex_Log__c> logs) {
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'MarketingCloudOTTSender:Send';

        try {
            User ownerUser = allocatorPhones.get(rs.OwnerId);
            String rmName = ownerUser != null ? ownerUser.Name : '';
            String rmNumber = ownerUser != null ? ownerUser.MobilePhone : '';
            
         //   String rmNumber = rs.OwnerId != null ? allocatorPhones.get(rs.OwnerId) : null;

            Map<String, Object> attributes = new Map<String, Object>{
                'name'     => rs.Name__c,
                'rmname'   => rmName,
                'rmnumber' => rmNumber
            };
            Map<String, Object> recipient = new Map<String, Object>{
                'contactKey' => rs.SLead__c,
                'to'         => rs.Country_Code__c+rs.Phone__c,
                'attributes' => attributes
            };
            Map<String, Object> body = new Map<String, Object>{
                'definitionKey' => Label.SFMC_OTT_Definition_Key,
                'recipients'    => new List<Object>{ recipient }
            };
            String bodyJson = JSON.serialize(body);

            String endpoint = token.restInstanceUrl;
            if (!endpoint.endsWith('/')) endpoint += '/';
            endpoint += 'messaging/v1/ott/messages/';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token.accessToken);
            req.setBody(bodyJson);
            req.setTimeout(60000);

            log.Request__c = bodyJson;

            HttpResponse res = new Http().send(req);
            log.Response__c = res.getBody();

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                log.Status__c = 'SUCCESS';
            } else {
                log.Status__c = 'FAIL';
                log.Error_Message__c = 'OTT send failed: ' + res.getStatusCode();
            }
        } catch (Exception ex) {
            log.Status__c = 'FAIL';
            log.Error_Message__c = ex.getMessage();
            log.Response__c = ex.getStackTraceString();
        }
        logs.add(log);
    }

    private class TokenResult {
        String accessToken;
        String restInstanceUrl;
    }
}