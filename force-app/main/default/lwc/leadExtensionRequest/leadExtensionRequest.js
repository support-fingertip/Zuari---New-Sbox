import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getRequestState from '@salesforce/apex/LeadExtensionController.getRequestState';
import submitRequest from '@salesforce/apex/LeadExtensionController.submitRequest';
import approveRequest from '@salesforce/apex/LeadExtensionController.approveRequest';
import rejectRequest from '@salesforce/apex/LeadExtensionController.rejectRequest';

export default class LeadExtensionRequest extends NavigationMixin(LightningElement) {
    @api recordId;

    @wire(CurrentPageReference)
    pageReference;

    @track state = {};
    @track loading = true;
    @track submitting = false;
    @track hasError = false;

    inputDays;
    inputReason = '';
    inputNotes = '';

    connectedCallback() {
        this.initializeRecordId();
    }

    initializeRecordId() {
        // Extract recordId from page reference if not provided via @api
        // This handles quick action invocation where recordId is in the page state
        if (!this.recordId && this.pageReference && this.pageReference.state) {
            this.recordId = this.pageReference.state.recordId || this.pageReference.state.c__recordId;
        }
        
        // Load state once we have the recordId
        if (this.recordId) {
            this.loadState();
        } else {
            // If still no recordId, try again after a brief delay (wire might update)
            setTimeout(() => {
                if (!this.recordId && this.pageReference && this.pageReference.state) {
                    this.recordId = this.pageReference.state.recordId || this.pageReference.state.c__recordId;
                }
                this.loadState();
            }, 100);
        }
    }

    // Handle when pageReference wire updates
    handlePageReferenceChange() {
        if (!this.recordId && this.pageReference && this.pageReference.state) {
            this.recordId = this.pageReference.state.recordId || this.pageReference.state.c__recordId;
            if (this.recordId && !this.loading) {
                this.loadState();
            }
        }
    }

    async loadState() {
        this.loading = true;
        
        // Validate recordId is available
        if (!this.recordId) {
            this.hasError = true;
            this.toast('Error', 'This component must be placed on a Related Source record page.', 'error');
            this.loading = false;
            return;
        }
        
        this.hasError = false;
        try {
            this.state = await getRequestState({ recordId: this.recordId });
        } catch (e) {
            this.toast('Error', this.errorMessage(e), 'error');
        } finally {
            this.loading = false;
        }
    }

    get hasStatus() {
        return !!this.state.status;
    }

    get showRequestForm() {
        return this.state.canRequest === true;
    }

    get showDecisionForm() {
        return this.state.canDecide === true;
    }

    get isPendingForOther() {
        return this.state.status === 'Pending' && this.state.canDecide === false;
    }

    get windowSummary() {
        const base = this.state.expiryDays || 0;
        const ext = this.state.extensionDays || 0;
        return ext > 0 ? `${base} + ${ext}` : `${base}`;
    }

    handleDaysChange(event) {
        this.inputDays = event.target.value;
    }
    handleReasonChange(event) {
        this.inputReason = event.target.value;
    }
    handleNotesChange(event) {
        this.inputNotes = event.target.value;
    }

    async handleSubmit() {
        if (!this.recordId) {
            this.toast('Error', 'Record ID is missing.', 'error');
            return;
        }
        
        const days = parseInt(this.inputDays, 10);
        if (!days || days <= 0) {
            this.toast('Invalid', 'Enter a number of days greater than zero.', 'warning');
            return;
        }
        this.submitting = true;
        try {
            this.state = await submitRequest({
                recordId: this.recordId,
                days,
                reason: this.inputReason
            });
            this.inputDays = null;
            this.inputReason = '';
            this.toast('Submitted', 'Request sent to your manager.', 'success');
        } catch (e) {
            this.toast('Error', this.errorMessage(e), 'error');
        } finally {
            this.submitting = false;
        }
    }

    async handleApprove() {
        await this.decide(approveRequest, 'Approved');
    }

    async handleReject() {
        await this.decide(rejectRequest, 'Rejected');
    }

    async decide(apexCall, verdict) {
        if (!this.recordId) {
            this.toast('Error', 'Record ID is missing.', 'error');
            return;
        }
        
        this.submitting = true;
        try {
            this.state = await apexCall({ recordId: this.recordId, notes: this.inputNotes });
            this.inputNotes = '';
            this.toast(verdict, `Request ${verdict.toLowerCase()}.`, 'success');
            // Refresh the page after approval so surrounding UI updates
            if (verdict === 'Approved') {
                this.refreshPage();
            }
        } catch (e) {
            this.toast('Error', this.errorMessage(e), 'error');
        } finally {
            this.submitting = false;
        }
    }

    refreshPage() {
        if (this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            }, true);
        } else {
            window.location.reload();
        }
    }

    errorMessage(e) {
        if (e && e.body && e.body.message) return e.body.message;
        if (e && e.message) return e.message;
        return 'Unexpected error.';
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}