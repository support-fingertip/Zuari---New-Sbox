({
    doInit: function (component, event, helper) {
        var bookingRecordId = component.get("v.recordId");
        var bookingId = component.get("v.Bookid");
        helper.checkDemandStatus(component, event, helper);
        //alert(bookingId);
        
    },
    handleToggleChange : function(component, event, helper) {
        var isChecked = event.target.checked;
        if(isChecked == true){
            component.set("v.includeInterest", 'true');
        }
        else{
            component.set("v.includeInterest", 'false');
        }
        
    },
    
    sendEmail: function (component, event, helper) {
        console.log('here sendEmail'); 
        var action = component.get("c.RaiseDemand");
        var recId = component.get("v.recordId");
        //var contentDocumentIds = component.get('v.filesIDS'); // This is the list of file IDs
        //var contentHTML = component.get('v.emailContent'); // This is the email content
        var recordIdsList = component.get("v.recordIdsList") || [];
        var emailContentMap = component.get("v.emailContentMap") || {};
        var contentDocumentIdsMap = component.get("v.contentDocumentIdsMap") || {};
        recordIdsList.push(recId);
        console.log('here sendEmail'); 
        //emailContentMap[recId] = contentHTML;
        
        //contentDocumentIdsMap[recId] = contentDocumentIds;
        //console.log('here 4'+JSON.stringify(contentDocumentIds));
        component.set("v.recordIdsList", recordIdsList);
        //component.set("v.emailContentMap", emailContentMap);
        //component.set("v.contentDocumentIdsMap", contentDocumentIdsMap);
        //console.log('here 5' + JSON.stringify(contentDocumentIdsMap));
        // Set the parameter for the Apex method - receiptId is passed from the component
        action.setParams({
            "bookingIds": recordIdsList,
            "emailContents": emailContentMap,
            "contentIds": contentDocumentIdsMap
        });
        console.log('here 1');        
        // Set the callback function to handle the response from Apex
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                console.log('here sucess');
                // Retrieve the return value from the Apex method
                var res_string = response.getReturnValue();
                
                // Close the quick action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                // Determine the toast type based on the response
                var type = res_string === 'Demand Raise records created' ? 'success' : 'error';
                
                // Show toast notification
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'Success',
                    "title": 'success', // Capitalize title
                    "message": 'Demand Raise records created',
                    "duration": 2000
                });
                toastEvent.fire();
                
                // Refresh the view to reflect changes
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
        
        // Enqueue the action to call the Apex method
        $A.enqueueAction(action);
    },
    
    close: function (component, event, helper) {
        component.set('v.visible',false);
        $A.get("e.force:closeQuickAction").fire();
        
    }
})