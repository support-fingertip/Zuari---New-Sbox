public without sharing class SecurityRegisterFormController {

    @AuraEnabled
    public static String saveSecurityRegister(String formDataJson) {
        try {
            Map<String, Object> formData = (Map<String, Object>) JSON.deserializeUntyped(formDataJson);
            Security_Register__c record = new Security_Register__c();

            if (formData.containsKey('Security_Register_Name__c') && formData.get('Security_Register_Name__c') != null) {
                record.Security_Register_Name__c = String.valueOf(formData.get('Security_Register_Name__c'));
            }
            if (formData.containsKey('Phone__c') && formData.get('Phone__c') != null) {
                record.Phone__c = String.valueOf(formData.get('Phone__c'));
            }
            if (formData.containsKey('Email__c') && formData.get('Email__c') != null) {
                record.Email__c = String.valueOf(formData.get('Email__c'));
            }
            if (formData.containsKey('Secondary_Phone__c') && formData.get('Secondary_Phone__c') != null) {
                record.Secondary_Phone__c = String.valueOf(formData.get('Secondary_Phone__c'));
            }
            if (formData.containsKey('Secondary_Email__c') && formData.get('Secondary_Email__c') != null) {
                record.Secondary_Email__c = String.valueOf(formData.get('Secondary_Email__c'));
            }
            if (formData.containsKey('Country__c') && formData.get('Country__c') != null) {
                record.Country__c = String.valueOf(formData.get('Country__c'));
            }
            if (formData.containsKey('Country_Code__c') && formData.get('Country_Code__c') != null) {
                record.Country_Code__c = String.valueOf(formData.get('Country_Code__c'));
            }
            if (formData.containsKey('Project_Name__c') && formData.get('Project_Name__c') != null) {
                record.Project_Name__c = String.valueOf(formData.get('Project_Name__c'));
            }
            // Add Visitor_Type__c
            if (formData.containsKey('Visitor_Type__c') && formData.get('Visitor_Type__c') != null) {
                record.Visitor_Type__c = String.valueOf(formData.get('Visitor_Type__c'));
            }
            // Add Number_of_Visitors__c
            if (formData.containsKey('Number_of_Visitors__c') && formData.get('Number_of_Visitors__c') != null) {
                record.Number_of_Visitors__c = Integer.valueOf(formData.get('Number_of_Visitors__c'));
            }
            // Add Location__c
            if (formData.containsKey('Location__c') && formData.get('Location__c') != null) {
                record.Location__c = String.valueOf(formData.get('Location__c'));
            }
            if (formData.containsKey('Budget__c') && formData.get('Budget__c') != null) {
                record.Budget__c = String.valueOf(formData.get('Budget__c'));
            }
            if (formData.containsKey('Unit_Preference__c') && formData.get('Unit_Preference__c') != null) {
                record.Unit_Preference__c = String.valueOf(formData.get('Unit_Preference__c'));
            }
            if (formData.containsKey('Remarks__c') && formData.get('Remarks__c') != null) {
                record.Remarks__c = String.valueOf(formData.get('Remarks__c'));
            }

           //Start - Added By Siddaling On 10/06/2026
             // ✅ NEW: Build a message and trigger the notification future
            String details = buildNotificationMessage(formData);                    
            GREFormNotifier.sendNotificationsAsync(details);
            //End - Added By Siddaling On 10/06/2026

            insert record;
            return 'SUCCESS';

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

//Start - Added By Siddaling On 10/06/2026
    // ── Helper: builds a plain‑text summary of the form submission ─────────
    private static String buildNotificationMessage(Map<String, Object> formData) {
        return 'A new security register form has been submitted:\n' +
               '• Visitor Name: ' + (formData.get('Security_Register_Name__c') ?? '') + '\n' +
               '• Phone: ' + (formData.get('Phone__c') ?? '') + '\n' +
               '• Visitor Type: ' + (formData.get('Visitor_Type__c') ?? '') + '\n' +
               '• Number of Visitors: ' + (formData.get('Number_of_Visitors__c') ?? '') + '\n' +
               '• Location: ' + (formData.get('Location__c') ?? '') + '\n' +
               '• Remarks: ' + (formData.get('Remarks__c') ?? '');
    }
//End - Added By Siddaling On 10/06/2026


    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        try {
            List<String> values = new List<String>();
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
            if (sObjType == null) return values;

            Schema.DescribeSObjectResult describeResult = sObjType.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
            if (!fieldsMap.containsKey(fieldName)) return values;

            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldName).getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getValue());
                }
            }
            return values;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Fetches country options from Country_Code_Mapping__mdt Custom Metadata.
     * label = Country Name (shown in dropdown)
     * value = Country Code (e.g. +91, stored on record)
     * Mirrors the same method in ChannelPartnerLeadRegistrationController.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCountryCodeOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        // Default blank option
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
            opt.put('label', rec.MasterLabel);       // Country Name shown in UI
            opt.put('value', rec.CountryCode__c);    // Country Code saved to record
            options.add(opt);
        }
        return options;
    }
}