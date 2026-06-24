({
    doInit: function(component, event, helper) {
        var action = component.get("c.getLeadRecordTypeName");
        action.setParams({ leadId: component.get("v.recordId") });
        
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var recordTypeName = response.getReturnValue();
                component.set("v.recordTypeName", recordTypeName.recordTypeName);
                let statusOptions = [];
                if (recordTypeName.recordTypeName === "Pre Sales") {
                    if(recordTypeName.profileName != 'Sales' && recordTypeName.profileName != 'Pre Sales'){
                        statusOptions = ["New", "Open", "RNR", "Pre Sales Follow Up", "Allocated", "Site Visit Schedule","Rejected","Unqualified" ];
                    }
                    else{
                        statusOptions = ["New", "Open", "RNR", "Pre Sales Follow Up", "Allocated", "Site Visit Schedule","Request For Rejection","Unqualified" ];
                    }
                    
                } else {
                    if(recordTypeName.profileName != 'Sales' && recordTypeName.profileName != 'Pre Sales'){
                        statusOptions = ["New Sales Enquiry","Sales Follow up","SV Completed", "Negotiation","Booked", "Unqualified","Closed Lost" ];
                    }
                    else{
                        statusOptions = ["New Sales Enquiry","Sales Follow up","SV Completed", "Negotiation","Booked","Request For Rejection", "Unqualified" ];
                    }
                    
                }
                
                component.set("v.statusOptions", statusOptions);
            } else {
                helper.showToast("Error", "Failed to load record type name", "error");
            }
        });
        
        $A.enqueueAction(action);
        
        var actionun = component.get("c.getUnqualifiedReasons");
        actionun.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.unqualifiedReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(actionun);
        //Get the Closed Lost Reason
        
        var cactionun = component.get("c.getClosedLostReason");
        cactionun.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.closedLostReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(cactionun);
        
        //Open Reason
        var openreason = component.get("c.getOpenReason");
        openreason.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.openReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(openreason);
        //Allocated Reason
        var allreason = component.get("c.getAllocatedReason");
        allreason.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.AllocatedReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(allreason);
        
    },
    
    handleStatusChange : function(component, event, helper) {
        
        component.set("v.scheduleDate", null);
        component.set("v.rating", null);
    },
    
    handleSubmit : function(component, event, helper) {
        const status = component.get("v.leadStatus");
        const scheduleDate = component.get("v.scheduleDate");
        const selectedReason = component.get("v.selectedReason");
        const selectedOpenReason = component.get("v.selectedOpenReason");
        const selectedAlloctReason = component.get("v.selectedAllocatedReason");
        const othcomment = component.get("v.comment");
        
        
        // Validations
        if (!status || status === '') {
            helper.showToast("Error", "Please select a Lead Status.", "error");
            return;
        }
        
        if ((status === 'RNR' || status === 'Pre Sales Follow Up' || status === 'Site Visit Schedule'|| status === 'Sales Follow up') && !scheduleDate) {
            helper.showToast("Error", "Schedule Date is required for selected status.", "error");
            return;
        }
        
        if (status === 'Unqualified' && (!selectedReason || selectedReason === '')) {
            helper.showToast("Error", "Unqualified Reason is required for Unqualified leads.", "error");
            return;
        }
        
        if ((status === 'Request For Rejection' || status === 'Rejected' || status === 'Closed Lost') && (!selectedReason || selectedReason === 'Other') && (!othcomment || othcomment ==='')) {
            helper.showToast("Error", "Other Reason is required for Unqualified leads.", "error");
            return;
        }
        if ((status === 'Request For Rejection' || status === 'Rejected' || status === 'Closed Lost') &&  (!selectedReason || selectedReason === '')) {
            helper.showToast("Error", "Please Enter The Reason", "error");
            return;
        }

        //alert('Before Entering Method');
        helper.updateLeadAndRelated(component, status, scheduleDate, selectedReason,othcomment,selectedOpenReason,selectedAlloctReason);
    },
    
    handleCancel : function(component, event, helper) {
        component.set("v.isOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    },
    handleReasonChange: function(component, event, helper) {
        var selectedValue = event.getSource().get("v.value");
        component.set("v.selectedReason", selectedValue);
    },
    
    handleclosedReasonChange : function(component, event, helper) {
        
        var selectedReason = component.get("v.selectedReason");
        
        var reasonsRequiringDetail = [
            'Vaastu Concern',
            'Dimension',
            'Loan Eligibility',
            'Duplicate Lead',
            'Already Allocated',
            'Booked With Competitor',
            'Booked With Zuari',
            'Not A Valid Customer',
            'Not In Location',
            'Not In Size',
            'Not Interested',
            'CP Clash',
            'Junk Leads'
        ];
        
        var showDetail = reasonsRequiringDetail.includes(selectedReason);
        // alert(showDetail)
        component.set("v.showDetailReason", showDetail);
    },
    
})