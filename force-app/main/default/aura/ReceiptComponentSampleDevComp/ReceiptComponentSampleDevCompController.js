({
    doInit : function(component,event,helper)
    {
        var id=component.get('v.recordId');
        
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        var rcpt = component.get("v.rcpt");
        rcpt.Receipt_date__c = today;
        component.set("v.rcpt", rcpt);
        var recpName = component.get('v.receiptName');
        rcpt.Receipt_Name__c = recpName;
        if(recpName = 'Booking Amount Receipt'){
            component.set("v.isDisabled", true);
        }
        helper.addProductRecord(component, event,id);
        helper.getAdditionalCharges(component, event,helper);
        
        var action=component.get("c.getpaymentsc");
        action.setParams({'recid':  component.get('v.recordId') })
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){ 
                var datas=response.getReturnValue();
                component.set('v.paymentschdl',  datas.pysch);
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
        
        var action5 = component.get("c.gettdsamout");
        action5.setParams({'recid':  component.get('v.recordId') })
        action5.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var paymentTypePicklist = response.getReturnValue();
                component.set("v.totalPendingTds", paymentTypePicklist);
            }
        });
        $A.enqueueAction(action5);
        
        var action2 = component.get("c.getBookingDetails");
        action2.setParams({'recid':  component.get('v.recordId') })
        action2.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var db = response.getReturnValue();
                component.set("v.projectName", db.Project__c);
                component.set("v.flatNumber", db.Unit_No__c);
                component.set("v.FlatCost", db.GRAND_TOTAL__c);
                component.set("v.bookingPendingAmount",db.Pending_Amount__c);
                component.set("v.bookingPendingAmount1",db.Pending_Amount__c);
                component.set("v.bookingType",db.Project_Type__c);
            }
        });
        $A.enqueueAction(action2);
        
    },
    
    searchText : function(component, event, helper) {
        var pymntsc= component.get('v.paymentschdl');
        var searchText= component.get('v.searchText');
        
        var matchprds=[];
        if(searchText !=''){
            for(var i=0;i<pymntsc.length; i++){ 
                if(pymntsc[i].Name.toLowerCase().indexOf(searchText.toLowerCase())  != -1  ){
                    matchprds.push( pymntsc[i] );
                } 
            } 
            if(matchprds.length >0){
                component.set('v.matchpaymentschdl',matchprds);
            }
        }else{
            component.set('v.matchpaymentschdl',[]);
        }
        
    },
    
    selectedAdditionalCharge : function(component, event, helper) {
        const selectedChargeId = event.target.value;
        const additionalCharges = component.get("v.additionlCharges"); 
        const selectedCharge = additionalCharges.find(charge => charge.Id === selectedChargeId);
        
        if (selectedCharge) {
            var index = event.currentTarget.dataset.record;
            const recptItemList = component.get("v.recptItemList"); 
            recptItemList[index].Pending_Amount__c = selectedCharge.Pending_Amount__c;
            component.set("v.bookingPendingAmount",selectedCharge.Pending_Amount__c);
            component.set("v.recptItemList", recptItemList);
        }
    },
    update : function(component, event, helper) {
        component.set("v.savebuttonhide",true);
        component.set('v.spinner', true);
        
        var index = event.currentTarget.dataset.record;
        var pid =event.currentTarget.dataset.id;
        var prds= component.get('v.matchpaymentschdl');
        var oitems= component.get('v.recptItemList');
        for(var i=0;i<prds.length; i++){ 
            if(prds[i].Id === pid ){
                oitems[index].Payment_schedule__c = prds[i].Id;
                oitems[index].Name = prds[i].Name;
                
                oitems[index].Amount__c = prds[i].Pending_Amount__c;
                
                component.set('v.searchText', '');
                break;
            }
            
        } 
        component.set('v.recptItemList',oitems);
        component.set('v.matchpaymentschdl',[]);
        component.set('v.spinner', false);
        
    },
    
    
    ChangeName : function(component, event, helper)
    {
        component.set("v.savebuttonhide",true);
    },
    addRow: function(component, event, helper) {
        component.set("v.savebuttonhide",true);
        helper.addProductRecord(component, event);
    },
    removeRow: function(component, event, helper) {
        component.set("v.savebuttonhide",false);
        
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        
        var oitems= component.get('v.recptItemList');
        if(oitems[index].Id !='undefined' && oitems[index].Id !=''){
            var action=component.get("c.deleteProduct");
            action.setParams({'prId':  oitems[index].Id  })
            action.setCallback(this,function(response){
                
                if(response.getState() == "SUCCESS"){ 
                    
                    oitems.splice(index, 1);
                    component.set("v.recptItemList", oitems);
                    
                    if(oitems.length < 1){
                        helper.addProductRecord(component, event);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        
        
    },
    quoteSave: function(component,event,helper) {
        component.set("v.saveButtonDisabled", true);
        let isAllValid = component.find('field').reduce(function(isValidSoFar, inputCmp){
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        },true);
        
        if(isAllValid == true){
            helper.proceedWithSave(component, event, helper);
            // ✅ NEW VALIDATION: Check if this is the first receipt and validate booking amount
            //helper.validateFirstReceiptBookingAmount(component, event, helper);
        }
        else{
            helper.showToast("Please fill all mandatory fields","Error");
            component.set("v.saveButtonDisabled", false);
        }
    },
    
    quoteCancel:function(component, event, helper) {
        component.set("v.savebuttonhide",false);
        component.set("v.recptItemList", []);
        
        component.set("v.matchpaymentschdl", []);
        component.set("v.paymentschdl", []);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get('v.recordId'),
            "slideDevName": "detail"
        });
        navEvt.fire();
        
    },
    
    getGrandTotal : function(component, event, helper) {
        component.set("v.savebuttonhide", true);
        var index = event.currentTarget.dataset.record;
        var oitems = component.get('v.recptItemList');
        var bookPendingAmount = component.get('v.bookingPendingAmount');
        var totalReceivedAmount = 0;
        var totalPendingAmount = 0;
        
        // Calculate totals
        for (var i = 0; i < oitems.length; i++) {
            if (oitems[i].Received_Amount__c) {
                totalReceivedAmount += parseFloat(oitems[i].Received_Amount__c);
            }
        }
        
        totalPendingAmount = bookPendingAmount - totalReceivedAmount;
        
        if (parseFloat(totalReceivedAmount) > parseFloat(bookPendingAmount)) {
            helper.showToast("Received Amount cannot exceed the Maximum Pending Amount", "error");
            return; 
        }
        
        var newPendingAmount = parseFloat(bookPendingAmount) - parseFloat(totalReceivedAmount);
        component.set('v.newPendingAmount', newPendingAmount);
        
        component.set('v.recptItemList', oitems);
        component.set('v.totalrcvdAmount', totalReceivedAmount);
        component.set('v.totalPending', totalPendingAmount);
    },
    
    validateReceivedAmount: function(component, event, helper) {
        var index = event.currentTarget.dataset.record;
        var recptItemList = component.get("v.recptItemList");
        var receivedAmount = recptItemList[index].Received_Amount__c;
        
        if (isNaN(receivedAmount) || receivedAmount <= 0) {
            helper.showToast("Received Amount must be a valid number greater than 0", "error");
            recptItemList[index].Received_Amount__c = null;
            
        }
        
        helper.validateCumulativeAmount(component, event, helper,index);
    },
    
    selectingType: function(component, event, helper) {
    var index = event.currentTarget.dataset.record;
    var recptItemList = component.get("v.recptItemList");
    var selectedType = recptItemList[index].Payment_Type__c;
    var isTrue = false;
    
    // Check for duplicate payment types (except Additional Charges which can have multiple)
    if(selectedType !== 'Additional Charges') {
        for (var i = 0; i < recptItemList.length; i++) {
            if (i != index && recptItemList[i].Payment_Type__c === selectedType) {
                helper.showToast("This payment type has already been selected in another row", "error");
                isTrue = true;
                break;
            }
        }
    }
    
    if(!isTrue) {
        // Update pending amount based on selected type FOR THIS ROW ONLY
        if(selectedType === 'Flat Amount' || selectedType === 'Villa Amount' || selectedType === 'Plot Amount'){
            // Calculate the cumulative received amount for this payment type across other rows
            var cumulativeReceived = 0;
            for (var j = 0; j < recptItemList.length; j++) {
                if (j != index && 
                    (recptItemList[j].Payment_Type__c === 'Flat Amount' || 
                     recptItemList[j].Payment_Type__c === 'Villa Amount' || 
                     recptItemList[j].Payment_Type__c === 'Plot Amount')) {
                    cumulativeReceived += parseFloat(recptItemList[j].Received_Amount__c || 0);
                }
            }
            
            // Set pending amount for THIS SPECIFIC ROW
            var pendingAmount = parseFloat(component.get('v.bookingPendingAmount1')) - cumulativeReceived;
            recptItemList[index].Pending_Amount__c = pendingAmount;
        }
        else if(selectedType === 'TDS'){
            // Set TDS pending amount for THIS SPECIFIC ROW
            var tdsPending = component.get('v.totalPendingTds');
            recptItemList[index].Pending_Amount__c = tdsPending;
        }
        else if(selectedType === 'Additional Charges'){
            // Reset to 0 for additional charges (will be updated when specific charge is selected)
            recptItemList[index].Pending_Amount__c = 0;
        }
        else {
            // For any other payment type
            recptItemList[index].Pending_Amount__c = 0;
        }
        
        component.set("v.recptItemList", recptItemList);
    }
    else {
        // Remove row if duplicate type selected
        recptItemList.splice(index, 1);
        component.set("v.recptItemList", recptItemList);
        if(recptItemList.length === 0) {
            helper.addProductRecord(component, event);
        }
    }
}
})