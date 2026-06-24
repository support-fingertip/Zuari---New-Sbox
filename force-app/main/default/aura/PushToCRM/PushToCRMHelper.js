({
    pushToSales : function(component) {
        var rec = component.get("v.bookingRec");

        // Signature check
        if (!rec || rec.Booking_Form_Signature_Uploaded__c !== true) {
            $A.get("e.force:showToast").setParams({
                title: "Blocked",
                message: "Please Upload Booking Form Signature.",
                type: "error"
            }).fire();
            $A.get("e.force:closeQuickAction").fire();
            return;
        }

        // Approval check
        if (rec.Approval_yes_or_No__c !== true) {
            $A.get("e.force:showToast").setParams({
                title: "Blocked",
                message: "Booking amount not approved.",
                type: "error"
            }).fire();
            $A.get("e.force:closeQuickAction").fire();
            return;
        }

        var action1 = component.get("c.moveToCRMPreCheck");
        action1.setParams({ bookingId: component.get("v.recordId") });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result == 0) {
                    var action = component.get("c.moveToCRM");
                    action.setParams({ bookingId: component.get("v.recordId") });
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === 'SUCCESS') {
                            var result = response.getReturnValue();
                            if (result === 'Please update mandatory checkbox') {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    message: result,
                                    type: 'error'
                                });
                                toastEvent.fire();
                                $A.get("e.force:closeQuickAction").fire();
                            } else {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    message: 'Booking moved to CRM head successfully',
                                    type: 'success'
                                });
                                toastEvent.fire();
                                $A.get("e.force:closeQuickAction").fire();
                                $A.get('e.force:refreshView').fire();
                            }
                        } else if (state === 'ERROR') {
                            var errors = response.getError();
                            var message = 'Unknown error';
                            if (errors && Array.isArray(errors) && errors.length > 0) {
                                message = errors[0].message;
                            }
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                message: message,
                                type: 'error'
                            });
                            toastEvent.fire();
                        }
                    });
                    $A.enqueueAction(action);
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        message: 'Upload Necessary Documents',
                        type: 'error'
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message: message,
                    type: 'error'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action1);
    }
})