({
    doInit : function(component, event, helper) {
        var userAction = component.get("c.getSalesUsersForRS");
        userAction.setParams({ recordId : component.get("v.recordId") });
        userAction.setCallback(this, function(response){
            var state = response.getState();
          //  alert(state)
            if(state === 'SUCCESS'){
                var users = response.getReturnValue() || [];
                var options = users.map(function(u){
                    return { label: u.Name, value: u.Id };
                });
                component.set("v.userOptions", options);
                if(options.length === 0){
                    helper.showToast('warning', 'No eligible sales users configured for this source type. Update the Custom Label in Setup.');
                }
            } else {
                helper.showToast('error', 'Unable to load sales users');
            }
        });
        $A.enqueueAction(userAction);
    },

    pushRSToSalesComp : function(component, event, helper){
        component.set("v.isButtonDisabled", true);

        var selectedUserId = component.get("v.selectedUserId");
        var transferNotes = component.get("v.newNote");

        if(selectedUserId == '' || selectedUserId == null || selectedUserId == undefined){
            component.set("v.isButtonDisabled", false);
            helper.showToast('error', 'Please Select a Sales User');
            return;
        }

        if(transferNotes == '' || transferNotes == 'None' || transferNotes == null || transferNotes == undefined){
            component.set("v.isButtonDisabled", false);
            helper.showToast('error', 'Please Enter transfer notes');
            return;
        }

        var action = component.get("c.moveRSToSales");
        action.setParams({
            recordId: component.get("v.recordId"),
            newOwnerId: selectedUserId,
            addNote: transferNotes
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                helper.showToast('success', 'Related Source moved to sales team');

                var rsId = response.getReturnValue();
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({ "recordId": rsId });
                navEvt.fire();
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire();
            } else {
                component.set("v.isButtonDisabled", false);
                var errors = response.getError();
                var msg = (errors && errors[0] && errors[0].message) ? errors[0].message : 'Unable to push Related Source to Sales';
                helper.showToast('error', msg);
            }
        });
        $A.enqueueAction(action);
    },

    closeModel : function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})