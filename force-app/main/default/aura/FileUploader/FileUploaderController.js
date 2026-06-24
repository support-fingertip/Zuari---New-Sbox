({
    handleUploadFinished : function(component, event, helper) {
        var uploadedFiles = event.getParam("files");

        if (uploadedFiles && uploadedFiles.length > 0) {
            var docId   = uploadedFiles[0].documentId;
            var action  = component.get("c.markDocumentForType");
var tt = 'testt';
            action.setParams({
                recordId: component.get("v.parentId"),
                docType: component.get("v.docType"),
                fileName:tt,
                contentDocumentId: docId
            });

            action.setCallback(this, function(response) {
                // We ignore errors here for simplicity, but you can add toast if needed
                var appEvt = $A.get("e.c:FileUploadCompleteEvent");
                if (appEvt) {
                    appEvt.fire();
                }
            });

            $A.enqueueAction(action);
        }
    }
});