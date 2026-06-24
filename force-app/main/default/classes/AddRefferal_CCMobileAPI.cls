/**
 * @description REST API to add referral from Contact Center mobile app.
 * Validates customer master, creates lead, and then creates referral record.
 *
 * Request:
 * {
 *   "userId": "CPC001",
 *   "contactNumber": "8160419222",
 *   "name": "Smit Sudhir",
 *   "city": "Rajkot"
 * }
 *
 * Response:
 * {
 *   "status": true,
 *   "message": "Referral created successfully"
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-24
 */
@RestResource(urlMapping='/CCAddRefferalAPI/*')
global without sharing class AddRefferal_CCMobileAPI {

    @HttpPost
    global static void addRefferal() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody != null ? req.requestBody.toString() : '';

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'AddRefferal_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            AddRefferalRequest requestData = (AddRefferalRequest) JSON.deserialize(requestBody, AddRefferalRequest.class);

            String userId = requestData != null ? requestData.userId : null;
            String contactNumber = requestData != null ? requestData.contactNumber : null;
            String referralName = requestData != null ? requestData.name : null;
            String city = requestData != null ? requestData.city : null;

            List<String> missingParams = new List<String>();
            if (String.isBlank(userId)) missingParams.add('userId');
            if (String.isBlank(referralName)) missingParams.add('name');
            if (String.isBlank(contactNumber)) missingParams.add('contactNumber');
            if (!missingParams.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide ' + String.join(missingParams, ', '), 'AddRefferal_CCMobileAPI', requestBody);
                return;
            }

            List<Customer_Master__c> customerList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = true
                LIMIT 1
            ];

            if (customerList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'AddRefferal_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = customerList[0];

            // Check if a lead already exists for this contact number + project combination
            if (!String.isBlank(requestData.projectId)) {
                Set<String> phoneSet = new Set<String>();
                phoneSet.add(contactNumber + requestData.projectId);
                List<Lead> oldLeadList = [
                    SELECT Id
                    FROM Lead
                    WHERE (PhoneProject__c IN :phoneSet OR Secondary_Phone_Project__c IN :phoneSet)
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];
                if (!oldLeadList.isEmpty()) {
                    ErrorResponseUitilityClass.sendErrorResponse('Lead already exists for this project', 'AddRefferal_CCMobileAPI', requestBody);
                    return;
                }
            }

            Lead leadRec = new Lead();
            leadRec.LastName = referralName;
            leadRec.Customer_Master__c = customer.Id;
            leadRec.Company = 'Referral';

            Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();
            if (leadFields.containsKey('Phone')) {
                leadRec.put('Phone', contactNumber);
            }
            if (leadFields.containsKey('Phone__c')) {
                leadRec.put('Phone__c', contactNumber);
            }
            if (!String.isBlank(city) && leadFields.containsKey('City')) {
                leadRec.put('City', city);
            }
            if (!String.isBlank(city) && leadFields.containsKey('City__c')) {
                leadRec.put('City__c', city);
            }
            if (leadFields.containsKey('Lead_Source')) {
                leadRec.put('Lead_Source', 'Customer Referral');
            }
            if (leadFields.containsKey('Lead_source__c')) {
                leadRec.put('Lead_source__c', 'Customer Referral');
            }
            if (leadFields.containsKey('Source_Type__c')) {
                leadRec.put('Source_Type__c', 'Referral');
            }
            if (leadFields.containsKey('Allocated_Project__c') && !String.isBlank(requestData.projectId)) {
                leadRec.put('Allocated_Project__c', requestData.projectId);
            }

            insert leadRec;

            Schema.SObjectType referralType = Schema.getGlobalDescribe().get('Referral__c');
            if (referralType == null) {
                ErrorResponseUitilityClass.sendErrorResponse('Referral object not available', 'AddRefferal_CCMobileAPI', requestBody);
                return;
            }

            SObject referralRec = referralType.newSObject();
            Map<String, Schema.SObjectField> referralFields = referralType.getDescribe().fields.getMap();

            if (referralFields.containsKey('Customer_Master__c')) {
                referralRec.put('Customer_Master__c', customer.Id);
            }
            if (referralFields.containsKey('Lead__c')) {
                referralRec.put('Lead__c', leadRec.Id);
            }
            if (referralFields.containsKey('Referrer_Name__c')) {
                referralRec.put('Referrer_Name__c', referralName);
            }
            if (referralFields.containsKey('Contact_Number__c')) {
                referralRec.put('Contact_Number__c', contactNumber);
            }
            if (!String.isBlank(city) && referralFields.containsKey('City__c')) {
                referralRec.put('City__c', city);
            }
            if (referralFields.containsKey('Status__c')) {
                referralRec.put('Status__c', 'Submitted');
            }

            insert referralRec;

            AddRefferalResponse responseData = new AddRefferalResponse();
            responseData.status = true;
            responseData.message = 'Referral created successfully';

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));

            log.Response__c = 'Lead and referral created successfully';
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'AddRefferal_CCMobileAPI', requestBody);
        }
    }

    public class AddRefferalRequest {
        public String userId;
        public String contactNumber;
        public String name;
        public String city;
        public String projectId;
    }

    public class AddRefferalResponse {
        public Boolean status;
        public String message;
    }
}