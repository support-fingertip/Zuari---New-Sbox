({
    close: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    doInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
    console.log("Booking Record Id:", recordId);
        var action = component.get("c.getBookingDetails"); // Updated to use correct method to fetch booking details
        action.setParams({
            recordId: recordId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var booking = response.getReturnValue();
                if (!booking) {
                    console.error("Booking data is missing!");
                    return;
                }
                component.set("v.bookingRecord", booking);
               console.log("Booking JSON:", JSON.stringify(booking));
            } else {
                console.error("Failed to fetch booking details:", response.getError());
            }
        });

        $A.enqueueAction(action);
    },

    send: function(component, event, helper) {
        console.log("enterd into send");
        var booking = component.get("v.bookingRecord");
        console.log("Booking:",JSON.stringify(booking));
        //  Check if booking OR Possession Date is empty
        if (!booking || !booking.Possession_Date__c || booking.Possession_Date__c === '') {
            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Missing Possession Date",
                message: "Please provide the Possession Date before sending the certificate.",
                type: "warning",
                mode: "dismissible"
            });
            toastEvent.fire();
            
            return; // Stop execution
        }
         console.log("Possession Date exists:", booking.Possession_Date__c);

        var action = component.get("c.sendEmailToCustomer");
        action.setParams({
            "recId": component.get("v.recordId"),
            "pdfType": "PC"
        });

        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
                var res_string = response.getReturnValue();
                event.stopPropagation();
                $A.get("e.force:closeQuickAction").fire();
                var type = (res_string === 'sent to customer') ? 'Success' : 'error';
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type,
                    "message": 'Possession Certificate Sent Successfully',
                    "duration": 10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            } else {
                console.log('Email sending failed.');
            }
        });

        $A.enqueueAction(action);
    }
})