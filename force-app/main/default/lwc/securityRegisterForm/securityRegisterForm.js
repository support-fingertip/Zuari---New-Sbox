import { LightningElement, track, wire } from 'lwc';
import LOGO from '@salesforce/resourceUrl/Zuari';

import saveSecurityRegister from '@salesforce/apex/SecurityRegisterFormController.saveSecurityRegister';
import getPicklistValues   from '@salesforce/apex/SecurityRegisterFormController.getPicklistValues';
import getCountryCodeOptions from '@salesforce/apex/SecurityRegisterFormController.getCountryCodeOptions'; // ← NEW

export default class SecurityRegisterForm extends LightningElement {

    logoUrl = LOGO;

    @track showThankYou = false;
    @track isLoading    = false;
    @track showAlert    = false;
    @track alertMessage = '';
    @track alertClass   = '';
    @track alertIcon    = '';

    // Picklist options
    @track projectNameOptions    = [];
    @track budgetOptions         = [];
    @track unitPreferenceOptions = [];
    @track countryCodeOptions    = [];   // ← NEW: from Custom Metadata

    @track formData = {
        Security_Register_Name__c : '',
        Phone__c                  : '',
        Email__c                  : '',
        Secondary_Phone__c        : '',
        Secondary_Email__c        : '',
        Country__c                : '',   // stores Country Name (auto-filled)
        Country_Code__c           : '',   // stores Country Code (user picks)
        Project_Name__c           : '',
        Budget__c                 : '',
        Unit_Preference__c        : '',
        Remarks__c                : ''
    };

    // ── Wire: Country options from Custom Metadata ──────────────────────────
    @wire(getCountryCodeOptions)
    wiredCountryOptions({ data, error }) {
        if (data) {
            this.countryCodeOptions = data.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error loading country options', error);
            this.countryCodeOptions = [{ label: '-- Select Country --', value: '' }];
        }
    }

    // ── Wire: Project picklist ───────────────────────────────────────────────
    @wire(getPicklistValues, { objectName: 'Security_Register__c', fieldName: 'Project_Name__c' })
    wiredProjectOptions({ data, error }) {
        if (data) {
            this.projectNameOptions = [
                { label: '-- Select --', value: '' },
                ...data.map(v => ({ label: v, value: v }))
            ];
        } else if (error) {
            this.projectNameOptions = [{ label: '-- Select --', value: '' }];
        }
    }

    // ── Wire: Budget picklist ────────────────────────────────────────────────
    @wire(getPicklistValues, { objectName: 'Security_Register__c', fieldName: 'Budget__c' })
    wiredBudgetOptions({ data, error }) {
        if (data) {
            this.budgetOptions = [
                { label: '-- Select --', value: '' },
                ...data.map(v => ({ label: v, value: v }))
            ];
        } else if (error) {
            this.budgetOptions = [{ label: '-- Select --', value: '' }];
        }
    }

    // ── Wire: Unit Preference picklist ───────────────────────────────────────
    @wire(getPicklistValues, { objectName: 'Security_Register__c', fieldName: 'Unit_Preference__c' })
    wiredUnitOptions({ data, error }) {
        if (data) {
            this.unitPreferenceOptions = [
                { label: '-- Select --', value: '' },
                ...data.map(v => ({ label: v, value: v }))
            ];
        } else if (error) {
            this.unitPreferenceOptions = [{ label: '-- Select --', value: '' }];
        }
    }

    // ── Handlers ─────────────────────────────────────────────────────────────

    handleInputChange(event) {
        const { name, value } = event.target;
        this.formData = { ...this.formData, [name]: value };
    }

    /**
     * When user selects a country from the dropdown:
     *  - Country_Code__c  = the code value  (e.g. "+91")
     *  - Country__c       = the country name label (e.g. "India")
     *    so both fields are populated from a single selection.
     */
    handleCountryChange(event) {
        const selectedCode = event.target.value;

        // Find the matching label (country name) from our options list
        const match = this.countryCodeOptions.find(opt => opt.value === selectedCode);
        const countryName = match ? match.label : '';

        this.formData = {
            ...this.formData,
            Country_Code__c : selectedCode,
            Country__c      : countryName
        };
    }

    get saveButtonLabel() {
        return this.isLoading ? 'Saving...' : 'Submit';
    }

    async handleSave() {
        // Validate all inputs
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
            .reduce((valid, el) => {
                el.reportValidity();
                return valid && el.checkValidity();
            }, true);

        if (!allValid) {
            this.showAlertMsg('Please fill all required fields correctly.', 'error');
            return;
        }

        this.isLoading  = true;
        this.showAlert  = false;

        try {
            const result = await saveSecurityRegister({ formDataJson: JSON.stringify(this.formData) });

            if (result === 'SUCCESS') {
                this.showThankYou = true;
            } else {
                this.showAlertMsg('Something went wrong. Please try again.', 'error');
            }
        } catch (e) {
            const msg = e?.body?.message || e?.message || 'Unexpected error occurred.';
            this.showAlertMsg(msg, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showAlertMsg(message, type) {
        this.alertMessage = message;
        this.showAlert    = true;
        this.alertClass   = type === 'success'
            ? 'slds-notify slds-notify_alert slds-alert_success'
            : 'slds-notify slds-notify_alert slds-alert_error';
        this.alertIcon    = type === 'success' ? 'utility:success' : 'utility:error';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}