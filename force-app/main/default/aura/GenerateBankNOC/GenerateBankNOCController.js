({
    doInit : function(component, event, helper) {
        component.set("v.bankName", component.get("v.LeadRecord").Bank_Name__c);
        if(component.get("v.LeadRecord").Bank_Name__c == null){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type":'Error',
                "title": 'Error!',
                "message":'Please Select Bank Name',
                "duration":10000
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
        }
        component.set("v.projectName", component.get("v.LeadRecord").Project__c);
    },
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    sendEmail: function (component, event, helper) {
        var action = component.get("c.sendEmailToCustomerNOC");
        var bookingRecordId = component.get("v.recordId");
        action.setParams({ "recId": component.get("v.recordId")
                         });  
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": 'Bank NOC',
                    "message": 'NOC Draft sent to bank successfully.',
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