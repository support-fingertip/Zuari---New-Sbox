({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log('recordId :' + recordId);
        
        // FIX 1: Read from picklistValues (String), write formatted options to picklistOptions (List)
        let commaSeparatedValues = component.get('v.picklistValues');
        
        // FIX 2: Guard against picklistValues being null/undefined/empty
        if (!commaSeparatedValues || typeof commaSeparatedValues !== 'string') {
            console.warn('picklistValues is empty or not a string');
            component.set("v.picklistOptions", [{ label: "All", value: "" }]);
        } else {
            // Convert to array and format for lightning:combobox
            let picklistOptions = commaSeparatedValues.split(',').map(value => {
                return { label: value.trim(), value: value.trim() };
            });
            picklistOptions.unshift({ label: "All", value: "" });
            // FIX 3: Set picklistOptions (List), not picklistValues (String)
            component.set("v.picklistOptions", picklistOptions);
        }
        
        var documentName = component.get("v.selectedDocumentName");
        console.log('documentName :' + documentName);
        
        if (recordId) {
            helper.fetchUploadedFiles(component, recordId, documentName || '');
        }
    },
    
    handleChange: function(component, event, helper) {
        let selectedValue = event.getParam("value");
        var recordId = component.get("v.recordId");
        console.log('selectedValue: ' + selectedValue);
        component.set("v.selectedDocumentName", selectedValue);
        
        if (recordId) {
            helper.fetchUploadedFiles(component, recordId, selectedValue || '');
        }
    },
    
    filesChangeHandler: function(component, event, helper){
        var files = component.find("fileUpload").get("v.files");
        var fileName = [];
        
        if (files && files.length > 0) {
            Array.from(files).forEach((file) => {
                fileName.push(file.name);
            });
        }
        
        component.set("v.fileName", fileName);
    },
    
    uploadFiles: function(component, event, helper){
        $A.util.removeClass(component.find("mySpinner"), "slds-hide"); 
        var files = component.find("fileUpload").get("v.files");
        
        if (!$A.util.isEmpty(files) && !$A.util.isUndefinedOrNull(files)) {
            if (files.length > 0) {
                helper.uploadFiles(component, event, helper, files);
            } else {
                $A.util.addClass(component.find("mySpinner"), "slds-hide"); 
                helper.showToast(component, 'error', 'Please Select File to Upload');
            }
        } else {
            $A.util.addClass(component.find("mySpinner"), "slds-hide"); 
            helper.showToast(component, 'error', 'Please Select File to Upload');         
        }
    },
    
    handleUploadFinished : function(component, event, helper) {
        var uploadedFiles = event.getParam("files");
        var selectedDocType = component.get("v.selectedDocumentName");
        
        if (!uploadedFiles || uploadedFiles.length === 0) {
            helper.showToast(component, 'error', 'No files uploaded');
            return;
        }
        
        // Validate document type is selected
        if (!selectedDocType || selectedDocType.trim() === '') {
            helper.showToast(component, 'error', 'Please select a document type first');
            return;
        }
        
        var docId = uploadedFiles[0].documentId;
        var action = component.get("c.markDocumentForType");
        
        action.setParams({
            recordId: component.get("v.recordId"),
            docType: 'Document',
            fileName: selectedDocType,
            contentDocumentId: docId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.showToast(component, 'success', 'File uploaded successfully');
                
                // Fire custom event if it exists
                var appEvt = $A.get("e.c:FileUploadCompleteEvent");
                if (appEvt) {
                    appEvt.fire();
                }
                
                // FIX 4: Refresh file list INSIDE callback so rename is complete before fetching
                var recordId = component.get("v.recordId");
                var selectedValue = component.get("v.selectedDocumentName");
                helper.fetchUploadedFiles(component, recordId, selectedValue || '');
                
                $A.get('e.force:refreshView').fire();
            } else {
                // FIX 5: Log errors for easier debugging
                var errors = response.getError();
                var errorMsg = errors && errors[0] && errors[0].message ? errors[0].message : 'Error updating document type';
                console.error('markDocumentForType failed:', JSON.stringify(errors));
                helper.showToast(component, 'error', errorMsg);
            }
        });
        
        $A.enqueueAction(action);
    }
})