({
    doInit : function(component, event, helper) {
        let baseUrl = window.location.origin;
        var action = component.get("c.getDemandRaised");
        action.setParams({recordId : component.get("v.recordId") }); 
        action.setCallback(this, function(a){ 
            var state = a.getState();
            if (state === 'SUCCESS') {
                var url = '';
                component.set("v.demandRaisedRecord", a.getReturnValue());
                var demandRaisedValue = a.getReturnValue();
                // ====== CHANGED: Points to Credit_Note VF page instead of Demand_Note_Send ======
                url = baseUrl + '/apex/Credit_Note?Id=' + component.get("v.recordId");
                if(demandRaisedValue.Demand_Email_Content__c && demandRaisedValue.Demand_Email_Content__c != ''){
                    component.set("v.emailContent", demandRaisedValue.Demand_Email_Content__c);
                }
                component.set("v.vfPageUrl", url);
            } else if (state === 'ERROR') {
                console.log('here Error');
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    console.log('Error message: ' + errors[0].message);
                } else {
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },
    sendtoCustomer: function(component, event, helper) {
        var action = component.get("c.ResendRaiseDemand");
        var recId = component.get("v.recordId");
        var recordIdsList = component.get("v.recordIdsList") || [];
        recordIdsList.push(recId);
        component.set("v.recordIdsList", recordIdsList);
        action.setParams({
            "recordIds": recordIdsList,
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                console.log('here success');
                var res_string = response.getReturnValue();
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                var type = 'success';
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": type.charAt(0).toUpperCase() + type.slice(1),
                    "message": 'Credit Note mail successfully sent.',
                    "duration": 10000
                });
                toastEvent.fire();
                
                $A.get('e.force:refreshView').fire();
            } else if (state === 'ERROR') {
                console.log('here Error');
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
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS', getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },
    
    handleClick : function (cmp, event, helper) {
        var buttonstate = cmp.get('v.buttonstate');
        cmp.set('v.buttonstate', !buttonstate);
    },
    
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
        component.set('v.visible', false);
    },
})