({
    doInit : function(component, event, helper) {
          var ldid = component.get("v.recordId");
        component.set("v.leadRecID",ldid);
        component.set("v.callComp",true);
      
        
        /*
        var action = component.get("c.clickToCallNumber");
        action.setParams({ 'recordId' : component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var successFlag = response.getReturnValue(); // boolean

                if (successFlag === true) {
                    var recId = component.get("v.recordId");
                    component.set("v.leadRecID", recId);
                    component.set("v.callComp", true);
                    console.log("Call initiated for Lead ID: " + recId);

                    // close quick action if you don’t want to keep popup
                    helper.closeQuickAction(component, event);

                } else {
                    var toast = $A.get("e.force:showToast");
                    toast.setParams({
                        "title": "Error",
                        "type": "error",
                        "message": "Call could not be initiated from server."
                    });
                    toast.fire();
                    helper.closeQuickAction(component, event);
                }

            } else if (state === "ERROR") {
                var errors = response.getError();
                var errorMessage = "Unknown error, contact your system admin";
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                    console.log("Apex Error: " + errorMessage);
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "type": "error",
                    "message": errorMessage
                });
                toastEvent.fire();
                helper.closeQuickAction(component, event);
            }
        });
        $A.enqueueAction(action);
        
        */
    }
})