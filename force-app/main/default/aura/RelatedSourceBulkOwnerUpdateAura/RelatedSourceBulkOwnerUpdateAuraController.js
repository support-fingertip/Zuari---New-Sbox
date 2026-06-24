({
    doInit : function(component, event, helper) {
        component.set("v.columns", [
            { label: 'Name',              fieldName: 'Name',                 type: 'text' },
            { label: 'Owner',             fieldName: 'OwnerName',            type: 'text' },
            { label: 'Allocated Project', fieldName: 'Allocated_Project__c', type: 'text' },
            { label: 'Source Type',       fieldName: 'source_type__c',       type: 'text' },
            { label: 'Created Date',      fieldName: 'CreatedDate',          type: 'date' }
        ]);

        // Load Users with "All" option
        var userAction = component.get("c.getUsers");
        userAction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var opts = response.getReturnValue();
                opts.unshift({ label: '-- All Users --', value: '' });
                component.set("v.userOptions", opts);
            }
        });
        $A.enqueueAction(userAction);

        // Load Allocated Project picklist with "All" option
        var picklistAction = component.get("c.getAllocatedProjectPicklistValues");
        picklistAction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var options = [{ label: '-- All Projects --', value: '' }];
                response.getReturnValue().forEach(function(val) {
                    options.push({ label: val, value: val });
                });
                component.set("v.allocatedProjectOptions", options);
            }
        });
        $A.enqueueAction(picklistAction);

        // Load Source Type picklist with "All" option
        var sourceTypeAction = component.get("c.getSourceTypePicklistValues");
        sourceTypeAction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var options = [{ label: '-- All Source Types --', value: '' }];
                response.getReturnValue().forEach(function(val) {
                    options.push({ label: val, value: val });
                });
                component.set("v.sourceTypeOptions", options);
            }
        });
        $A.enqueueAction(sourceTypeAction);
    },

    selectOwnerTab : function(component, event, helper) {
        if (component.get("v.activeTab") === "owner") return;
        component.set("v.activeTab", "owner");
        component.set("v.showFilters", true);
        component.set("v.records", []);
        component.set("v.selectedIds", []);
    },

    selectSTM2Tab : function(component, event, helper) {
        if (component.get("v.activeTab") === "stm2") return;
        component.set("v.activeTab", "stm2");
        component.set("v.showFilters", true);
        component.set("v.records", []);
        component.set("v.selectedIds", []);
    },

    goBack : function(component, event, helper) {
        component.set("v.activeTab", "");
        component.set("v.showFilters", false);
        component.set("v.records", []);
        component.set("v.selectedIds", []);
        component.set("v.toUserId", null);
        component.set("v.stm2ToUserId", null);
        component.set("v.stm2FromUserId", null);
        component.set("v.stm2Mode", "empty");
        component.set("v.dateRangeOption", "all");
        component.set("v.fromDate", null);
        component.set("v.toDate", null);
        component.set("v.fromUserId", '');
        component.set("v.allocatedProject", '');
        component.set("v.sourceType", '');
    },

    onDateRangeChange : function(component, event, helper) {
        var selected = component.get("v.dateRangeOption");
        // When switching to "All", clear any previously entered dates
        // When switching to "Range", clear dates so user enters them fresh
        if (selected === 'all' || selected === 'range') {
            component.set("v.fromDate", null);
            component.set("v.toDate", null);
        }
    },

    searchRecords : function(component, event, helper) {
        // Validate date inputs when Range is selected
        var dateRangeOption = component.get("v.dateRangeOption");
        if (dateRangeOption === 'range') {
            var fromDate = component.get("v.fromDate");
            var toDate   = component.get("v.toDate");
            if (!fromDate && !toDate) {
                $A.get("e.force:showToast").setParams({
                    title   : "Validation",
                    message : "Please enter at least a From Date or To Date when Range is selected.",
                    type    : "warning"
                }).fire();
                return;
            }
            if (fromDate && toDate && fromDate > toDate) {
                $A.get("e.force:showToast").setParams({
                    title   : "Validation",
                    message : "From Date cannot be later than To Date.",
                    type    : "error"
                }).fire();
                return;
            }
        }
        helper.loadRecords(component);
    },

    clearFilters : function(component, event, helper) {
        component.set("v.dateRangeOption", 'all');
        component.set("v.fromDate", null);
        component.set("v.toDate", null);
        component.set("v.fromUserId", '');
        component.set("v.allocatedProject", '');
        component.set("v.sourceType", '');
        component.set("v.records", []);
        component.set("v.selectedIds", []);
    },

    handleRowSelection : function(component, event, helper) {
        var selectedRows = event.getParam("selectedRows");
        component.set("v.selectedIds", selectedRows.map(function(row) {
            return row.Id;
        }));
    },

    updateOwner : function(component, event, helper) {
        if (!component.get("v.toUserId")) {
            $A.get("e.force:showToast").setParams({
                title: "Error", message: "New Owner is required.", type: "error"
            }).fire();
            return;
        }
        if (!component.get("v.selectedIds") || component.get("v.selectedIds").length === 0) {
            $A.get("e.force:showToast").setParams({
                title: "Error", message: "Please select at least one record.", type: "error"
            }).fire();
            return;
        }
        helper.updateOwnerHelper(component);
    },

    updateEmptySTM2 : function(component, event, helper) {
        if (!component.get("v.selectedIds") || component.get("v.selectedIds").length === 0) {
            $A.get("e.force:showToast").setParams({
                title: "Error", message: "Please select at least one record.", type: "error"
            }).fire();
            return;
        }
        helper.updateEmptySTM2Helper(component);
    },

    reassignSTM2 : function(component, event, helper) {
        if (!component.get("v.selectedIds") || component.get("v.selectedIds").length === 0) {
            $A.get("e.force:showToast").setParams({
                title: "Error", message: "Please select at least one record.", type: "error"
            }).fire();
            return;
        }
        helper.reassignSTM2Helper(component);
    }
})