@RestResource(urlMapping='/portalLead/*')
global without sharing class PortalLeadInsertAPIController {
    
    @HttpPost
    global static void createTaskForLead() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString(); // Get the JSON body
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c ='PortalLeadInsertAPIController '+' portalLead';
        
        try {
            // Deserialize the JSON body into the callWrapper class
            leadWrapper ldData = (leadWrapper) JSON.deserialize(requestBody, leadWrapper.class);
            log.Request__c=requestBody;
            // Create a new Lead using the deserialized data
            Lead nld = new Lead();
            nld.LastName = ldData.lastName;
            nld.Sub_Source__c = ldData.subSource;
            nld.Phone = ldData.mobile;
            nld.Phone__c = ldData.mobile;
            nld.Email = ldData.email;
            nld.Allocated_project__c = ldData.project;
            nld.Campaign__c = ldData.campaign;
            
            if(ldData.source =='MagicBricks'|| ldData.source =='99 Acres' || ldData.source =='Housing.com'){
                nld.Source_Type__c ='Digital Marketing';
                nld.Lead_source__c ='Real Estate Portals';
                nld.Tertiary_Source__c =ldData.source;
                
            }
            nld.Description = ldData.description;
            // nld.Source_Type__c='Digital';
            nld.UTM_Source__c = ldData.utmSource;
            nld.UTM_Medium__c = ldData.utmMedium;
            nld.UTM_Campaign__c = ldData.utmCampaign;
            nld.UTM_Adgroup__c = ldData.utmAdgroup;
            nld.UTM_Term__c = ldData.utmTerm;
            nld.UTM_Placement__c = ldData.utmPlacment;
            nld.UTM_Device__c = ldData.utmDevice;
            nld.Chat_Conversation__c = ldData.chatConversation;
            nld.Portal_Lead__c=true;
            nld.Company = 'Zuari';
            // Added on 02-02-2026 by Praveen as per requested by Website Team
            nld.Source_of_Consent__c =  ldData.sourceOfConsent;
            nld.Consent_Lead__c = ldData.consetStatus != null ? ldData.consetStatus : false;
            insert nld;
            // Return success response
            log.response__c = string.valueof(nld);
            log.Status__c ='SUCCESS';
            insert log;
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => true,
                    'Salesforce LeadId' => nld.Id
                    }));
        } catch (Exception e) {
            log.response__c = e.getStackTraceString();
            log.Status__c ='FAIL';
            log.Error_Message__c = e.getMessage();
            insert log;
            
            System.debug('Error creating task: ' + e.getMessage());
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
    
    // Wrapper class for deserialization
    public class leadWrapper {
        public String lastName;
        public String source;
        public String subSource;
        public String mobile;
        public String email;
        public String project;
        public String unitPreference;
        public String campaign;
        public String description;
        public String residencelocation;
        public String worklocation;
        public String hearaboutus;
        public String utmSource;
        public String utmMedium;
        public String utmCampaign;
        public String utmAdgroup;
        public String utmTerm;
        public String utmPlacment;
        public String utmDevice;
        public String chatConversation;
        public String tertiarySource;
        public String sourceOfConsent;// Added on 02-02-2026 by Praveen as per requested by Website Team
        Public Boolean consetStatus;// Added on 02-02-2026 by Praveen as per requested by Website Team
    }
    
    
}