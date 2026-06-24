({
    doInit : function(component, event, helper) {
        var action = component.get("c.getMilestoneDetails");
        action.setParams({
            milestoneId : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                var result = response.getReturnValue();

                if (!result.completedDate) {
                    $A.get("e.force:closeQuickAction").fire();
                    setTimeout(function() {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : "Error",
                            message : "Please enter the Completion Date before generating the document.",
                            type : "error",
                            mode : "dismissible"
                        });
                        toastEvent.fire();
                    }, 300);
                    return;
                }

                var milestoneId = component.get("v.recordId");
                var pdfUrl = "/apex/Milestone_Completed_Form?id=" + milestoneId;

                component.set("v.pdfUrl", pdfUrl);
                component.set("v.showPreview", true);

            } else {
                $A.get("e.force:closeQuickAction").fire();
                setTimeout(function() {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : "Error",
                        message : "Something went wrong. Please try again.",
                        type : "error",
                        mode : "dismissible"
                    });
                    toastEvent.fire();
                }, 300);
            }
        });

        $A.enqueueAction(action);
    },

    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})