import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import saveComment from '@salesforce/apex/CRMCommentController.saveComment';
import uploadFileToComment from '@salesforce/apex/CRMCommentController.uploadFileToComment';

const MAX_FILE_SIZE_BYTES = 4718592; // 4.5 MB (base64 inflates ~33%, Apex heap limit ~6MB)

export default class CrmCommentAction extends LightningElement {
    @api recordId;
    @track comment = '';
    @track isLoading = false;
    @track isOpen = false;
    @track selectedFiles = [];

    @api invoke() {
        this.comment = '';
        this.isLoading = false;
        this.isOpen = true;
        this.selectedFiles = [];
    }

    handleCommentChange(event) {
        this.comment = event.target.value;
    }

    get saveButtonLabel() {
        return this.isLoading ? 'Saving...' : 'Save';
    }

    get hasFiles() {
        return this.selectedFiles.length > 0;
    }

    handleFilesChange(event) {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        const oversizedFiles = [];
        const readPromises = [];

        for (let i = 0; i < files.length; i++) {
            const file = files[i];

            if (file.size > MAX_FILE_SIZE_BYTES) {
                oversizedFiles.push(file.name);
                continue;
            }

            readPromises.push(
                new Promise((resolve) => {
                    const reader = new FileReader();
                    reader.onload = () => {
                        const base64 = reader.result.split(',')[1];
                        resolve({
                            name: file.name,
                            size: file.size,
                            sizeLabel: this.formatFileSize(file.size),
                            base64Data: base64,
                            key: Date.now() + '-' + i
                        });
                    };
                    reader.readAsDataURL(file);
                })
            );
        }

        if (oversizedFiles.length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'File Size Exceeded',
                    message: `The following file(s) exceed the 4.5 MB limit and were not added: ${oversizedFiles.join(', ')}`,
                    variant: 'warning'
                })
            );
        }

        Promise.all(readPromises).then((results) => {
            this.selectedFiles = [...this.selectedFiles, ...results];
        });

        // Reset file input so the same file can be re-selected if removed
        event.target.value = null;
    }

    handleRemoveFile(event) {
        const fileKey = event.currentTarget.dataset.key;
        this.selectedFiles = this.selectedFiles.filter(f => f.key !== fileKey);
    }

    formatFileSize(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / 1048576).toFixed(1) + ' MB';
    }

    closeModal() {
        this.isOpen = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSave() {
        const textArea = this.template.querySelector('lightning-textarea');
        if (textArea) {
            textArea.reportValidity();
            if (!textArea.checkValidity()) {
                return;
            }
        }

        if (!this.comment || this.comment.trim() === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter a comment.',
                    variant: 'error'
                })
            );
            return;
        }

        this.isLoading = true;

        try {
            // Step 1: Save the comment and get the CRM_Comment__c record Id
            const commentId = await saveComment({ queryId: this.recordId, comment: this.comment });

            // Step 2: Upload files linked to the CRM Comment record
            let fileUploadErrors = [];
            if (this.selectedFiles.length > 0) {
                for (const file of this.selectedFiles) {
                    try {
                        await uploadFileToComment({
                            commentId: commentId,
                            fileName: file.name,
                            base64Data: file.base64Data
                        });
                    } catch (fileError) {
                        fileUploadErrors.push(file.name);
                    }
                }
            }

            // Step 3: Show appropriate toast
            if (fileUploadErrors.length > 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Partial Success',
                        message: `Comment saved, but failed to upload: ${fileUploadErrors.join(', ')}`,
                        variant: 'warning'
                    })
                );
            } else {
                const fileMsg = this.selectedFiles.length > 0
                    ? ` with ${this.selectedFiles.length} file(s)`
                    : '';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Comment added successfully${fileMsg}.`,
                        variant: 'success'
                    })
                );
            }

            // Refresh the record page and related lists
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            try {
                eval("$A.get('e.force:refreshView').fire()");
            } catch (e) {
                // Fallback: force:refreshView not available outside LEX
            }

            this.closeModal();
        } catch (error) {
            const msg = error?.body?.message || error?.message || 'An unexpected error occurred.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: msg,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.closeModal();
    }
}