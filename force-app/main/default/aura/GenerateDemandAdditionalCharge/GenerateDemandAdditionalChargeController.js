({
	doInit : function(component, event, helper) {
		//component.set("v.projectName", component.get("v.LeadRecord").Project__c);
	},
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    sendEmail: function (component, event, helper) {
        var action = component.get("c.sendEmailWithAttachment");
        var bookingRecordId = component.get("v.recordId");
        var bookingId = component.get("v.Bookid");
        //alert(bookingId);
        action.setParams({ "recId": component.get("v.recordId"),
                          "typeOfDemand":'AD'});  
        action.setCallback(this, function (response) {
            var state = response.getState();
            //alert(state);
            if (state === 'SUCCESS') {
                var res_string = response.getReturnValue();
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var type = (res_string === 'Demand raise email sent Successfully') ? 'Success' : 'error';
                //alert(2);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type,
                    "message": res_string,
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