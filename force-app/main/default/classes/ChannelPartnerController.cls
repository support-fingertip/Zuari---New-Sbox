public without sharing class ChannelPartnerController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRegionPicklistValues() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Map<String, String> defaultOpt = new Map<String, String>();
        defaultOpt.put('label', '-- Select Region --');
        defaultOpt.put('value', '');
        options.add(defaultOpt);

        Schema.DescribeFieldResult fieldResult = Channel_Partner__c.Select_Region__c.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                Map<String, String> opt = new Map<String, String>();
                opt.put('label', entry.getLabel());
                opt.put('value', entry.getValue());
                options.add(opt);
            }
        }

        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSourcingRMOptions(String region) {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Map<String, String> defaultOpt = new Map<String, String>();
        defaultOpt.put('label', '-- Select Sourcing RM --');
        defaultOpt.put('value', '');
        options.add(defaultOpt);

        // No region selected -> only the default placeholder option
        if (String.isBlank(region)) {
            return options;
        }

        List<User> users = [SELECT Id, Name FROM User
                            WHERE Show_In_CP_Form__c = true
                            AND IsActive = true
                            AND CP_Region__c INCLUDES (:region)
                            WITH SYSTEM_MODE
                            ORDER BY Name];

        for (User u : users) {
            Map<String, String> opt = new Map<String, String>();
            opt.put('label', u.Name);
            opt.put('value', u.Id);
            options.add(opt);
        }

        Map<String, String> otherOpt = new Map<String, String>();
        otherOpt.put('label', 'Other');
        otherOpt.put('value', 'OTHER');
        options.add(otherOpt);

        return options;
    }

    @AuraEnabled
    public static String createChannelPartner(Map<String, Object> fieldValues) {
        try {
            Channel_Partner__c cp = new Channel_Partner__c();
            populateChannelPartnerFields(cp, fieldValues);
            applyConsentDefaults(cp);
            insert cp;

            return cp.Id;

        } catch (Exception e) {
            throw new AuraHandledException('Error creating record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveFileToRecord(String recordId, String fileName, String base64Data, String contentType) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required');
            }
            if (String.isBlank(fileName)) {
                throw new AuraHandledException('File name is required');
            }
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('File data is required');
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            insert cv;

            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            List<ContentDocumentLink> existingLinks = [SELECT Id FROM ContentDocumentLink
                WHERE ContentDocumentId = :cv.ContentDocumentId AND LinkedEntityId = :recordId LIMIT 1];

            if (existingLinks.isEmpty()) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.LinkedEntityId = recordId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
            }

            return cv.Id;

        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
        }
    }

    /**
     * Inserts a ContentVersion that is NOT yet linked to any record.
     * Used by the LWC to upload each PDF before the Channel_Partner__c is committed.
     * Caller MUST follow up with commitChannelPartnerWithFiles (success path) or
     * cleanupOrphanFiles (abort path) to avoid leaking orphan files.
     */
    @AuraEnabled
    public static String uploadOrphanFile(String fileName, String base64Data, String contentType) {
        try {
            if (String.isBlank(fileName)) {
                throw new AuraHandledException('File name is required');
            }
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('File data is required');
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            // Inserted as a minor version so subsequent chunks can update VersionData
            // (Salesforce blocks VersionData updates once IsMajorVersion = true).
            // commitChannelPartnerWithFiles promotes it to major after all chunks land.
            cv.IsMajorVersion = false;
            insert cv;

            return cv.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }

    /**
     * Appends a base64 chunk to a previously-created orphan ContentVersion.
     * Used by the LWC to upload files larger than the single-request Aura limit
     * (the failure surfaces as aura:systemError around ~2MB payloads).
     * Each chunk's base64 length must be a multiple of 4 except for the final chunk.
     */
    @AuraEnabled
    public static void appendToOrphanFile(String contentVersionId, String base64Chunk) {
        try {
            if (String.isBlank(contentVersionId)) {
                throw new AuraHandledException('ContentVersion Id is required');
            }
            if (String.isBlank(base64Chunk)) {
                throw new AuraHandledException('File data is required');
            }
            ContentVersion cv = [SELECT Id, VersionData FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            String existingB64 = EncodingUtil.base64Encode(cv.VersionData);
            cv.VersionData = EncodingUtil.base64Decode(existingB64 + base64Chunk);
            update cv;
        } catch (Exception e) {
            throw new AuraHandledException('Error appending file: ' + e.getMessage());
        }
    }

    /**
     * Atomic commit: inserts the Channel_Partner__c record, links the previously-uploaded
     * orphan ContentVersions, and submits for approval — all inside a single Savepoint.
     * If anything fails, the record is rolled back AND the orphan ContentVersions passed
     * in `fileLinks` are deleted so nothing is left behind.
     *
     * fileLinks elements: { "contentVersionId": "068...", "docType": "GST Certificate" }
     */
    @AuraEnabled
    public static String commitChannelPartnerWithFiles(Map<String, Object> fieldValues, List<Map<String, Object>> fileLinks) {
        List<Id> orphanCvIds = new List<Id>();
        if (fileLinks != null) {
            for (Map<String, Object> link : fileLinks) {
                Object cvId = link.get('contentVersionId');
                if (cvId != null) {
                    orphanCvIds.add((Id) cvId);
                }
            }
            // Fail loudly if the client sent file entries but none carried a
            // contentVersionId — otherwise the record would commit with no
            // ContentDocumentLinks and Files would silently be empty.
            if (!fileLinks.isEmpty() && orphanCvIds.size() != fileLinks.size()) {
                throw new AuraHandledException(
                    'fileLinks payload missing contentVersionId values. Got '
                    + orphanCvIds.size() + ' of ' + fileLinks.size() + ' entries.'
                );
            }
        }

        Savepoint sp = Database.setSavepoint();
        try {
            Channel_Partner__c cp = new Channel_Partner__c();
            populateChannelPartnerFields(cp, fieldValues);
            applyConsentDefaults(cp);
            insert cp;

            if (!orphanCvIds.isEmpty()) {
                Map<Id, Id> cvToContentDoc = new Map<Id, Id>();
                for (ContentVersion cv : [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id IN :orphanCvIds]) {
                    cvToContentDoc.put(cv.Id, cv.ContentDocumentId);
                }

                Map<String, String> docTypeToCheckbox = getDocTypeToCheckboxMap();
                Set<String> uploadedDocTypes = new Set<String>();

                List<ContentVersion> cvUpdates = new List<ContentVersion>();
                List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
                for (Map<String, Object> link : fileLinks) {
                    Id cvId = (Id) link.get('contentVersionId');
                    Id docId = cvToContentDoc.get(cvId);
                    if (docId == null) {
                        throw new AuraHandledException('Uploaded file no longer available: ' + cvId);
                    }
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = docId;
                    cdl.LinkedEntityId = cp.Id;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    newLinks.add(cdl);

                    // Promote to major version now that all chunks have landed
                    // and apply the "<Document Name> - <Channel Partner Name>" title.
                    ContentVersion update_cv = new ContentVersion(
                        Id = cvId,
                        IsMajorVersion = true
                    );
                    Object docType = link.get('docType');
                    if (docType != null && String.isNotBlank(cp.Name)) {
                        String newTitle = ((String) docType) + ' - ' + cp.Name;
                        update_cv.Title = newTitle;
                       // update_cv.PathOnClient = newTitle + '.pdf';
                        uploadedDocTypes.add((String) docType);
                    }
                    cvUpdates.add(update_cv);
                }
                if (!newLinks.isEmpty()) {
                    insert newLinks;
                }
                if (!cvUpdates.isEmpty()) {
                    update cvUpdates;
                }

                // Flip the Uploaded__c checkbox for every doc type that was committed
                // in this submit, in a single update on the parent record.
                Channel_Partner__c flags = new Channel_Partner__c(Id = cp.Id);
                Boolean hasFlagToSet = false;
                for (String docType : uploadedDocTypes) {
                    String fieldApi = docTypeToCheckbox.get(docType);
                    if (fieldApi != null) {
                        flags.put(fieldApi, true);
                        hasFlagToSet = true;
                    }
                }
                if (hasFlagToSet) {
                    update flags;
                }
            }

            return cp.Id;

        } catch (Exception e) {
            Database.rollback(sp);
            // We do NOT delete the orphan ContentVersions here: throwing an
            // AuraHandledException rolls the entire transaction back, which would
            // undo the delete too. The client compensates by calling
            // cleanupOrphanFiles() in its catch block when this method fails.
            throw new AuraHandledException('Error saving Channel Partner: ' + e.getMessage());
        }
    }

    /**
     * Deletes orphan ContentVersions (and their parent ContentDocuments) when the
     * client-side flow aborts before commit — e.g. one of several parallel orphan
     * uploads failed and the Channel Partner record was never created.
     */
    @AuraEnabled
    public static void cleanupOrphanFiles(List<Id> contentVersionIds) {
        if (contentVersionIds == null || contentVersionIds.isEmpty()) {
            return;
        }
        try {
            deleteContentVersionsAndDocs(contentVersionIds);
        } catch (Exception e) {
            throw new AuraHandledException('Error cleaning up files: ' + e.getMessage());
        }
    }

    private static void deleteContentVersionsAndDocs(List<Id> contentVersionIds) {
        Set<Id> docIds = new Set<Id>();
        for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds]) {
            if (cv.ContentDocumentId != null) {
                docIds.add(cv.ContentDocumentId);
            }
        }
        if (!docIds.isEmpty()) {
            // Deleting ContentDocument cascades to its ContentVersions and ContentDocumentLinks.
            delete [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
        }
    }

    private static Map<String, String> getDocTypeToCheckboxMap() {
        return new Map<String, String>{
            'GST Certificate'      => 'GST_Document_Uploaded__c',
            'PAN Card'             => 'PAN_Document_Uploaded__c',
            'RERA Certificate'     => 'RERA_Document_Uploaded__c',
            'Aadhaar Card'          => 'Aadhar_Document_Uploaded__c',
            'Address Proof'        => 'Address_Proof_Document_Uploaded__c',
            'Cancel Cheque'        => 'Cancel_Cheque_Document_Uploaded__c',
            'Company Registration' => 'Company_Registration_Document_Uploaded__c',
            'Authorization Letter' => 'Authorization_Letter_Document_Uploaded__c',
            'Board Resolution'     => 'Board_Resolution_Document_Uploaded__c'
        };
    }

    private static void applyConsentDefaults(Channel_Partner__c cp) {
        cp.Consent_Date_Time__c = System.now();
        cp.Consent_Given__c = true;
        cp.Consent_Source__c = 'CP Registration Form';
    }

    private static void populateChannelPartnerFields(Channel_Partner__c cp, Map<String, Object> fieldValues) {
        if (fieldValues.containsKey('Entity_Type__c')) {
            cp.Entity_Type__c = (String) fieldValues.get('Entity_Type__c');
            if ((String) fieldValues.get('Entity_Type__c') == 'Company') {
                if (fieldValues.containsKey('Company_Name__c')) {
                    cp.Name = (String) fieldValues.get('Name');
                    cp.Company_Name__c = (String) fieldValues.get('Company_Name__c');
                }
            }
            if ((String) fieldValues.get('Entity_Type__c') == 'Individual') {
                if (fieldValues.containsKey('Name')) {
                    cp.Name = (String) fieldValues.get('Name');
                }
            }
        }

        if (fieldValues.containsKey('Company_Declaration__c')) {
            cp.Company_Declaration__c = (Boolean) fieldValues.get('Company_Declaration__c');
        }
        if (fieldValues.containsKey('Indivisual_Declaration__c')) {
            cp.Indivisual_Declaration__c = (Boolean) fieldValues.get('Indivisual_Declaration__c');
        }
        if (fieldValues.containsKey('Are_you_GST_Registered__c')) {
            cp.Are_you_GST_Registered__c = (Boolean) fieldValues.get('Are_you_GST_Registered__c');
        }
        if (fieldValues.containsKey('GST__c')) {
            cp.GST__c = (String) fieldValues.get('GST__c');
        } else {
            cp.GST__c = 'NA';
        }
        if (fieldValues.containsKey('Company_Head_Name__c')) {
            cp.Company_Head_Name__c = (String) fieldValues.get('Company_Head_Name__c');
        }
        if (fieldValues.containsKey('RERA__c')) {
            cp.RERA__c = (String) fieldValues.get('RERA__c');
        }
        if (fieldValues.containsKey('Company_Owner_Name__c')) {
            cp.Company_Owner_Name__c = (String) fieldValues.get('Company_Owner_Name__c');
        }
        if (fieldValues.containsKey('Team_Strength__c')) {
            cp.Team_Strength__c = (String) fieldValues.get('Team_Strength__c');
        }
        if (fieldValues.containsKey('Company_Website__c')) {
            cp.Company_Website__c = (String) fieldValues.get('Company_Website__c');
        }
        if (fieldValues.containsKey('Email__c')) {
            cp.Email__c = (String) fieldValues.get('Email__c');
        }
        if (fieldValues.containsKey('Email_ID__c')) {
            cp.Email_ID__c = (String) fieldValues.get('Email_ID__c');
        }
        if (fieldValues.containsKey('Alternate_number__c')) {
            cp.Alternate_number__c = (String) fieldValues.get('Alternate_number__c');
        }
        if (fieldValues.containsKey('Company_Head_Email_ID__c')) {
            cp.Company_Head_Email_ID__c = (String) fieldValues.get('Company_Head_Email_ID__c');
        }
        if (fieldValues.containsKey('Company_Owner_Email_ID__c')) {
            cp.Company_Owner_Email_ID__c = (String) fieldValues.get('Company_Owner_Email_ID__c');
        }
        if (fieldValues.containsKey('Company_Head_Contact_No__c')) {
            cp.Company_Head_Contact_No__c = (String) fieldValues.get('Company_Head_Contact_No__c');
        }
        if (fieldValues.containsKey('Company_Owner_Contact_No__c')) {
            cp.Company_Owner_Contact_No__c = (String) fieldValues.get('Company_Owner_Contact_No__c');
        }
        if (fieldValues.containsKey('Company_Address__c')) {
            cp.Company_Address__c = (String) fieldValues.get('Company_Address__c');
        }
        if (fieldValues.containsKey('State__c')) {
            cp.State__c = (String) fieldValues.get('State__c');
        }
        if (fieldValues.containsKey('Communication_Address__c')) {
            cp.Communication_Address__c = (String) fieldValues.get('Communication_Address__c');
        }
        if (fieldValues.containsKey('City_of_Primary_Work__c')) {
            cp.City_of_Primary_Work__c = (String) fieldValues.get('City_of_Primary_Work__c');
        }
        if (fieldValues.containsKey('City__c')) {
            cp.City__c = (String) fieldValues.get('City__c');
        }
        if (fieldValues.containsKey('City_you_reside_in__c')) {
            cp.City_you_reside_in__c = (String) fieldValues.get('City_you_reside_in__c');
        }
        if (fieldValues.containsKey('Select_Region__c')) {
            cp.Select_Region__c = (String) fieldValues.get('Select_Region__c');
        }
        if (fieldValues.containsKey('Sourcing_RM__c')) {
            String rm = (String) fieldValues.get('Sourcing_RM__c');
            cp.Sourcing_RM__c = (String.isBlank(rm) || rm == 'OTHER') ? null : rm;
        }
        if (fieldValues.containsKey('Company_GST_No__c')) {
            cp.Company_GST_No__c = (String) fieldValues.get('Company_GST_No__c');
        }
        if (fieldValues.containsKey('Company_PAN_Card_No__c')) {
            cp.Company_PAN_Card_No__c = (String) fieldValues.get('Company_PAN_Card_No__c');
        }
        if (fieldValues.containsKey('PAN_Card_No__c')) {
            cp.PAN_Card_No__c = (String) fieldValues.get('PAN_Card_No__c');
        }
        if (fieldValues.containsKey('Company_RERA_No__c')) {
            cp.Company_RERA_No__c = (String) fieldValues.get('Company_RERA_No__c');
        }
        if (fieldValues.containsKey('Active_Medium__c')) {
            cp.Active_Medium__c = (String) fieldValues.get('Active_Medium__c');
        }
        if (fieldValues.containsKey('Mobile_Number__c')) {
            cp.Mobile_Number__c = (String) fieldValues.get('Mobile_Number__c');
        }
        if (fieldValues.containsKey('RERA_Validity__c')) {
            Object dateValue = fieldValues.get('RERA_Validity__c');
            if (dateValue instanceof String) {
                cp.RERA_Validity__c = Date.valueOf((String) dateValue);
            } else if (dateValue instanceof Date) {
                cp.RERA_Validity__c = (Date) dateValue;
            }
        }
    }
}