({
    doInit : function(component, event, helper) {
        var changeType = event.getParams().changeType;
        if (changeType === "LOADED") {
            var rec = component.get("v.bookingRec");

            // Signature check
            if (!rec || rec.Booking_Form_Signature_Uploaded__c !== true) {
                $A.get("e.force:showToast").setParams({
                    title: "Blocked",
                    message: "Please Upload Signed Booking Form and Mark the checkbox to true.",
                    type: "error"
                }).fire();
                $A.get("e.force:closeQuickAction").fire();
                return;
            }

            // Approval check
            if (rec.Approval_yes_or_No__c !== true) {
                $A.get("e.force:showToast").setParams({
                    title: "Blocked",
                    message: "Booking amount not approved.",
                    type: "error"
                }).fire();
                $A.get("e.force:closeQuickAction").fire();
                return;
            }

            helper.pushToSales(component);
        } else if (changeType === "ERROR") {
            $A.get("e.force:showToast").setParams({
                title: "Error",
                message: component.get("v.recordLoadError"),
                type : "error"
            }).fire();
        }
    }
})