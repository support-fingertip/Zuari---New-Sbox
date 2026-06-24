({
    doInit: function (component, event, helper) {
        var leadRecord = component.get("v.LeadRecord");
        if (leadRecord && leadRecord.Bank_Name__c) {
            component.set("v.bankName", leadRecord.Bank_Name__c);
            component.set("v.projectName", leadRecord.Project__c);
        } else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                type: 'error',
                title: 'Error!',
                message: 'Please select Bank Name before proceeding.',
                duration: 10000
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
        }
    },

    close: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    sendEmail: function (component, event, helper) {
        
        var action = component.get("c.sendEmailToCustomerTPA");
        var recordId = component.get("v.recordId");
        //alert(recordId)
        if (!recordId) {
            var toast = $A.get("e.force:showToast");
            toast.setParams({
                type: "error",
                title: "Error",
                message: "Record Id is missing. Unable to send email."
            });
            toast.fire();
            return;
        }

        action.setParams({ recId: recordId });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    type: 'success',
                    title: 'Success!',
                    message: 'Email Sent successfully.',
                    duration: 10000
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                var message = 'Unknown error'; // Default error message
                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    type: 'error',
                    title: 'Error sending email',
                    message: message,
                    duration: 10000
                });
                toastEvent.fire();
                console.error('Error sending email: ', errors);
            }
        });

        $A.enqueueAction(action);
    }
})