/****************************************************************
* Class Name   : CreateLead_MobileAPI
* Company      : Fingertipplus
* Created Date : 16-12-2025
*
* Description  :
* --------------------------------------------------------------
* This Apex REST API creates a Lead and links it to
* a Channel Partner using userId.
*
* Input JSON:
* {
*   "userId": "CP-009",
*   "fullName": "John Kalgo",
*   "phoneNumber": "1234567891",
*   "emailAddress": "john@gmail.com",
*   "projectId": "a0PXXXXXXXXXXXX",
*   "leadSourceId": "a0LXXXXXXXXXXXX",
*   "additionalNotes": "This is additional notes"
* }
*
* Success Response:
* {
*   "status": true,
*   "message": "Lead created successfully"
* }
* Author       : Sandeep Kumar
*
* Change Log:
* ---------------------------------------------------------------------------------------
* Version | Author         | Date       | Description
* ---------------------------------------------------------------------------------------
* 1.0     | Sandeep Kumar  | 16-12-2025 | Initial version
******************************************************************************************/ 

@RestResource(urlMapping='/CreateLeadAPI/*')
global without sharing class CreateLead_MobileAPI {

    @HttpPost
    global static void createLead() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c(
            Request_Type__c = 'CreateLead_MobileAPI',
            Request__c = requestBody
        );

        Boolean logInserted = false;

        try {
            // Deserialize input
            CreateLeadWrapper input = 
                (CreateLeadWrapper) JSON.deserialize(requestBody, CreateLeadWrapper.class);
            System.debug('Input JSON: ' + JSON.serialize(input));

            // Validate mandatory fields
            if (String.isBlank(input.userId) ||
                String.isBlank(input.fullName) ||
                String.isBlank(input.emailAddress) ||
                String.isBlank(input.mobileNumber)) {

              //  sendError('Required fields are missing', log, logInserted);
                 ErrorResponseUitilityClass.sendErrorResponse('Required fields are missing','CreateLead_MobileAPI',requestBody);
              
                return;
            }

            // Fetch Channel Partner
            List<Channel_Partner__c> cpList = [
                SELECT Id, Name
                FROM Channel_Partner__c
                WHERE User_Id__c = :input.userId
                AND Active__c = TRUE
                LIMIT 1
            ];

            if (cpList.isEmpty()) {
              //  sendError('Channel Partner not found', log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Channel Partner not found','CreateLead_MobileAPI',requestBody);
              
                return;
            }

            Channel_Partner__c cp = cpList[0];
            System.debug('Channel Partner found: ' + cp);

            // Validate picklist: Allocated_Project__c
            Schema.DescribeFieldResult projectField = Lead.Allocated_Project__c.getDescribe();
            Set<String> validProjectValues = new Set<String>();
            for (Schema.PicklistEntry pe : projectField.getPicklistValues()) {
                validProjectValues.add(pe.getValue());
            }
            if (String.isNotBlank(input.projectId) && !validProjectValues.contains(input.projectId)) {
               // sendError('Invalid Project picklist value: ' + input.projectId, log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Invalid Project picklist value: ' + input.projectId,'CreateLead_MobileAPI',requestBody);
              
                return;
            }

            // Validate picklist: Lead_source__c
            Schema.DescribeFieldResult sourceField = Lead.Lead_source__c.getDescribe();
            Set<String> validSourceValues = new Set<String>();
            for (Schema.PicklistEntry pe : sourceField.getPicklistValues()) {
                validSourceValues.add(pe.getValue());
            }
            if (String.isNotBlank(input.leadSourceId) && !validSourceValues.contains(input.leadSourceId)) {
              //  sendError('Invalid Lead Source picklist value: ' + input.leadSourceId, log, logInserted);
                ErrorResponseUitilityClass.sendErrorResponse('Invalid Lead Source picklist value: ' + input.leadSourceId,'CreateLead_MobileAPI',requestBody);
              
                return;
            }
            String phoneNumber = input.mobileNumber;
            String normalizedPhone = normalizePhone(input.mobileNumber);
            System.debug('Normalized Phone: ' + normalizedPhone);
             // ==================================================
            // DUPLICATE CHECK : Phone + Allocated Project
            // ==================================================
            List<Lead> existingLeads = [
                SELECT Id, Name
                FROM Lead
                WHERE Phone__c = :normalizedPhone
                AND Allocated_Project__c = :input.projectId
                LIMIT 1
            ];

            if (!existingLeads.isEmpty()) {
                Lead existingLead = existingLeads[0];

                ErrorResponseUitilityClass.sendErrorResponse('Lead already exists with the same mobile number and project','CreateLead_MobileAPI',requestBody);
              
                return;
            }

            // Create Lead
            Lead l = new Lead();
            l.LastName = input.fullName;
            l.Phone__c = input.mobileNumber;
            l.Email = input.emailAddress;
            l.Description = input.additionalNotes;
            l.Channel_Partner__c = cp.Id;
            l.Allocated_Project__c = input.projectId;
            l.Source_Type__c='Channel partner';
            l.Lead_source__c = input.leadSourceId;
            //Added on 10-02-2026
            l.Consent_Lead__c = True;
            l.Consent_Time__c = System.now();
            l.Source_of_Consent__c='Lead from Channel Partner App';
            

            insert l;
            System.debug('Lead created: ' + l);

            // Success response
            ResponseWrapper res = new ResponseWrapper(true, 'Lead created successfully');
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

            // Log success
            log.Status__c = 'SUCCESS';
            log.Response__c = JSON.serialize(res);
            insert log;
            logInserted = true;

        } catch (Exception e) {
            System.debug('Error creating lead: ' + e);
            
           // sendError('Lead creation failed: ' + e.getMessage(), log, logInserted);
             ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(),'CreateLead_MobileAPI',requestBody);
         
        }
    }

    // ---------- Input Wrapper ----------
    public class CreateLeadWrapper {
        public String userId;
        public String fullName;
        public String mobileNumber;
        public String emailAddress;
        public String projectId;      // Picklist value
        public String leadSourceId;   // Picklist value
        public String additionalNotes;
    }

    // ---------- Response Wrapper ----------
    public class ResponseWrapper {
        public Boolean status;
        public String message;
        public ResponseWrapper(Boolean s, String m) {
            status = s;
            message = m;
        }
    }

    // ---------- Error Helper ----------
    /*
    private static void sendError(String msg, Apex_Log__c log, Boolean logInserted) {
        ResponseWrapper res = new ResponseWrapper(false, msg);
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));

        log.Status__c = 'FAIL';
        log.Error_Message__c = msg;
        log.Response__c = JSON.serialize(res);

        if (logInserted) {
            update log;
        } else {
            insert log;
        }
    }*/
    
    private static String normalizePhone(String phone) {
        if (String.isBlank(phone)) return null;
        
        // Remove spaces, +, -
        String cleaned = phone.replaceAll('[^0-9]', '');
        
        // Remove country code 91 if present
        if (cleaned.startsWith('91') && cleaned.length() == 12) {
            cleaned = cleaned.substring(2);
        }
        
        return cleaned;
    }
}