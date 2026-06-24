({
	doInit : function(component, event, helper) {
		component.set("v.projectName", component.get("v.LeadRecord").Project__c);
        if(component.get("v.LeadRecord").Project__c != 'Corner Stone' && component.get("v.LeadRecord").Project__c != 'Tamarind' && component.get("v.LeadRecord").Project__c != 'Treasure Trove'){
            component.set("v.isShowButton",false);
        }
	},
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    sendEmail: function (component, event, helper) {
        var action = component.get("c.sendEmailToCustomer");
        var bookingRecordId = component.get("v.recordId");
        action.setParams({ "recId": component.get("v.recordId"),
                          "pdfType":'SaleDeed'});  
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": 'Sale Deed',
                    "message": 'Sale Deed Draft sent to customer successfully.',
                    "duration": 10000
                });
                toastEvent.fire();
                
            } else {
                console.log('Failed to send email.');
            }
        });
        $A.enqueueAction(action);
    },
    sendEmail2: function (component, event, helper) {
        var action = component.get("c.sendEmailToBank");
        var bookingRecordId = component.get("v.recordId");
        action.setParams({ "recId": component.get("v.recordId"),
                          "pdfType":'SaleDeed'});  
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": 'Sale Deed',
                    "message": 'Sale Deed Draft sent to Bank successfully.',
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