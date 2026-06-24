({
    doInit: function(component, event, helper) {
       /*
        var action = component.get("c.getLeadRecordTypeName");
        
        action.setParams({ relatedSourceId: component.get("v.recordId") });
        
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
                        statusOptions = ["New", "Open", "RNR", "Pre Sales Follow Up", "Allocated", "Site Visit Schedule","Request for Rejection","Unqualified" ];
                    }
                } else {
                    if(recordTypeName.profileName != 'Sales' && recordTypeName.profileName != 'Pre Sales'){
                        statusOptions = ["New Sales Enquiry","Sales RNR","Sales Follow up","Site Visit Schedule","SV Completed", "Negotiation","Booked", "Unqualified","Closed Lost" ];
                    }
                    else{
                        statusOptions = ["New Sales Enquiry","Sales RNR","Sales Follow up","Site Visit Schedule","SV Completed", "Negotiation","Booked","Request for Rejection", "Unqualified" ];
                    }
                }
                
                component.set("v.statusOptions", statusOptions);
            } else {
                helper.showToast("Error", "Failed to load record type name", "error");
            }
        });
        
        $A.enqueueAction(action);
        
        */
        
        var actionssss = component.get("c.getLeadRecordTypeName1");
        
        actionssss.setParams({ relatedSourceId: component.get("v.recordId") });
        
        
        actionssss.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
              //  alert(result.recordTypeName +'==== '+ result.statusOptions);
                component.set("v.recordTypeName", result.recordTypeName);
                component.set("v.statusOptions", result.statusOptions);
            }
        });
        $A.enqueueAction(actionssss);
        
        
        var actionun = component.get("c.getUnqualifiedReasons");
        actionun.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.unqualifiedReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(actionun);
        
        var cactionun = component.get("c.getClosedLostReason");
        cactionun.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.closedLostReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(cactionun);
        
        var actionLQ = component.get("c.getLeadQuality");
        var recordId = component.get("v.recordId");
        
        actionLQ.setParams({ relatedSourceId: recordId });
        
        actionLQ.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.leadQualitys", result.picklistValues);
                var currentValue = result.currentValue;
                
                if (currentValue) {
                    component.set("v.showLeadQuality", false);
                } else {
                    component.set("v.showLeadQuality", true);
                }
            } else if (state === "ERROR") {
                console.error('Apex Error:', response.getError());
                component.set("v.showLeadQuality", false);
            }
        });
        $A.enqueueAction(actionLQ);
        
        var openreason = component.get("c.getOpenReason");
        openreason.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.openReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(openreason);
        
        var allreason = component.get("c.getAllocatedReason");
        allreason.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.AllocatedReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(allreason);
        
        var actionLead = component.get("c.getLeadCurrentStatus");
        actionLead.setParams({ relatedSourceId: component.get("v.recordId") });
        actionLead.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.currentLeadStatus", response.getReturnValue());
            }
        });
        $A.enqueueAction(actionLead);
    },
    
    handleStatusChange : function(component, event, helper) {
        // Reset dependent fields when status changes so stale values don't leak through validation
        component.set("v.scheduleDate", null);
        component.set("v.followUpDate", null);
        component.set("v.rating", null);
        component.set("v.selectedReason", null);
        component.set("v.selectedOpenReason", null);
        component.set("v.selectedAllocatedReason", null);
        component.set("v.comment", '');
        component.set("v.showDetailReason", false);
    },
    
    handleSubmit : function(component, event, helper) {
        if (component.get("v.isSubmitting")) {
            return;
        }
        
        component.set("v.isSubmitting", true);
         // helper.updateScheduleDateVisibility(component);
        const status = component.get("v.leadStatus");
        const currentStatus = component.get("v.currentLeadStatus");
        const scheduleDate = component.get("v.scheduleDate");
        const followUpDate = component.get("v.followUpDate");
        const addNotes = component.get("v.addNotes");
        const selectedReason = component.get("v.selectedReason");
        const selectedOpenReason = component.get("v.selectedOpenReason");
        const selectedAlloctReason = component.get("v.selectedAllocatedReason");
        const othcomment = component.get("v.comment");
        const showDetailReason = component.get("v.showDetailReason");
        const recordTypeName = component.get("v.recordTypeName");
        
        let statusOrder = [];
        if (recordTypeName === 'Pre Sales') {
            statusOrder = [
                "Pre-Sales New Enquiry","Pre-Sales RNR","Pre-Sales Unqualified","Pre-Sales Closed Lost","Pre-Sales Interested","Pre-Sales Site Visit Schedule",
                "New", "Open", "RNR", "Pre Sales Follow Up", "Allocated", "Site Visit Schedule",
                "Request for Rejection", "Rejected", "Unqualified"
                  
            ];
        } else {
            statusOrder = [
                "New Sales Enquiry", "Sales RNR", "Sales Follow up", "Site Visit Schedule",
                "SV Completed", "Negotiation", "Booked","Request for Rejection", "Unqualified", "Closed Lost"
            ];
        }
        
        // VALIDATION 1: Status must be selected
        if (!status || status === '') {
            helper.showToast("Error", "Please select a Related Source Status.", "error");
            component.set("v.isSubmitting", false);
            return;
        }
        
        // VALIDATION 2: Strict forward-only — any move to a lower-indexed status is blocked.
        if (currentStatus
            && statusOrder.indexOf(status) !== -1
            && statusOrder.indexOf(currentStatus) !== -1
            && statusOrder.indexOf(status) < statusOrder.indexOf(currentStatus)) {
            helper.showToast(
                "Error",
                "You cannot move the Related Source status backward from " + currentStatus + " to " + status + ".",
                "error"
            );
            component.set("v.isSubmitting", false);
            return;
        }
        
        // VALIDATION 3: Last Note mandatory
        if (!addNotes || addNotes.trim() === '') {
            helper.showToast("Error", "Last Note is required before submitting.", "error");
            component.set("v.isSubmitting", false);
            return;
        }
        
        // VALIDATION 4: Schedule Date required for non-terminal statuses
        const statusesNotNeedingDate = ['Request for Rejection', 'Rejected', 'Closed Lost', 'Unqualified','Pre-Sales Unqualified','Pre-Sales Closed Lost'];
        
        if (statusesNotNeedingDate.indexOf(status) === -1) {
            if (!scheduleDate) {
                helper.showToast("Error", "Schedule Date is required for status: " + status, "error");
                component.set("v.isSubmitting", false);
                return;
            }
            var selectedDt = new Date(scheduleDate);
            var nowDt = new Date();
            if (selectedDt <= nowDt) {
                helper.showToast("Error", "Please select a future Date and Time for Schedule Date.", "error");
                component.set("v.isSubmitting", false);
                return;
            }
        }
        
        // VALIDATION 4b: Follow Up Date is mandatory and must be future when status is Site Visit Schedule
        if (status === 'Site Visit Schedule') {
            if (!followUpDate) {
                helper.showToast("Error", "Follow Up Date is required for status: Site Visit Schedule.", "error");
                component.set("v.isSubmitting", false);
                return;
            }
            var fuDt = new Date(followUpDate);
            var nowDt2 = new Date();
            if (fuDt <= nowDt2) {
                helper.showToast("Error", "Please select a future Date and Time for Follow Up Date.", "error");
                component.set("v.isSubmitting", false);
                return;
            }
        }
        
        // VALIDATION 5: Subject required for certain statuses
        const statusesNeedingSubject = ['RNR','Pre Sales Follow Up','Sales Follow up','Sales RNR','Negotiation'];
        if (statusesNeedingSubject.indexOf(status) !== -1) {
            if (!othcomment || othcomment.trim() === '') {
                helper.showToast("Error", "Subject is required for status: " + status, "error");
                component.set("v.isSubmitting", false);
                return;
            }
        }
        
        // VALIDATION 6: Unqualified Reason
        if (status === 'Unqualified') {
            if (!selectedReason || selectedReason === '') {
                helper.showToast("Error", "Unqualified Reason is required.", "error");
                component.set("v.isSubmitting", false);
                return;
            }
        }
        
        // VALIDATION 7: Closed Lost / Rejected / Request for Rejection
        if (status === 'Closed Lost' || status === 'Rejected' || status === 'Request for Rejection') {
            if (!selectedReason || selectedReason === '') {
                helper.showToast("Error", "Reason is required for status: " + status, "error");
                component.set("v.isSubmitting", false);
                return;
            }
            if (showDetailReason && (!othcomment || othcomment.trim() === '')) {
                helper.showToast("Error", "Reasons in Detail is required for the selected reason.", "error");
                component.set("v.isSubmitting", false);
                return;
            }
        }
        
        // VALIDATION 8: Open Reason
        if (status === 'Open') {
            if (!selectedOpenReason || selectedOpenReason === '') {
                helper.showToast("Error", "Open Reason is required.", "error");
                component.set("v.isSubmitting", false);
                return;
            }
        }
        
        // VALIDATION 9: Allocated Reason
        if (status === 'Allocated') {
            if (!selectedAlloctReason || selectedAlloctReason === '') {
                helper.showToast("Error", "Allocated Reason is required.", "error");
                component.set("v.isSubmitting", false);
                return;
            }
        }
        
        // VALIDATION 10: SV Completed requires a completed Site Visit
        if (status === 'SV Completed') {
            var checkAction = component.get("c.hasCompletedSiteVisit");
            checkAction.setParams({ relatedSourceId: component.get("v.recordId") });
            
            checkAction.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var hasCompleted = response.getReturnValue();
                    if (hasCompleted === true) {
                        helper.updateLeadAndRelated(
                            component, status, addNotes, scheduleDate,
                            selectedReason, othcomment, selectedOpenReason, selectedAlloctReason, followUpDate
                        );
                    } else {
                        helper.showToast(
                            "Error",
                            "Status cannot be set to 'SV Completed'. No related Site Visit with status 'Completed' exists. Please complete the Site Visit first.",
                            "error"
                        );
                        component.set("v.isSubmitting", false);
                    }
                } else {
                    helper.showToast("Error", "Unable to verify Site Visit status. Please try again.", "error");
                    component.set("v.isSubmitting", false);
                }
            });
            
            $A.enqueueAction(checkAction);
            return;
        }
        
        helper.updateLeadAndRelated(component, status, addNotes, scheduleDate, selectedReason, othcomment, selectedOpenReason, selectedAlloctReason, followUpDate);
    },
    
    handlequalityChange : function(component, event, helper) {
        var selectedQuality = event.getSource().get("v.value");
        component.set("v.selectedquality", selectedQuality);
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
            'Vaastu Concern','Dimension','Loan Eligibility','Duplicate Lead',
            'Already Allocated','Booked With Competitor','Booked With Zuari',
            'Not A Valid Customer','Not In Location','Not In Size','Not Interested',
            'CP Clash','Junk Leads'
        ];
        
        var showDetail = reasonsRequiringDetail.includes(selectedReason);
        component.set("v.showDetailReason", showDetail);
    },
})