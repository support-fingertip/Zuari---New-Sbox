({
    doInit : function(component, event, helper) {
        var record = component.get("v.LeadRecord");
        if(record.Project_Name__c != null) {
            component.set("v.projectName", record.Project_Name__c);
        }
    },
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    sendEmail: function(component, event, helper) {
        var action = component.get("c.sendEmailToCustomer");
        action.setParams({
            "recId": component.get("v.recordId"),
            "pdfType": 'Allotment Letter'
        });
        action.setCallback(this, function(response) {
            if(response.getState() == 'SUCCESS') {
                var res_string = response.getReturnValue();
                event.stopPropagation();
                $A.get("e.force:closeQuickAction").fire();
                var type = (res_string == 'sent to customer') ? 'success' : 'error';
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type,
                    "message": 'Allotment Letter Sent Successfully',
                    "duration": 10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            } else {
                console.log('failed');
            }
        });
        $A.enqueueAction(action);
    },
})