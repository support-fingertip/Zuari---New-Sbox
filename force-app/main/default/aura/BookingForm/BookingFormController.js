({
	 doInit : function(component, event, helper) {
         
		component.set('v.showPdf',true);         
         var leadRecord = component.get("v.LeadRecord");
         if (leadRecord.Project__c == 'Zuari Gangothri Tribhuja') {
             var vfpage = 'https://zuari.lightning.force.com/apex/Booking_Form_ZGT?id='+component.get('v.recordId');	
             component.set('v.vfPage',vfpage);
         } else if(leadRecord.Project__c == 'Zuari Garden City') {
             var vfpage = 'https://zuari.lightning.force.com/apex/BookingFormZGC?id='+component.get('v.recordId');	
             component.set('v.vfPage',vfpage);
         }
        
      
			 
            },
    send: function(component,event,helper){
         component.set("v.isSending", true);
        var action = component.get("c.sendEmailtoCustomer");
        action.setParams({"recId":component.get("v.recordId")});
        action.setCallback(this,function(response){
            if(response.getState() == 'SUCCESS' ) {
                
                var res_string= response.getReturnValue();
                event.stopPropagation();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var type;
                if(res_string == 'Booking form sent to customer'){
                    //system.debug(res_string);
                    type = 'success';
                }
                else{
                    type = 'error';
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":type,
                    "title": type,
                    "message":res_string,
                    "duration":10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                (state === 'ERROR')
                {
                    console.log('failed');
                }
            }
        });
        $A.enqueueAction(action);
    },
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
      sendEmail : function(component, event, helper) {
          
        component.set("v.isPopup", false);
    },
    closeModal : function(component, event, helper) {
        // Close the confirmation modal
        component.set("v.isPopup", false);
    },	
       // });
       //$A.enqueueAction(action);
})