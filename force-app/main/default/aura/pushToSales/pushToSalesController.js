({
    doInit : function(component, event, helper) {
       // var siteVisitCheck = component.get("v.LeadRecord").Is_Site_Visit_Mandatory__c;
      //  var svcreated = component.get("v.LeadRecord").Is_Site_Visit_Created__c;
        /*
        if(siteVisitCheck == true && svcreated == false){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                message: 'Please Create atleast one site visit',
                type : 'error'
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
            
        }      */  
        
    },
    pushToSalesComp : function(component, event, helper){
          component.set("v.isButtonDisabled", true);
       // var recordEditForm = component.get("v.selectedProject");
       // alert(recordEditForm)
        var transferNotes = component.get("v.newNote");
       /* if(recordEditForm == '' || recordEditForm == 'None' || recordEditForm ==null || recordEditForm == undefined){
            component.set("v.isButtonDisabled", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                message: 'Please Select Project Name',
                type : 'error'
            });
            toastEvent.fire();
        }
        else*/
            if(transferNotes == '' || transferNotes == 'None' || transferNotes ==null || transferNotes == undefined){
            component.set("v.isButtonDisabled", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                message: 'Please Enter transfer notes',
                type : 'error'
            });
            toastEvent.fire();
        }
          /*  else{
                 // First, check if the site visit is scheduled
    var ld = component.get("v.recordId");
    var checkAction = component.get("c.isSiteVisitScheduled");
    checkAction.setParams({ LdId : ld });
    
    checkAction.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
            var isScheduled = response.getReturnValue();
            if (!isScheduled) {
                
                // Show error toast if no scheduled site visit is found
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message: 'Please create a site visit before moving to sales.',
                    type: 'error'
                });
                toastEvent.fire();
                  $A.get("e.force:closeQuickAction").fire();
                component.set("v.isButtonDisabled", false);
	
            } 
            else {
                component.set("v.isButtonDisabled", true);
                // Call moveToSales if the site visit is scheduled
                var action = component.get("c.moveToSales");
                action.setParams({ 
                    LeadId: component.get("v.recordId"),
                    project : recordEditForm,
                    addNote: component.get("v.newNote")
                });
                
                action.setCallback(this, function(response) {
                     component.set("v.isButtonDisabled", true);
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            message: 'Lead moved to sales team',
                            type: 'success'
                        });
                        toastEvent.fire(); 
                        
                        
                        var listviews = response.getReturnValue();
                        
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": listviews
                        });
                        navEvt.fire();
                        $A.get('e.force:refreshView').fire();
                        
                    }
                });
                $A.enqueueAction(action);
                
            }
            
            
        }
       
    });
    $A.enqueueAction(checkAction);

            }
        */
         else {
                component.set("v.isButtonDisabled", true);
                // Call moveToSales if the site visit is scheduled
                var action = component.get("c.moveToSales");
                action.setParams({ 
                    LeadId: component.get("v.recordId"),
                    addNote: component.get("v.newNote")
                });
                
                action.setCallback(this, function(response) {
                     component.set("v.isButtonDisabled", true);
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            message: 'Lead moved to sales team',
                            type: 'success'
                        });
                        toastEvent.fire(); 
                        
                        
                        var listviews = response.getReturnValue();
                        
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": listviews
                        });
                        navEvt.fire();
                        $A.get('e.force:refreshView').fire();
                        
                    }
                });
                $A.enqueueAction(action);
                
            }
           
        
    },
    closeModel :function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})