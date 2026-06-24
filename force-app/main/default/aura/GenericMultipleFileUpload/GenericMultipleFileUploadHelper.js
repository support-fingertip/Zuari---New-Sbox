({
    fetchUploadedFiles: function(component, recordId, selectedValue) {
        var action = component.get("c.getMultiFiles");
        
        action.setParams({
            recordId: recordId,
            fileName: selectedValue || '' 
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.contentDocIds",result);
                console.log('uploaded FIles '+ JSON.stringify(result));
            } else {
                console.log("Error fetching files: " + response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    uploadFiles: function(component, event, helper, files){
        var self = this;
        Array.from(files).forEach((file,index) => {
            var readFile = new FileReader();
            readFile.onload = $A.getCallback(function() {
            var fileData = readFile.result;
            fileData = fileData.substring(fileData.indexOf('base64,') + 'base64,'.length)
            self.insertDocuments(component, event, helper, fileData, file);
        });
        readFile.readAsDataURL(file);
    });
},
 insertDocuments: function(component, event, helper, fileData, file){
    $A.util.removeClass(component.find("mySpinner"),"slds-hide");
    let ispicklistActive =  component.get('v.showPicklist');
    var parentId = component.get("v.recordId");
    var documentName = ispicklistActive == true? component.get("v.sectionName") +'-'+ component.get("v.selectedDocumentName"): component.get("v.sectionName");
    console.log('documentName'+documentName);
    var size = file.size;
    var actualFileName = documentName && documentName.trim() !== '' ?  documentName : file.name;
    var fileName = file.name;
    var fileType = file.type; 
    var action1  = component.get("c.multifileUpload");
    action1.setParams({
        'parentId': parentId,
        'name': fileName,
        'fileType': fileType,
        'fileData': fileData,
        'documentName':actualFileName,
        'isPicklist':ispicklistActive
    });
    action1.setCallback(this, function(response){
        var state = response.getState();
        $A.util.addClass(component.find("mySpinner"),"slds-hide");
        if(state === 'SUCCESS'){
            var result = response.getReturnValue();
            if(!$A.util.isEmpty(result) && !$A.util.isUndefinedOrNull(result)){
                var contentDocIds = component.get("v.contentDocIds");
                 console.log('contentDocIds '+JSON.stringify(contentDocIds));
                contentDocIds.push(result);
                component.set("v.contentDocIds",contentDocIds);
                var emptyFiles = [];
                component.find("fileUpload").set("v.files",null);
                component.set("v.fileName",emptyFiles);
                this.showToast(component, 'success','Document Inserted Successfully');
                this.fetchUploadedFiles(component, parentId, documentName);
                $A.get('e.force:refreshView').fire();
            }
            else{
                this.showToast(component, 'error','Something went wrong, Not able to fetch ContentDocumentId');
            }
        }else {
                // Handle the error case
                var errors = response.getError();
                if (errors && errors.length > 0) {
                    // Iterate through the errors and display them
                    var errorMessage = "Unknown error";  // Default message in case of unexpected errors
                    for (var i = 0; i < errors.length; i++) {
                        if (errors[i] && errors[i].message) {
                            errorMessage = errors[i].message;  // Get the error message from the response
                            break;  // You can exit after finding the first error message
                        }
                    }
                    this.showToast(component, 'error', errorMessage); // Show the error message in a toast
                } else {
                    this.showToast(component, 'error', 'Unknown error occurred');
                }
            }
    });
    $A.enqueueAction(action1);
},
    showToast: function(cmp, type, message){
        var notification = $A.get("e.force:showToast");
        notification.setParams({
            message: message,
            duration: '1000',
            type: type,
            mode: 'pester'
        });
        notification.fire();
    }
})