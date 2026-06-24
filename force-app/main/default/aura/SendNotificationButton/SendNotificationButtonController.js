({
	doInit : function(component, event, helper) {
         var action = component.get("c.sendNotification");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        
         action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get("e.force:showToast").setParams({
                    title: "Success",
                    message: "Notification sent!",
                    type: "success"
                }).fire();
                $A.get("e.force:closeQuickAction").fire();
            } else {
                console.error(response.getError());
                $A.get("e.force:showToast").setParams({
                    title: "Error",
                    message: "Failed to send notification.",
                    type: "error"
                }).fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });

        $A.enqueueAction(action);
		
	}
})