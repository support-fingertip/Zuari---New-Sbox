({
 updateLeadAndRelated : function(component, status, scheduleDate, selectedReason,othcomment,selectedOpenReason,selectedAlloctReason) {
    const action = component.get("c.updateLeadWithStatus");
    action.setParams({
        leadId: component.get("v.recordId"),
        status: status,
        scheduleDate: scheduleDate,
        rating: selectedReason,
        openreason: selectedOpenReason,
        alloctreason: selectedAlloctReason,
        othercom : othcomment
    });

    action.setCallback(this, function(response) {
        const state = response.getState();
        //alert('alert');
        //alert(state);
        if (state === "SUCCESS") {
            var responseMessage = response.getReturnValue();
            //alert(responseMessage);
            if(responseMessage == 'Updated Successully'){
                
            $A.get("e.force:showToast").setParams({
                "title": "Success",
                "message": "Lead Status Updated Successfully!",
                "type": "success"
            }).fire();
                
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
                if(status=='Unqualified' || status=='Closed Lost' || status=='Request For Rejection'){
                    
                 window.location.href = '/lightning/o/Lead/home';
                }
            }
            else {
                if (responseMessage.includes('Please select future date / time') || responseMessage.includes('Please enter future Date')) {
                     $A.get("e.force:showToast").setParams({
                        "title": "Validation Error",
                        "message": 'Choose Future Date and Time',
                        "type": "warning"
                    }).fire();
                   
                }
                        
            }
            
        } else {
            let errors = response.getError();
            console.error(errors);

            let errorMsg = "Something went wrong.";
            if (errors && errors[0] && errors[0].message) {
                errorMsg = errors[0].message;

                if (errorMsg.includes("Please select future date / time")) {
                    // Show validation toast if future date message
                    $A.get("e.force:showToast").setParams({
                        "title": "Validation Error",
                        "message": errorMsg,
                        "type": "warning"
                    }).fire();
                    return;
                }
            }

            // Default error toast
            $A.get("e.force:showToast").setParams({
                "title": "Error",
                "message": errorMsg,
                "type": "error"
            }).fire();
        }
    });

    $A.enqueueAction(action);
},

    showToast : function(title, message, type) {
        const toast = $A.get("e.force:showToast");
        if (toast) {
            toast.setParams({
                title: title,
                message: message,
                type: type,
                mode: 'dismissible'
            });
            toast.fire();
        }
    }
})