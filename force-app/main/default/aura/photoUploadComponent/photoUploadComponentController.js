({
    doInit : function(component, event, helper){  
       helper.getUploadedFiles(component, event);
      //alert(component.get('v.recordId'));
    },      
    
    previewFile : function(component, event, helper){  
        $A.get('e.lightning:openFiles').fire({ 
            recordIds: [event.currentTarget.id]
        });  
    },  
    
    uploadFinished : function(component, event, helper) {  
        var uploadedFiles = event.getParam("files");
        var allFiles = component.get('v.files');
        allFiles.push(...uploadedFiles);
        component.set('v.files', allFiles);
        var contentDocumentIds = allFiles.map(file => file.documentId);
        helper.getUploadedFiles(component,helper,contentDocumentIds);    
        
        var fileUploadEvent = component.getEvent("fileUploadEvent");
        fileUploadEvent.setParams({ "files": contentDocumentIds });
        fileUploadEvent.fire();
        var toastEvent = $A.get("e.force:showToast");
        // show toast on file uploaded successfully 
        toastEvent.setParams({
            "message": "Files have been uploaded successfully!",
            "type": "success",
            "duration" : 2000
        });
        toastEvent.fire();
    }, 
    
    deleteSelectedFile : function(component, event, helper){
        if( confirm("Confirm deleting this file?")){
            component.set("v.showSpinner", true); 
            helper.deleteUploadedFile(component, event);                
        }
    }
 })