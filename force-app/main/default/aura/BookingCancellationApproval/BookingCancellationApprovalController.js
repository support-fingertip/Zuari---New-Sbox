({
    saveCancellationDetails : function(component, event, helper) {
        var isValid = true;

        // Get all mandatory fields
        var allFields = component.find("mandateFields");

        if(Array.isArray(allFields)){
            allFields.forEach(function(field){
                if(!field.get("v.value")){
                    field.showHelpMessageIfInvalid();
                    isValid = false;
                }
            });
        } else {
            if(!allFields.get("v.value")){
                allFields.showHelpMessageIfInvalid();
                isValid = false;
            }
        }

        if(!isValid){
            return; // stop save if any mandatory field is empty
        }

        // Proceed with Apex call
        var action = component.get("c.sendCancellationApproval");  
        action.setParams({
            'recId': component.get('v.recordId'),
            'cancellationReason' : component.get('v.cancellationReason'),
            'cancellationRemarks' : component.get('v.cancellationRemarks'),
            'cancellationCharges' : component.get('v.cancellationCharges')
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The Request submitted for Booking Cancellation.",
                    "type":"success"
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    }
})