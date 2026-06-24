({
    doInit : function(component, event, helper) {
        var record = component.get("v.LeadRecord");
        if (record && record.Project1__r && record.Project1__r.Name === 'Zuari Gangothri Tribhuja') {
            component.set("v.vfPageName", "ZGT_statement_Of_Accounts");
        } else {
            component.set("v.vfPageName", "Customer_Statement");
        }
    },
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    sendEmail: function (component, event, helper) {
        var action = component.get("c.sendReceiptToCustomer");
        var recordId = component.get("v.recordId");
        action.setParams({ "BookingId": component.get("v.recordId")});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": 'Receipt',
                    "message": 'Statement Of Accounts sent to customer successfully.',
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