({
    validate: function(component, event) {
        var isValid = true;
        var oppPlot = component.get('v.oppPlot');
        console.log(oppPlot)
        if(oppPlot.Unit__c == null){
            isValid = false;
            alert('Please select Plot.');
        }
        return isValid;
    },
    save  : function(component, event, helper){
        component.set('v.spinner',true);
        var action=component.get("c.saveOppPlot");  
        action.setParams({
            oppPlot:component.get("v.oppPlot"),
            
            prevBooking : component.get("v.recordId")
            
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var quotid = response.getReturnValue();
                if(quotid != 'notc'){
                    helper.getmasterpaymentschedule(component,event,helper);
                    helper.saveSchedules(component,event,helper);
                    component.set('v.spinner',false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                       
                        "title": "Success!",
                        "message": "The Request For Swapping Sent Successfully.",
                        "type":"success"
                       
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.force:closeQuickAction").fire();
                }
                else{
                    component.set('v.spinner',false);
                    var errors = response.getError();
                    var errormessage=errors[0].message;
                    if (errors) {
                        helper.showToast('Error','Unknown Error',errormessage);
                    }
                    else {
                        console.log("Unknown error");
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    showToast : function(type,title,message) {
        console.log(message)
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "title":title,
            "message":message
        });
        toastEvent.fire();
    },
    getmasterpaymentschedule: function(component, event,helper) {
        var oppPlot = component.get('v.oppPlot');
        var pymplan = component.get('v.paymentType');
        var project = component.get('v.projectName');
        var action = component.get("c.getPaymentSchedules");
        action.setParams({'Pay':  pymplan,
                          'Project': project
                         })
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS" ){ 
                var db = response.getReturnValue();
                if(db.payList !=null){
                    component.set('v.paymentSchedules', db.payList );
                }
                else{
                    console.log('else');
                }
            }
        });
        $A.enqueueAction(action); 
    },
    saveSchedules : function(component,event,helper) {
        var schedules;
        var patType = component.get('v.paymentType');
        if(patType == 'Standard'){
            schedules = component.get('v.paymentSchedules');
        }
        else if(patType == 'Custom'){
            schedules = component.get('v.CustompaymentSchedules');
        }
        var action=component.get("c.insertSchedules");
        action.setParams({'payList':schedules,
                          'gt':component.get('v.GrandTotal'),
                          'quoteid':component.get('v.quoteId')});
        action.setCallback(this,function(response){ 
            if(response.getState() == "SUCCESS"){ 
                component.set("v.paymentSchedules", []);
                component.set('v.GrandTotal',0.00);
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": component.get('v.quoteId'),
                    "slideDevName": "detail"
                });
                debugger;
                navEvt.fire();
                component.set('v.quoteId','');
            }
            else if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                }
            }
            debugger;
        });
        $A.enqueueAction(action); 
    }
    
})