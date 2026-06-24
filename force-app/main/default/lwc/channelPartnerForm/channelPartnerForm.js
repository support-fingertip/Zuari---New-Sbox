import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadOrphanFile from '@salesforce/apex/ChannelPartnerController.uploadOrphanFile';
import appendToOrphanFile from '@salesforce/apex/ChannelPartnerController.appendToOrphanFile';
import commitChannelPartnerWithFiles from '@salesforce/apex/ChannelPartnerController.commitChannelPartnerWithFiles';
import cleanupOrphanFiles from '@salesforce/apex/ChannelPartnerController.cleanupOrphanFiles';
import getRegionPicklistValues from '@salesforce/apex/ChannelPartnerController.getRegionPicklistValues';
import getSourcingRMOptions from '@salesforce/apex/ChannelPartnerController.getSourcingRMOptions';
import LOGO from '@salesforce/resourceUrl/Zuari';

// Base64 chars per chunk. Must be a multiple of 4 so non-final chunks decode
// to whole bytes on the server. ~750KB keeps each Aura request well below
// the framework size limit that caused aura:systemError on ~2MB uploads.
const CHUNK_SIZE = 750000;

export default class ChannelPartnerForm extends LightningElement {
    logoUrl = LOGO;

    /* ===================== STATE ===================== */
@track showUpload = false;
    @track entityType = '';
    @track declarationChecked = false;

    @track showAlert = false;
    @track alertMessage = '';
    @track alertClass = '';
    @track alertIcon = '';

    @track recordId = null;
    @track isSaving = false;
    @track showForm = true;
    @track showThankYouScreen = false;
    
    @track regionOptions = [];
    @track sourcingRMOptions = [];

    /* ===================== PICKLIST OPTIONS ===================== */

    entityOptions = [
        { label: 'Company', value: 'Company' },
        { label: 'Individual', value: 'Individual' }
    ];

    @track mediumOptions = [
    { label: 'Digital', value: 'Digital', checked: false },
    { label: 'Offline', value: 'Offline', checked: false },
    { label: 'Portals', value: 'Portals', checked: false },
    { label: 'Social Media', value: 'Social Media', checked: false },
    { label: 'Reference', value: 'Reference', checked: false },
    { label: 'Others', value: 'Others', checked: false },
    { label: 'All', value: 'All', checked: false }
];


    /* ===================== FORM DATA ===================== */

    @track formData = {
        Company_Name__c: '',
        Name: '',
        Company_Head_Name__c: '',
        Mobile_Number__c: '',
        Company_Owner_Name__c: '',
        Alternate_number__c: '',
        Team_Strength__c: '',
        Company_Website__c: '',
        Email__c: '',
        Email_ID__c: '',
        Company_Head_Email_ID__c: '',
        Company_Owner_Email_ID__c: '',
        Company_Head_Contact_No__c: '',
        Company_Owner_Contact_No__c: '',
        Company_Address__c: '',
        Communication_Address__c: '',
        City__c: '',
        State__c: '',
        City_you_reside_in__c: '',
        City_of_Primary_Work__c: '',
        Select_Region__c: '',
        Sourcing_RM__c: '',
        Active_Medium__c: '',
        Entity_Type__c: '',
        Company_GST_No__c: '',
        GST__c  : 'NA',
        Are_you_GST_Registered__c: false,
        Company_Declaration__c:false,
        Indivisual_Declaration__c:false,
        Company_PAN_Card_No__c: '',
        PAN_Card_No__c: '',
        Company_RERA_No__c: '',
        RERA__c: '',
        RERA_Validity__c: ''
    };
@track uploadStatus = {
  gst: '',
  pan: '',
  rera: '',
  aadhar: '',
  other: '',
  authorization: '',
  board: '',
  addressProof: '',
  cancelCheque: '',
  companyRegistration: ''
};

    @track uploadedDocs = {
    gst: false,
    pan: false,
    rera: false,
    aadhar: false,
    authorizationOrBoard: false // company only
};

    // Files staged in the browser, keyed by data-document-type. Held in memory
    // until handleSave uploads them as orphan ContentVersions and then commits
    // the record + links atomically. Single-file slots store a File; the
    // 'Other Document' slot stores an Array<File>.
    pendingFiles = {};

    /* ===================== LIFECYCLE ===================== */

    connectedCallback() {
        getRegionPicklistValues()
            .then(result => {
                this.regionOptions = result.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            })
            .catch(error => {
                console.error('Error loading region picklist:', error);
            });

        // Sourcing RM options are loaded on demand once the user selects a Region
        // (see handleRegionChange). This filters the dropdown to only the
        // Sourcing Managers mapped to the chosen region via User.CP_Region__c.
    }

    /* ===================== GETTERS ===================== */
get saveButtonLabel() {
    return this.isSaving ? 'Submitting...' : 'Submit Application';
}
get watermarkStyle() {
    return `--logo-url: url(${this.logoUrl});`;
}


    get showDeclaration() {
        return this.entityType !== '';
    }

    get isCompany() {
        return this.entityType === 'Company';
    }

    get isIndividual() {
        return this.entityType === 'Individual';
    }

    get showCompanyForm() {
        return this.isCompany && this.declarationChecked;
    }
    get showIndividualForm() {
    return this.isIndividual && this.declarationChecked;
}
get showAuthDocError() {
        return false;
    }


    get declarationCheckboxLabel() {
        return 'I agree to the above declaration';
    }
get isGSTDisabled() {
    return !this.formData.Are_you_GST_Registered__c;
}

get isGSTRequired() {
    return this.formData.Are_you_GST_Registered__c;
}

get gstPattern() {
    return this.formData.Are_you_GST_Registered__c
        ? '[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}'
        : null; // ⬅️ CRITICAL
}


    get declarationText() {
        if (this.isCompany) {
            return `
                <b>Company Declaration:</b>
                I confirm that I am duly authorised by the Company/Organisation to provide information
                and personal data (including my own and that of the Company/Organisation) for the stated purposes.
                I hereby give my free, specific, informed, unconditional and unambiguous consent to the collection,
                storage, processing and lawful sharing of such data in accordance with the
                <a href="https://www.zuariinfra.com/privacy-policy/" target="_blank">Privacy Policy</a>.
                I understand that this consent may be withdrawn in accordance with the Privacy Policy.
            `;
        }
        return `
            <b>Individual Declaration:</b>
            I hereby give my free, specific, informed, unconditional and unambiguous consent to the collection,
            storage, processing and use of my personal data for the stated purposes, in accordance with the
            <a href="https://www.zuariinfra.com/privacy-policy/" target="_blank">Privacy Policy</a>.
            I understand that I may withdraw my consent at any time as described in the Privacy Policy.
        `;
    }
    handleMediumChange(event) {
    const value = event.target.value;
    const checked = event.target.checked;

    // Handle "All" selection
    if (value === 'All') {
        this.mediumOptions = this.mediumOptions.map(opt => {
            return { ...opt, checked: checked };
        });
    } else {
        this.mediumOptions = this.mediumOptions.map(opt => {
            return opt.value === value
                ? { ...opt, checked: checked }
                : opt;
        });

        // If any unchecked → uncheck "All"
        const allSelected = this.mediumOptions
            .filter(o => o.value !== 'All')
            .every(o => o.checked);

        this.mediumOptions = this.mediumOptions.map(opt => {
            if (opt.value === 'All') {
                return { ...opt, checked: allSelected };
            }
            return opt;
        });
    }

    // Save multipicklist value (semicolon separated)
    const selected = this.mediumOptions
        .filter(opt => opt.checked && opt.value !== 'All')
        .map(opt => opt.value);

    this.formData.Active_Medium__c = selected.join(';');
}


    /* ===================== HANDLERS ===================== */

    handleEntityChange(event) {
        this.entityType = event.detail.value;
        this.formData.Entity_Type__c = this.entityType;
        this.declarationChecked = false;
    }
handleDeclarationChange(event) {
    const checked = event.target.checked;
    this.declarationChecked = checked;

    if (this.isCompany) {
        this.formData.Company_Declaration__c = checked;
        this.formData.Indivisual_Declaration__c = false;
    }

    if (this.isIndividual) {
        this.formData.Indivisual_Declaration__c = checked;
        this.formData.Company_Declaration__c = false;
    }
}
handleGSTCheckboxChange(event) {
    const checked = event.target.checked;
    this.formData.Are_you_GST_Registered__c = checked;

    if (!checked) {
        // If not GST registered
        this.formData.GST__c = 'NA';
    } else {
        // If GST registered, clear GST so user can enter
        this.formData.GST__c = '';
    }
}

    handleInputChange(event) {
        const { name, value } = event.target;
        this.formData[name] = value;
    }

    handleRegionChange(event) {
        const region = event.detail.value;
        this.formData.Select_Region__c = region;

        // Reset the dependent Sourcing RM selection and options
        this.formData.Sourcing_RM__c = '';
        this.sourcingRMOptions = [];

        if (!region) {
            return;
        }

        getSourcingRMOptions({ region: region })
            .then(result => {
                this.sourcingRMOptions = result.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            })
            .catch(error => {
                console.error('Error loading Sourcing RM options:', error);
                this.toast('Error', this.extractErrorMessage(error), 'error');
            });
    }

    get isSourcingRMDisabled() {
        return !this.formData.Select_Region__c;
    }

    handleSourcingRMChange(event) {
        this.formData.Sourcing_RM__c = event.detail.value;
    }

    handleFileSelect(event) {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        const docType = event.target.dataset.documentType;
        const MAX_SIZE = 4500000;
        const accepted = [];

        for (let file of files) {
            if (!file.type.includes('application/pdf') && !file.name.toLowerCase().endsWith('.pdf')) {
                this.toast('Error', `${file.name} is not a PDF. Only PDF documents are allowed.`, 'error');
                continue;
            }
            if (file.size > MAX_SIZE) {
                this.toast('Error', `${file.name} exceeds 4.5MB limit`, 'error');
                continue;
            }
            accepted.push(file);
        }

        if (accepted.length === 0) {
            event.target.value = null;
            return;
        }

        if (docType === 'Other Document') {
            const existing = this.pendingFiles[docType] || [];
            this.pendingFiles[docType] = existing.concat(accepted);
            accepted.forEach(f => this.updateUploadStatus(docType, f.name));
        } else {
            this.pendingFiles[docType] = accepted[0];
            this.updateUploadStatus(docType, accepted[0].name);
        }
    }

    async handleSave() {
        if (this.isCompany && !this.declarationChecked) {
            this.showAlertMessage(
                'Please accept the Company Declaration before submitting the application.',
                'error'
            );
            window.scrollTo({ top: 0, behavior: 'smooth' });
            return;
        }
        if (!this.formData.Are_you_GST_Registered__c) {
            this.formData.GST__c = 'NA';
        }

        const unifiedMsg = 'Please fill all mandatory fields and upload every document marked with * before submitting.';

        const allValid = [
            ...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allValid) {
            this.showAlertMessage(unifiedMsg, 'error');
            this.toast('Mandatory information missing', unifiedMsg, 'error');
            return;
        }

        const missing = this.getMissingRequiredDocs();
        if (missing.length > 0) {
            this.showAlertMessage(unifiedMsg, 'error');
            this.toast('Mandatory information missing', unifiedMsg, 'error');
            window.scrollTo({ top: 0, behavior: 'smooth' });
            return;
        }

        this.isSaving = true;
        this.showAlert = false;

        const fileQueue = this.flattenPendingFiles();
        const uploadedCvIds = [];

        try {
            // Phase 1: upload each selected file as an orphan ContentVersion in parallel.
            // If any single upload rejects, cleanup the ones that did succeed and abort —
            // the Channel_Partner__c record is never created.
            const results = await Promise.allSettled(fileQueue.map(async ({ file, docType }) => {
                const cvId = await this.uploadFileInChunks(file);
                return { contentVersionId: cvId, docType, fileName: file.name };
            }));

            const fileLinks = [];
            const failures = [];
            for (const r of results) {
                if (r.status === 'fulfilled') {
                    uploadedCvIds.push(r.value.contentVersionId);
                    fileLinks.push(r.value);
                } else {
                    failures.push(r.reason);
                }
            }

            if (failures.length > 0) {
                if (uploadedCvIds.length > 0) {
                    try { await cleanupOrphanFiles({ contentVersionIds: uploadedCvIds }); } catch (e) { /* best-effort */ }
                }
                throw failures[0];
            }

            // Phase 2: atomic commit — record + ContentDocumentLinks + approval inside a Savepoint.
            const payload = {};
            Object.keys(this.formData).forEach(key => {
                if (this.formData[key] !== undefined && this.formData[key] !== null) {
                    payload[key] = this.formData[key];
                }
            });

            let recordId;
            try {
                recordId = await commitChannelPartnerWithFiles({
                    fieldValues: payload,
                    fileLinks: fileLinks
                });
            } catch (commitErr) {
                // Apex rolled back the record + links. The orphan ContentVersions
                // survived (they were inserted in earlier transactions), so delete
                // them here so nothing is leaked.
                try { await cleanupOrphanFiles({ contentVersionIds: uploadedCvIds }); } catch (e) { /* best-effort */ }
                throw commitErr;
            }

            this.recordId = recordId;
            this.isSaving = false;
            this.showForm = false;
            this.showUpload = false;
            this.showThankYouScreen = true;

            this.toast(
                'Success',
                `Application submitted! Reference ID: ${recordId}. For further processing, please contact our Sourcing Head, Om Prakash, at +91 95139 71362`,
                'success'
            );
            window.scrollTo({ top: 0, behavior: 'smooth' });

        } catch (error) {
            this.isSaving = false;
            const msg = this.extractErrorMessage(error);
            this.showAlertMessage(msg, 'error');
            this.toast('Error', msg, 'error');
        }
    }

    flattenPendingFiles() {
        const queue = [];
        Object.keys(this.pendingFiles).forEach(docType => {
            const entry = this.pendingFiles[docType];
            if (Array.isArray(entry)) {
                entry.forEach(file => queue.push({ file, docType }));
            } else if (entry) {
                queue.push({ file: entry, docType });
            }
        });
        return queue;
    }

    getMissingRequiredDocs() {
        const missing = [];
        const has = (key) => Boolean(this.uploadStatus[key]);

        if (this.isIndividual) {
            if (!has('pan')) missing.push('PAN Card');
            if (!has('rera')) missing.push('RERA Certificate');
            if (!has('aadhar')) missing.push('Aadhar Card');
            if (!has('cancelCheque')) missing.push('Cancel Cheque');
        }
        if (this.isCompany) {
            if (!has('pan')) missing.push('PAN Card');
            if (!has('rera')) missing.push('RERA Certificate');
            if (!has('aadhar')) missing.push('Aadhar Card');
            if (!has('cancelCheque')) missing.push('Cancel Cheque');
        }
        return missing;
    }

    /* ===================== HELPERS ===================== */

    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    async uploadFileInChunks(file) {
        const base64 = await this.readFileAsBase64(file);
        let cvId = null;
        for (let i = 0; i < base64.length; i += CHUNK_SIZE) {
            const chunk = base64.substring(i, i + CHUNK_SIZE);
            if (cvId === null) {
                cvId = await uploadOrphanFile({
                    fileName: file.name,
                    base64Data: chunk,
                    contentType: file.type
                });
            } else {
                await appendToOrphanFile({
                    contentVersionId: cvId,
                    base64Chunk: chunk
                });
            }
        }
        return cvId;
    }
    updateUploadStatus(type, name) {
    if (type === 'GST Certificate') this.uploadStatus.gst = `✓ ${name}`;
    if (type === 'PAN Card') this.uploadStatus.pan = `✓ ${name}`;
    if (type === 'RERA Certificate') this.uploadStatus.rera = `✓ ${name}`;
    if (type === 'Aadhar Card' || type === 'Aadhaar Card') this.uploadStatus.aadhar = `✓ ${name}`;

    if (type === 'Authorization Letter') this.uploadStatus.authorization = `✓ ${name}`;
    if (type === 'Board Resolution') this.uploadStatus.board = `✓ ${name}`;

    if (type === 'Address Proof') this.uploadStatus.addressProof = `✓ ${name}`;
    if (type === 'Cancel Cheque') this.uploadStatus.cancelCheque = `✓ ${name}`;
    if (type === 'Company Registration') this.uploadStatus.companyRegistration = `✓ ${name}`;

    if (type === 'Other Document') {
        this.uploadStatus.other =
            this.uploadStatus.other ? `${this.uploadStatus.other}, ${name}` : `✓ ${name}`;
    }
}



    extractErrorMessage(error) {
        return error?.body?.message || error?.message || 'Unexpected error occurred';
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showAlertMessage(message, type) {
        this.alertMessage = message;
        this.showAlert = true;
        this.alertClass = type === 'success'
            ? 'slds-notify slds-notify_alert slds-alert_success'
            : 'slds-notify slds-notify_alert slds-alert_error';
        this.alertIcon = type === 'success' ? 'utility:success' : 'utility:error';
    }

    closeAlert() {
        this.showAlert = false;
    }

}