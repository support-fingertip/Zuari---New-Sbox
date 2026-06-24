({
	onInit : function (component, event, helper) {
        let action = component.get("c.readContacts");
         action.setParams({ 
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            //alert(state);
            if (state == "SUCCESS") {
                let result=response.getReturnValue();
                if(result !== undefined && result != null  && result.length > 0){
                    //component.set("v.phoneList",result);
                    //Added by basavaraj on 5/12/2025 
                    let phoneList = [];
                    
                    result.forEach(phone => {
                        let masked = phone.substring(0, 7)
                        + '*'.repeat(phone.length - 4)
                        + phone.substring(phone.length - 2);
                        
                        phoneList.push({
                        masked: masked,
                        actual: phone
                    });
                });
                
                component.set("v.phoneList", phoneList);
                    if(result.length > 0){
                        component.set("v.selectedPhone", result[0]);
                    }
                }
            else{
                
                helper.displayMessage(component,"There is no Phone number for this lead"+message, "error");
            }
            }
            else if(state === "ERROR"){
                let errors = response.getError();
                let message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                helper.displayMessage(component,"Something went wrong. Message-"+message, "error");
                console.error('Error-'+message);
            }else{
                helper.displayMessage(component,"Something went wrong.", "error");
            }
        });
        $A.enqueueAction(action);
    },
    
    callNumber : function (component, event, helper) {
         var action = component.get("c.callCustomer");
        console.log('recordId@@@@@@@@@@@@@@@@'+component.get("v.recordId"));
        console.log('selectedPhone---------------'+component.get("v.selectedPhone"));
         action.setParams({ 
             recordId : component.get("v.recordId"),
             phone : component.get("v.selectedPhone")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            //alert('Success');
            if (state == "SUCCESS") {
                let result=response.getReturnValue();
                if(result !== undefined && result != null && result == true){
                    var msg = 'Your call will soon be connected. ';
                    component.set("v.isdisabled",false);
                    helper.displayMessage(component, msg , "success");
                    component.set('v.displayCall', true);
                    component.set("v.selectedPhone", '');
                    if(component.get('v.fromQucickAction')){
                       component.set('v.showComments',true);
                        component.set('v.spinner',true);
                        component.set("v.recordOwner", component.get("v.LeadRecord").OwnerId);
                        var userId = $A.get("$SObjectType.CurrentUser.Id");
                        var primaryUser = component.get("v.LeadRecord").isCurrentUser__c;
                        alert(primaryUser);
                        var secondaryUser = component.get("v.LeadRecord").isCurrentUserSec__c;
                        alert(secondaryUser);
                        if(primaryUser == true){
                            component.set('v.isPrimary',true);
                        }
                        if(secondaryUser == true){
                            component.set('v.isSecondary',true);
                        }
                    }
                }else{
                    component.set("v.isdisabled",false);
                    helper.displayMessage(component, result , "error");
                    if(component.get('v.fromQucickAction')){
                        $A.get("e.force:closeQuickAction").fire();
}
                     //helper.displayMessage(component,"Something went wrong. Lead Owner should be same to make call", "error");  
              
                    //helper.displayMessage(component,"Something went wrong. Message-"+result, "error");  
                }
            }else if(state === "ERROR"){
                
                let errors = response.getError();
                let message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                helper.displayMessage(component,"Something went wrong. Message-"+message, "error");
                console.error('Error-'+message);
                    if(component.get('v.fromQucickAction')){
                        $A.get("e.force:closeQuickAction").fire();
}
            }else{
                helper.displayMessage(component,"Something went wrong.", "error");
                    if(component.get('v.fromQucickAction')){
                        $A.get("e.force:closeQuickAction").fire();
}
            }
        });  
        $A.enqueueAction(action);
    },
    
    displayMessage : function(component,message,type){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "message": message
        });
        toastEvent.fire();
        //Close the Pop up in Home Notification 
       if ( type=='success'  && (component.get("v.fromHome") == true)) {
        var parentComponent = component.get("v.parent");
        parentComponent.closePopUp();
      }    
        
    },  
    getDetails : function(component, event, helper, payload) {
       if(payload.UserId__c  == $A.get( "$SObjectType.CurrentUser.Id" )){ 
            if(payload.RecordId__c  == component.get("v.recordId")  && payload.TaskId__c  != undefined ){ 
                component.set('v.callcomplete',true);
                component.set('v.taskId',payload.TaskId__c );
            } 
        } 
     },
     getCallDetails : function(component, event, helper, payload) {
       if(payload.User_Id__c == $A.get( "$SObjectType.CurrentUser.Id" )){ 
                if(payload.Record_Id__c == component.get('v.recordId')  ){
                     component.set('v.displayCall', true); 
                     component.set('v.callcomplete',false);
                }
          }
    },
    readCallDetails : function(component, event, helper) {
         let action = component.get("c.readstatus");
         action.setParams({ 
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state == "SUCCESS") {
                     component.set('v.displayCall', response.getReturnValue());
            } 
        });
        $A.enqueueAction(action);
     }  
    ,saveCall: function(component, event, helper) {  
        let action = component.get("c.saveCallSummary");
        action.setParams({ 
            taskId: component.get("v.taskId"),
            summary: document.getElementById("textareaid01").value,
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state == "SUCCESS") {
                    component.set('v.displayCall',false);
                    helper.displayMessage(component, 'Summary Saved Succesfully' , "success");
            }else{
                helper.displayMessage(component,"Something went wrong.", "error");
            } 
        });
        $A.enqueueAction(action);
     },
         
         getInitialValues : function(component) {
             var action = component.get("c.getInitialValues"); // Apex method
             
             action.setParams({
                 recordId : component.get("v.recordId")
             });
             
             action.setCallback(this, function(response) {
                 var state = response.getState();
                 if (state === "SUCCESS") {
                     var result = response.getReturnValue();
                     component.set("v.showLeadQuality", result.showLeadQuality);
                 } else {
                     console.error(response.getError());
                 }
             });
             
             $A.enqueueAction(action);
         }



})