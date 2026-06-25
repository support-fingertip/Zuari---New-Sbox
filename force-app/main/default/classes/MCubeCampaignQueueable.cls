/****************************************************************
 * Class Name   : MCubeCampaignQueueable
 * Company      : Fingertipplus
 * @description : Queueable that posts newly created Related_Source__c
 *                records into the MCube outbound-calling campaign API
 *                (POST https://config.mcube.com/Restmcube-api/campaign).
 *                Endpoint, bearer token and campaign defaults are read
 *                from Mcube__mdt so they can rotate without code.
 *                One Apex_Log__c row is written per record. Failures
 *                are logged and swallowed - never rolled back.
 **************************************************************/
public with sharing class MCubeCampaignQueueable implements Queueable, Database.AllowsCallouts {

    @TestVisible private List<Related_Source__c> records;

    public MCubeCampaignQueueable(List<Related_Source__c> records) {
        this.records = records;
    }

    public void execute(QueueableContext ctx) {

        Map<String, String> cfg = loadConfig();
        String endpoint        = cfg.get('CampaignEndpoint');
        String token           = cfg.get('CampaignToken');
        String campaignIdStr   = cfg.get('CampaignId');
        String retryTime       = cfg.get('CampaignRetryTime');
        String retryAttempt    = cfg.get('CampaignRetryAttempt');

        List<Apex_Log__c> logs = new List<Apex_Log__c>();

        if (String.isBlank(endpoint) || String.isBlank(token) || String.isBlank(campaignIdStr)) {
            logs.add(buildLog(null, 'FAIL',
                'Missing Mcube__mdt config (CampaignEndpoint / CampaignToken / CampaignId)',
                null, null));
            insert logs;
            return;
        }

        Integer campaignId = Integer.valueOf(campaignIdStr);

        for (Related_Source__c rs : records) {
            if (String.isBlank(rs.Phone__c)) {
                logs.add(buildLog(rs, 'SKIP', 'Phone__c is blank', null, null));
                continue;
            }
            sendOne(rs, endpoint, token, campaignId, retryTime, retryAttempt, logs);
        }

        if (!logs.isEmpty()) insert logs;
    }

    private void sendOne(Related_Source__c rs, String endpoint, String token,
                         Integer campaignId, String retryTime, String retryAttempt,
                         List<Apex_Log__c> logs) {

        Map<String, Object> entry = new Map<String, Object>{
            'number'        => sanitizePhone(rs.Phone__c),
            'name'          => rs.Name__c,
            'source'        => rs.Source_Type__c,
            'retry_time'    => retryTime,
            'retry_attempt' => retryAttempt
        };
        Map<String, Object> body = new Map<String, Object>{
            'campaign_id' => campaignId,
            'listData'    => new List<Object>{ entry }
        };
        String bodyJson = JSON.serialize(body);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(bodyJson);
        req.setTimeout(60000);

        try {
            HttpResponse res = new Http().send(req);
            Boolean ok = res.getStatusCode() >= 200 && res.getStatusCode() < 300;
            logs.add(buildLog(rs,
                ok ? 'SUCCESS' : 'FAIL',
                ok ? null : 'HTTP ' + res.getStatusCode(),
                bodyJson,
                res.getBody()));
        } catch (Exception ex) {
            logs.add(buildLog(rs, 'FAIL', ex.getMessage(), bodyJson, ex.getStackTraceString()));
        }
    }

    private Apex_Log__c buildLog(Related_Source__c rs, String status,
                                 String err, String requestBody, String responseBody) {
        return new Apex_Log__c(
            Request_Type__c     = 'MCubeCampaign:' + (rs != null ? String.valueOf(rs.Id) : 'Config'),
            Status__c           = status,
            Error_Message__c    = err,
            Request__c          = requestBody,
            Response__c         = responseBody,
            Input_parameters__c = (rs != null ? String.valueOf(rs.Id) : null)
        );
    }

    private Map<String, String> loadConfig() {
        Map<String, String> m = new Map<String, String>();
        for (Mcube__mdt c : [
            SELECT DeveloperName, Value__c
            FROM Mcube__mdt
            WHERE DeveloperName IN (
                'CampaignEndpoint','CampaignToken','CampaignId',
                'CampaignRetryTime','CampaignRetryAttempt'
            )
        ]) {
            m.put(c.DeveloperName, c.Value__c);
        }
        return m;
    }

    private String sanitizePhone(String p) {
        if (p == null) return null;
        return p.replace('+91','').replaceAll('[\\s()\\-]', '');
    }
}
