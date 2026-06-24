public without sharing class ChannelPartnerLeadRegistrationController {

    public class LeadRegistrationResponse {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String cpId;
        @AuraEnabled public String cpName;
        @AuraEnabled public String leadId;
    }

    private static final String MSG_PAN_NOT_FOUND =
        'Your PAN Number is not matching with us to register lead,Please empanel yourself and talk to our Sourcing Head - Om Prakash ( +91 9513971362)';

    private static final String MSG_LEAD_SUCCESS =
        'Your Lead is registered, Please get the customer to Site Visit to avail your credit';

    private static LeadRegistrationResponse lookupPan(String pan) {
        LeadRegistrationResponse resp = new LeadRegistrationResponse();
        String normalizedPan = pan == null ? '' : pan.trim().toUpperCase();

        List<Channel_Partner__c> cpList = [
            SELECT Id, Name
            FROM Channel_Partner__c
            WHERE Company_PAN_Card_No__c = :normalizedPan
               OR PAN_Card_No__c = :normalizedPan
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        if (cpList.isEmpty()) {
            resp.isValid = false;
            resp.message = MSG_PAN_NOT_FOUND;
        } else {
            resp.isValid = true;
            resp.cpId = cpList[0].Id;
            resp.cpName = cpList[0].Name;
            resp.message = 'PAN validated successfully.';
        }
        return resp;
    }

    @AuraEnabled(cacheable=true)
    public static LeadRegistrationResponse validatePan(String pan) {
        return lookupPan(pan);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getLeadPicklistOptions(String leadFieldApiName) {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Map<String, String> defaultOpt = new Map<String, String>();
        defaultOpt.put('label', '-- Select --');
        defaultOpt.put('value', '');
        options.add(defaultOpt);

        Schema.SObjectType leadType = Lead.SObjectType;
        Map<String, Schema.SObjectField> fieldMap = leadType.getDescribe().fields.getMap();

        if (!fieldMap.containsKey(leadFieldApiName)) {
            return options;
        }

        Schema.DescribeFieldResult fieldResult = fieldMap.get(leadFieldApiName).getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                Map<String, String> opt = new Map<String, String>();
                opt.put('label', entry.getLabel());
                opt.put('value', entry.getValue());
                options.add(opt);
            }
        }
        return options;
    }

    // NEW: Fetches country options from Custom Metadata
    // label = Country Name (shown to user), value = Country Code (stored on Lead)
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCountryCodeOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Map<String, String> defaultOpt = new Map<String, String>();
        defaultOpt.put('label', '-- Select Country --');
        defaultOpt.put('value', '');
        options.add(defaultOpt);

        for (Country_Code_Mapping__mdt rec : [
            SELECT MasterLabel, CountryCode__c
            FROM Country_Code_Mapping__mdt
            ORDER BY MasterLabel ASC
        ]) {
            Map<String, String> opt = new Map<String, String>();
            opt.put('label', rec.MasterLabel);      // Country Name displayed in dropdown
            opt.put('value', rec.CountryCode__c);   // Country Code saved to Lead field
            options.add(opt);
        }
        return options;
    }

    @AuraEnabled
    public static LeadRegistrationResponse insertLead(String pan, Map<String, Object> leadFields) {
        LeadRegistrationResponse validationResult = lookupPan(pan);

        if (!validationResult.isValid) {
            LeadRegistrationResponse resp = new LeadRegistrationResponse();
            resp.success = false;
            resp.message = validationResult.message;
            return resp;
        }

        try {
            Lead newLead = new Lead();

            if (leadFields.containsKey('Name')) {
                newLead.LastName = (String) leadFields.get('Name');
            }
            if (leadFields.containsKey('Company')) {
                newLead.Company = (String) leadFields.get('Company');
            } else {
                newLead.Company = 'N/A';
            }
            if (leadFields.containsKey('Allocated_Project__c')) {
                newLead.Allocated_Project__c = (String) leadFields.get('Allocated_Project__c');
            }
            if (leadFields.containsKey('Email')) {
                newLead.Email = (String) leadFields.get('Email');
            }
            if (leadFields.containsKey('Country_Code__c')) {
                newLead.Country_Code__c = (String) leadFields.get('Country_Code__c');
            }
            if (leadFields.containsKey('Phone__c')) {
                newLead.Phone__c = (String) leadFields.get('Phone__c');
            }
            if (leadFields.containsKey('Secondary_Phone__c')) {
                newLead.Secondary_Phone__c = (String) leadFields.get('Secondary_Phone__c');
            }
            if (leadFields.containsKey('Secondary_Email__c')) {
                newLead.Secondary_Email__c = (String) leadFields.get('Secondary_Email__c');
            }
            if (leadFields.containsKey('Unit_Preference__c')) {
                newLead.Unit_Preference__c = (String) leadFields.get('Unit_Preference__c');
            }
            if (leadFields.containsKey('Budget__c')) {
                newLead.Budget__c = (String) leadFields.get('Budget__c');
            }

            newLead.Channel_Partner__c = validationResult.cpId;
            newLead.Source_Type__c = 'Channel Partner';
            newLead.Lead_source__c = 'Channel Partner';
            newLead.Tertiary_Source__c = validationResult.cpName;

            insert newLead;

            LeadRegistrationResponse resp = new LeadRegistrationResponse();
            resp.success = true;
            resp.leadId = newLead.Id;
            resp.message = MSG_LEAD_SUCCESS;
            return resp;

        } catch (Exception e) {
            throw new AuraHandledException('Error inserting lead: ' + e.getMessage());
        }
    }
}