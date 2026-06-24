({ 
    doInit : function(component, event, helper) {
        
    
    },
     handleSwap : function(component, event, helper) {
          var reason = component.get("v.reason");

        if (!reason || reason.trim() === '') {
            var toast = $A.get("e.force:showToast");
            toast.setParams({
                title: "Error",
                message: "Please enter a date before submitting.",
                type: "error"
            });
            toast.fire();
            return;
        }
          var action = component.get("c.requestSwapApproval");
        action.setParams({
            bookingId : component.get("v.recordId"),
            reason    : reason
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {

                var toast = $A.get("e.force:showToast");
                toast.setParams({
                    title: "Success",
                    message: "Approval submitted successfully.",
                    type: "success"
                });
                toast.fire();

        $A.get("e.force:closeQuickAction").fire();
                $A.get("e.force:refreshView").fire();
            } 
            else {
                var errors = response.getError();
                var message = errors && errors[0] && errors[0].message 
                                ? errors[0].message 
                                : "Unknown error";

                var toast = $A.get("e.force:showToast");
                toast.setParams({
                    title: "Error",
                    message: message,
                    type: "error"
                });
                toast.fire();
            }
        });

        $A.enqueueAction(action);
    },
    doCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})