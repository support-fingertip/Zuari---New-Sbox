({
    addNote: function(component, event, helper) {
        var leadId = component.get("v.recordId");
        var newNote = component.get("v.newNote");
        
        if (!newNote || !newNote.trim()) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please enter characters in the 'Add Note' box.",
                "type": "error"
            });
            toastEvent.fire();
            return; 
        }
        
        var action = component.get("c.updateLastNote");
        action.setParams({
            "leadId": leadId,
            "newNote": newNote
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                var responseValue = response.getReturnValue();
                console.log('Server response:', responseValue);
                
                component.set('v.newNote', '');
                //component.set('v.lastNote', responseValue.Last_Note__c);
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Note added successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                
                var leadId1 = component.get("v.recordId");
                var action1 = component.get("c.fetchLeadLastNotes");
                
                action1.setParams({
                    "leadId": leadId1
                });
                
                action1.setCallback(this, function(a) {
                    component.set("v.ShowRecords", a.getReturnValue());
                });
                
                $A.enqueueAction(action1);
                
                
                //var dismissActionPanel = $A.get("e.force:closeQuickAction");
                //dismissActionPanel.fire();
                
                //window.location.reload();
                
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
    
    Clear: function(component, event, helper) {
        component.set("v.newNote",null);
    },
    
    DisplayNotes: function(component, event, helper) {
        var leadId = component.get("v.recordId");
        var action = component.get("c.fetchLeadLastNotes");
        
        action.setParams({
            "leadId": leadId
        });
        
        action.setCallback(this, function(a) {
            component.set("v.ShowRecords", a.getReturnValue());
        });
        
        $A.enqueueAction(action);
    }

})