import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CURRENT_USER_ID from '@salesforce/user/Id';
import escalateManual from '@salesforce/apex/CustomerQueryEscalationService.escalateManual';
import reassignManual from '@salesforce/apex/CustomerQueryEscalationService.reassignManual';
import getCrmExecutives from '@salesforce/apex/CustomerQueryEscalationService.getCrmExecutives';

const QUERY_FIELDS = [
    'Customer_Query__c.Escalation_Level__c',
    'Customer_Query__c.Query_Status__c',
    'Customer_Query__c.Next_Escalation_Date__c',
    'Customer_Query__c.OwnerId'
];
const USER_PROFILE_FIELDS = ['User.Profile.Name'];

export default class CustomerQueryEscalationPanel extends LightningElement {
    @api recordId;
    @track isBusy = false;
    @track showReassign = false;
    @track reassignReason = '';
    @track reassignOwnerId = '';
    @track targetLevel = '';
    @track userOptions = [];

    currentLevel;
    status;
    profileName;

    @wire(getRecord, { recordId: '$recordId', fields: QUERY_FIELDS })
    wiredQuery({ data }) {
        if (data) {
            this.currentLevel = data.fields.Escalation_Level__c.value;
            this.status = data.fields.Query_Status__c.value;
        }
    }

    @wire(getRecord, { recordId: CURRENT_USER_ID, fields: USER_PROFILE_FIELDS })
    wiredUser({ data }) {
        if (data) {
            this.profileName = data.fields.Profile.value.fields.Name.value;
        }
    }

    @wire(getCrmExecutives)
    wiredExecutives({ data }) {
        if (data) {
            this.userOptions = data.map(u => ({ label: u.Name, value: u.Id }));
        }
    }

    get isClosed() { return this.status === 'Closed'; }

    get showTlActions() {
        return !this.isClosed && this.currentLevel === 'TL' && this.profileName === 'CRM Manager';
    }
    get showHodActions() {
        return !this.isClosed && this.currentLevel === 'HOD' && this.profileName === 'HOD';
    }
    get showCfoActions() {
        return !this.isClosed && this.currentLevel === 'CFO' && this.profileName === 'CFO';
    }
    get hasAnyAction() {
        return this.showTlActions || this.showHodActions || this.showCfoActions;
    }

    handleEscalateToHod()  { this.runEscalate('HOD'); }
    handleEscalateToCfo()  { this.runEscalate('CFO'); }
    handleEscalateToCeo()  { this.runEscalate('CEO'); }

    async runEscalate(toLevel) {
        this.isBusy = true;
        try {
            await escalateManual({ queryId: this.recordId, toLevel, reason: 'Manual escalation by ' + this.profileName });
            this.toast('Success', `Query escalated to ${toLevel}.`, 'success');
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (e) {
            this.toast('Error', e?.body?.message || e?.message || 'Failed to escalate.', 'error');
        } finally {
            this.isBusy = false;
        }
    }

    handleOpenReassign() {
        this.reassignReason = '';
        this.reassignOwnerId = '';
        this.showReassign = true;
    }
    handleReasonChange(e)  { this.reassignReason = e.target.value; }
    handleOwnerChange(e)   { this.reassignOwnerId = e.target.value; }
    handleCancelReassign() { this.showReassign = false; }

    async handleConfirmReassign() {
        if (!this.reassignOwnerId) {
            this.toast('Error', 'Pick a user to reassign to.', 'error');
            return;
        }
        if (!this.reassignReason || this.reassignReason.trim() === '') {
            this.toast('Error', 'Reason is required.', 'error');
            return;
        }
        this.isBusy = true;
        try {
            await reassignManual({
                queryId: this.recordId,
                newOwnerId: this.reassignOwnerId,
                reason: this.reassignReason
            });
            this.toast('Success', 'Query reassigned.', 'success');
            this.showReassign = false;
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (e) {
            this.toast('Error', e?.body?.message || e?.message || 'Failed to reassign.', 'error');
        } finally {
            this.isBusy = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}