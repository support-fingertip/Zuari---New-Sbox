({
    addProductRecord: function(component,event,helper) {
        console.log('a')
        var shcdules = component.get("v.CustompaymentSchedules");
         console.log(shcdules)
        var sno =  shcdules.length+ 1;
        console.log(sno)
        shcdules.push({
            'sobjectType': 'Payment_schedule__c',
            'Name': '',
            'Payment_percent__c': '',
            'Payment_Due_Date__c':'',
            'Tentative_TimeLine__c':'',
            'Amount__c': '',
            'Completed_Date__c':'',
            'status__c':'',
            'Master_Payment_Schedule__c':'',
            'S_No__c':sno,
            'Received_Amount__c':'',
            'Recived_Per__c':''
            
        });
        component.set("v.CustompaymentSchedules", shcdules);
      // alert(JSON.stringify( component.get('v.paymentSchedules')));
       // alert('v.paymentSchedules');
    },
    validate: function(component, event) {
        var isValid = true;
        var oppPlot = component.get('v.oppPlot');
        
        var patType = component.get('v.paymentType');
        console.log(oppPlot)
        if(oppPlot.Unit__c == null){
            isValid = false;
            //alert('Please select Plot.');
        }
        if(oppPlot.Payment_Plan__c == null && paymentType=='Standard'){
            isValid = false;
        }
        
        return isValid;
    },
    save  : function(component, event, helper){
        component.set('v.spinner',true);
        var action=component.get("c.saveOppPlot");  
        action.setParams({
            oppPlot:component.get("v.oppPlot")
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
               // var quotid = response.getReturnValue();
                
                 var result = response.getReturnValue();
                
            component.set("v.quoteId", result.quoteId);
            component.set("v.recordTypeName", result.recordTypeName);
               // component.set("v.quoteId",quotid);
                //alert(component.get('v.quoteId'));
                if(quotid != 'notc'){
                    helper.saveSchedules(component,event,helper);
                    component.set('v.spinner',false);
                    helper.showToast("Quote Created Successfully.","success");
                      /*var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": component.get('v.quoteId'),
                                "slideDevName": "detail"
                            });
                            navEvt.fire();*/
                 
                }
                else{
                    component.set('v.spinner',false);
                    var errors = response.getError();
                    //alert(errors[0].message);
                    var errormessage=errors[0].message;
                if (errors) {
                   helper.showToast('Error','Unknown Error',errormessage);
                    }
                else {
                    console.log("Unknown error");
                }
                    
                                     
                }
            }
        });
        $A.enqueueAction(action);
    },
    previewsave  : function(component, event, helper){
        component.set('v.spinner',true);
        //alert(JSON.stringify(component.get("v.oppPlot")));
        var action=component.get("c.saveOppPlot");  
        action.setParams({
            oppPlot:component.get("v.oppPlot")
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
              //  var quotid = response.getReturnValue();
                
                 var result = response.getReturnValue();
               // alert(JSON.stringify(result))
                component.set("v.quoteId", result.quoteId);
            component.set("v.recordTypeName", result.recordTypeName);
                
                
//component.set("v.quoteId",quotid);
                //alert(component.get('v.quoteId'));
                if(result != 'notc'){
                    helper.savePreviewSchedules(component,event,helper);
                    
                    component.set('v.showPreview',true);
                    component.set('v.spinner',false);
                   
                }
                else{
                    component.set('v.spinner',false);
                    var errors = response.getError();
                    //alert(errors[0].message);
                    var errormessage=errors[0].message;
                if (errors) {
                   helper.showToast('Error','Unknown Error',errormessage);
                    }
                else {
                    console.log("Unknown error");
                }
                    
                                     
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    
    saveSchedules : function(component,event,helper) {
        var schedules;
        var patType = component.get('v.paymentType');
        if(patType == 'Standard'){
              schedules = component.get('v.paymentSchedules');
            
        }
        else if(patType == 'Custom'){
              schedules = component.get('v.CustompaymentSchedules');
        }
       
        var action=component.get("c.insertSchedules");
        //alert('Quote IDbvvvvv :'+component.get('v.quoteId'));
        action.setParams({'payList':schedules,
                          'gt':component.get('v.GrandTotal'),
                          'quoteid':component.get('v.quoteId')});
       
        action.setCallback(this,function(response){ 
            //alert(response.getState());
            if(response.getState() == "SUCCESS"){ 
                component.set("v.paymentSchedules", []);
                component.set('v.GrandTotal',0.00);
                
                
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": component.get('v.quoteId'),
                    "slideDevName": "detail"
                });
                debugger;
                navEvt.fire();
                helper.showToast("Quote Created Successfully.","success");
                //helper.showToast("Payment schedules updated successfully","success");
                component.set('v.quoteId','');
            }
            else if (response.getState() === "ERROR") {
                var errors = response.getError();
               //alert(errors);
               //alert(errors[0].message);
                if (errors) {
                     //alert(errors[0].message);
               
                }
                
            }
            debugger;
        });
        $A.enqueueAction(action); 
        
    },
    
    savePreviewSchedules : function(component,event,helper) {
        var schedules;
        var patType = component.get('v.paymentType');
        if(patType == 'Standard'){
              schedules = component.get('v.paymentSchedules');
            
        }
        else if(patType == 'Custom'){
              schedules = component.get('v.CustompaymentSchedules');
        }
       
        var action=component.get("c.insertSchedules");
        //alert('Quote IDbvvvvv :'+component.get('v.quoteId'));
        action.setParams({'payList':schedules,
                          'gt':component.get('v.GrandTotal'),
                          'quoteid':component.get('v.quoteId')});
       
        action.setCallback(this,function(response){ 
            //alert(response.getState());
            if(response.getState() == "SUCCESS"){ 
              /*  component.set("v.paymentSchedules", []);
                component.set('v.GrandTotal',0.00);
                
                
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": component.get('v.quoteId'),
                    "slideDevName": "detail"
                });
                debugger;
                navEvt.fire();
                helper.showToast("Quote Created Successfully.","success");
                //helper.showToast("Payment schedules updated successfully","success");
                component.set('v.quoteId','');
                
                */
            }
            else if (response.getState() === "ERROR") {
                var errors = response.getError();
               //alert(errors);
               //alert(errors[0].message);
                if (errors) {
                     //alert(errors[0].message);
               
                }
                
            }
            debugger;
        });
        $A.enqueueAction(action); 
        
    },
     showToast : function(type,title,message) {
        console.log(message)
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "title":title,
            "message":message
        });
        toastEvent.fire();
    },
    getFilteredLead: function(component, event,helper) {
        //alert('hh')
        var oppPlot = component.get('v.oppPlot');
        var pymplan = component.get('v.paymentType');
        var project = component.get('v.projectName');
        var totalCost = component.get("v.GrandTotal");
        var gstPer = component.get('v.oppPlot.GST1__c');
        gstPer = (typeof gstPer !== 'undefined') ? gstPer : 0;
        var totalWithgst = (parseFloat(totalCost) + (parseFloat(totalCost) * parseFloat(gstPer))/100);
        //alert(gstPer);
        //alert(totalCost);
        //alert(totalWithgst);
        component.set('v.FlatCost', totalCost);
        component.set('v.GrandTotalwithGST',totalWithgst);
        component.set("v.oppPlot.Grand_Total_Amount_With_Tax__c", totalWithgst);
        //alert(pymplan+'--'+project)
         var action = component.get("c.getPaymentSchedules");
        	
        action.setParams({'Pay':  pymplan,
                         'Project': project
                         })
        action.setCallback(this,function(response){
            var state = response.getState();
				//alert(state);
            if(state == "SUCCESS" ){ 
               
              var db = response.getReturnValue();
                var shcdules = component.get("v.paymentSchedules");
               //alert(db);
                //alert(db.payList);
                 //console.log(db.payList.length());
                for(var i=0;i<db.length; i++){
                    var amout = (parseFloat(db[i].Payment_Percent__c) * parseFloat(totalWithgst))/100
                    //alert('Id  '+db[i].Id);
                    shcdules.push({
                        'sobjectType': 'Payment_schedule__c',
                        'Name': db[i].Name,
                        'Payment_percent__c': db[i].Payment_Percent__c,
                        'Payment_Due_Date__c':'',
                        'Amount__c': amout,
                        'Include_Interest__c' : db[i].Include_Interest__c,
                        'Completed_Date__c':db[i].Completed_Date__c,
                        'status__c':db[i].Status__c,
                        'Master_Payment_Schedule__c':db[i].Id,
                        'S_No__c':db[i].S_No__c,
                        'Tentative_TimeLine__c':db[i].Tentative_TimeLine__c
                    });
                    
                } 
                if(db!=null){
                    console.log('if');
                    
                   component.set("v.paymentSchedules", shcdules);
                     //alert('calling the payment',db);
               //alert(JSON.stringify(component.get('v.paymentSchedules')))
                }
                else{
                    
                    //  helper.addProductRecord(component,event,helper);
                    console.log('else');
                
                }
              
            }
        });
        $A.enqueueAction(action); 
        
    },
    handleCalculations : function(component,event,helper) {
        // Get the values from the input fields
        var builtUpArea = component.get("v.oppPlot.Built_up_area__c") || 0;
        var basicPrice = component.get("v.oppPlot.Basic_Price__c") || 0;
        var clubHouse = component.get("v.oppPlot.Club_House__c") || 0;
        var corpusFund = component.get("v.oppPlot.Corpus_Fund__c") || 0;
        var legalDocCharges = component.get("v.oppPlot.Legal_Documentation_Charges__c") || 0;
        var maintenanceCharge = component.get("v.oppPlot.Maintenance_Charge__c") || 0;
        var infrastructureCharges = component.get("v.oppPlot.Infrastructure_Charges_per_sqft__c") || 0;
        var premiumLocationCharge = component.get("v.oppPlot.Premium_Location_Charge__c") || 0;

        // Calculate the Grand Total
        var grandTotal = parseFloat(basicPrice) * parseFloat(builtUpArea) + parseFloat(clubHouse) + 
                 parseFloat(corpusFund) + parseFloat(legalDocCharges) +
                 parseFloat(maintenanceCharge) * parseFloat(builtUpArea) * 12  + parseFloat(infrastructureCharges) * parseFloat(builtUpArea) + 
                 parseFloat(premiumLocationCharge) * parseFloat(builtUpArea);

        // Update the Grand Total field
        //component.set("v.oppPlot.GRAND_TOTAL__c", grandTotal);
        //component.set('v.GrandTotal',grandTotal);
    },
     approvalSubmit: function(component,event,helper) {
                    var action=component.get("c.submitapproval");
                    action.setParams({
                        'quoteId' :component.get('v.quoteId')
                    });
                    action.setCallback(this,function(response){
                        if(response.getState() == "SUCCESS"){
                            
                            helper.showToast("Quote Created Successfully and Submited for Approval","Success");
                            
                            
                            var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": component.get('v.quoteId'),
                                "slideDevName": "detail"
                            });
                            navEvt.fire();
                        }
                    });
                    $A.enqueueAction(action);		
                },
    /*
    getmasterpaymentschedule: function(component, event,helper) {
        
        var oppPlot = component.get('v.oppPlot');
         var pymplan = component.get('v.paymentType');
       // var pymplan = oppPlot.Payment_Plan__c;
        //var project = oppPlot.Projects__c;
        
        var project = component.get('v.projectName');
      //  alert(pymplan+'--'+project)
      // alert(project);
        //alert(component.get('v.blockId'));
         var action = component.get("c.getPaymentSchedules");
        	
        action.setParams({'Pay':  pymplan,
                         'Project': project,
                          'blockId': component.get('v.blockId')
                         })
        action.setCallback(this,function(response){
            var state = response.getState();
          
            if(state == "SUCCESS" ){ 
               
              var db = response.getReturnValue();
               // alert(JSON.stringify(db))
                 //console.log(db.payList.length()); 
                if(db.payList !=null){
                    console.log('if');
                    
                    component.set('v.paymentSchedules', db.payList );
                    
                     
               //alert(JSON.stringify(component.get('v.paymentSchedules')))
                }
                else{
                    
                    //  helper.addProductRecord(component,event,helper);
                    console.log('else');
                
                }
              
            }
        });
        $A.enqueueAction(action); 
        
    },*/
        /*
    getFilteredLead: function(component, event,helper) {
       // alert('hh')
        var oppPlot = component.get('v.oppPlot');
        var pymplan = oppPlot.Payment_Plan__c;
        var project = oppPlot.Projects__c;
        
       // alert(pymplan+'--'+project)
         var action = component.get("c.getPaymentSchedules");
        	
        action.setParams({'Pay':  pymplan,
                         'Project': project
                         })
        action.setCallback(this,function(response){
            var state = response.getState();
          
            if(state == "SUCCESS" ){ 
              //  alert(1);
              var db = response.getReturnValue();
               
                 //console.log(db.payList.length());
                if(db.payList !=null){
                    console.log('if');
                    
                    component.set('v.paymentSchedules', db.payList );
                     
               //alert(JSON.stringify(component.get('v.paymentSchedules')))
                }
                else{
                    
                    //  helper.addProductRecord(component,event,helper);
                    console.log('else');
                
                }
              
            }
        });
        $A.enqueueAction(action); 
        
    },
    */
    /*
     updvalidate: function(component, event) {
        var isValid = true;
        var oppPlot = component.get('v.oppPlot');
        // alert('Hi----'+JSON.stringify(component.get('v.oppPlot')))
        console.log(oppPlot)
        if(oppPlot.Unit__c == null){
            isValid = false;
            alert('Please select Plot.');
        }
        if(oppPlot.Payment_Plan__c == null){
            isValid = false;
            
                helper.showToast("Quote Created successfully","success");
           alert('Please select Payment Plan.');
             component.set("v.showNextCmp", false);
        }
        return isValid;
    },
    */
     getpaymentplan: function(component, event,helper) {
       // alert('hh')
        var oppPlot = component.get('v.oppPlot');
        var pymplan = oppPlot.Payment_Plan__c;
        var project = oppPlot.Projects__c;
        
       // alert(pymplan+'--'+project)
         var action = component.get("c.getUpdatedPaymentSchedules");
        	
        action.setParams({'Pay':  pymplan,
                         'Project': project
                         })
        action.setCallback(this,function(response){
            var state = response.getState();
          
            if(state == "SUCCESS" ){ 
              //  alert(1);
              var db = response.getReturnValue();
               
                 //console.log(db.payList.length());
                if(db.payList !=null){
                    console.log('if');
                    
                    component.set('v.paymentSchedules', db.payList );
                     
              // alert(JSON.stringify(component.get('v.paymentSchedules')))
                }
                else{
                    
                    //  helper.addProductRecord(component,event,helper);
                    console.log('else');
                
                }
              
            }
        });
        $A.enqueueAction(action); 
        
    },
  
})