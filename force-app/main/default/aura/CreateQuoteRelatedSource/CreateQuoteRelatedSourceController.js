({
    doInit: function(component, event, helper) {
        helper.addProductRecord(component, event,helper);
        var action=component.get("c.getPlots");  
        action.setParams({'recId':  component.get('v.recordId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var result = response.getReturnValue();
                   if (result) {
                      
                    // Set Project Name and Plot List separately
                    component.set("v.LeadprojectName", result.projectName);
                    component.set("v.projectType", result.projectType);

                    // For Apartments: show Block lookup first, units come after block selection
                    if (result.projectType === 'Apartments') {
                        component.set("v.plots", []);
                        component.set("v.showUnits", false);
                        // Load blocks for the project
                        var blockAction = component.get("c.getBlock");
                        blockAction.setParams({'recId': component.get('v.recordId')});
                        blockAction.setCallback(this, function(blockResponse){
                            if(blockResponse.getState() === "SUCCESS"){
                                var blocks = blockResponse.getReturnValue();
                                component.set("v.blocks", blocks);
                                component.set("v.showBlockLookup", true);
                            }
                        });
                        $A.enqueueAction(blockAction);
                    } else {
                        // For non-Apartments (Plots, Villas): load all units directly
                        component.set("v.plots", result.plots);
                        if (result.plots && result.plots.length > 0) {
                            component.set("v.showUnits", true);
                        } else {
                            component.set("v.showUnits", false);
                            console.log('⚠️ No plots found for project:', result.projectName);
                        }
                    }

                    // Load Payment Plans for the project
                    var action4 = component.get("c.getPyamentPlan");
                    action4.setParams({'project': result.projectName});
                    action4.setCallback(this, function(response){
                        if(response.getState() === "SUCCESS"){
                            var pymnpln = response.getReturnValue();
                            component.set("v.paymentplan", pymnpln);
                        }
                    });
                    $A.enqueueAction(action4);
                   }
               // component.set("v.plots",blocks);
              //  component.set("v.showUnits", true);
                
            }
             else if (response.getState() === "ERROR") {
                var errors = response.getError();
                console.error("❌ Error fetching plots:", JSON.stringify(errors));
                component.set("v.showUnits", false);

                let message = (errors && errors[0] && errors[0].message) ? errors[0].message : "Unknown error";
             //   alert("Error while fetching plots: " + message);
            } 
            else {
                console.warn("⚠️ Unexpected response state:", state);
            }
            
        });
        $A.enqueueAction(action);
        /*
        var action=component.get("c.getBlock");  
        action.setParams({'recId':  component.get('v.recordId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var blocks = response.getReturnValue();
                component.set("v.blocks",blocks);
                component.set("v.showBlockLookup", true);
                
            }
        });
        $A.enqueueAction(action);
        */
        /*   var actionT=component.get("c.quotationqquery");  
        actionT.setParams({'Leadid':  component.get('v.recordId') });
        actionT.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var plots = response.getReturnValue();
                component.set("v.ismultiplequotes", plots);
                console.log('plots:'+plots);
              
                
            }
        });
        $A.enqueueAction(actionT);
        */
        
        var action1 = component.get("c.getPaymentTypePicklistValues");
        action1.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var paymentTypePicklist = response.getReturnValue();
                component.set("v.paymentTypePicklist", paymentTypePicklist);
            }
        });
        $A.enqueueAction(action1);
        
        
        
        
    },
    handleInputChange: function(component, event, helper) {
        helper.handleCalculations(component, event, helper);
    },
    searchText2 : function(component, event, helper){
        
        var block= component.get('v.blocks');
        
        component.set('v.showCostSheet',false);
        var searchText1= component.get('v.searchText2');
        //alert(searchText1+ '--'+ JSON.stringify(block))
        if(searchText1.length < 1){
            console.log(searchText1)
        }
        var matchblocks=[];
        if(searchText1 !=''){
            for(var i=0;i<block.length; i++){ 
                if(block[i].Name.toLowerCase().indexOf(searchText1.toLowerCase())  != -1  ){
                    if(matchblocks.length <70){
                        matchblocks.push( block[i] );
                    }else{
                        break;
                    }
                } 
            } 
            if(matchblocks.length >0){
                component.set('v.matchblocks',matchblocks);
            }
        }else{
            component.set('v.showUnits',false);
            component.set('v.matchblocks',[]);
        }
    },
     searchText1 : function(component, event, helper) {
        //alert('Enetr 1');
        var plot= component.get('v.plots');
        //alert(plot);
        component.set('v.+',false);
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
   
    update2 : function(component, event, helper){
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchblocks');
        var oppPlot = component.get('v.oppPlot');

        for(var i=0;i<plt.length; i++){
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.searchText2', plt[i].Name);
                    // Fetch units filtered by selected block
                    var action=component.get("c.getPlotsByBlock");
                    action.setParams({'blockId': edi});
                    action.setCallback(this,function(response){
                        if(response.getState()=="SUCCESS"){
                            var result = response.getReturnValue();
                            component.set("v.plots", result);
                            component.set("v.showNextCmp", false);
                            component.set('v.showUnits', true);
                            component.set('v.blockId', edi);
                            component.set('v.matchblocks', []);
                            // Clear previous unit selection
                            component.set('v.searchText1', '');
                            component.set('v.Showfields', false);
                            component.set('v.showCostSheet', false);
                        }
                    });
                    $A.enqueueAction(action);
                }
                oppPlot.Block_Lookup__c = plt[i].Id;
                component.set('v.oppPlot',oppPlot);
                break;
            }
        }
        
    },
    
    update1: function(component, event, helper) {
        component.set('v.Showfields', false);
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchplots');
        var selPlot= component.get('v.plots');
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var opp = component.get("v.OppRecord");
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        for(var i=0;i<plt.length; i++){ 
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.Showfields', true);
                    component.set('v.searchText1', plt[i].Name);
                    component.set('v.projectName', plt[i].Project__r.Name);
                    component.set('v.flatNumber', plt[i].Name);
                    //alert(plt[i].Block1__c);
                    component.set('v.blockName', plt[i].Block1__c);
                    component.set('v.projectType',plt[i].Project__r.Project_Type__c);
                }
                selPlot = plt[i];
                if( plt[i].Project__r.Project_Type__c == 'Apartments')
                {
                    // Unit Information
                    oppPlot.Property_Type__c = 'Apartments';
                    oppPlot.Related_Source__c=component.get('v.recordId');
                    oppPlot.Unit__c = plt[i].Id;
                    oppPlot.Project__c = plt[i].Project__r.Project__c;
                    oppPlot.Tower__c = plt[i].Tower__c;
                    oppPlot.Floor__c = plt[i].Floor__c;
                    oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                    oppPlot.Unit_Facing_Direction__c = plt[i].Unit_Facing_Direction__c;
                    oppPlot.Super_Built_UpArea__c = plt[i].Super_Built_up_Area__c;
                    oppPlot.Carpet_Area__c = plt[i].Carpet_Area_in_SFT__c;
                    oppPlot.Balcony_Area_Sq_ft__c = plt[i].Balcony_in_SFT__c;
                    oppPlot.UDS_in_Sqyards__c = plt[i].UDS_in_Sqyards__c;
                    oppPlot.Corner_Non_Corner__c = plt[i].Corner_Non_Corner__c;
                    oppPlot.Mort_Non_Mortgage__c = plt[i].Mort_Non_Mortgage__c;
                    oppPlot.Utility_in_SFT__c = plt[i].Utility_in_SFT__c;

                    // Component of Agreement Value (per sq.ft rates)
                    oppPlot.Rate_per_sqft__c = plt[i].Rate_per_sqft__c;
                    oppPlot.Floor_Rise_Charges_Rate__c = plt[i].Floor_Rise_Charge__c;
                    oppPlot.Facing_charges__c = plt[i].East_Facing_Charges__c || 0;
                    oppPlot.Corner_Charges__c = plt[i].Corner_Charges__c;
                    oppPlot.Road_View_Charges__c = plt[i].Road_View_Charges__c;
                    oppPlot.ORR_View_Charges__c = plt[i].ORR_View_Charges__c;
                    oppPlot.Garden_View_Charges__c = plt[i].Garden_View_Charges__c;

                    // Other Charges (fixed amount)
                    oppPlot.Clubhouse_Charges__c = plt[i].Clubhouse_Charges__c;
                    oppPlot.Water_Electricity_Rate__c = plt[i].Water_Electricity_Charges__c;
                    oppPlot.Car_Parking__c = plt[i].Car_Parking__c;

                    // Passthrough Charges
                    oppPlot.Corpus_Fund__c = plt[i].Corpus_Fund__c;
                    oppPlot.Maintenance_Charge__c = plt[i].Project__r.Maintenance_Charge_Rate__c;
                    oppPlot.Legal_Documentation_Charges__c = plt[i].Legal_Documentation_Charges__c;

                    // CHANGE 1: Always populate GST defaults from project on unit selection for Apartments
                    oppPlot.GST_for_Aggrement_Value__c = plt[i].Project__r.GST_on_Aggrement__c;
                    oppPlot.GST_For_Other_Charges__c = plt[i].Project__r.GST_on_Other__c;
                }
                if( plt[i].Project__r.Project_Type__c == 'Villas')
                {
                    oppPlot.Property_Type__c = 'Villas';
                    oppPlot.Related_Source__c=component.get('v.recordId');
                    oppPlot.Unit__c = plt[i].Id;
                    oppPlot.Block_Lookup__c = plt[i].Block_Lookup__c;
                    oppPlot.Project__c = plt[i].Project__r.Project__c;
                    oppPlot.Block__c = plt[i].Block__c;
                    oppPlot.Wing__c = plt[i].Wing__c;
                    oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                    oppPlot.Super_Built_UpArea__c = plt[i].Super_Built_up_Area__c;
                    oppPlot.Rate_per_sqft__c = plt[i].Rate_per_sqft__c;
                    oppPlot.Maintenance_Charge__c = plt[i].Maintenance_Charge__c;
                    oppPlot.Floor_Rise_Charges_Rate__c = plt[i].Floor_Rise_Charge__c;
                    oppPlot.Guideline_Value__c = plt[i].Project__r.Guideline_Value_Charges__c;
                    oppPlot.Home_Automation_Rate__c = plt[i].Project__r.Home_Automation__c;
                    oppPlot.Unit_Facing_Direction__c = plt[i].Unit_Facing_Direction__c;
                }
                if( plt[i].Project__r.Project_Type__c == 'Plots')
                {
                    oppPlot.Property_Type__c = 'Plots';
                    oppPlot.Related_Source__c=component.get('v.recordId');
                    oppPlot.Unit__c = plt[i].Id;
                    oppPlot.Plot_Type__c = plt[i].Plot_Type__c;
                    oppPlot.Block_Lookup__c = plt[i].Block_Lookup__c;
                    oppPlot.Project__c = plt[i].Project__r.Project__c;
                    oppPlot.Block__c = plt[i].Block__c;
                    oppPlot.Wing__c = plt[i].Wing__c;
                    oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                    oppPlot.Super_Built_UpArea__c = plt[i].Super_Built_up_Area__c;
                    oppPlot.Rate_per_sqft__c = plt[i].Rate_per_sqft__c;
                    oppPlot.Unit_Facing_Direction__c = plt[i].Unit_Facing_Direction__c;
                    oppPlot.Infrastructure_Charges_per_sqft__c = plt[i].Infrastructure_Charges_per_sqft__c;
                    oppPlot.Maintenance_Charge__c=plt[i].Project__r.Maintenance_Charge_Rate__c;
                    oppPlot.Clubhouse_Charges__c=plt[i].Project__r.Clubhouse_Charges__c;
                    oppPlot.PLC_Charges__c=plt[i].PLC_Charges__c;
                }
                
                component.set('v.GrandTotal',plt[i].Sale_Consideration__c);
                component.set('v.GrandTotalwithGST',plt[i].Total_Payable_Charges__c);
                
                oppPlot.Quote_date__c = today;
                
                oppPlot.Projects__c = plt[i].Project__c;
                
                component.set('v.today', today);
                component.set('v.RecTypeId',plt[i].Name);
                helper.handleCalculations(component, event, helper);    
                break;
            } 
        } 
        component.set('v.showCostSheet',true);
        // component.set('v.plots', selPlot);
        component.set('v.oppPlot',oppPlot);
        component.set('v.matchplots',[]);
        
    },
      searchText3 : function(component, event, helper) {
        var pymntp= component.get('v.paymentplan');
       
        var searchText= component.get('v.searchText3');
        console.log(searchText.length)
      
        if(searchText.length < 1){
            console.log(searchText)
            //$A.util.toggleClass(open, 'slds-is-open');
        }
        var matchpaymentplan=[];
        if(searchText !=''){
            for(var i=0;i<pymntp.length; i++){ 
                if(pymntp[i].Name.toLowerCase().indexOf(searchText.toLowerCase())  != -1  ){
                    
                    if(matchpaymentplan.length <50){
                        matchpaymentplan.push( pymntp[i] );
                    }
                    else{
                        break;
                    }
                } 
            } 
           // alert(matchpaymentplan)
            if(matchpaymentplan.length >0){
                component.set('v.matchpaymentplan',matchpaymentplan);
               // component.set('v.showqute',true);
            }
        }
        else{
            component.set('v.matchpaymentplan',[]);
             component.set('v.showqute',true);
            
      //  var selectedValue = component.find("projectSelect").get("v.value");
            
        var selectedValue= component.get('v.LeadprojectName');
           // alert(selectedValue);
            
          // getting Payment Plan
          
       var action4=component.get("c.getPyamentPlan");  
       
        action4.setParams({'project':selectedValue});
        action4.setCallback(this,function(response){
           
            if(response.getState()=="SUCCESS"){ 
                var pymnpln = response.getReturnValue();
               
                component.set("v.paymentplan",pymnpln);
            }
        });
        $A.enqueueAction(action4);
            
       
        }
    },
  
     update3 : function(component, event, helper) {
        
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchpaymentplan');
        var selPlot= component.get('v.paymentplan');
        var oppPlot = component.get('v.oppPlot');
    //  alert(component.get('v.oppPlot')+'--'+edi);
        var opp = component.get("v.OppRecord");
        
        for(var i=0;i<plt.length; i++){  
            
            if(plt[i].Id ===  edi ){
                component.set('v.searchText3', plt[i].Name);
                selPlot = plt[i];
              // alert(JSON.stringify(plt[i])+'---'+edi)
                oppPlot.Payment_Plan__c = plt[i].Id;
                break;
            }
        }
         component.set('v.paymentplan', selPlot);
        component.set('v.oppPlot',oppPlot);
        //alert(JSON.stringify(component.get('v.oppPlot')))
        component.set('v.matchpaymentplan',[]);
    },
   
    
    navigateToPaymentSchedule: function (component, event, helper) {
        
        const oppPlot = component.get("v.oppPlot");
        const payType = oppPlot.Payment_Type__c;
        const withGST = oppPlot.With_GST__c;
       //alert(withGST);
        if (withGST === 'None' ||  withGST === undefined ||  withGST === null ||  withGST === ''){
            helper.showToast('Error', 'Mandate Error', 'Please Choose With GST Option');
            return;
        }
        // Validate payment type
        if (payType === 'None' || !payType) {
            helper.showToast('Error', 'Mandate Error', 'Please Select The Payment Type');
            return;
        }
        
        // Handle different payment types
        if (payType === 'Standard') {
            const payPlot = oppPlot.Payment_Plan__c;
            
            // Validate payment plan for Standard type
            if (!payPlot) {
                helper.showToast('Error', 'Mandate Error', 'Please Select Payment Plan');
                return;
            }
        }
        
        // Common logic for both Standard (after validation) and other types
        helper.getpaymentplan(component, event, helper);
        component.set("v.showNextCmp", true);
        
    },
    
    /*
    navigateToPaymentPlanSchedule: function (component, event, helper) {
           if (helper.updvalidate(component, event)) {
           
             helper.getpaymentplan(component,event,helper);
                component.set("v.showNextCmp", true);
         
            
           }
        // helper.addOppProductRecord(component, event,helper);
    },
    */
    doSave: function(component,event,helper) {
        
          var schedules;
        var paymentpercentage = 0;
        var patType = component.get('v.paymentType');
        if(patType == 'Standard'){
              schedules = component.get('v.paymentSchedules');
            
        }
        else if(patType == 'Custom'){
            
              schedules = component.get('v.CustompaymentSchedules');
        }
         schedules.forEach(function(item){
              paymentpercentage += parseFloat(item.Payment_percent__c) || 0; // convert to number
         });
      
        if(paymentpercentage != 100)
         {
               helper.showToast("Error","Payment Percentage should not exceed more then 100.","Error");
             return;
         }
        else{
            
        helper.save(component,event,helper);
        }
        
    },
    redirectToQuote: function(component,event,helper) {
         let discount = component.get("v.oppPlot.Discount_Price__c");
        
       /* if(discount > 100){
            
          var action=component.get("c.callQuoteApproval");  
        action.setParams({'recId':  component.get('v.quoteId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                
         component.set('v.quoteId','');
            }
        });
        $A.enqueueAction(action);
             helper.showToast('Success','Approval',"Quote Created Submited for Approval");
                          
        }*/
        
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": component.get('v.quoteId'),
                    "slideDevName": "detail"
                });
        
                debugger;
                navEvt.fire();
         component.set('v.quoteId','');
    },
    
    doPreview: function(component,event,helper) {
        
          var schedules;
        var paymentpercentage = 0;
        var patType = component.get('v.paymentType');
        if(patType == 'Standard'){
              schedules = component.get('v.paymentSchedules');
            
        }
        else if(patType == 'Custom'){
            
              schedules = component.get('v.CustompaymentSchedules');
        }
         schedules.forEach(function(item){
              paymentpercentage += parseFloat(item.Payment_percent__c) || 0; // convert to number
         });
      
        if(paymentpercentage != 100)
         {
               helper.showToast("Error","Payment Percentage should not exceed more then 100.","Error");
             return;
         }
        else{
            
        helper.previewsave(component,event,helper);
        }
        
    },
    
    handleChange: function (component, event, helper) {
        
        var selectedOptionValue = component.find("select").get('v.value');  
        component.set('v.paymentType',selectedOptionValue);
        //alert(selectedOptionValue);
        if(selectedOptionValue=='None')
        {
            helper.showToast('Error','Mandate Error','Please Select The Payment Type');
            $A.get("e.force:closeQuickAction").fire();
        } 
        
        var paymentType = component.find("select").get("v.value");
        if (paymentType === "Custom") {
            component.set("v.showNextCmp", false);
        }
        else if (paymentType === "Standard") {
            component.set("v.showNextCmp", false);
        }
    },
    closeModel: function(component, event, helper) {
        
        
        //   var homeEvt = $A.get("e.force:navigateToObjectHome");
        //  homeEvt.setParams({
        //      "scope": "Lead"
        //  });
        // homeEvt.fire();
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
        
        
    },
    
    handlePrevious: function (component, event, helper) {
        component.set("v.showNextCmp", false);
        component.set('v.paymentSchedules',[]);
    },
    
    handlePreviewPrevious: function (component, event, helper) {
        component.set("v.showNextCmp", false);
        component.set("v.showPreview", false);
        component.set('v.paymentSchedules',[]);
        
          var action=component.get("c.deleteQuote");  
        action.setParams({'recId':  component.get('v.quoteId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                
         component.set('v.quoteId','');
            }
        });
        $A.enqueueAction(action);
      
    },
    addRow: function(component, event, helper) {
        //alert('hello ocean');
        helper.addProductRecord(component, event,helper);
    },
    
    removeRow: function(component, event, helper) {
        //alert('hello remove');
        //var quoteList = component.get("v.QuoteItemList");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        console.log(index);
        var oitems= component.get('v.CustompaymentSchedules');
        console.log(oitems);
        console.log(oitems[index].Id);
        if(oitems[index].Id !='undefined' && oitems[index].Id !='' && oitems[index].Id !=undefined){
            console.log('in');
            
            if( oitems[index].Payment_percent__c !='' && oitems[index].Payment_percent__c !=undefined){
                var grandtotal = (component.get('v.GrandTotal')-oitems[index].Amount__c);
                var recivedamount = (component.get('v.RecivedAmountTotal')-oitems[index].Received_Amount__c);
                var perct = (component.get('v.totalPercent')-oitems[index].Payment_percent__c);
                component.set('v.GrandTotal',grandtotal.toFixed(2));
                component.set('v.RecivedAmountTotal',recivedamount.toFixed(2));
                component.set('v.totalPercent',perct);
            }
            oitems.splice(index, 1);
            for (var i = 0; i < oitems.length; i++) {
                oitems[i].S_No__c = i+1;
            }        
            component.set("v.CustompaymentSchedules", oitems);
            
            if(oitems.length < 1){
                helper.addProductRecord(component, event,helper);
            }
            
        }else{
            console.log(oitems[index].Payment_percent__c);
            if( oitems[index].Payment_percent__c !='' && oitems[index].Payment_percent__c !=undefined){
                var grandtotal = (component.get('v.GrandTotal')-oitems[index].Amount__c);
                var recivedamount = (component.get('v.RecivedAmountTotal')-oitems[index].Received_Amount__c);
                console.log(grandtotal);
                var perct = (component.get('v.totalPercent')-oitems[index].Payment_percent__c);
                console.log(perct);
                component.set('v.GrandTotal',grandtotal.toFixed(2));
                component.set('v.RecivedAmountTotal',recivedamount.toFixed(2));
                component.set('v.totalPercent',perct);
                console.log('d');
            }
            oitems.splice(index, 1);
            for (var i = 0; i < oitems.length; i++) {
                oitems[i].S_No__c = i+1;
            }  
            console.log('s');
            component.set("v.CustompaymentSchedules", oitems);
            
            if(oitems.length < 1){
                helper.addProductRecord(component, event);
            } 
            
        }
    },
    fillDueDate : function(component, event, helper) {
        //alert('changedDueDate');
        var paymentSchedules = component.get("v.paymentSchedules");
        //alert('paymentSchedules');
        var changedDueDate = event.getSource().get("v.value");
        //alert(changedDueDate);
        // Iterate through the paymentSchedules and update due dates for completed items
        paymentSchedules.forEach(function(item) {
            if (item.status__c === 'Completed') {
                item.Payment_Due_Date__c = changedDueDate;
            }
        });
        
        // Update the attribute to reflect the changes
        component.set("v.paymentSchedules", paymentSchedules);
    }
    ,
    // CHANGE 2: handleGSTOptionChange - For Apartments only update With_GST__c flag,
    // GST on Agreement and GST on Other stay as project defaults always.
    // For Plots: existing behavior preserved.
    handleGSTOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var selectedValue = component.find("gstSelect").get("v.value");
        var projectType = component.get('v.projectType');

        if (projectType === 'Apartments') {
            // For Apartments: only toggle the With_GST__c flag
            // Do NOT change GST_for_Aggrement_Value__c or GST_For_Other_Charges__c
            if (selectedValue === "Yes") {
                component.set('v.isSingleCheckboxChecked', true);
                oppPlot.With_GST__c = true;
            } else if (selectedValue === "No") {
                component.set('v.isSingleCheckboxChecked', false);
                oppPlot.With_GST__c = false;
            }
        } else {
            // For Plots and others: existing behavior
            if (selectedValue === "Yes") {
                oppPlot.With_GST__c = true;
                oppPlot.GST_for_Aggrement_Value__c=selPlot[0].Project__r.GST_on_Aggrement__c;
                
                component.set('v.isSingleCheckboxChecked', true);
            }
            
            else {
                oppPlot.With_GST__c = false;
                oppPlot.GST_for_Aggrement_Value__c=0;              
                
                component.set('v.isSingleCheckboxChecked', false);
            }
            oppPlot.GST_For_Other_Charges__c=selPlot[0].Project__r.GST_on_Other__c;
        }

        component.set('v.oppPlot',oppPlot);
    },
   
    handleParkingOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var selectedValue = component.find("parkingSelect").get("v.value");
        if (selectedValue === "Yes") {
            
            component.set('v.isSingleCheckboxChecked', true);
            oppPlot.Car_Parking__c=selPlot[0].Car_Parking__c;
            oppPlot.Type_of_Car_Parking__c='Single Covered';
            
        }
        else {
            oppPlot.Car_Parking__c=0;
            
        }
        component.set('v.oppPlot',oppPlot);
        
        
        
    },
    
    handleGSTAggrementOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var selectedValue = component.find("gstAggremSelect").get("v.value");
        if (selectedValue === "Yes") {
            
            component.set('v.isGSTChecked', true);
            oppPlot.GST_for_Aggrement_Value__c=selPlot[0].Project__r.GST_on_Aggrement__c;
        }
        else {
            oppPlot.GST_for_Aggrement_Value__c=0;
            
        }
        component.set('v.oppPlot',oppPlot);
        
        
        
    },
     calculatePaymentPercent: function(component, event, helper) {
        var paymentlist = component.get("v.CustompaymentSchedules");
         var paymentpercentage = 0;
         paymentlist.forEach(function(item){
              paymentpercentage += parseFloat(item.Payment_percent__c) || 0; // convert to number
     
         });
         
         if(paymentpercentage > 100)
         {
               helper.showToast("Error","Payment Percentage should not exceed more then 100.","Error");
         }
    },
    handleGSTOtherOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        //  alert(JSON.stringify(oppPlot))
        var selectedValue = component.find("gstOthSelect").get("v.value");
        if (selectedValue === "Yes") {
            
            component.set('v.isgstonOtherChecked', true);
            oppPlot.GST_For_Other_Charges__c=selPlot[0].Project__r.GST_on_Other__c;
        }
        else {
            oppPlot.GST_For_Other_Charges__c=0;
            
        }
        component.set('v.oppPlot',oppPlot);
        
        
        
    },
     handleDiscountChange : function(component, event, helper) {
        let discount = component.get("v.oppPlot.Discount_Price__c");
      
      /*  if(discount > 684){
            // Show error message
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Validation Error",
                "message": "Discount cannot be greater than 684.",
                "type": "error"
            });
            toastEvent.fire();

            // Reset field value
           component.set("v.oppPlot.Discount_Price__c", null);
            return;
        }*/
         
    },
})