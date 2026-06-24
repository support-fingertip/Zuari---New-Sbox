({
	doInit : function(component, event, helper) {
        helper.showBulkDemand(component, event, helper);
    /*var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
        componentDef : "c:BulkRaiseDemand",
        componentAttributes: {
            recordId : component.get("v.recordId"),
            sObjectName : component.get("v.sObjectName")
        }
    });
    evt.fire();*/
},
    selectStandCus : function(component, event, helper) {
        var standCusType = component.get('v.standCustType');
        if(standCusType == 'Project'){
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
        if(standCusType == 'Block'){
            var action = component.get("c.getTowerRecords");
            action.setParams({ "masterPaymentScheduleId": component.get('v.recordId')});
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.plots',response.getReturnValue());
                    /*component.set("v.bookingRecords", response.getReturnValue());
                    var evt = $A.get("e.force:navigateToComponent");
                    evt.setParams({
                        componentDef : "c:BulkRaiseDemand", 
                        componentAttributes: {
                            recordId : component.get("v.recordId"),
                            sObjectName : component.get("v.sObjectName"),
                            isStandard : true,
                            bookingRecords : component.get("v.bookingRecords")
                        }
                    });
                    evt.fire();*/
                } else {
                    console.error("Error fetching Booking records");
                }
            });
            
            $A.enqueueAction(action);
        }
    },
    
    searchText1 : function(component, event, helper){
    var plot = component.get('v.plots');
        component.set('v.showCostSheet',false);
        var searchText1= component.get('v.searchText1');
        console.log(searchText1.length)
        if(searchText1.length < 1){
            console.log(searchText1)
        }
        var matchplots=[];
        if(searchText1 !=''){
            for(var i=0;i<plot.length; i++){ 
                if(plot[i].Name.toLowerCase().indexOf(searchText1.toLowerCase())  != -1  ){
                    
                    if(matchplots.length <50){
                        matchplots.push( plot[i] );
                        
                    }else{
                        break;
                    }
                } 
            } 
            if(matchplots.length >0){
                component.set('v.matchplots',matchplots);
            }
        }else{
            component.set('v.matchplots',[]);
        }
},
    
    update1 : function(component, event, helper){
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.plots');
         for(var i=0;i<plt.length; i++){  
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.searchText1', plt[i].Name);
                    component.set('v.matchplots',[]);
                    //alert(plt[i].Id);
                    var action = component.get("c.getBookingRecordsWithTower");
                    action.setParams({ "masterPaymentScheduleId": component.get('v.recordId'),
                                      "TowerId": plt[i].Id});
                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            //alert(response.getReturnValue());
                            var evt = $A.get("e.force:navigateToComponent");
                            evt.setParams({
                                componentDef : "c:BulkRaiseDemand", 
                                componentAttributes: {
                                    recordId : component.get("v.recordId"),
                                    sObjectName : component.get("v.sObjectName"),
                                    isStandard : true,
                                    bookingRecords : response.getReturnValue(),
                                    fromDescription : 'FromBlock'
                                }
                            });
                            evt.fire();
                        }
                        
                    });
                    $A.enqueueAction(action);
                }
            }
         }
        
    }
})