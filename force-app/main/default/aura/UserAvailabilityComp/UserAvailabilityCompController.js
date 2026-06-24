({
    doInit: function(component, event, helper) {
        helper.getUsers(component);
    },
    
    selectChange:function(component, event, helper) {
       var user=component.get('v.usr');
       helper.onChange(component,event,'');
    },
    closePopUP:function(component, event, helper)
    {
         var user=component.get('v.usr');
        user.Availability__c = true;
        component.set('v.usr', user);
        component.set("v.isFalse", false);
    },
    submitDetails:function(component, event, helper)
    {
      var reasone= component.find('reasone').get('v.value');
        if(reasone.length>0)
        {helper.onChange(component,event,reasone);
         component.set('v.isFalse',false);}
        else{
             var toastsuccessEvent = $A.get("e.force:showToast");
              toastsuccessEvent.setParams({
                    "title": "Select Reasone.",
                    "message": "Please Select the Reasone.",
                    "type" : "error"
                });
            toastsuccessEvent.fire(); 
        }
          
    }
})