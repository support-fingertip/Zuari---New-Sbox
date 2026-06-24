({
    fetchUploadedFiles: function(component, recordId, documentName) {
        console.log('Fetching files for: ' + documentName);
        
        var action = component.get("c.getMultiFiles");
        
        action.setParams({
            recordId: recordId,
            fileName: documentName || '' 
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.contentDocIds", result);
                console.log('Uploaded Files: ' + JSON.stringify(result));
            } else {
                console.log("Error fetching files: " + JSON.stringify(response.getError()));
                this.showToast(component, 'error', 'Error fetching uploaded files');
            }
        });
        
        $A.enqueueAction(action);
    },
    
    uploadFiles: function(component, event, helper, files){
        var self = this;
        Array.from(files).forEach((file, index) => {
            var readFile = new FileReader();
            readFile.onload = $A.getCallback(function() {
                var fileData = readFile.result;
                fileData = fileData.substring(fileData.indexOf('base64,') + 'base64,'.length);
                self.insertDocuments(component, event, helper, fileData, file);
            });
            readFile.readAsDataURL(file);
        });
    },
    
    insertDocuments: function(component, event, helper, fileData, file){
        $A.util.removeClass(component.find("mySpinner"), "slds-hide");
        var parentId = component.get("v.recordId");
        var documentName = component.get("v.selectedDocumentName");
        var fileName = file.name;
        var fileType = file.type; 
        
        // Use documentName if selected, otherwise use original filename
        var actualFileName = documentName && documentName.trim() !== '' ? documentName : file.name;
        
        var action1 = component.get("c.fileUpload");
        action1.setParams({
            'parentId': parentId,
            'name': fileName,
            'fileType': fileType,
            'fileData': fileData,
            'documentName': actualFileName,
        });
        
        action1.setCallback(this, function(response){
            var state = response.getState();
            $A.util.addClass(component.find("mySpinner"), "slds-hide");
            
            if(state === 'SUCCESS'){
                var result = response.getReturnValue();
                if(!$A.util.isEmpty(result) && !$A.util.isUndefinedOrNull(result)){
                    
                    // Mark document type
                    this.markDocumentType(component, parentId, documentName, result);
                    
                    var contentDocIds = component.get("v.contentDocIds") || [];
                    contentDocIds.push({
                        fileId: result,
                        title: actualFileName
                    });
                    component.set("v.contentDocIds", contentDocIds);
                    
                    var emptyFiles = [];
                    component.find("fileUpload").set("v.files", null);
                    component.set("v.fileName", emptyFiles);
                    
                    this.showToast(component, 'success', 'Document Inserted Successfully');
                    this.fetchUploadedFiles(component, parentId, documentName);
                    $A.get('e.force:refreshView').fire();
                }
                else{
                    this.showToast(component, 'error', 'Something went wrong, Not able to fetch ContentDocumentId');
                }
            }
            else{
                var errors = response.getError();
                if(errors){
                    var errorMsg = errors[0] && errors[0].message ? errors[0].message : 'Exception occurred';
                    this.showToast(component, 'error', errorMsg);
                }
            }
        });
        $A.enqueueAction(action1);
    },
    
    // Mark document type after upload
    markDocumentType: function(component, recordId, fileName, contentDocumentId) {
        var action = component.get("c.markDocumentForType");
        
        action.setParams({
            recordId: recordId,
            docType: 'Document',
            fileName: fileName,
            contentDocumentId: contentDocumentId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state !== "SUCCESS") {
                console.error('Error marking document type: ' + JSON.stringify(response.getError()));
            }
        });
        
        $A.enqueueAction(action);
    },
    
    showToast: function(cmp, type, message){
        var notification = $A.get("e.force:showToast");
        notification.setParams({
            message: message,
            duration: '3000',
            type: type,
            mode: 'dismissable'
        });
        notification.fire();
    }
})