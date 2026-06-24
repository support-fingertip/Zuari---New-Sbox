({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var sectionName = component.get("v.sectionName");
        let activePicklist = component.get('v.showPicklist');
        
        if(activePicklist){
            let commaSeparatedValues = component.get('v.picklistValues');
            
            // Convert to array and format for lightning:combobox
            let picklistOptions = commaSeparatedValues.split(',').map(value => {
                return { label: value.trim(), value: value.trim() };
                                                                      });
            
            picklistOptions.unshift({ label: "All", value: "" ,selected:true});
            
            // Set the formatted picklist values in component
            component.set("v.picklistValues", picklistOptions);
        }
        
        if (recordId) {
            if (sectionName && sectionName !== '' && !activePicklist) {
                helper.fetchUploadedFiles(component, recordId, sectionName);
            }
            else{
                helper.fetchUploadedFiles(component, recordId, '');
            }
        }
    },
    
    handleChange: function(component, event, helper) {
        let selectedValue = event.getParam("value");
        var recordId = component.get("v.recordId");
        component.set("v.selectedDocumentName",selectedValue);
        if (recordId) {
            if (selectedValue && selectedValue !== '') {
                helper.fetchUploadedFiles(component, recordId, component.get("v.sectionName") +'-'+ component.get("v.selectedDocumentName"));
            } else {
                helper.fetchUploadedFiles(component, recordId,'');
            }
        }
    },
    downloadFile : function(component, event, helper) {
        var fileDownloadUrl = event.getSource().get("v.name");
        
        // Open the file download URL in a new tab
        window.open(fileDownloadUrl, "_blank");
    },
    
    deleteFile : function(component, event, helper) {
        var fileId = event.getSource().get("v.name");
        var contentDocIds = component.get("v.contentDocIds");
        console.log('fileId '+fileId);
        // Call the server-side method to delete the file
        var action = component.get("c.deleteFileFromSalesforce");
        action.setParams({ fileId: fileId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Remove the file from the component's state
                var newContentDocIds = contentDocIds.filter(function(file) {
                    return file.fileId !== fileId;
                });
                component.set("v.contentDocIds", newContentDocIds);
            }
        });
        $A.enqueueAction(action);
    },
    filesChangeHandler: function(component, event, helper){
        var files = component.find("fileUpload").get("v.files");
        var fileName = [];
        Array.from(files).forEach((file,index) => {
            fileName.push(file.name);
        });
            component.set("v.fileName",fileName);
        },
            uploadFiles: function(component, event, helper){
                $A.util.removeClass(component.find("mySpinner"),"slds-hide"); 
                var files = component.find("fileUpload").get("v.files");
                if(!$A.util.isEmpty(files) && !$A.util.isUndefinedOrNull(files)){
                    if(files.length > 0){
                        helper.uploadFiles(component, event, helper, files);
                    }
                    else{
                        $A.util.addClass(component.find("mySpinner"),"slds-hide"); 
                        helper.showToast(component, 'error', 'Please Select File to Upload')
                    }
                }
                else{
                    $A.util.addClass(component.find("mySpinner"),"slds-hide"); 
                    helper.showToast(component, 'error', 'Please Select File to Upload');         
                }
            }
            
        })