({
    doInit : function(component, event, helper) {
        if(component.get("v.LeadRecord").Customer_Approved_Sale_Agreement__c == true){
            var action=component.get("c.sendRequestForAgreementAmount");  
            action.setParams({'recId':  component.get('v.recordId') });
            action.setCallback(this,function(response){
                if(response.getState()=="SUCCESS"){ 
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "The Request For Sale Agreement Sent Successfully.",
                        "type":"success"
                    });
                    toastEvent.fire();
                    
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.force:closeQuickAction").fire();
                    
                }
            });
            $A.enqueueAction(action);
        }
        else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please mark 'Customer Approved Sale Agreement' checkbox to request for approval",
                "type":"error"
            });
            toastEvent.fire();
            $A.get('e.force:refreshView').fire();
            $A.get("e.force:closeQuickAction").fire();
        }
        
    }
})