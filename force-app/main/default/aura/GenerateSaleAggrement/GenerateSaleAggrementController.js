({
    doInit : function(component, event, helper) {
        let baseUrl = window.location.origin;
        var action = component.get("c.getBookingDetails");
        action.setParams({recordId :component.get("v.recordId") });     
        action.setCallback(this,function(response){   
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                var booking = result.booking;
                
                if (!booking) {
                    console.error("Booking data is missing!");
                    return;
                }
                component.set("v.bookingRecord", result.booking);
                // Check if booking fields exist, else assign default values
                var project = booking.Project1__r.Name ? booking.Project1__r.Name : "N/A";
                var unit = booking.Plot__r.Name ? booking.Plot__r.Name : "N/A";
                
                // Construct customer name safely
                var customerName = result.customerNames;                
                var defaultEmailContent = "<div style='color: black;'><strong>Dear Sir/Madam,</strong><br/><br/>" +
                    "Greetings from Zuari.<br/>" +
                    "We are pleased to send you the sale agreement document concerning Plot/Unit No."+ unit +" at Zuari "+ project +" Please find the attached document for your review and signature.<br/>" +
                    "We kindly request you to review the document for finalizing the agreement at your earliest convenience. Your prompt action will help us proceed without further delay.<br/>" +
                    "Please treat this as an urgent matter and confirm the agreement date as soon as possible.<br/>" + 
                    "<p>Should you need any assistance or further clarification, please feel free to reach out. We are here to help.</p>" +
                    "<p>Thank you for your immediate attention to this matter.</p>" +
                    "<p>Warm regards,</p>" +
                    "<p>Zuari Infraworld India Ltd.</p>"+
                    "</div>";
                
                component.set("v.emailContent", defaultEmailContent);
                
                if (!component.get("v.recordId")) {
                    console.error("Record ID is missing!");
                    return;
                }
                
                // Construct VF Page URL safely
                let url = baseUrl + '/apex/SaleAgreement?id=' + component.get("v.recordId");
                component.set("v.vfPageUrl", url);
                
            }
        });
        $A.enqueueAction(action);
    },
    sendtoCustomer: function (component, event, helper) {
        console.log('Initiating email dispatch process...');
        
        var booking = component.get("v.bookingRecord");
        if (!booking || !booking.Agreement_Executed_Date__c) {
            var toastEvent = $A.get("e.force:showToast");
            if (toastEvent) {
                toastEvent.setParams({
                    title: "Missing Field",
                    message: "Please provide the Agreement Executed Date before proceeding with the email dispatch.",
                    type: "warning",
                    mode: "dismissible"
                });
                toastEvent.fire();
            }
            return;
        }
        
        // Prepare action to call Apex method
        var action = component.get("c.sendEmailGenerateSA");
        var emailContent = component.get("v.emailContent");
        
        action.setParams({
            recId: component.get("v.recordId"),
            emailContent: emailContent
        });
        
        // Handle callback from server
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('Apex response state:', state);
            
            if (state === "SUCCESS") {
                var resultMessage = response.getReturnValue();
                console.log('Apex response message:', resultMessage);
                
                // Close the quick action panel if it exists
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                if (dismissActionPanel) {
                    dismissActionPanel.fire();
                }
                
                // Determine toast type
                var toastType = resultMessage === 'Email sent successfully' ? 'success' : 'error';
                
                // Show toast notification
                var toastEvent = $A.get("e.force:showToast");
                if (toastEvent) {
                    toastEvent.setParams({
                        type: toastType,
                        title: toastType === 'success' ? 'Success' : 'Error',
                        message: resultMessage,
                        duration: 10000
                    });
                    toastEvent.fire();
                }
                
                // Refresh view
                $A.get('e.force:refreshView').fire();
                
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.error('Apex error:', errors);
                
                var toastEvent = $A.get("e.force:showToast");
                if (toastEvent) {
                    toastEvent.setParams({
                        type: 'error',
                        title: 'Error',
                        message: errors && errors[0] && errors[0].message ? errors[0].message : 'Unknown error',
                        duration: 10000
                    });
                    toastEvent.fire();
                }
            }
        });
        
        // Enqueue action to run
        $A.enqueueAction(action);
    },
    
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
    handleClick : function (cmp, event, helper) {
        var buttonstate = cmp.get('v.buttonstate');
        cmp.set('v.buttonstate', !buttonstate);
    }
})