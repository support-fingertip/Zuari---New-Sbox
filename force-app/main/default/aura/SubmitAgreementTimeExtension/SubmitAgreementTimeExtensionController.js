({
    handleApprovalSubmit : function(component, event, helper) {
        // Get the recordId from the component attribute
        var recordId = component.get("v.recordId");

        // Call the Apex method to trigger the approval process
        var action = component.get("c.agreementTimeEXtensionApproval");

        action.setParams({
            recordId: recordId,
        });

        // Handle the response from Apex
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Success, show success toast message
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success",
                    "message": "Approval Process submitted successfully.",
                    "type": "success"  // Type of toast (success, error, info, warning)
                });
                toastEvent.fire();
                 $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "ERROR") {
                // Error occurred, show error toast message
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": errors[0].message,
                        "type": "error"  // Type of toast (success, error, info, warning)
                    });
                    toastEvent.fire();
                }
                $A.get("e.force:closeQuickAction").fire();
            }
        });

        // Enqueue the action
        $A.enqueueAction(action);
    }
})