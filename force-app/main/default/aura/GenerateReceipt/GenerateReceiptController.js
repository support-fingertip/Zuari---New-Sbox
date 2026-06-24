({
    doInit: function(component, event, helper) {
        // Get the base URL for the current window
        let baseUrl = window.location.origin;
        
        // Get the recordId from the component attribute
        var recordId = component.get("v.recordId");
        
        // Call the Apex method to get booking record
        var action = component.get("c.getBookingRecordViaReciept");
        action.setParams({ 
            recordId: component.get("v.recordId") 
        });
        
        // Set callback for the action
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                // Set the booking record in the component
                component.set("v.bookingRecord", response.getReturnValue());
                
                // Build the Visualforce page URL
                let vfPageUrl = baseUrl + '/apex/Receipt?Id=' + component.get("v.recordId");
                
                // Set the URL in the component
                component.set("v.vfPageUrl", vfPageUrl);
            } else if (state === 'ERROR') {
                // Handle any errors
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error("Error fetching booking record: " + errors[0].message);
                    }
                } else {
                    console.error("Unknown error");
                }
            }
        });
        
        // Enqueue the action
        $A.enqueueAction(action);
    },
    
    send: function(component, event, helper) {
        // Prevent multiple clicks - check if already sending
        if (component.get("v.isSending")) {
            return;
        }
        
        // Set sending state to true and disable buttons
        component.set("v.isSending", true);
        component.set("v.isButtonDisabled", true);
        
        // Call the Apex method to send email
        var action = component.get("c.sendEmailGenerateReceipt");
        
        // Set the parameter for the Apex method
        action.setParams({
            "receiptId": component.get("v.recordId")
        });
        
        // Set the callback function to handle the response
        action.setCallback(this, function(response) {
            // Re-enable buttons regardless of outcome
            component.set("v.isSending", false);
            component.set("v.isButtonDisabled", false);
            
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                // Retrieve the return value from the Apex method
                var resultString = response.getReturnValue();
                
                // Stop the event propagation
                event.stopPropagation();
                
                // Determine the toast type based on the response
                var toastType = resultString === 'Email sent successfully' ? 'success' : 'error';
                var toastTitle = toastType === 'success' ? 'Success' : 'Error';
                
                // Show toast notification
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": toastType,
                    "title": toastTitle,
                    "message": resultString,
                    "duration": 10000
                });
                toastEvent.fire();
                
                // Only close the modal and refresh if successful
                if (toastType === 'success') {
                    // Close the quick action panel
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    
                    // Refresh the view to reflect changes
                    $A.get('e.force:refreshView').fire();
                }
                
            } else if (state === 'ERROR') {
                // Handle error case
                var errors = response.getError();
                var errorMessage = "Failed to send email. Please try again.";
                
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                    console.error('Failed to send email: ', errors);
                }
                
                // Show error toast
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error",
                    "message": errorMessage,
                    "duration": 10000
                });
                toastEvent.fire();
            } else if (state === 'INCOMPLETE') {
                // Handle incomplete state
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "title": "Warning",
                    "message": "The request was incomplete. Please try again.",
                    "duration": 10000
                });
                toastEvent.fire();
            }
        });
        
        // Add a timeout as a safety net (optional)
        setTimeout($A.getCallback(function() {
            if (component.get("v.isSending")) {
                component.set("v.isSending", false);
                component.set("v.isButtonDisabled", false);
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "title": "Timeout",
                    "message": "The request is taking longer than expected. Please try again.",
                    "duration": 10000
                });
                toastEvent.fire();
            }
        }), 30000); // 30 second timeout
        
        // Enqueue the action to call the Apex method
        $A.enqueueAction(action);
    },
    
    close: function(component, event, helper) {
        // Only close if not currently sending
        if (!component.get("v.isSending")) {
            $A.get("e.force:closeQuickAction").fire();
        }
    }
})