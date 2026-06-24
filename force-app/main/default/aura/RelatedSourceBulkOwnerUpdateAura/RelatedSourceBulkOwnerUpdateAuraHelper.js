({
    loadRecords : function(component) {
        var fromUserId       = component.get("v.fromUserId");
        var allocatedProject = component.get("v.allocatedProject");
        var sourceType       = component.get("v.sourceType");

        var action = component.get("c.fetchRelatedSources");
        action.setParams({
            fromDate              : component.get("v.fromDate")      || null,
            toDate                : component.get("v.toDate")        || null,
            fromUserId            : (fromUserId === ''       ? null : fromUserId),
            allocatedProjectValue : (allocatedProject === '' ? null : allocatedProject),
            sourceTypeValue       : (sourceType === ''       ? null : sourceType)
        });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var records = response.getReturnValue();
                records.forEach(function(rec) {
                    rec.OwnerName = rec.Owner ? rec.Owner.Name : '';
                });
                component.set("v.records", records);
                component.set("v.selectedIds", []);
                if (records.length === 0) {
                    $A.get("e.force:showToast").setParams({
                        title   : "No Records",
                        message : "No records found for the selected filters.",
                        type    : "info"
                    }).fire();
                }
            } else {
                var errors = response.getError();
                $A.get("e.force:showToast").setParams({
                    title   : "Error",
                    message : errors && errors[0] ? errors[0].message : "Unknown error occurred.",
                    type    : "error"
                }).fire();
            }
        });
        $A.enqueueAction(action);
    },

    updateOwnerHelper : function(component) {
        var action = component.get("c.bulkUpdateOwner");
        action.setParams({
            recordIds : component.get("v.selectedIds"),
            toUserId  : component.get("v.toUserId")
        });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                $A.get("e.force:showToast").setParams({
                    title: "Success", message: "Owner updated successfully.", type: "success"
                }).fire();
                this.loadRecords(component);
            } else {
                var errors = response.getError();
                $A.get("e.force:showToast").setParams({
                    title   : "Error",
                    message : errors && errors[0] ? errors[0].message : "Unknown error occurred.",
                    type    : "error"
                }).fire();
            }
        });
        $A.enqueueAction(action);
    },

    updateEmptySTM2Helper : function(component) {
        var action = component.get("c.bulkUpdateEmptySTM2");
        action.setParams({
            recordIds  : component.get("v.selectedIds"),
            stm2UserId : component.get("v.stm2ToUserId")
        });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                $A.get("e.force:showToast").setParams({
                    title: "Success", message: "STM2 updated for empty fields.", type: "success"
                }).fire();
                this.loadRecords(component);
            } else {
                var errors = response.getError();
                $A.get("e.force:showToast").setParams({
                    title   : "Error",
                    message : errors && errors[0] ? errors[0].message : "Unknown error occurred.",
                    type    : "error"
                }).fire();
            }
        });
        $A.enqueueAction(action);
    },

    reassignSTM2Helper : function(component) {
        var action = component.get("c.bulkReassignSTM2");
        action.setParams({
            recordIds  : component.get("v.selectedIds"),
            fromUserId : component.get("v.stm2FromUserId"),
            toUserId   : component.get("v.stm2ToUserId")
        });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                $A.get("e.force:showToast").setParams({
                    title: "Success", message: "STM2 reassigned successfully.", type: "success"
                }).fire();
                this.loadRecords(component);
            } else {
                var errors = response.getError();
                $A.get("e.force:showToast").setParams({
                    title   : "Error",
                    message : errors && errors[0] ? errors[0].message : "Unknown error occurred.",
                    type    : "error"
                }).fire();
            }
        });
        $A.enqueueAction(action);
    }
})