/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : EOIFormController
* Author          : Siddaling
* Created Date    : Jun 20, 2026
* Last Modified By: Siddaling
* Last Modified On: Jun 23, 2026
* Description     : Backend for the public EOI form rendered via
*                   Visualforce -> Lightning Out (ltng:outApp) -> Aura wrapper -> LWC (c:eoiForm).
*
* Runs "without sharing" so the Site Guest user can insert EOI__c + ContentVersion.
* Guest profile needs: Apex Class access to EOIFormController, Create on EOI__c / Lead /
* ContentVersion (+ Update on Lead), FLS on the fields, and a Guest sharing rule that
* grants the Guest access to the EOI__c record so the same-transaction file attach works.
*
* Change History  :
*  Date          │   Author     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  Jun 20, 2026  │ Siddaling  │ Initial version (VF + JS Remoting)
*  Jun 23, 2026  │ Siddaling  │ Ported to @AuraEnabled for LWC; FirstPublishLocationId
*                              attach + @future Lead handling carried over from VF fixes.
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/


/**
* EOIFormController
* Backend for the public EOI form (LWC c:eoiForm) on an Experience (LWR) site.
* "without sharing" so the Site Guest user can insert EOI__c + ContentVersion.
*
* DEBUG BUILD: submitEOI/attachFiles now return filesReceived + attachError so the
* browser console can show exactly why a file did or did not attach. System.debug
* lines are sprinkled through so a debug log on the GUEST user is readable too.
*/


public without sharing class EOIFormController {
    
    private static String lastAttachError;   // set by attachFiles when the insert throws
    
    /* ---------------- Metadata (picklists + source dependency) ---------------- */
    @AuraEnabled(cacheable=true)
    public static FormMetadata getFormMetadata() {
        FormMetadata meta   = new FormMetadata();
        meta.salutation      = describePicklist(EOI__c.Salutation__c);
        meta.profession      = describePicklist(EOI__c.Profession__c);
        meta.qualification   = describePicklist(EOI__c.Qualification__c);
        meta.annualIncome    = describePicklist(EOI__c.Annual_Household_Income__c);
        meta.purpose         = describePicklist(EOI__c.Purpose_of_Purchase__c);
        meta.howKnow         = describePicklist(EOI__c.How_did_you_get_to_know_about_us__c);
        meta.preferredPLC    = describePicklist(EOI__c.Preferred_PLC__c);
        meta.preferredArea   = describePicklist(EOI__c.Preferred_Area__c);
        meta.preferredFacing = describePicklist(EOI__c.Preferred_Facing__c);
        meta.roadFacing      = describePicklist(EOI__c.Road_Facing__c);
        meta.sourceTypes     = buildSourceTypes();
        meta.sourceMap       = buildSourceMap();
        return meta;
    }
    
    private static List<Option> describePicklist(Schema.SObjectField field) {
        List<Option> options = new List<Option>();
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new Option(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }
    
    /* ---------------- Submit: EOI + files + Lead ---------------- */
    @AuraEnabled
    public static SubmitResult submitEOI(EOI__c record, String filesJson, Map<String, String> leadInfo) {
        if (record == null) {
            throw new AuraHandledException('No application data was received.');
        }
        List<FileInput> files;
        try {
            files = String.isBlank(filesJson)
                ? new List<FileInput>()
                : (List<FileInput>) JSON.deserialize(filesJson, List<FileInput>.class);
        } catch (Exception e) {
            files = new List<FileInput>();
        }
        Integer received = (files == null) ? 0 : files.size();
        System.debug('EOI DEBUG → submitEOI start. files received from browser: ' + received);
        
        try {
            record.DPDP_Consent_DateTime__c = System.now();
            if (String.isBlank(record.Submission_Source__c)) {
                record.Submission_Source__c = 'Web - Public Site';
            }
            resolveChannelPartner(record);
            insert record;
            System.debug('EOI DEBUG → EOI inserted. Id=' + record.Id);
            
            String stype = (leadInfo != null) ? leadInfo.get('sourceType') : null;
            String ssec  = (leadInfo != null) ? leadInfo.get('secondary')  : null;
            String ster  = (leadInfo != null) ? leadInfo.get('tertiary')   : null;
            handleLeadFuture(record.Id, stype, ssec, ster);
            
            Integer attached = attachFiles(record.Id, files);
            System.debug('EOI DEBUG → attachFiles returned: ' + attached
                         + ' | lastAttachError=' + lastAttachError);
            
            // DEBUG: what did the SERVER actually receive for each file?
            String info = '';
            if (files != null) {
                for (FileInput fi : files) {
                    if (fi == null) { info += 'NULL; '; }
                    else { info += fi.fileName + '=' +
                        (fi.base64 == null ? 'NULLb64' : String.valueOf(fi.base64.length()) + 'chars') + '; '; }
                }
            }
            System.debug('EOI DEBUG → serverFileInfo: ' + info);
            
            SubmitResult result = new SubmitResult();
            result.recordId       = record.Id;
            result.attached       = attached;
            result.filesReceived  = received;       // how many the browser actually sent
            result.attachError    = lastAttachError; // null if no error
            result.serverFileInfo = info;            // per-file base64 length seen on the server
            return result;
        } catch (DmlException e) {
            System.debug('REAL DML CAUSE → ' + e.getDmlMessage(0));
            System.debug('REAL DML FIELDS → ' + e.getDmlFieldNames(0));
            throw new AuraHandledException(firstDmlMessage(e));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /* ---------------- Attach files in the creating transaction ---------------- */
    private static Integer attachFiles(Id parentId, List<FileInput> files) {
        lastAttachError = null;
        if (parentId == null || files == null || files.isEmpty()) {
            System.debug('EOI DEBUG → attachFiles: nothing to attach (parentId or files empty)');
            return 0;
        }
        try {
            List<ContentVersion> toInsert = new List<ContentVersion>();
            for (FileInput fi : files) {
                if (fi != null && String.isNotBlank(fi.base64)) {
                    System.debug('EOI DEBUG → preparing file: ' + fi.fileName
                                 + ' | base64 length=' + fi.base64.length());
                    toInsert.add(new ContentVersion(
                        Title                  = String.isBlank(fi.title) ? fi.fileName : fi.title,
                        PathOnClient           = fi.fileName,
                        VersionData            = EncodingUtil.base64Decode(fi.base64),
                        FirstPublishLocationId = parentId
                    ));
                } else {
                    System.debug('EOI DEBUG → skipping a file (null or blank base64)');
                }
            }
            if (!toInsert.isEmpty()) {
                insert toInsert;
                System.debug('EOI DEBUG → ContentVersion insert OK. count=' + toInsert.size());
                return toInsert.size();
            }
        } catch (Exception e) {
            lastAttachError = e.getMessage();
            System.debug('EOI DEBUG → EOI file attach FAILED: ' + e.getMessage());
        }
        return 0;
    }
    
    /* ---------------- Channel Partner lookup (best-effort fallback by name) ---------------- */
    private static void resolveChannelPartner(EOI__c eoi) {
        try {
            String cpName = eoi.Channel_Partner_Names__c;
            if (String.isBlank(cpName) || eoi.Channel_Partner__c != null) {
                return;
            }
            List<Channel_Partner__c> matches = [
                SELECT Id FROM Channel_Partner__c
                WHERE Name = :cpName AND Approval_Status__c = 'Approved' LIMIT 1
            ];
            if (!matches.isEmpty()) {
                eoi.Channel_Partner__c = matches[0].Id;
            }
        } catch (Exception e) {
            // best-effort; typed name preserved on the record
        }
    }
    
    /* ---------------- Lead: create new, or flag existing by phone (async) ---------------- */
    @future
    public static void handleLeadFuture(Id eoiId, String sourceType, String secondary, String tertiary) {
        if (eoiId == null) return;
        List<EOI__c> rows = [
            SELECT Id, Primary_Contact_No__c, How_did_you_get_to_know_about_us__c, Others_Source__c,
            Name__c, Salutation__c, Project_Name__c, Email__c, Channel_Partner__c
            FROM EOI__c WHERE Id = :eoiId LIMIT 1
        ];
        if (rows.isEmpty()) return;
        EOI__c eoi = rows[0];
        
        if (String.isBlank(sourceType)) sourceType = eoi.How_did_you_get_to_know_about_us__c;
        if (String.isBlank(tertiary))   tertiary   = eoi.Others_Source__c;
        
        Map<String, Schema.SObjectField> fmap = Lead.SObjectType.getDescribe().fields.getMap();
        Schema.SObjectField fSource    = fmap.get('lead_source__c');
        Schema.SObjectField fSecondary = fmap.get('sub_source__c');
        Schema.SObjectField fTertiary  = fmap.get('tertiary_source__c');
        
        String mobile = eoi.Primary_Contact_No__c;
        if (String.isNotBlank(mobile)) {
            List<Lead> existing = [
                SELECT Id, EOI_Collected__c FROM Lead WHERE Phone__c = :mobile LIMIT 1
            ];
            if (!existing.isEmpty()) {
                Lead existingLead = existing[0];
                existingLead.EOI_Collected__c = true;
                if (fmap.containsKey('round_robin_off__c')) existingLead.put('Round_Robin_Off__c', true);
                safeSet(existingLead, fSource,    sourceType);
                safeSet(existingLead, fSecondary, secondary);
                safeSet(existingLead, fTertiary,  tertiary);
                if (eoi.Channel_Partner__c != null && fmap.containsKey('channel_partner__c')) {
                    existingLead.put('Channel_Partner__c', eoi.Channel_Partner__c);
                }
                update existingLead;
                stampRelatedSource(existingLead.Id, sourceType, secondary);
                return;
            }
        }
        
        String fullName = (eoi.Name__c == null) ? '' : eoi.Name__c.trim();
        String firstName;
        String lastName;
        if (fullName.contains(' ')) {
            firstName = fullName.substringBefore(' ').trim();
            lastName  = fullName.substringAfter(' ').trim();
        } else {
            firstName = null;
            lastName  = String.isBlank(fullName) ? 'EOI Applicant' : fullName;
        }
        if (firstName != null && firstName.length() > 40) firstName = firstName.substring(0, 40);
        if (lastName != null && lastName.length() > 80)  lastName  = lastName.substring(0, 80);
        
        Lead newLead = new Lead();
        newLead.Salutation           = eoi.Salutation__c;
        newLead.FirstName            = firstName;
        newLead.LastName             = lastName;
        newLead.Company              = String.isBlank(fullName) ? 'Individual' : fullName;
        newLead.Allocated_Project__c = eoi.Project_Name__c;
        newLead.Phone__c             = mobile;
        newLead.Email                = eoi.Email__c;
        newLead.EOI_Collected__c     = true;
        if (fmap.containsKey('round_robin_off__c')) newLead.put('Round_Robin_Off__c', true);
        safeSet(newLead, fSource,    sourceType);
        safeSet(newLead, fSecondary, secondary);
        safeSet(newLead, fTertiary,  tertiary);
        if (eoi.Channel_Partner__c != null && fmap.containsKey('channel_partner__c')) {
            newLead.put('Channel_Partner__c', eoi.Channel_Partner__c);
        }
        
        insert newLead;
        stampRelatedSource(newLead.Id, sourceType, secondary);
    }
    
    /* ---------------- Stamp Source Type / Secondary Source onto the auto-created Related_Source__c ----------------
A trigger creates a Related_Source__c child whenever the Lead is inserted/updated. By the time the Lead DML
above returns, that child exists in THIS transaction, so we find the most recent one for the Lead and write
the source values onto it. Lookup field + target fields are resolved dynamically so a name change never
throws - if a field is missing, that write is simply skipped. */
    private static void stampRelatedSource(Id leadId, String sourceType, String secondary) {
        if (leadId == null) return;
        if (String.isBlank(sourceType) && String.isBlank(secondary)) return;
        try {
            Schema.DescribeSObjectResult d = Related_Source__c.SObjectType.getDescribe();
            Map<String, Schema.SObjectField> rmap = d.fields.getMap();
            
            // Find the lookup field on Related_Source__c that points to Lead.
            String lookupField;
            for (Schema.SObjectField f : rmap.values()) {
                Schema.DescribeFieldResult fd = f.getDescribe();
                if (fd.getType() == Schema.DisplayType.Reference) {
                    for (Schema.SObjectType ref : fd.getReferenceTo()) {
                        if (ref == Lead.SObjectType) { lookupField = fd.getName(); break; }
                    }
                }
                if (lookupField != null) break;
            }
            if (lookupField == null) return;
            
            Boolean hasSrc = rmap.containsKey('source_type_c__c');
            Boolean hasSec = rmap.containsKey('secondary_source__c');
            if (!hasSrc && !hasSec) return;
            
            // The newest Related_Source__c for this Lead is the one for THIS submission.
            List<Related_Source__c> rows = Database.query(
                'SELECT Id FROM Related_Source__c WHERE ' + lookupField + ' = :leadId ORDER BY CreatedDate DESC LIMIT 1'
            );
            if (rows.isEmpty()) return;
            
            Related_Source__c r = rows[0];
            if (hasSrc && String.isNotBlank(sourceType)) r.put('Source_Type_c__c', sourceType);
            if (hasSec && String.isNotBlank(secondary))  r.put('Secondary_source__c', secondary);
            update r;
            System.debug('EOI DEBUG → stamped Related_Source__c ' + r.Id);
        } catch (Exception e) {
            System.debug('EOI DEBUG → stampRelatedSource failed: ' + e.getMessage());
        }
    }
    
    /* ---------------- Set a field only if the value exists on the picklist ---------------- */
    private static void safeSet(SObject rec, Schema.SObjectField f, String val) {
        if (f == null || String.isBlank(val)) return;
        Schema.DescribeFieldResult d = f.getDescribe();
        Schema.DisplayType t = d.getType();
        if (t == Schema.DisplayType.Picklist || t == Schema.DisplayType.MultiPicklist) {
            Boolean ok = false;
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                if (e.isActive() && e.getValue().equalsIgnoreCase(val)) { ok = true; break; }
            }
            if (!ok) return;
        }
        rec.put(d.getName(), val);
    }
    
    /* ---------------- Channel Partner type-ahead lookup ---------------- */
    @AuraEnabled
    public static List<Option> searchChannelPartners(String term) {
        List<Option> out = new List<Option>();
        try {
            String likeTerm = '%' + (term == null ? '' : String.escapeSingleQuotes(term.trim())) + '%';
            for (Channel_Partner__c cp : [
                SELECT Id, Name FROM Channel_Partner__c
                WHERE Approval_Status__c = 'Approved' AND Name LIKE :likeTerm
                ORDER BY Name LIMIT 20]) {
                    out.add(new Option(cp.Name, cp.Id));
                }
        } catch (Exception e) {
            System.debug('CP search failed: ' + e.getMessage());
        }
        return out;
    }
    
    /* ---------------- Source Type -> Secondary Source dependency ---------------- */
    private static List<Option> buildSourceTypes() {
        return new List<Option>{
            new Option('Direct Walkin/Site Branding', 'Direct Walkin/Site Branding'),
                new Option('Channel partner',             'Channel partner'),
                new Option('Referral',                    'Referral'),
                new Option('Zuari Champion (Dealer)',     'Zuari Champion')
                };
                    }
    
    private static Map<String, List<String>> buildSourceMap() {
        return new Map<String, List<String>>{
            'Direct Walkin/Site Branding' => new List<String>{ 'NA' },
                'Channel partner'             => new List<String>{ 'Channel Partner' },
                    'Referral'                    => new List<String>{ 'Employe Referral', 'Customer Referral' },
                        'Zuari Champion'              => new List<String>{ 'Bangalore', 'Chennai', 'Hyderabad' }
        };
            }
    
    private static String firstDmlMessage(DmlException e) {
        return (e.getNumDml() > 0) ? e.getDmlMessage(0) : e.getMessage();
    }
    
    /* ---------------- Wrappers ---------------- */
    public class FormMetadata {
        @AuraEnabled public List<Option> salutation;
        @AuraEnabled public List<Option> profession;
        @AuraEnabled public List<Option> qualification;
        @AuraEnabled public List<Option> annualIncome;
        @AuraEnabled public List<Option> purpose;
        @AuraEnabled public List<Option> howKnow;
        @AuraEnabled public List<Option> preferredPLC;
        @AuraEnabled public List<Option> preferredArea;
        @AuraEnabled public List<Option> preferredFacing;
        @AuraEnabled public List<Option> roadFacing;
        @AuraEnabled public List<Option> sourceTypes;
        @AuraEnabled public Map<String, List<String>> sourceMap;
    }
    
    public class SubmitResult {
        @AuraEnabled public String recordId;
        @AuraEnabled public Integer attached;
        @AuraEnabled public Integer filesReceived;
        @AuraEnabled public String attachError;
        @AuraEnabled public String serverFileInfo;
    }
    
    public class Option {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public Option(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    public class FileInput {
        @AuraEnabled public String fileName;
        @AuraEnabled public String title;
        @AuraEnabled public String base64;
    }
    
    /* ---------------- Upload ONE file (kept for backward compatibility) ---------------- */
    @AuraEnabled
    public static Boolean uploadFile(Id parentId, String fileName, String title, String base64) {
        if (parentId == null || String.isBlank(base64)) {
            return false;
        }
        ContentVersion cv = new ContentVersion(
            Title                  = String.isBlank(title) ? fileName : title,
            PathOnClient           = fileName,
            VersionData            = EncodingUtil.base64Decode(base64),
            FirstPublishLocationId = parentId
        );
        insert cv;
        return true;
    }
}