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
                component.set('v.projectName',ProjectPickList)
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
    },
    /*retrieveUnitData: function(component, unitId) {
        var action = component.get("c.fetchUnitData");
        action.setParams({ unitId : unitId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var unitData = response.getReturnValue();
                component.set("v.ratePerSqFeet", unitData.Basic_Price__c);
                component.set("v.plotSize", unitData.Built_up_area__c);
                component.set("v.basicprice", unitData.Basic_Price__c * unitData.Built_up_area__c);
            } else {
                console.log("Failed to retrieve Unit data");
            }
        });
        $A.enqueueAction(action);
    }*/
})