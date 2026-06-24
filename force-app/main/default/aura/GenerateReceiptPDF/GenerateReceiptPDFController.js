({
	doInit : function(component, event, helper) {
		//component.set("v.projectName", component.get("v.LeadRecord").Project__c);
	},
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    sendEmail: function (component, event, helper) {
        var action = component.get("c.sendReceiptToCustomer");
    //    var bookingRecordId = component.get("v.recordId");
        action.setParams({ "Receiptid": component.get("v.recordId")
                         });  
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": 'Receipt',
                    "message": 'Receipt sent to customer successfully.',
                    "duration": 10000
                });
                toastEvent.fire();
                
            } else {
                console.log('Failed to send email.');
            }
        });
        $A.enqueueAction(action);
    },
})