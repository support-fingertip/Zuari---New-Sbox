({
	showBulkDemand : function(component, event, helper){
   
                   var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:BulkRaiseDemand", 
                componentAttributes: {
                    recordId : component.get("v.recordId"),
                    sObjectName : component.get("v.sObjectName"),
                    isStandard : true
                }
            });
            evt.fire();
    }
})