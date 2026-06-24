({
    getPickListValue : function(component, event, helper)
    {
        //var recoooordif = component.get("v.recordId");
        //alert('hiii getPickListValue  '+ recoooordif)
        var action = component.get("c.getPickListValues");
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                var ProjectPickList = response.getReturnValue();
                console.log(ProjectPickList);
               component.set('v.accounts',ProjectPickList)
               
            }
        });
        $A.enqueueAction(action);
    },
    
	toastMsg : function (type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg
        });
        toastEvent.fire();
    }
})