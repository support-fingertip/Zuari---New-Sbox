({
    doInit: function(component, event, helper) {
        // Get the list of selected records
        var selectedRecords = component.get("v.selectedRecords");
        
        // Initialize selectedBookingIds with all booking IDs
        var bookingIds = [];
        selectedRecords.forEach(function(record) {
            bookingIds.push(record.booking.Id);
        });
        
        // Set the selectedBookingIds attribute with all the IDs
        component.set("v.selectedBookingIds", bookingIds);
    },
    submit: function(component, event, helper) {
        var contentDocumentIds = component.get("v.selectedFileIds");
        var selectedBookingIds = [];
        var emailContentMap = component.get("v.emailContentMap") || {};
        var contentDocumentIdsMap = component.get("v.contentDocumentIdsMap") || {};
        
        var checkboxes = component.find("bookingCheckbox");
        checkboxes = Array.isArray(checkboxes) ? checkboxes : [checkboxes];
        checkboxes.forEach(function(checkbox) {
            if (checkbox.get("v.checked")) { 
                
                var bookingRecord = checkbox.get("v.value");
                
                selectedBookingIds.push(bookingRecord.Id);
                
                var applicantNames = '';
                
                if (bookingRecord.salutation_Applicant1__c && bookingRecord.First_Applicant_Name__c) {
                    applicantNames = bookingRecord.salutation_Applicant1__c + ' ' + bookingRecord.First_Applicant_Name__c;
                }
                
                var secondApplicantName = '';
                if (bookingRecord.Second_Applicant_Name__c && bookingRecord.Second_Applicant_Name__c.trim() !== '') {
                    secondApplicantName = bookingRecord.salutation_Applicant2__c + ' ' + bookingRecord.Second_Applicant_Name__c;
                }
                
                if (secondApplicantName != '') {
                    applicantNames += ' and ' + secondApplicantName;
                }
                
                var defaultEmailContent = '<div style="color: black;"><strong>Dear ' + applicantNames + ',</strong></div><br/>'+'<div>Please find the attached Demand Letter.<br/><br/>' +
                    'We are pleased to inform you that your booking has been confirmed. ' +
                    'Attached is the Demand Letter for your reference.<br/><br/>' +
                    'If you have any questions or need further assistance, please do not hesitate to contact us.<br/><br/>' +
                    'Thank you for choosing <strong>Zuari</strong>.<br/><br/>' +
                    'Best regards,<br/>';
                    defaultEmailContent += '<strong>Zuari</strong></div>'
                emailContentMap[bookingRecord.Id] = '';
                contentDocumentIdsMap[bookingRecord.Id] = contentDocumentIds;
            }
        });
        
        component.set("v.emailContentMap", emailContentMap);
        component.set("v.contentDocumentIdsMap", contentDocumentIdsMap);
        component.set("v.selectedBookingIds", selectedBookingIds);
        
        var action = component.get("c.RaiseDemand");
        action.setParams({
            "bookingIds": selectedBookingIds,
            "emailContents": emailContentMap,
            "contentIds": contentDocumentIdsMap
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                var res_string = response.getReturnValue();
                var type = res_string === 'Demand Raise records created and submitted for approval.' ? 'success' : 'error';
                component.set("v.showPopup",false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type.charAt(0).toUpperCase() + type.slice(1), // Capitalize title
                    "message": res_string,
                    "duration": 10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
                
            } else if (state === 'ERROR') {
                console.log('here Error');
                // Handle error case
                var errors = response.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    console.log('Error message: ' + errors[0].message);
                } else {
                    console.log('Unknown error');
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    Close: function(component, event, helper) {
        component.set("v.showPopup",false);
    }
})