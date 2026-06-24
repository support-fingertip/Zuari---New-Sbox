({
    doInit : function(component, event, helper) {
        console.log('recordId'+component.get("v.recordId"));
        
        console.log('sObjectName'+component.get("v.sObjectName"));
        
        
        /* ===== COMMENTED OUT: Last Receipt Approval Status Check =====
        var action=component.get("c.getLastReiptApprovalStatus");
        action.setParams({'recid':  component.get('v.recordId') })
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){ 
                var datas=response.getReturnValue();
                
                if(datas =='Approved' || datas =='Rejected' || datas == 'No Receipt Found'){
                    
                    var evt = $A.get("e.force:navigateToComponent");
                    evt.setParams({
                        componentDef : "c:ReceiptComponentSampleDevComp",
                        componentAttributes: {
                            recordId : component.get("v.recordId"),
                            sObjectName : component.get("v.sObjectName")
                        }
                    });
                    evt.fire();
                    
                }else{
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":"Success",
                        "message":  "Please Approved Last Pending Receipt Before creating New Receipt"
                    });
                    toastEvent.fire();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get('v.recordId'),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }
                
            }
        });
        
        $A.enqueueAction(action); 
        ===== END COMMENTED BLOCK ===== */
        
        
        // Directly navigate to the receipt component without checking approval status
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:ReceiptComponentSampleDevComp",
            componentAttributes: {
                recordId : component.get("v.recordId"),
                sObjectName : component.get("v.sObjectName")
            }
        });
        evt.fire();
        
    }
})