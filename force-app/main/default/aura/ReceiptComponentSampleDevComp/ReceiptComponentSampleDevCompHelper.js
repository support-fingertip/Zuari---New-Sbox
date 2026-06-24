({
    addOppProductRecord : function(component, event, id) {
        var action = component.get("c.Rcitemlist");
        action.setParams({'recid': component.get('v.recordId')})
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS") { 
                var db = response.getReturnValue();
                if(db.rcList != '') {
                    component.set('v.recptItemList', db.rcList);
                }
            }	
        });
        $A.enqueueAction(action); 
    },
    
    getAdditionalCharges : function(component, event, helper) {
        var action = component.get("c.getAddChar");
        action.setParams({'recid': component.get('v.recordId')})
        action.setCallback(this, function(response) {
            if(response.getState() == "SUCCESS") { 
                var datas = response.getReturnValue();
                component.set('v.additionlCharges', datas);
            }
        });
        $A.enqueueAction(action); 
    },
    
    addProductRecord: function(component, event) {
    var productList = component.get("v.recptItemList");
     
    // Check if the list already has 4 items
    if (productList.length >= 4) {
        this.showToast("You can only add up to 4 items.", "warning");
        return;
    }
    
    productList.push({
        'sobjectType': 'Receipt_Line_Item__c',
        'Payment_schedule__c': '',
        'Mode_of_Payment__c': '',
        'Name': '',
        'Payment_Type__c': '',
        'Cheque_no_Transaction_Number__c': '',
        'Received_Amount__c': '',
        'Payment_From__c': '',
        'Bank_Name__c': '',
        'Branch__c': '',
        'Pending_Amount__c': 0,  // Initialize to 0
        'Additional_Charges__c': ''
    });
    component.set("v.recptItemList", productList);
},
    
    showToast : function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },
    
    validateCumulativeAmount: function(component, event, helper, index) {
        var recptItemList = component.get("v.recptItemList");
        var bookingPendingAmount1 = component.get("v.bookingPendingAmount1");
        var totalPendingTds = component.get("v.totalPendingTds");
        var cumulativeReceivedAmount = 0;
        var cumulativeTdsAmount = 0;
        var cumulativeAdditionalCharges = 0;
        
        // Calculate totals for each payment type
        for (var i = 0; i < recptItemList.length; i++) {
            var receivedAmt = parseFloat(recptItemList[i].Received_Amount__c) || 0;
            
            if (recptItemList[i].Payment_Type__c === 'Flat Amount' || 
                recptItemList[i].Payment_Type__c === 'Villa Amount' || 
                recptItemList[i].Payment_Type__c === 'Plot Amount') {
                cumulativeReceivedAmount += receivedAmt;
            } else if (recptItemList[i].Payment_Type__c === 'TDS') {
                cumulativeTdsAmount += receivedAmt;
            } else if (recptItemList[i].Payment_Type__c === 'Additional Charges') {
                cumulativeAdditionalCharges += receivedAmt;
            }
        }
        
        // Validate based on current row's payment type
        var currentPaymentType = recptItemList[index].Payment_Type__c;
        var currentReceivedAmount = parseFloat(recptItemList[index].Received_Amount__c) || 0;
        
        if (currentPaymentType === 'Flat Amount' || 
            currentPaymentType === 'Villa Amount' || 
            currentPaymentType === 'Plot Amount') {
            
            if (cumulativeReceivedAmount > bookingPendingAmount1) {
                helper.showToast("Cumulative received amount cannot exceed the total pending amount of ₹" + bookingPendingAmount1, "error");
                recptItemList[index].Received_Amount__c = null;
                cumulativeReceivedAmount -= currentReceivedAmount;
            }
            
            // Update pending amount for flat/villa/plot
            var newPending = parseFloat(bookingPendingAmount1) - parseFloat(cumulativeReceivedAmount);
            component.set('v.bookingPendingAmount', newPending);
            component.set('v.totalPending', newPending);
            
        } else if (currentPaymentType === 'TDS') {
            
            if (cumulativeTdsAmount > totalPendingTds) {
                helper.showToast("Cumulative TDS amount cannot exceed the total pending TDS of ₹" + totalPendingTds, "error");
                recptItemList[index].Received_Amount__c = null;
                cumulativeTdsAmount -= currentReceivedAmount;
            }
            
        } else if (currentPaymentType === 'Additional Charges') {
            
            var pendingAdditionalAmount = parseFloat(recptItemList[index].Pending_Amount__c) || 0;
            if (currentReceivedAmount > pendingAdditionalAmount) {
                helper.showToast("Received amount cannot exceed the pending amount for this additional charge", "error");
                recptItemList[index].Received_Amount__c = null;
            }
        }
        
        // Calculate total received across all payment types
        var totalReceivedAmount = cumulativeReceivedAmount + cumulativeTdsAmount + cumulativeAdditionalCharges;
        component.set('v.totalrcvdAmount', totalReceivedAmount.toFixed(2));
        
        // Update the list
        component.set("v.recptItemList", recptItemList);
    },
    
    // ✅ NEW METHOD: Validate first receipt booking amount
    validateFirstReceiptBookingAmount: function(component, event, helper) {
        var bookingId = component.get('v.recordId');
        
        // Call Apex to check if approved receipts exist and get booking amount
        var action = component.get("c.validateFirstReceiptAmount");
        action.setParams({
            'bookingId': bookingId
        });
        
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                
                // result.hasApprovedReceipts - boolean indicating if approved receipts exist
                // result.bookingAmount - the booking amount from the booking record
                
                if (!result.hasApprovedReceipts) {
                    // This is the first receipt - validate against booking amount
                    var totalReceivedAmount = parseFloat(component.get('v.totalrcvdAmount')) || 0;
                    var bookingAmount = parseFloat(result.bookingAmount) || 0;
                    
                    if (totalReceivedAmount !== bookingAmount) {
                        helper.showToast(
                            "First receipt amount (₹" + totalReceivedAmount.toFixed(2) + 
                            ") must match the Booking Amount (₹" + bookingAmount.toFixed(2) + ")",
                            "error"
                        );
                        component.set("v.saveButtonDisabled", false);
                        return;
                    }
                }
                
                // Validation passed, proceed with save
                helper.proceedWithSave(component, event, helper);
                
            } else {
                var errors = response.getError();
                helper.showToast(errors[0].message, "error");
                component.set("v.saveButtonDisabled", false);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    // ✅ NEW METHOD: Proceed with the actual save operation
    proceedWithSave: function(component, event, helper) {
        component.set("v.savebuttonhide", true);
        var ponum = component.get("v.rcpt.Receipt_Name__c"); 
        var reark = component.get("v.rcpt.Remarks__c"); 
        var tarik = component.get("v.rcpt.Receipt_date__c");
        
        var action = component.get("c.insertReceiptLineItems");
        action.setParams({
            'polist': component.get('v.recptItemList'),
            'pon': ponum,
            'remark': reark,
            'poc': tarik,
            'recid': component.get('v.recordId'),
            'paidAmount': component.get('v.receivedAmount'),
            'interestAmount': component.get('v.interestAmount'),
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();      
            
            if (state === "SUCCESS") {
                var ttu = response.getReturnValue();
                helper.showToast("Receipt has been created successfully", "Success");
                $A.get('e.force:refreshView').fire();
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/" + ttu
                });
                urlEvent.fire();
                $A.get('e.force:refreshView').fire();
            } else {
                var errors = response.getError();
                helper.showToast(errors[0].message, "Error");
                component.set("v.saveButtonDisabled", false);
            }
        });
        
        $A.enqueueAction(action);
    },
    selectedAdditionalCharge : function(component, event, helper) {
    const selectedChargeId = event.target.value;
    const additionalCharges = component.get("v.additionlCharges"); 
    const selectedCharge = additionalCharges.find(charge => charge.Id === selectedChargeId);
    
    if (selectedCharge) {
        var index = event.currentTarget.dataset.record;
        const recptItemList = component.get("v.recptItemList"); 
        
        // Set pending amount for THIS SPECIFIC ROW
        recptItemList[index].Pending_Amount__c = selectedCharge.Pending_Amount__c;
        
        // Update component-level variable for display (optional)
        component.set('v.bookingPendingAmount', selectedCharge.Pending_Amount__c);
        component.set("v.recptItemList", recptItemList);
    }
}
});