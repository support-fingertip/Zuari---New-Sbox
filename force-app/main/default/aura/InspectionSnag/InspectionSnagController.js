({
    doInit: function(component, event, helper) {
        const today = new Date().toISOString().split('T')[0];
        component.set("v.inspectionDate", today);
        
        component.set("v.snagRows", [{
            'sobjectType': 'Snag_List__c',
            'Description__c': '',
            'Status__c': 'Open',
            'Priority__c': 'Medium',
            'Inspection_Type__c':'',
            'selectedFiles': []
        }]);
        
        // Add this line after setting snagRows
helper.attachScrollListener();
    },
    

handleScroll: function(component, event, helper) {
    var openDropdowns = document.querySelectorAll('.slds-combobox.slds-is-open');
    openDropdowns.forEach(function(el) {
        el.classList.remove('slds-is-open');
    });
},
    
    addSnagRow: function(component, event, helper) {
        let snagRows = component.get("v.snagRows");
        let sno = snagRows.length + 1;
        
        snagRows.push({
            'sobjectType': 'Snag_List__c',
            'Description__c': '',
            'Status__c': 'Open',
            'Priority__c': 'Medium',
            'Inspection_Type__c':'',
            'S_No__c': sno,
            'selectedFiles': []
        });
        component.set("v.snagRows", snagRows);
    },
    
    deleteSnagRow: function(component, event, helper) {
        const index = parseInt(event.getSource().get("v.value"));
        let snagRows = component.get("v.snagRows");
        
        if (snagRows.length === 1) {
            helper.showToast('Warning', 'At least one snag must be present', 'warning');
            return;
        }
        
        snagRows.splice(index, 1);
        
        snagRows.forEach(function(snag, idx) {
            snag.S_No__c = idx + 1;
        });
        
        component.set("v.snagRows", snagRows);
    },
    
    handleSnagChange: function(component, event, helper) {
        var source = event.getSource();
        var index = parseInt(source.get("v.data-index")); 
        var fieldName = source.get("v.name");
        var value = source.get("v.value");
        var snagRows = component.get("v.snagRows");
        
        if (snagRows && snagRows.length > index) {
            if (fieldName === 'description') {
                snagRows[index]['Description__c'] = value;
            } else if (fieldName === 'status') {
                snagRows[index]['Status__c'] = value;
            } else if (fieldName === 'priority') {
                snagRows[index]['Priority__c'] = value;
            } else if (fieldName === 'inspec') {
                snagRows[index]['Inspection_Type__c'] = value;
            }
            component.set("v.snagRows", snagRows);
        }
    },
    
    handleFileChange: function(component, event, helper) {
        console.log('=== handleFileChange called ===');
        const input = event.target || event.getSource().getElement();
        const index = parseInt(input.dataset.index);
        const files = input.files;
        
        console.log('Index:', index);
        console.log('Files selected:', files ? files.length : 0);
        
        if (!files || files.length === 0) {
            console.log('No files selected');
            return;
        }
        
        let snagRows = component.get("v.snagRows");
        console.log('Current snagRows count:', snagRows ? snagRows.length : 0);
        
        if (snagRows && snagRows.length > index) {
            // Initialize selectedFiles array if needed
            if (!snagRows[index].selectedFiles) {
                snagRows[index].selectedFiles = [];
                console.log('Initialized selectedFiles array for snag', index);
            }
            
            // Process each file
            let filesAdded = 0;
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                console.log('Processing file:', file.name, 'Size:', file.size, 'Type:', file.type);
                
                // Check if file already exists
                const exists = snagRows[index].selectedFiles.some(f => f.name === file.name);
                if (!exists) {
                    // Store the actual file object
                    snagRows[index].selectedFiles.push({
                        name: file.name,
                        size: file.size,
                        type: file.type,
                        file: file  // Store actual file reference
                    });
                    filesAdded++;
                    console.log('File added:', file.name);
                } else {
                    console.log('File already exists, skipping:', file.name);
                }
            }
            
            // Update component state
            component.set("v.snagRows", snagRows);
            
            console.log('Total files for snag', index + ':', snagRows[index].selectedFiles.length);
            console.log('Files added this time:', filesAdded);
            
            if (filesAdded > 0) {
                helper.showToast('Success', filesAdded + ' file(s) selected', 'success');
            }
        } else {
            console.error('Invalid index or snagRows not found. Index:', index, 'SnagRows length:', snagRows ? snagRows.length : 0);
        }
    },
    
    removeFile: function(component, event, helper) {
        const button = event.getSource();
        const value = button.get("v.value");
        const indices = value.split('-');
        const snagIndex = parseInt(indices[0]);
        const fileIndex = parseInt(indices[1]);
        
        let snagRows = component.get("v.snagRows");
        
        if (snagRows && snagRows.length > snagIndex && snagRows[snagIndex].selectedFiles) {
            snagRows[snagIndex].selectedFiles.splice(fileIndex, 1);
            component.set("v.snagRows", snagRows);
            
            // Reset the file input element if all files are removed
            if (snagRows[snagIndex].selectedFiles.length === 0) {
                const fileInput = document.getElementById('fileInput_' + snagIndex);
                if (fileInput) {
                    fileInput.value = '';
                }
            }
        }
    },
    
    saveInspection: function(component, event, helper) {
        console.log('=== saveInspection called ===');
        
        const inspectionDate = component.get("v.inspectionDate");
        const inspectionDescription = component.get("v.inspectionDescription");
        
        if (!inspectionDate || !inspectionDescription) {
            helper.showToast('Error', 'Please fill in all Inspection details', 'error');
            return;
        }
        
        const snagRows = component.get("v.snagRows");
        console.log('Snag rows before save:', JSON.stringify(snagRows.map(s => ({
            Description: s.Description__c,
            Status: s.Status__c,
            Priority: s.Priority__c,
            fileCount: s.selectedFiles ? s.selectedFiles.length : 0,
            files: s.selectedFiles ? s.selectedFiles.map(f => f.name) : []
        }))));
        
        if (snagRows.length === 0) {
            helper.showToast('Error', 'Please add at least one snag', 'error');
            return;
        }
        
        let isValid = true;
        let errorMessage = '';
        
        snagRows.forEach((snag, index) => {
            if (!snag.Description__c || !snag.Status__c) {
            isValid = false;
                errorMessage = `Please fill in all fields for Snag #${index + 1}`;
                
            }
        });
        
        if (!isValid) {
            helper.showToast('Error', errorMessage, 'error');
            return;
        }
        
        component.set("v.isLoading", true);
        
        const snagListData = snagRows.map(snag => {
            return {
                Description__c: snag.Description__c,
                Status__c: snag.Status__c,
            Inspection_Type__c:snag.Inspection_Type__c,
                Priority__c: snag.Priority__c
            };
        });
        
        const action = component.get("c.saveInspectionWithSnags");
        action.setParams({
            bookingId: component.get("v.recordId"),
            inspectionDate: inspectionDate,
            inspectionDescription: inspectionDescription,
            snagListJson: JSON.stringify(snagListData)
        });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            console.log('Apex callback state:', state);
            
            if (state === "SUCCESS") {
                const result = JSON.parse(response.getReturnValue());
                console.log('Apex result:', result);
                const snagIds = result.snagIds;
                console.log('Snag IDs received:', snagIds);
                
                helper.uploadFilesForSnags(component, snagRows, snagIds);
                helper.closeModal(component);
            } else {
                component.set("v.isLoading", false);
                const errors = response.getError();
                let errorMessage = 'An error occurred while saving';
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                console.error('Apex error:', errorMessage);
                helper.showToast('Error', errorMessage, 'error');
            }
        });
        
        $A.enqueueAction(action);
    },
    
    
    
    closeModal: function(component, event, helper) {
        helper.closeModal(component);
    }
})