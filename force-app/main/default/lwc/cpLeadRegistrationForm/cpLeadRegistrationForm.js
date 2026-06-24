import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import LOGO from '@salesforce/resourceUrl/Zuari';

import validatePan from '@salesforce/apex/ChannelPartnerLeadRegistrationController.validatePan';
import getLeadPicklistOptions from '@salesforce/apex/ChannelPartnerLeadRegistrationController.getLeadPicklistOptions';
import getCountryCodeOptions from '@salesforce/apex/ChannelPartnerLeadRegistrationController.getCountryCodeOptions';
import insertLead from '@salesforce/apex/ChannelPartnerLeadRegistrationController.insertLead';

export default class CpLeadRegistrationForm extends LightningElement {
    logoUrl = LOGO;

    @track showForm = true;
    @track showThankYouScreen = false;

    @track showAlert = false;
    @track alertMessage = '';
    @track alertClass = '';
    @track alertIcon = '';

    @track pan = '';
    @track panValidated = false;
    @track isValidating = false;
    @track isSubmitting = false;

    @track projectOptions = [];
    @track countryCodeOptions = [];
    @track unitPreferenceOptions = [];
    @track budgetOptions = [];

    @track leadData = {
        Name: '',
        Allocated_Project__c: '',
        Email: '',
        Country_Code__c: '',
        Phone__c: '',
        Secondary_Phone__c: '',
        Secondary_Email__c: '',
        Unit_Preference__c: '',
        Budget__c: ''
    };

    connectedCallback() {
        this.loadPicklists();
    }

    loadPicklists() {
        // Project
        getLeadPicklistOptions({ leadFieldApiName: 'Allocated_Project__c' })
            .then(result => {
                this.projectOptions = result.map(item => ({ label: item.label, value: item.value }));
            })
            .catch(() => {
                this.projectOptions = [{ label: '-- Select --', value: '' }];
            });

        // Country Code — from Custom Metadata (label = Country Name, value = Country Code)
        getCountryCodeOptions()
            .then(result => {
                this.countryCodeOptions = result.map(item => ({ label: item.label, value: item.value }));
            })
            .catch(() => {
                this.countryCodeOptions = [{ label: '-- Select Country --', value: '' }];
            });

        // Unit Preference
        getLeadPicklistOptions({ leadFieldApiName: 'Unit_Preference__c' })
            .then(result => {
                this.unitPreferenceOptions = result.map(item => ({ label: item.label, value: item.value }));
            })
            .catch(() => {
                this.unitPreferenceOptions = [{ label: '-- Select --', value: '' }];
            });

        // Budget
        getLeadPicklistOptions({ leadFieldApiName: 'Budget__c' })
            .then(result => {
                this.budgetOptions = result.map(item => ({ label: item.label, value: item.value }));
            })
            .catch(() => {
                this.budgetOptions = [{ label: '-- Select --', value: '' }];
            });
    }

    get validateButtonLabel() {
        return this.isValidating ? 'Validating...' : 'Validate PAN';
    }

    get submitButtonLabel() {
        return this.isSubmitting ? 'Submitting...' : 'Submit Lead';
    }

    handlePanChange(event) {
        this.pan = event.target.value;
    }

    async handleValidatePan() {
        const panInput = this.template.querySelector('lightning-input');
        if (panInput) {
            panInput.reportValidity();
            if (!panInput.checkValidity()) return;
        }

        this.isValidating = true;
        this.showAlert = false;

        try {
            const res = await validatePan({ pan: this.pan });

            if (!res.isValid) {
                this.showAlertMessage(res.message, 'error');
                this.toast('Error', res.message, 'error');
                return;
            }

            this.panValidated = true;
            this.toast('Success', 'PAN validated successfully.', 'success');

        } catch (e) {
            const msg = this.extractErrorMessage(e);
            this.showAlertMessage(msg, 'error');
            this.toast('Error', msg, 'error');
        } finally {
            this.isValidating = false;
        }
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this.leadData = { ...this.leadData, [name]: value };
    }

    handleComboboxChange(event) {
        const { name, value } = event.target;
        this.leadData = { ...this.leadData, [name]: value };
    }

    async handleSubmit() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            this.showAlertMessage('Please fill all required fields correctly.', 'error');
            this.toast('Error', 'Please fill all required fields correctly.', 'error');
            return;
        }

        this.isSubmitting = true;
        this.showAlert = false;

        try {
            const payload = {
                Name: this.leadData.Name,
                Allocated_Project__c: this.leadData.Allocated_Project__c,
                Email: this.leadData.Email,
                Country_Code__c: this.leadData.Country_Code__c,  // Stores the code (e.g. +91), not the name
                Phone__c: this.leadData.Phone__c,
                Secondary_Phone__c: this.leadData.Secondary_Phone__c,
                Secondary_Email__c: this.leadData.Secondary_Email__c,
                Unit_Preference__c: this.leadData.Unit_Preference__c,
                Budget__c: this.leadData.Budget__c
            };

            const res = await insertLead({ pan: this.pan, leadFields: payload });

            if (!res.success) {
                this.showAlertMessage(res.message, 'error');
                this.toast('Error', res.message, 'error');
                return;
            }

            this.toast('Success', res.message, 'success');
            this.showForm = false;
            this.showThankYouScreen = true;

        } catch (e) {
            const msg = this.extractErrorMessage(e);
            this.showAlertMessage(msg, 'error');
            this.toast('Error', msg, 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    handleBack() {
        this.panValidated = false;
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
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    closeAlert() {
        this.showAlert = false;
    }
}