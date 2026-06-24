({
    addNote: function(component, event, helper) {
        var leadId = component.get("v.recordId");
        var newNote = component.get("v.newNote");
        
        if (!newNote || !newNote.trim()) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please enter comments.",
                "type": "error"
            });
            toastEvent.fire();
            return; 
        }
        
        var action = component.get("c.updateTLRHSNote");
        action.setParams({
            "leadId": leadId,
            "newNote": newNote
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                var responseValue = response.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Note added successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "An error occurred while adding the note.",
                    "type": "error"
                });
                toastEvent.fire();
            }
        });
        
        $A.enqueueAction(action);
    },
    doCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
    
})