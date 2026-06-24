public without sharing class ErrorResponseUitilityClass {
    
    
    public static void sendErrorResponse(String message, String requestType, String requestBody) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody =
            Blob.valueOf(JSON.serialize(
                new Map<String, Object>{
                    'status' => false,
                        'message' => message
                        }
            ));
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c =requestType;
        log.Request__c =requestBody;
        log.Response__c = message;
        log.Error_Message__c = message;
        log.Status__c = 'FAIL';
        insert log;
        
    }
    
}