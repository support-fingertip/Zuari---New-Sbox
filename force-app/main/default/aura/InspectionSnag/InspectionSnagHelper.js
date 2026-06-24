({
    showToast: function(title, message, variant) {
        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            type: variant,
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
    
    closeModal: function(component) {
        // Close the quick action modal
        $A.get("e.force:closeQuickAction").fire();
    },
    
    uploadFilesForSnags: function(component, snagRows, snagIds) {
        console.log('Starting file upload for snags');
        console.log('Snag IDs:', snagIds);
        
        const uploadPromises = [];
        
        snagRows.forEach((snag, index) => {
            if (snag.selectedFiles && snag.selectedFiles.length > 0) {
                console.log('Snag ' + index + ' has ' + snag.selectedFiles.length + ' files');
                snag.selectedFiles.forEach(fileObj => {
                    console.log('Uploading file: ' + fileObj.name + ' to snag: ' + snagIds[index]);
                    uploadPromises.push(this.uploadFile(component, fileObj.file, snagIds[index]));
                });
            }
        });
        
        if (uploadPromises.length === 0) {
            console.log('No files to upload');
            // No files to upload, just finish
            this.finishSave(component);
            return;
        }
        
        console.log('Total files to upload: ' + uploadPromises.length);
        
        Promise.all(uploadPromises)
            .then(() => {
                console.log('All files uploaded successfully');
                this.finishSave(component);
            })
            .catch(error => {
                console.error('Error uploading files:', error);
                component.set("v.isLoading", false);
                this.showToast('Error', 'Error uploading files: ' + error.message, 'error');
            });
    },
    
    uploadFile: function(component, file, snagId) {
        return new Promise((resolve, reject) => {
            console.log('Reading file: ' + file.name);
            const reader = new FileReader();
            
            reader.onload = $A.getCallback(() => {
                try {
                    const base64 = reader.result.split(',')[1];
                    console.log('File read successfully, uploading to Salesforce');
                    
                    const action = component.get("c.uploadFileToSnag");
                    action.setParams({
                        snagId: snagId,
                        fileName: file.name,
                        base64Data: base64,
                        contentType: file.type || 'application/octet-stream'
                    });
                    
                    action.setCallback(this, function(response) {
                        const state = response.getState();
                        console.log('Upload response state: ' + state);
                        
                        if (state === "SUCCESS") {
                            console.log('File uploaded successfully: ' + file.name);
                            resolve();
                        } else {
                            const errors = response.getError();
                            let errorMessage = 'Unknown error';
                            if (errors && errors[0] && errors[0].message) {
                                errorMessage = errors[0].message;
                            }
                            console.error('Upload failed:', errorMessage);
                            reject(new Error(errorMessage));
                        }
                    });
                    
                    $A.enqueueAction(action);
                } catch(e) {
                    console.error('Error in onload callback:', e);
                    reject(e);
                }
            });
            
            reader.onerror = $A.getCallback(() => {
                console.error('Error reading file: ' + file.name);
                reject(new Error('Error reading file: ' + file.name));
            });
            
            reader.readAsDataURL(file);
        });
    },
    attachScrollListener: function() {
    setTimeout(function() {
        var modalContent = document.getElementById('modal-content');
        if (modalContent) {
            modalContent.addEventListener('scroll', function() {
                var openDropdowns = document.querySelectorAll('.slds-is-open');
                openDropdowns.forEach(function(dropdown) {
                    dropdown.classList.remove('slds-is-open');
                });
            });
        }
    }, 300);
},
    finishSave: function(component) {
        component.set("v.isLoading", false);
        this.showToast('Success', 'Inspection and Snags saved successfully!', 'success');
        // Refresh the page
        $A.get('e.force:refreshView').fire();
        // Close the modal
        this.closeModal(component);
    }
})