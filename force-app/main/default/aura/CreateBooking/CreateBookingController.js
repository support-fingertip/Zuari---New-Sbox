({
    doInit: function(component, event, helper) {
        //  component.set('v.Spinner', true); 
        
        // var prd = component.get("v.prd") || {};
        component.set("v.provinceOptions", []);
        
        var book = component.get('v.book');
        if (!component.get("v.book.Office_Address1__CountryCode__s")) {
            component.set("v.book.Office_Address1__CountryCode__s", "IN");
        } if (!component.get("v.book.Correspondence_Address__CountryCode__s")) {
            component.set("v.book.Correspondence_Address__CountryCode__s", "IN");
        } if (!component.get("v.book.Permanent_Address2__CountryCode__s")) {
            component.set("v.book.Permanent_Address2__CountryCode__s", "IN");
        }
        
        helper.loadCountryOptions(component);
        helper.loadProvinceOptions(component, "IN");
        component.set('v.showCostSheet',true);
        
        var action = component.get("c.quoteRecord");
        action.setParams({ 
            recId: component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state=response.getState();
            console.log('Response : '+response.getReturnValue()); 
            
            if(state==='SUCCESS'){
                var qt = response.getReturnValue();
                var booking = component.get('v.book');
                component.set('v.quote',qt);
                component.set('v.book',booking);
                var book = component.get("v.book");
                var unitstatus = qt.Unit__r.Status__c;
                
                if(unitstatus == 'Booked'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": "Booking already created for this Unit.",
                        "type": "error"
                    });
                    toastEvent.fire(); 
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }
                var quotestatus = qt.Quote_status__c;
                if(quotestatus == 'Converted'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": "Booking already created for this Quote.",
                        "type": "error"
                    });
                    toastEvent.fire(); 
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }
                
                book.Plot__c	 = qt.Unit_Number__c;	
                book.Wing__c	 = qt.Wing__c;	
				book.Related_Source__c = qt.Related_Source__c;
                book.Rate_per_sqft__c	 = qt.Rate_per_sqft__c;	
                book.Email__c = qt.SLead__r.Email;
                book.Agreement_Value_Before_GST__c = qt.Agreement_Value_Before_GST__c;
                book.Project__c	 = qt.Project__c;
                //alert( JSON.stringify(book))
                component.set('v.book',book);
                
            }
            component.set("v.isModalOpen", true);
        });
        $A.enqueueAction(action);
    },
    
    handleEmailChange: function(component, event, helper) {
        var newEmail = event.getSource().get("v.value");
        component.set("v.PEmail", newEmail);
    },
    
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        
        component.set("v.isModalOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    },
    save: function(component, event, helper) {
        
        var aadharValue = component.get("v.book.Aadhaar__c");
      
        
        if(helper.validateFields(component,event,helper)) {
            // If validation passes, call the helper function to save the record
            helper.saveRecord(component,event,helper);
        }
    },
    
    handleAddressChange : function(component, event, helper) {
        let params = event.getParams();
        // Salesforce passes full address object
        let country = params.country;  
        
        // var address = event.getParam("value");
        helper.loadProvinceOptions(component, country);
        
        // Validate postal code after a short delay to ensure value is set
        window.setTimeout(
            $A.getCallback(function() {
                helper.validatePostalCodes(component);
            }), 100
        );
    },
    
    validateDOB: function(component, event, helper) {
        var applicantList = component.get("v.applicantList");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var prd = applicantList[index];
        var dateOfBirth = prd.Date_of_Birth__c;
        var spdateOfBirth = prd.Spouse_Date_Of_Birth_coapp__c;
        var poadateOfBirth = prd.Power_of_Attorney_DOB__c;
        
        if (dateOfBirth ) {
            var birthDate = new Date(dateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            component.set("v.coPowerofAttorney", age < 18);
            
        } else {
            // No DOB -> hide POA
            component.set("v.coPowerofAttorney", false);
        }

    component.set("v.applicantList", applicantList);
        
        if (spdateOfBirth ) {
            var birthDate = new Date(spdateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            if (age < 18) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Age should more than 18.",
                    "type": "error"
                });
                toastEvent.fire(); 
                prd.Spouse_Date_Of_Birth_coapp__c = null; 
                component.set("v.applicantList", applicantList); 
            } else {
                component.set("v.applicantList", applicantList); 
            }
        }
        
        if (poadateOfBirth ) {
            var birthDate = new Date(poadateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            if (age < 18) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Age should more than 18.",
                    "type": "error"
                });
                toastEvent.fire(); 
                prd.Power_of_Attorney_DOB__c = null; 
                component.set("v.applicantList", applicantList); 
            } else {
                component.set("v.applicantList", applicantList); 
            }
        }
    },
    
    validateAnnviDateBooking: function(component, event, helper) {
        var anniversaryDate = component.get("v.book.Anniverssary_Date1__c");
        
        if (anniversaryDate) {
            var selectedDate = new Date(anniversaryDate);
            var currentDate = new Date();
            
            // Check if date is in future
            if (selectedDate > currentDate) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Anniversary date cannot be a future date.",
                    "type": "error"
                });
                toastEvent.fire(); 
                component.set("v.book.Anniverssary_Date1__c", null);
            } 
        }
    },
    validateBookingDate: function(component, event, helper) {
        var anniversaryDate = component.get("v.book.Booking_Date__c");
        var dopyamentDate = component.get("v.book.Date_of_Payment__c");
        
        if (anniversaryDate) {
            var selectedDate = new Date(anniversaryDate);
            var currentDate = new Date();
            
            // Check if date is in future
            if (selectedDate > currentDate) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Booking date cannot be a future date.",
                    "type": "error"
                });
                toastEvent.fire(); 
                component.set("v.book.Booking_Date__c", null);
            } 
        }
        if (dopyamentDate) {
            var selectedDate = new Date(dopyamentDate);
            var currentDate = new Date();
            
            // Check if date is in future
            if (selectedDate > currentDate) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Date of Payment cannot be a future date.",
                    "type": "error"
                });
                toastEvent.fire(); 
                component.set("v.book.Date_of_Payment__c", null);
            } 
        }
    },
    
    validateAnnviDateApplicants: function(component, event, helper) {
        var applicantList = component.get("v.applicantList");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var prd = applicantList[index];
        var anniversaryDate = prd.Anniverssary_Date__c;
        
        if (anniversaryDate) {
            var selectedDate = new Date(anniversaryDate);
            var currentDate = new Date();
            
            // Reset time parts to compare dates only
            selectedDate.setHours(0, 0, 0, 0);
            currentDate.setHours(0, 0, 0, 0);
            
            // Check if date is in future
            if (selectedDate > currentDate) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Anniversary date cannot be a future date.",
                    "type": "error"
                });
                toastEvent.fire(); 
                prd.Anniverssary_Date__c = null; 
                component.set("v.applicantList", applicantList); 
            } else {
                component.set("v.applicantList", applicantList); 
            }
        }
    },
    validateAge : function(component, event, helper) {
        var book = component.get("v.book");
        var dateOfBirth = component.get("v.book.Date_of_Birth1__c");
        var spdateOfBirth = component.get("v.book.Spouse_Date_Of_Birth__c");
        var poadateOfBirth = component.get("v.book.Power_of_Attorney_DOB__c");
        
        if (dateOfBirth) {
            var birthDate = new Date(dateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            
            
            if (age < 18) {
                
                component.set("v.powerofAttorney", true);
                if (age < 18) {
                    // show POA section
                    component.set("v.powerofAttorney", true);
                } else {
                    // hide POA section
                    component.set("v.powerofAttorney", false);
                }
            } else {
                // no DOB → hide POA by default if you want
                component.set("v.powerofAttorney", false);
            }
        }
        
                /*  var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Age should more than 18.",
                    "type": "error"
                });
                toastEvent.fire(); 
                component.set("v.book.Date_of_Birth1__c", null);*/
           
        if (spdateOfBirth) {
            var birthDate = new Date(spdateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            
            
            if (age < 18) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Age should more than 18.",
                    "type": "error"
                });
                toastEvent.fire(); 
                component.set("v.book.Spouse_Date_Of_Birth__c", null);
                
                
            } 
        }
        if (poadateOfBirth) {
            var birthDate = new Date(poadateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            
            
            if (age < 18) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Age should more than 18.",
                    "type": "error"
                });
                toastEvent.fire(); 
                component.set("v.book.Power_of_Attorney_DOB__c", null);
                
                
            } 
        }
        
        
        component.set("v.book", book);
        
    },
    
    handleFilesChangePhoto: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", 'Applicant Aadhaar Card');
        
    },
    handleFilesChange2ndPhoto: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file2ndName", 'Applicant PAN Card');
        
    },
    handleFilesChange3rdPhoto: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file3rdName", 'Applicant Passport Size Photo');
        
    },
    
    handleFilesChange4thPhoto: function(component, event, helper) {
        var fileName = 'No Cheque Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file4thName", 'Cheque Copy');
        
    },
    
    handleFilesChange5thPhoto: function(component, event, helper) {
        var fileName = 'No Co Applicant Photo Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file5thName", 'Co Applicant Photo');
        
    },
    handleFilesChange6thPhoto: function(component, event, helper) {
        var fileName = 'No Co Applicant Aadhar Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file6thName", 'Co Applicant Aadhaar');
        
    },
    handleFilesChange7thPhoto: function(component, event, helper) {
        var fileName = 'No Co Applicant Pan Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file7thName", 'Co Applicant Pan');
        
    },
    removeRow : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var aitems= component.get('v.applicantList');
        //alert(index);
        aitems.splice(index, 1);
        component.set("v.applicantList", aitems);
        /*if(aitems.length < 1){
            helper.addAppliacantRecord(component, event, helper);
        }*/
    },
    addRow: function(component, event, helper) { 
        helper.addAppliacantRecord(component, event, helper);
    },
    
    formatPassport: function(component, event, helper) {
        var passportField = event.getSource();
        var passportValue = passportField.get("v.value");
        
        if (passportValue) {
            passportField.set("v.value", passportValue.toUpperCase()); // Force uppercase
        }
    },
    formatPAN: function(component, event, helper) {
        var panField = event.getSource();
        var panValue = panField.get("v.value");
        
        if (panValue) {
            panField.set("v.value", panValue.toUpperCase()); // Force uppercase
        }
    },
    handleSameAddressChange : function(component, event, helper) {
        var isChecked = event.getSource().get("v.checked");
        
        var book = component.get("v.book");
        
        if (isChecked) {
            // Copy Correspondence Address → Permanent Address
            book.Permanent_Address2__Street__s = book.Correspondence_Address__Street__s;
            book.Permanent_Address2__City__s = book.Correspondence_Address__City__s;
            book.Permanent_Address2__CountryCode__s = book.Correspondence_Address__CountryCode__s;
            book.Permanent_Address2__StateCode__s = book.Correspondence_Address__StateCode__s;
            book.Permanent_Address2__PostalCode__s = book.Correspondence_Address__PostalCode__s;
        } else {
            // Clear Permanent Address if checkbox unchecked
            book.Permanent_Address2__Street__s = '';
            book.Permanent_Address2__City__s = '';
            book.Permanent_Address2__StateCode__s = '';
            book.Permanent_Address2__PostalCode__s = '';
        }
        
        component.set("v.book", book);
    },
    
    handleCoappSameAddressChange: function(component, event, helper) {
        var checked = event.getSource().get("v.checked");
        var index = event.getSource().get("v.name"); // get index from checkbox name
        var appList = component.get("v.applicantList");
        
        // Log before change
        console.log('Before Change:', JSON.stringify(appList[index]));
        
        if (checked) {
            appList[index].Permanent_Address1__Street__s = appList[index].Communication_Address1__Street__s;
            appList[index].Permanent_Address1__City__s = appList[index].Communication_Address1__City__s;
            
            
            appList[index].Permanent_Address1__CountryCode__s = appList[index].Communication_Address1__CountryCode__s;
            appList[index].Permanent_Address1__PostalCode__s = appList[index].Communication_Address1__PostalCode__s;
            appList[index].Permanent_Address1__StateCode__s = appList[index].Communication_Address1__StateCode__s;
        } else {
            appList[index].Permanent_Address1__Street__s = '';
            appList[index].Permanent_Address1__City__s = '';
            appList[index].Permanent_Address1__CountryCode__s = '';
            appList[index].Permanent_Address1__PostalCode__s = '';
            appList[index].Permanent_Address1__StateCode__s = '';
        }
        
        component.set("v.applicantList", appList);
        
        // Log after change
        console.log('After Change:', JSON.stringify(appList[index]));
    }
})