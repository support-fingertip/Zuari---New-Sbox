({
    doInit: function (component, event, helper) {
        var masterPaymentScheduleId = component.get("v.recordId");
        var gotList = component.get('v.bookingRecords');
        if(gotList.length === 0 ){
            var action = component.get("c.getBookingRecords");
            action.setParams({ "masterPaymentScheduleId": masterPaymentScheduleId });
            
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.bookingRecords", response.getReturnValue());
                } else {
                    console.error("Error fetching Booking records");
                    helper.showToast(component, 'Error', 'Error fetching Booking records', 'error');
                }
            });
            
            $A.enqueueAction(action);
        }
        else{
            
        }        
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
    },
    
    handleToggleChange: function (component, event, helper) {
        var index = event.currentTarget.dataset.bookingIndex;
        var bookingRecords = component.get("v.bookingRecords");
        var bookingWrapper = bookingRecords[index];
        bookingWrapper.includeIntrest = event.target.checked ? 'true' : 'false';
        component.set("v.bookingRecords", bookingRecords);
    },
    
    raiseDemand: function (component, event, helper) {
        var bookingId = event.getSource().get("v.value").booking.Id;
        var payScheduleId = event.getSource().get("v.value").paymentScheduleId;
        var incLudeInt = event.getSource().get("v.value").includeIntrest;
        component.set('v.inc',incLudeInt);
        component.set("v.Bookid", bookingId);
        component.set("v.paymentScheduleId", payScheduleId);
        component.set("v.showNextCmp", true);
        
        var raiseDemandEvent = component.getEvent("raiseDemandEvent");
        raiseDemandEvent.setParams({
            "showNextCmp": component.get("v.showNextCmp")
        });
        raiseDemandEvent.fire();
    },
    raiseAllDemands: function (component, event, helper) {
        var selectedRecords = [];
        var checkboxes = component.find("bookingCheckbox");
        checkboxes = Array.isArray(checkboxes) ? checkboxes : [checkboxes];
        checkboxes.forEach(function(checkbox) {
            if (checkbox.get("v.checked")) {              
                selectedRecords.push(checkbox.get("v.value"));
            }
        });
        
        var allFiles = component.get('v.filesIDS');
        
        if (selectedRecords.length > 0) {
            component.set("v.selectedRecords",selectedRecords);
            component.set("v.selectedFileIds",allFiles);
            component.set("v.showRaiseAll",true);
        } else {
            helper.showToast(component, 'Error', 'Please select at least one booking to raise demands.', 'error');
        }
    },
    toggleSelectAll: function (component, event, helper) {
        const allChecked = event.getSource().get("v.checked");
        component.set("v.allChecked", allChecked);
        
        const checkboxes = component.get("v.bookingRecords");
        
        checkboxes.forEach(function (checkbox) {
            if (!checkbox.booking.Email__c || checkbox.demandRaised) {
                checkbox.selected = false;
            } else {
                checkbox.selected = allChecked;
            }
        });
        
        component.set("v.bookingRecords", checkboxes);
    },
    toggleCheckbox: function (component, event, helper) {
        const index = event.getSource().get("v.name");
        const checkboxes = component.get("v.bookingRecords");
        
        checkboxes[index].selected = event.getSource().get("v.checked");
        
        component.set("v.bookingRecords", checkboxes);
        
        const allChecked = checkboxes.every(checkbox => {
            return (!checkbox.booking.Email__c || checkbox.demandRaised) || checkbox.selected;
        });
        
        component.set("v.allChecked", allChecked);
    },
    
    /*
    raiseAllDemands: function (component, event, helper) {
        var selectedBookings = [];
        var paySchId = [];
        var mapSet = {};
        var checkboxes = component.find("bookingCheckbox");
        checkboxes = Array.isArray(checkboxes) ? checkboxes : [checkboxes];
        checkboxes.forEach(function(checkbox) {
            if (checkbox.get("v.checked")) {
                var selBook  = checkbox.get("v.value").booking.Id;
                var payId = checkbox.get("v.value").paymentScheduleId;
                var incLudeInt = checkbox.get("v.value").includeIntrest;
                selectedBookings.push(selBook);
                mapSet[selBook] = incLudeInt;
                paySchId.push(payId);
            }
        });
        
        var allFiles = component.get('v.files');
        var contentDocumentIds = allFiles.map(file => file.Id);
        
        if (selectedBookings.length > 0) {
            var action = component.get("c.sendEmailsToBookings");
            action.setParams({ "selectedBookingIds": selectedBookings,
                              "payscheduleId" : component.get("v.recordId"),
                              "contentIds" : contentDocumentIds,
                              "mapData": mapSet
                             });
            
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var action2 = component.get("c.updatePaymentSchedules");
                    action2.setParams({ "payIds": paySchId });
                    action2.setCallback(this, function (response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            helper.showToast(component, 'Success', 'All Demand Letters Sent Successfully', 'success');
                        }
                    });
                    $A.enqueueAction(action2); 
                } else {
                    helper.showToast(component, 'Error', 'Error sending emails. Please try again.', 'error');
                }
            });
            $A.enqueueAction(action);
        } else {
            helper.showToast(component, 'Error', 'Please select at least one booking to raise demands.', 'error');
        }
    }*/
})