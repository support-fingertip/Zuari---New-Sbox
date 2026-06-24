import { LightningElement, wire, api } from 'lwc';
import getInvoices from '@salesforce/apex/ChannelPartnerPaymentController.getInvoices';
import createPayment from '@salesforce/apex/ChannelPartnerPaymentController.createPayment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class ChannelPartnerPayment extends NavigationMixin(LightningElement) {

    @api recordId;

    invoices = [];
    filteredInvoices = [];
    selectedInvoices = [];

    baseName = '';
    paymentDate = '';
    utrNumber = '';
    paymentMethod = '';
    status = '';
    searchKey = '';

    columns = [
        { label: 'Invoice No', fieldName: 'Name' },
        { label: 'Project', fieldName: 'Project_Name1__c' },
        { label: 'Invoice Date', fieldName: 'Invoice_Date__c', type: 'date' },
        { label: 'Net Amount', fieldName: 'Net_Invoice_Amount__c', type: 'currency' }
    ];

    statusOptions = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Processed', value: 'Processed' }
    ];

    paymentMethodOptions = [
        { label: 'UPI', value: 'UPI' },
        { label: 'NEFT', value: 'NEFT' },
        { label: 'RTGS', value: 'RTGS' },
        { label: 'IMPS', value: 'IMPS' },
        { label: 'Cheque', value: 'Cheque' }
    ];

    /* ================= LOAD INVOICES ================= */
    @wire(getInvoices, { recId: '$recordId' })
    wiredInvoices({ data, error }) {
        if (data) {
            this.invoices = data;
            this.filteredInvoices = data; // show all pending by default
        } else if (error) {
            this.showToast('Error', 'Failed to load invoices', 'error');
        }
    }

    /* ================= SEARCH ================= */
    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();

        if (!this.searchKey) {
            this.filteredInvoices = this.invoices;
            return;
        }

        this.filteredInvoices = this.invoices.filter(inv =>
            inv.Name.toLowerCase().includes(this.searchKey)
        );
    }

    /* ================= ROW SELECTION ================= */
    handleRowSelection(event) {
        this.selectedInvoices = event.detail.selectedRows;
    }

    /* ================= FIELD HANDLERS ================= */
    handleNameChange(e) { this.baseName = e.target.value; }
    handleDate(e) { this.paymentDate = e.target.value; }
    handleUTR(e) { this.utrNumber = e.target.value; }
    handleStatus(e) { this.status = e.target.value; }
    handlePaymentMethod(e) { this.paymentMethod = e.target.value; }

    /* ================= SAVE PAYMENT ================= */
    savePayment() {
        if (!this.selectedInvoices.length) {
            this.showToast('Error', 'Please select at least one invoice', 'error');
            return;
        }

        if (!this.baseName || !this.paymentDate || !this.utrNumber ||
            !this.paymentMethod || !this.status) {
            this.showToast('Error', 'Please fill all required fields', 'error');
            return;
        }

        createPayment({
            baseName: this.baseName,
            paymentDate: this.paymentDate,
            utrNumber: this.utrNumber,
            status: this.status,
            paymentMethod: this.paymentMethod,
            recId: this.recordId,
            invoiceIds: this.selectedInvoices.map(inv => inv.Id)
        })
            .then(paymentId => {
                this.showToast('Success', 'Payment created successfully', 'success');

                // Navigate to the newly created payment record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: paymentId,
                        objectApiName: 'Payment__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(err => {
                this.showToast('Error', err.body?.message || 'An error occurred', 'error');
            });
    }

    /* ================= HELPERS ================= */
    get totalInvoiceAmount() {
        return this.selectedInvoices.reduce(
            (sum, inv) => sum + (inv.Net_Invoice_Amount__c || 0),
            0
        );
    }

    get isInvalid() {
        return !this.baseName || !this.paymentDate || !this.utrNumber ||
            !this.paymentMethod || !this.status;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}