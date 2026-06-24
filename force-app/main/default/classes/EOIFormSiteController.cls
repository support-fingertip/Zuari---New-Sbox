/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : EOIFormController
 * Author          : Siddaling
 * Created Date    : Jun 20, 2026
 * Last Modified By: Siddaling
 * Last Modified On: Jun 20, 2026
 * Description     : This class implements for EOI Form 
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jun 20, 2026  │ Siddaling  │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */



/**
 * EOIFormSiteController
 * Controller for the PURE VISUALFORCE public EOI form (no Lightning Out).
 * Picklists render server-side via getters; submit + per-file upload run through
 * JavaScript Remoting (@RemoteAction). Works for the Site Guest user on desktop
 * and mobile because nothing depends on the Lightning framework bootstrapping.
 *
 * Guest profile needs: Apex Class access to EOIFormSiteController, Create on
 * EOI__c / Lead / ContentVersion (+ Update on Lead), and FLS on the fields.
 */


/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : EOIFormController
 * Author          : Siddaling
 * Created Date    : Jun 20, 2026
 * Last Modified By: Siddaling
 * Last Modified On: Jun 20, 2026
 * Description     : This class implements for EOI Form 
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jun 20, 2026  │ Siddaling  │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */



/**
 * EOIFormSiteController
 * Controller for the PURE VISUALFORCE public EOI form (no Lightning Out).
 * Picklists render server-side via getters; submit + per-file upload run through
 * JavaScript Remoting (@RemoteAction). Works for the Site Guest user on desktop
 * and mobile because nothing depends on the Lightning framework bootstrapping.
 *
 * Guest profile needs: Apex Class access to EOIFormSiteController, Create on
 * EOI__c / Lead / ContentVersion (+ Update on Lead), and FLS on the fields.
 */





/*global without sharing class EOIFormSiteController {

    /* ---------------- Picklist option getters (rendered server-side) ---------------- 
    public List<Opt> getSalutationOptions()    { return opts(EOI__c.Salutation__c); }
    public List<Opt> getProfessionOptions()    { return opts(EOI__c.Profession__c); }
    public List<Opt> getQualificationOptions() { return opts(EOI__c.Qualification__c); }
    public List<Opt> getIncomeOptions()        { return opts(EOI__c.Annual_Household_Income__c); }
    public List<Opt> getPurposeOptions()       { return opts(EOI__c.Purpose_of_Purchase__c); }
    public List<Opt> getHowKnowOptions()       { return opts(EOI__c.How_did_you_get_to_know_about_us__c); }
    public List<Opt> getPlcOptions()           { return opts(EOI__c.Preferred_PLC__c); }
    public List<Opt> getAreaOptions()          { return opts(EOI__c.Preferred_Area__c); }
    public List<Opt> getFacingOptions()        { return opts(EOI__c.Preferred_Facing__c); }
    public List<Opt> getRoadOptions()          { return opts(EOI__c.Road_Facing__c); }

    private List<Opt> opts(Schema.SObjectField field) {
        List<Opt> result = new List<Opt>();
        for (Schema.PicklistEntry e : field.getDescribe().getPicklistValues()) {
            if (e.isActive()) {
                result.add(new Opt(e.getValue(), e.getLabel()));
            }
        }
        return result;
    }

    /* ---------------- Submit: EOI + Lead ---------------- 
    @RemoteAction
    global static String submitEOIRemote(String recordJson, String filesJson, String leadJson) {
        if (String.isBlank(recordJson)) {
            throw new AuraHandledException('No application data was received.');
        }
        EOI__c record = (EOI__c) JSON.deserialize(recordJson, EOI__c.class);
        record.DPDP_Consent_DateTime__c = System.now();
        if (String.isBlank(record.Submission_Source__c)) {
            record.Submission_Source__c = 'Web - Public Site';
        }
        resolveChannelPartner(record);
        insert record;

        Map<String, String> extras = null;
        if (String.isNotBlank(leadJson)) {
            try {
                extras = (Map<String, String>) JSON.deserialize(leadJson, Map<String, String>.class);
            } catch (Exception e) { extras = null; }
        }
        // Create/flag the Lead in an async transaction. Running it out of the synchronous
        // Guest request avoids INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY when SLeadTrigger
        // reassigns the Lead owner (a Guest can't set OwnerId to another user synchronously).
        String stype = (extras != null) ? extras.get('sourceType') : null;
        String ssec  = (extras != null) ? extras.get('secondary')  : null;
        String ster  = (extras != null) ? extras.get('tertiary')   : null;
        handleLeadFuture(record.Id, stype, ssec, ster);

        // Attach files in the SAME transaction as the record creation, while the
        // Guest user is still the creator. Attaching in a separate call fails with
        // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY because Secure Guest User
        // Record Access isolates the Guest from the OWD, and the committed/reassigned
        // record is no longer accessible to it. Same-transaction attach avoids that.
        Integer attached = attachFiles(record.Id, filesJson);

        return JSON.serialize(new Map<String, Object>{
            'recordId' => record.Id,
            'attached' => attached
        });
    }

    /* ---------------- Attach files in the creating transaction ----------------
       Works once the Site Guest user has access to the EOI (via a Guest user sharing
       rule). Without that access the link throws INSUFFICIENT_ACCESS and is caught, so
       the EOI + Lead still save. 
    private static Integer attachFiles(Id parentId, String filesJson) {
        if (parentId == null || String.isBlank(filesJson)) {
            return 0;
        }
        try {
            List<FileInput> incoming =
                (List<FileInput>) JSON.deserialize(filesJson, List<FileInput>.class);
            List<ContentVersion> toInsert = new List<ContentVersion>();
            for (FileInput fi : incoming) {
                if (fi != null && String.isNotBlank(fi.base64)) {
                    toInsert.add(new ContentVersion(
                        Title                  = String.isBlank(fi.title) ? fi.fileName : fi.title,
                        PathOnClient           = fi.fileName,
                        VersionData            = EncodingUtil.base64Decode(fi.base64),
                        FirstPublishLocationId = parentId
                    ));
                }
            }
            if (!toInsert.isEmpty()) {
                insert toInsert;
                return toInsert.size();
            }
        } catch (Exception e) {
            // Never fail the submission because of a file - the EOI + Lead are saved.
            System.debug('EOI file attach failed: ' + e.getMessage());
        }
        return 0;
    }

    /* ---------------- Upload one file ---------------- 
    @RemoteAction
    global static Boolean uploadFileRemote(Id parentId, String fileName, String title, String base64) {
        if (parentId == null || String.isBlank(base64)) {
            return false;
        }
        // Attach the file directly to the record via FirstPublishLocationId.
        // This auto-creates the ContentDocumentLink in a single insert and avoids
        // re-querying ContentVersion - a query that returns no rows for Site Guest
        // users (ContentVersion has its own sharing that "without sharing" does not
        // open). That re-query is why uploads worked in the authenticated preview
        // but silently failed (attached: 0) on the public Guest link.
        ContentVersion cv = new ContentVersion(
            Title                  = String.isBlank(title) ? fileName : title,
            PathOnClient           = fileName,
            VersionData            = EncodingUtil.base64Decode(base64),
            FirstPublishLocationId = parentId
        );
        insert cv;
        return true;
    }

    /* ---------------- Channel Partner lookup (best-effort fallback by name) ---------------- 
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
            // best-effort; typed name preserved in Channel_Partner_Name__c
        }
    }

    /* ---------------- Lead: create new, or flag existing by phone (async) ----------------
       Runs as a future so SLeadTrigger's owner reassignment isn't blocked by the Guest's
       synchronous DML restrictions. The EOI is re-queried by Id (futures take primitives only). 
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

        // Fallbacks to the older "How did you hear" mapping if the Source block was not used.
        if (String.isBlank(sourceType)) sourceType = eoi.How_did_you_get_to_know_about_us__c;
        if (String.isBlank(tertiary))   tertiary   = eoi.Others_Source__c;

        Map<String, Schema.SObjectField> fmap = Lead.SObjectType.getDescribe().fields.getMap();
        Schema.SObjectField fSource    = fmap.get('lead_source__c');     // Source Type -> picklist
        Schema.SObjectField fSecondary = fmap.get('sub_source__c');      // Secondary   -> text
        Schema.SObjectField fTertiary  = fmap.get('tertiary_source__c'); // Name        -> text

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
    }

    /* ---------------- Set a field only if the value exists on the picklist ----------------
       For any picklist (restricted or not), the value is checked against the field's
       active picklist values first; if it's not there, the set is skipped instead of
       writing a bad value or throwing. Text fields (e.g. Tertiary_Source__c) always write. 
    private static void safeSet(SObject rec, Schema.SObjectField f, String val) {
        if (f == null || String.isBlank(val)) return;
        Schema.DescribeFieldResult d = f.getDescribe();
        Schema.DisplayType t = d.getType();
        if (t == Schema.DisplayType.Picklist || t == Schema.DisplayType.MultiPicklist) {
            Boolean ok = false;
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                if (e.isActive() && e.getValue().equalsIgnoreCase(val)) { ok = true; break; }
            }
            if (!ok) return; // value not on the picklist - skip
        }
        rec.put(d.getName(), val);
    }

    /* ---------------- #13 Channel Partner search (type-ahead lookup) ---------------- 
    @RemoteAction
    global static String searchChannelPartners(String term) {
        List<Opt> out = new List<Opt>();
        try {
            String likeTerm = '%' + (term == null ? '' : String.escapeSingleQuotes(term.trim())) + '%';
            for (Channel_Partner__c cp : [
                    SELECT Id, Name FROM Channel_Partner__c
                    WHERE Approval_Status__c = 'Approved' AND Name LIKE :likeTerm
                    ORDER BY Name LIMIT 20]) {
                out.add(new Opt(cp.Id, cp.Name));
            }
        } catch (Exception e) {
            System.debug('CP search failed: ' + e.getMessage());
        }
        return JSON.serialize(out);
    }

    /* ---------------- Source Type -> Secondary Source dependency ---------------- 
    // Returns { sourceTypes:[...], map:{ sourceType:[secondary...] } }.
    // "Channel Partner" and "Dealer (Zuari Champion)" are fixed per spec; "Direct &
    // Walkin" and "Referral" are read from the Lead field dependency
    // (Source_Type__c controlling Secondary_Source__c) when that is configured.
    @RemoteAction
    global static String getSourceDependencyJson() {
        // Source Types shown on the form. 'value' = the EXACT Lead Source_Type__c value
        // (so it saves); 'label' = what the user sees.
        List<Map<String, String>> sourceTypes = new List<Map<String, String>>{
            new Map<String, String>{ 'value' => 'Direct Walkin/Site Branding', 'label' => 'Direct Walkin/Site Branding' },
            new Map<String, String>{ 'value' => 'Channel partner',             'label' => 'Channel partner' },
            new Map<String, String>{ 'value' => 'Referral',                    'label' => 'Referral' },
            new Map<String, String>{ 'value' => 'Zuari Champion',              'label' => 'Zuari Champion (Dealer)' }
        };

        // Hard-coded Secondary Source options per Source Type. EDIT THESE LISTS freely.
        // On save, the Lead logic writes the chosen value to Lead.Secondary_Source__c ONLY if
        // that value exists on the picklist (see safeSet) - so a value missing from the
        // picklist is simply skipped, never an error.
        Map<String, List<String>> depMap = new Map<String, List<String>>{
            'Direct Walkin/Site Branding' => new List<String>{ 'NA' },
            'Channel partner'             => new List<String>{ 'Channel Partner' },
            'Referral'                    => new List<String>{ 'Employe Referral', 'Customer Referral' },
            'Zuari Champion'              => new List<String>{ 'Bangalore', 'Chennai', 'Hyderabad' }
        };

        return JSON.serialize(new Map<String, Object>{
            'sourceTypes' => sourceTypes,
            'map'         => depMap
        });
    }

    private static Map<String, List<String>> decodeDependency(
            Schema.SObjectField controllingF, Schema.SObjectField dependentF) {
        Map<String, List<String>> result = new Map<String, List<String>>();
        List<String> ctrlVals = new List<String>();
        for (Schema.PicklistEntry e : controllingF.getDescribe().getPicklistValues()) {
            if (e.isActive()) ctrlVals.add(e.getValue());
        }
        for (String c : ctrlVals) result.put(c, new List<String>());

        for (Schema.PicklistEntry dep : dependentF.getDescribe().getPicklistValues()) {
            if (!dep.isActive()) continue;
            PicklistEntryWrapper w =
                (PicklistEntryWrapper) JSON.deserialize(JSON.serialize(dep), PicklistEntryWrapper.class);
            if (String.isBlank(w.validFor)) continue;
            String hex = EncodingUtil.convertToHex(EncodingUtil.base64Decode(w.validFor));
            for (Integer i = 0; i < ctrlVals.size(); i++) {
                Integer byteIndex = i / 8;
                if (byteIndex * 2 + 1 >= hex.length()) continue;
                Integer byteVal = hexPair(hex.substring(byteIndex * 2, byteIndex * 2 + 2));
                Integer mask = 128 >> Math.mod(i, 8);
                if ((byteVal & mask) != 0) {
                    result.get(ctrlVals[i]).add(dep.getValue());
                }
            }
        }
        return result;
    }

    private static final String HEXCHARS = '0123456789abcdef';
    private static Integer hexPair(String two) {
        String s = two.toLowerCase();
        return HEXCHARS.indexOf(s.substring(0, 1)) * 16 + HEXCHARS.indexOf(s.substring(1, 2));
    }

    public class PicklistEntryWrapper {
        public String value;
        public String label;
        public Boolean active;
        public Boolean defaultValue;
        public String validFor;
    }

    /* ---------------- Option wrapper for the VF page ---------------- 
    public class Opt {
        public String value { get; set; }
        public String label { get; set; }
        public Opt(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    /* ---------------- File payload wrapper ---------------- 
    global class FileInput {
        public String fileName;
        public String title;
        public String base64;
    }
}*/



global without sharing class EOIFormSiteController {

    /* ---------------- Picklist option getters (rendered server-side) ---------------- */
    public List<Opt> getSalutationOptions()    { return opts(EOI__c.Salutation__c); }
    public List<Opt> getProfessionOptions()    { return opts(EOI__c.Profession__c); }
    public List<Opt> getQualificationOptions() { return opts(EOI__c.Qualification__c); }
    public List<Opt> getIncomeOptions()        { return opts(EOI__c.Annual_Household_Income__c); }
    public List<Opt> getPurposeOptions()       { return opts(EOI__c.Purpose_of_Purchase__c); }
    public List<Opt> getHowKnowOptions()       { return opts(EOI__c.How_did_you_get_to_know_about_us__c); }
    public List<Opt> getPlcOptions()           { return opts(EOI__c.Preferred_PLC__c); }
    public List<Opt> getAreaOptions()          { return opts(EOI__c.Preferred_Area__c); }
    public List<Opt> getFacingOptions()        { return opts(EOI__c.Preferred_Facing__c); }
    public List<Opt> getRoadOptions()          { return opts(EOI__c.Road_Facing__c); }

    private List<Opt> opts(Schema.SObjectField field) {
        List<Opt> result = new List<Opt>();
        for (Schema.PicklistEntry e : field.getDescribe().getPicklistValues()) {
            if (e.isActive()) {
                result.add(new Opt(e.getValue(), e.getLabel()));
            }
        }
        return result;
    }

    /* ---------------- Submit: EOI + Lead ---------------- */
    @RemoteAction
    global static String submitEOIRemote(String recordJson, String filesJson, String leadJson) {
        if (String.isBlank(recordJson)) {
            throw new AuraHandledException('No application data was received.');
        }
        EOI__c record = (EOI__c) JSON.deserialize(recordJson, EOI__c.class);
        record.DPDP_Consent_DateTime__c = System.now();
        if (String.isBlank(record.Submission_Source__c)) {
            record.Submission_Source__c = 'Web - Public Site';
        }
        resolveChannelPartner(record);
        insert record;

        Map<String, String> extras = null;
        if (String.isNotBlank(leadJson)) {
            try {
                extras = (Map<String, String>) JSON.deserialize(leadJson, Map<String, String>.class);
            } catch (Exception e) { extras = null; }
        }
        handleLead(record, extras);

        // Attach files in the SAME transaction as the record creation, while the
        // Guest user is still the creator. Attaching in a separate call fails with
        // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY because Secure Guest User
        // Record Access isolates the Guest from the OWD, and the committed/reassigned
        // record is no longer accessible to it. Same-transaction attach avoids that.
        Integer attached = attachFiles(record.Id, filesJson);

        return JSON.serialize(new Map<String, Object>{
            'recordId' => record.Id,
            'attached' => attached
        });
    }

    /* ---------------- Attach files in the creating transaction ----------------
       Works once the Site Guest user has access to the EOI (via a Guest user sharing
       rule). Without that access the link throws INSUFFICIENT_ACCESS and is caught, so
       the EOI + Lead still save. */
    private static Integer attachFiles(Id parentId, String filesJson) {
        if (parentId == null || String.isBlank(filesJson)) {
            return 0;
        }
        try {
            List<FileInput> incoming =
                (List<FileInput>) JSON.deserialize(filesJson, List<FileInput>.class);
            List<ContentVersion> toInsert = new List<ContentVersion>();
            for (FileInput fi : incoming) {
                if (fi != null && String.isNotBlank(fi.base64)) {
                    toInsert.add(new ContentVersion(
                        Title                  = String.isBlank(fi.title) ? fi.fileName : fi.title,
                        PathOnClient           = fi.fileName,
                        VersionData            = EncodingUtil.base64Decode(fi.base64),
                        FirstPublishLocationId = parentId
                    ));
                }
            }
            if (!toInsert.isEmpty()) {
                insert toInsert;
                return toInsert.size();
            }
        } catch (Exception e) {
            // Never fail the submission because of a file - the EOI + Lead are saved.
            System.debug('EOI file attach failed: ' + e.getMessage());
        }
        return 0;
    }

    /* ---------------- Upload one file ---------------- */
    @RemoteAction
    global static Boolean uploadFileRemote(Id parentId, String fileName, String title, String base64) {
        if (parentId == null || String.isBlank(base64)) {
            return false;
        }
        // Attach the file directly to the record via FirstPublishLocationId.
        // This auto-creates the ContentDocumentLink in a single insert and avoids
        // re-querying ContentVersion - a query that returns no rows for Site Guest
        // users (ContentVersion has its own sharing that "without sharing" does not
        // open). That re-query is why uploads worked in the authenticated preview
        // but silently failed (attached: 0) on the public Guest link.
        ContentVersion cv = new ContentVersion(
            Title                  = String.isBlank(title) ? fileName : title,
            PathOnClient           = fileName,
            VersionData            = EncodingUtil.base64Decode(base64),
            FirstPublishLocationId = parentId
        );
        insert cv;
        return true;
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
            // best-effort; typed name preserved in Channel_Partner_Name__c
        }
    }

    /* ---------------- Lead: create new, or flag existing by phone ---------------- */
    private static void handleLead(EOI__c eoi, Map<String, String> extras) {
        // Source mapping coming from the Source Type / Secondary / Tertiary block.
        String sourceType = (extras != null) ? extras.get('sourceType') : null;
        String secondary  = (extras != null) ? extras.get('secondary')  : null;
        String tertiary   = (extras != null) ? extras.get('tertiary')   : null;

        // Fallbacks to the older "How did you hear" mapping if the block was not used.
        if (String.isBlank(sourceType)) sourceType = eoi.How_did_you_get_to_know_about_us__c;
        if (String.isBlank(tertiary))   tertiary   = eoi.Others_Source__c;

        Map<String, Schema.SObjectField> fmap = Lead.SObjectType.getDescribe().fields.getMap();
        Schema.SObjectField fSource    = fmap.get('lead_source__c');   // Source Type  -> picklist
        Schema.SObjectField fSecondary = fmap.get('sub_source__c');    // Secondary    -> text
        Schema.SObjectField fTertiary  = fmap.get('tertiary_source__c'); // Name        -> text

        String mobile = eoi.Primary_Contact_No__c;
        if (String.isNotBlank(mobile)) {
            List<Lead> existing = [
                SELECT Id, EOI_Collected__c FROM Lead WHERE Phone__c = :mobile LIMIT 1
            ];
            if (!existing.isEmpty()) {
                Lead existingLead = existing[0];
                existingLead.EOI_Collected__c = true;
                safeSet(existingLead, fSource,    sourceType);
                safeSet(existingLead, fSecondary, secondary);
                safeSet(existingLead, fTertiary,  tertiary);
                if (eoi.Channel_Partner__c != null && fmap.containsKey('channel_partner__c')) {
                    existingLead.put('Channel_Partner__c', eoi.Channel_Partner__c);
                }
                update existingLead;
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
        safeSet(newLead, fSource,    sourceType);
        safeSet(newLead, fSecondary, secondary);
        safeSet(newLead, fTertiary,  tertiary);
        if (eoi.Channel_Partner__c != null && fmap.containsKey('channel_partner__c')) {
            newLead.put('Channel_Partner__c', eoi.Channel_Partner__c);
        }

        insert newLead;
    }

    /* ---------------- Set a field only if the value exists on the picklist ----------------
       For any picklist (restricted or not), the value is checked against the field's
       active picklist values first; if it's not there, the set is skipped instead of
       writing a bad value or throwing. Text fields (e.g. Tertiary_Source__c) always write. */
    private static void safeSet(SObject rec, Schema.SObjectField f, String val) {
        if (f == null || String.isBlank(val)) return;
        Schema.DescribeFieldResult d = f.getDescribe();
        Schema.DisplayType t = d.getType();
        if (t == Schema.DisplayType.Picklist || t == Schema.DisplayType.MultiPicklist) {
            Boolean ok = false;
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                if (e.isActive() && e.getValue().equalsIgnoreCase(val)) { ok = true; break; }
            }
            if (!ok) return; // value not on the picklist - skip
        }
        rec.put(d.getName(), val);
    }

    /* ---------------- #13 Channel Partner search (type-ahead lookup) ---------------- */
    @RemoteAction
    global static String searchChannelPartners(String term) {
        List<Opt> out = new List<Opt>();
        try {
            String likeTerm = '%' + (term == null ? '' : String.escapeSingleQuotes(term.trim())) + '%';
            for (Channel_Partner__c cp : [
                    SELECT Id, Name FROM Channel_Partner__c
                    WHERE Approval_Status__c = 'Approved' AND Name LIKE :likeTerm
                    ORDER BY Name LIMIT 20]) {
                out.add(new Opt(cp.Id, cp.Name));
            }
        } catch (Exception e) {
            System.debug('CP search failed: ' + e.getMessage());
        }
        return JSON.serialize(out);
    }

    /* ---------------- Source Type -> Secondary Source dependency ---------------- */
    // Returns { sourceTypes:[...], map:{ sourceType:[secondary...] } }.
    // "Channel Partner" and "Dealer (Zuari Champion)" are fixed per spec; "Direct &
    // Walkin" and "Referral" are read from the Lead field dependency
    // (Source_Type__c controlling Secondary_Source__c) when that is configured.
    @RemoteAction
    global static String getSourceDependencyJson() {
        // Source Types shown on the form. 'value' = the EXACT Lead Source_Type__c value
        // (so it saves); 'label' = what the user sees.
        List<Map<String, String>> sourceTypes = new List<Map<String, String>>{
            new Map<String, String>{ 'value' => 'Direct Walkin/Site Branding', 'label' => 'Direct Walkin/Site Branding' },
            new Map<String, String>{ 'value' => 'Channel partner',             'label' => 'Channel partner' },
            new Map<String, String>{ 'value' => 'Referral',                    'label' => 'Referral' },
            new Map<String, String>{ 'value' => 'Zuari Champion',              'label' => 'Zuari Champion (Dealer)' }
        };

        // Hard-coded Secondary Source options per Source Type. EDIT THESE LISTS freely.
        // On save, handleLead writes the chosen value to Lead.Secondary_Source__c ONLY if
        // that value exists on the picklist (see safeSet) - so a value missing from the
        // picklist is simply skipped, never an error.
        Map<String, List<String>> depMap = new Map<String, List<String>>{
            'Direct Walkin/Site Branding' => new List<String>{ 'NA' },
            'Channel partner'             => new List<String>{ 'Channel Partner' },
            'Referral'                    => new List<String>{ 'Employe Referral', 'Customer Referral' },
            'Zuari Champion'              => new List<String>{ 'Bangalore', 'Chennai', 'Hyderabad' }
        };

        return JSON.serialize(new Map<String, Object>{
            'sourceTypes' => sourceTypes,
            'map'         => depMap
        });
    }

    private static Map<String, List<String>> decodeDependency(
            Schema.SObjectField controllingF, Schema.SObjectField dependentF) {
        Map<String, List<String>> result = new Map<String, List<String>>();
        List<String> ctrlVals = new List<String>();
        for (Schema.PicklistEntry e : controllingF.getDescribe().getPicklistValues()) {
            if (e.isActive()) ctrlVals.add(e.getValue());
        }
        for (String c : ctrlVals) result.put(c, new List<String>());

        for (Schema.PicklistEntry dep : dependentF.getDescribe().getPicklistValues()) {
            if (!dep.isActive()) continue;
            PicklistEntryWrapper w =
                (PicklistEntryWrapper) JSON.deserialize(JSON.serialize(dep), PicklistEntryWrapper.class);
            if (String.isBlank(w.validFor)) continue;
            String hex = EncodingUtil.convertToHex(EncodingUtil.base64Decode(w.validFor));
            for (Integer i = 0; i < ctrlVals.size(); i++) {
                Integer byteIndex = i / 8;
                if (byteIndex * 2 + 1 >= hex.length()) continue;
                Integer byteVal = hexPair(hex.substring(byteIndex * 2, byteIndex * 2 + 2));
                Integer mask = 128 >> Math.mod(i, 8);
                if ((byteVal & mask) != 0) {
                    result.get(ctrlVals[i]).add(dep.getValue());
                }
            }
        }
        return result;
    }

    private static final String HEXCHARS = '0123456789abcdef';
    private static Integer hexPair(String two) {
        String s = two.toLowerCase();
        return HEXCHARS.indexOf(s.substring(0, 1)) * 16 + HEXCHARS.indexOf(s.substring(1, 2));
    }

    public class PicklistEntryWrapper {
        public String value;
        public String label;
        public Boolean active;
        public Boolean defaultValue;
        public String validFor;
    }

    /* ---------------- Option wrapper for the VF page ---------------- */
    public class Opt {
        public String value { get; set; }
        public String label { get; set; }
        public Opt(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    /* ---------------- File payload wrapper ---------------- */
    global class FileInput {
        public String fileName;
        public String title;
        public String base64;
    }
}