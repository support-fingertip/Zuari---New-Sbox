({
    doInit: function(component, event, helper) {
        //helper.addProductRecord(component, event,helper);
        var action=component.get("c.getPlots");  
        action.setParams({'recId':  component.get('v.recordId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var plots = response.getReturnValue();
                console.log('plots:'+plots);
                component.set("v.plots",plots);
                component.set("v.showNextCmp", false);
                
            }
        });
        $A.enqueueAction(action);
        
        var action1 = component.get("c.getPaymentTypePicklistValues");
        action1.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var paymentTypePicklist = response.getReturnValue();
                component.set("v.paymentTypePicklist", paymentTypePicklist);
            }
        });
        $A.enqueueAction(action1);
        
        
    },
    searchText1 : function(component, event, helper) {
        var plot= component.get('v.plots');
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
    
    update1: function(component, event, helper) {
        component.set('v.Showfields', false);
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchplots');
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var opp = component.get("v.OppRecord");
        
        for(var i=0;i<plt.length; i++){  
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.Showfields', true);
                    component.set('v.searchText1', plt[i].Name);
                    component.set('v.projectName', plt[i].Project__r.Name);
                    component.set('v.flatNumber', plt[i].Name);
                }
                selPlot = plt[i];
               // alert(plt[i].Project__r.Project_Type__c)
                if(plt[i].Project__r.Project_Type__c=='Villas'){
                    oppPlot.RecordTypeId='012GB00000228dSYAQ';
                oppPlot.Villa_No__c = plt[i].Name;
                }else{
                    oppPlot.RecordTypeId='012GB00000228dRYAQ';
                oppPlot.Flat_No__c = plt[i].Name;
                    
                }
                oppPlot.Unit__c = plt[i].Id;
                oppPlot.Project__c = plt[i].Project__r.Project__c;
                oppPlot.Plot_Type__c = plt[i].Project__r.Plot_Type__c;
                //oppPlot.Plot_Number__c = plt[i].Plot_Number__c;
                oppPlot.Plot_Size__c = plt[i].Plot_Size__c;
                oppPlot.Unit_Facing_Direction__c = plt[i].Unit_Facing_Direction__c;
                oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                oppPlot.Basic_Price__c = plt[i].Basic_Price__c;
                // oppPlot.Tower__c = plt[i].Tower__c;
                oppPlot.East_North_Charges__c = plt[i].East_North_Charges__c;
                oppPlot.Corner_Charges__c = plt[i].Corner_Charges__c;
                oppPlot.Piped_Gas__c = plt[i].Piped_Gas__c;
                oppPlot.Mutation__c = plt[i].Mutation__c;
                oppPlot.Stamps_Duty__c = plt[i].Stamps_Duty__c;
                oppPlot.Floor_Rise_Charges_Rate__c = plt[i].Floor_Rise__c;
                oppPlot.Block_Lookup__c = plt[i].Block1__c;
				           
                oppPlot.BESCOM_Deposit_Rs__c = plt[i].BESCOM_Deposit_Rs__c;
                //oppPlot.East_Facing__c = plt[i].East_Facing__c;
                oppPlot.Sale_Area__c = plt[i].Sale_Area__c;
                if(plt[i].Sale_Area__c<1400){
                    component.set('v.singlecarparking', true);
                    component.set('v.waterconnectiondoublebed', true);
                    
                    
                }
                oppPlot.Single_Car_Parking__c = plt[i].Single_Car_Parking__c;
                oppPlot.Water_Connection_Charges_for_Double_Bed__c = plt[i].Water_Connection_Charges_for_Double_Bed__c;
                //oppPlot.Car_Parking_Charge__c = plt[i].Car_Parking_Charge__c;
                //oppPlot.Infrastructure_Charges_per_sqft__c = plt[i].Infrastructure_Charges_per_sqft__c;
                oppPlot.Built_up_area__c = plt[i].Built_up_area__c;
                oppPlot.Carpet_Area__c = plt[i].Carpet_Area__c;
                //oppPlot.Balcony_Area__c = plt[i].Terrace_Area__c;
                oppPlot.GST1__c = plt[i].GST1__c;
                //oppPlot.Block__c = plt[i].Block__c;
                oppPlot.Development_Charge__c = plt[i].Development_Charge__c;
                oppPlot.Maintenance_Charge__c = plt[i].Maintenance_Charge__c;
                oppPlot.Premium_Charge__c = plt[i].Premium_Charge__c;
                oppPlot.Plot_Land_Area__c = plt[i].Plot_Land_Area__c;
                oppPlot.Clubhouse_Charges__c = plt[i].Clubhouse_Charges__c;
                oppPlot.Legal_Documentation_Charges__c = plt[i].Legal_Charges__c;
                oppPlot.Corpus_Fund__c = plt[i].Corpus_Fund__c;
                oppPlot.Maintenance_Deposite__c = plt[i].Maintenance_Deposite__c;
                oppPlot.Apartment_No__c = plt[i].Apartment_No__c;
                oppPlot.Fixed_Land_Sqft__c = plt[i].Fixed_Land__c;
                oppPlot.Extra_Land_Sqft__c = plt[i].Extra_Land__c;
                oppPlot.Fixed_Land_Charges__c = plt[i].Fixed_Land_Charges__c;
                oppPlot.Amenities_Charges_For_Villa__c = plt[i].amenities_charges__c;
                oppPlot.Project_Type__c = plt[i].Project__r.Project_Type__c;
                oppPlot.Floor__c = plt[i].Floor__c;
                oppPlot.Corpus_Fund_for_Villas__c = plt[i].Corpus_Fund_for_Villas__c;
                oppPlot.Park_Facing__c = plt[i].Park_Facing__c;
                oppPlot.Forest_Facing__c = plt[i].Forest_Facing__c;
                oppPlot.Corner_charges_for_Villa__c = plt[i].Corner_charges_for_Villa__c;
                oppPlot.East_north_Charges_for_Villa__c = plt[i].East_north_Charges_for_Villa__c;
                oppPlot.Maintenance_Charge_For_Villa__c = plt[i].Maintenance_Charge_For_Villa__c;

                //oppPlot.Quote_date__c = today;
                
                //helper.handleCalculations(component, event, helper);    
                break;
            } 
        } 
        component.set('v.matchplots',[]);
        //component.set('v.showCostSheet',true);
        component.set('v.plots', selPlot);
        component.set('v.oppPlot',oppPlot);
        
    },
    doSave: function(component,event,helper) {
        
        if (helper.validate(component, event)) {
            helper.save(component,event,helper);
        }
    },
    closeModel: function(component, event, helper) {
         $A.get('e.force:closeQuickAction').fire();
         $A.get('e.force:refreshView').fire();
     }
    
})