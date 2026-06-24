({
    checkDemandStatus: function(component, event, helper) {
        var bookingId = component.get("v.recordId");
        
        var action = component.get("c.checkDemandedRaised");
        action.setParams({
            bookingId: bookingId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var isDemanded = response.getReturnValue();
                component.set("v.canRaiseDemand", isDemanded);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    console.log("Error message: " + errors[0].message);
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    showToast: function(message, type, title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    
})