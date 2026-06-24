({
    MAX_FILE_SIZE: 4500000, // Max file size 4.5 MB
    CHUNK_SIZE: 750000,      // Chunk Max size 750 KB
    
    addAppliacantRecord: function(component, event, helper) {
        var appList = component.get("v.applicantList");
        appList.push({
            'sObjectType': 'Co_Applicant__c',
            'Salutation__c':"Mr.",
            'Name':'',
            'Date_of_Birth__c':'',
            'Anniverssary_Date__c':'',
            'Son_Daughter_Wife_of__c': '',
            'Son2_Daughter_Wife_of__c': '',
            'Nationality__c': '',
            'Passport_Number__c': '',
            'Aadhar_Number__c': '',
            'PAN_Number__c':'',
            'Email__c': '',
            'Primary_Phone__c': '',
            'Residential_Status__c': 'Resident',
            'Industry__c': '',
            'Employeed_at__c': '',
            'Country_of_Residence__c':'India',
            'Power_of_Attorney__c':'',
            'Power_of_Attorney_DOB__c':'',
            'Spouse_Name__c':'',
            'Spouse_Date_Of_Birth_coapp__c':'',
            'Qualification__c':'Graduate',
            'Annual_House_Hold_Income__c':'5 - 10 Lakhs',
            'Communication_Address1__c':'',
            'Communication_Address1__Street__s':'',
            'Communication_Address1__City__s':'',
            'Communication_Address1__CountryCode__s':'IN',
            'Communication_Address1__PostalCode__s':'',
            'Communication_Address1__StateCode__s':'',
            'Permanent_Address1__c':'',
            'Permanent_Address1__Street__s':'',
            'Permanent_Address1__City__s':'',
            'Permanent_Address1__CountryCode__s':'IN',
            'Permanent_Address1__PostalCode__s':'',
            'Permanent_Address1__StateCode__s':'',
            'Office_Address1__c':'',
            'Office_Address1__Street__s':'',
            'Office_Address1__City__s':'',
            'Office_Address1__CountryCode__s':'IN',
            'Office_Address1__PostalCode__s':'',
            'Office_Address1__StateCode__s':'',
            'Pincode_commmunication__c':'',
            'Permanent_Address__c':'',
            'Pincode_permanent__c':'',
            'Other_Qualification__c':'',
            'Other_Industry__c':'',
            'Alternate_Contact_No__c':'',
            'Marital_Status__c':'Married',
            'Designation__c': ''
        });
        component.set("v.applicantList", appList);
    },
    validateFields : function(component, event, helper) {
     
        var book = component.get("v.book");
       
        var applicantList = component.get("v.applicantList");
       
        //alert( JSON.stringify(book))
        var fieldLabels = {
            'Booking_Date__c': 'Booking Date',
            'Booking_Amount__c': 'Booking Amount',
            'Mode_Of_Payment__c': 'Mode of Payment',
            'Transaction_ID__c': 'Transaction No.',
            'Date_of_Payment__c': 'Date of Payment',
            'Funding_Type__c': 'Funding Type',
            'Bank_Name__c': 'Bank Name',
            'Branch_Name__c': 'Branch Name',
            'City_Name__c': 'City Name',
            'Date_of_Birth1__c':'Date of Birth',
            'First_Applicant_Name__c':'First Applicant Name',
            'Residential_Status__c':'Residential Status',
            'Nationality1__c':'Nationality',
            'PAN_Number__c':'PAN Number',
            'Aadhar_No__c': 'Aadhar No.',
            'Marital_Status__c':'Marital Status',
            'Mobile__c':'Mobile',
            'Email__c':'Email',
            'Son_Daughter_Wife_of1__c':'Son/Daughter/Wife of',
            'First_Applicant_Name__c':'First Applicant Name',
            'Designation__c':'Designation',
            'Employeed_at__c':'Employeed At',
            'Industry__c':'Industry',
            'Qualification__c': 'Qualification',
            'Annual_House_Hold_Income__c': 'Annual House Hold Income',
            'Purpose_of_Purchase__c':'Pupose of Purchase',
            'Pan_Uploaded__c':'PAN Uploaded',
            'Applicant_Photo_Uploaded__c':'Applicant Photo Uploaded',
            'Correspondence_Address__Street__s':'Correspondence Address Street',
            'Correspondence_Address__City__s':'Correspondence Address City',
            'Correspondence_Address__CountryCode__s':'Corresponding Address Country',
            'Correspondence_Address__PostalCode__s':'Corresponding Address Pin Code',
            'Correspondence_Address__StateCode__s':'Corresponding Address State',
            'Permanent_Address2__Street__s':'Permanent Address Street',
            'Permanent_Address2__City__s':'Permanent Address City',
            'Permanent_Address2__CountryCode__s':'Permanent Address Country',
            'Permanent_Address2__StateCode__s':'Permanent Address State',
            'Permanent_Address2__PostalCode__s':'Permanent Address Pin Code',
            'Office_Address1__Street__s':'Office Address Street',
            'Office_Address1__City__s':'Office Address City',
            'Office_Address1__CountryCode__s':'Office Address Country',
            'Office_Address1__StateCode__s':'Office Address State',
            'Office_Address1__PostalCode__s':'Office Address Pin Code',
            'Aadhaar_Uploaded__c':'Aadhaar Uploaded'
        };
        
        var coappfieldLabels = {
            'Name' : 'Co Applicant Name',
            'Date_of_Birth__c' :'DOB of Co Applicant',
            'Son_Daughter_Wife_of__c' :'Son/Daughter/Wife of',
            'Designation__c' : 'Designation',
            'Employeed_at__c' : 'Employeed At',
            'Industry__c' : 'Industry',
            'Residential_Status__c' : 'Residential Status',
            'Primary_Phone__c' : 'Primary Phone',
            'Email__c': 'Email',
            'Aadhar_Number__c': 'Aadhaar No.',
            'Country_of_Residence__c': 'Country of Residence',
            'Communication_Address1__Street__s': 'Communication Address Street',
            'Communication_Address1__City__s':'Communication Address City',
            'Communication_Address1__CountryCode__s':'Communication Address Country',
            'Communication_Address1__PostalCode__s':'Communication Address Pincode',
            'Communication_Address1__StateCode__s':'Communication Address State',
            'Permanent_Address1__Street__s': 'Permanent Address Street',
            'Permanent_Address1__City__s':'Permanent Address City',
            'Permanent_Address1__CountryCode__s':'Permanent Address Country',
            'Permanent_Address1__PostalCode__s':'Permanent Address Pincode',
            'Permanent_Address1__StateCode__s':'Permanent Address State',
            'Office_Address1__Street__s': 'Office Address Street',
            'Office_Address1__City__s':'Office Address City',
            'Office_Address1__CountryCode__s':'Office Address Country',
            'Office_Address1__PostalCode__s':'Office Address Pincode',
            'Office_Address1__StateCode__s':'Office Address State',
            'Marital_Status__c':'Martial Status',
            'PAN_Number__c':'PAN No.'
        };
        
        var mandatoryFields = Object.keys(fieldLabels);
        if (book.Residential_Status__c === 'non-resident') {
            mandatoryFields = mandatoryFields.filter(function(f) { return f !== 'Aadhar_No__c'; });
        }
        var baseCoFields = Object.keys(coappfieldLabels);

        var isValid = true;
        
        // ✅ Validate main applicant mandatory fields
        var missingFields = mandatoryFields.filter(function(field) {
            return !book[field];
        });
        
        if (missingFields.length > 0) {
            isValid = false;
            var missingFieldsList = missingFields.map(function(field) {
                return fieldLabels[field];
            }).join(', ');
            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "The following fields are missing: " + missingFieldsList,
                "type": "error"
            });
            toastEvent.fire();
        }
        
        // ✅ Aadhar validation for main applicant
        if (book.Aadhar_No__c) {
            var aadharRegex = /^[2-9]{1}[0-9]{11}$/;
            if (!aadharRegex.test(book.Aadhar_No__c)) {
                isValid = false;
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Invalid Aadhaar Number",
                    "message": "Main Applicant Aadhaar must be a valid 12-digit number starting with 2–9.",
                    "type": "error"
                });
                toastEvent.fire();
            }
        }
        var dateOfBirth = component.get("v.book.Date_of_Birth1__c"); 
        if (dateOfBirth) {
            var birthDate = new Date(dateOfBirth);
            var currentDate = new Date();
            var age = currentDate.getFullYear() - birthDate.getFullYear();
            var m = currentDate.getMonth() - birthDate.getMonth();
            
            if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                age--;
            }
            
            
            if (age < 18) {
                if (!book.Power_of_Attorney__c || !book.Power_of_Attorney_DOB__c ) {
                    isValid = false;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": "Please Check Power of Attorney Detail.",
                        "type": "error"
                    });
                    toastEvent.fire();
                }
                
            } 
        }
        
        
        
        // ✅ Validate Funding Type conditions
        /* if (book.Funding_Type__c === 'Loan' ) {
        if (!book.Loan_Status__c || !book.Loan_amount__c || !book.Loan_Approved_Date__c || !book.Loan_Bank_Name__c) {
            isValid = false;
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "Please Check Loan Related Detail 'Loan'.",
                "type": "error"
            });
            toastEvent.fire();
        }
    }*/
       
       if (book.Credit_Debit_Card_Number__c && book.Credit_Debit_Card_Number__c.length !== 16) {
           isValid = false;
           var toastEvent = $A.get("e.force:showToast");
           toastEvent.setParams({
               "title": "Invalid Card Number",
               "message": "Credit/Debit Card Number must be exactly 16 digits.",
               "type": "error"
           });
           toastEvent.fire();
       }
       // ✅ Payment mode-based checks
       if (book.Mode_Of_Payment__c === 'Cheque') {
           
           if(!book.Posting_in_Date__c || !book.Cheque_Date__c || !book.Cheque_Uploaded__c){
               isValid = false;
               var toastEvent = $A.get("e.force:showToast");
               toastEvent.setParams({
                   "title": "Error",
                   "message": "Please Cheque related Detail Expected Clearence Date, Cheque Date and Cheque Upload.",
                   "type": "error"
               });
               toastEvent.fire();
           }
       }
       if (book.Marital_Status__c === 'Married') {
           
           if(!book.Anniverssary_Date1__c || !book.Spouse_Name__c || !book.Spouse_Date_Of_Birth__c){
               isValid = false;
               var toastEvent = $A.get("e.force:showToast");
               toastEvent.setParams({
                   "title": "Error",
                   "message": "Please Check Anniversary Date, Spouse Name and Spouse Date of Birth.",
                   "type": "error"
               });
               toastEvent.fire();
           }
       }
       
       if ((book.Mode_Of_Payment__c === 'Credit Card' || book.Mode_Of_Payment__c === 'Debit Card') && !book.Credit_Debit_Card_Number__c) {
           isValid = false;
           var toastEvent = $A.get("e.force:showToast");
           toastEvent.setParams({
               "title": "Error",
               "message": "Credit/Debit Card Number is mandatory when mode of payment is Card.",
               "type": "error"
           });
           toastEvent.fire();
       }
       
       if (applicantList.length > 0) {
           if(!book.Co_Applicant_Aadhar_Upload__c || !book.Co_Applicant_Pan_Upload__c || !book.Co_Applicant_Photo_Uploaded__c ){
               isValid = false;
               var toastEvent = $A.get("e.force:showToast");
               toastEvent.setParams({
                   "title": "Error",
                   "message": "Please check Co applicant Photo, Aadhaar or PAN File Upload",
                   "type": "error"
               });
               toastEvent.fire();
           }
       }
        if (book.Industry__c === 'Other' || book.Qualification__c === 'Others') {
    var industryOk = (book.Industry__c !== 'Other') || !$A.util.isEmpty(book.Other_Profession__c);
    var qualificationOk = (book.Qualification__c !== 'Others') || !$A.util.isEmpty(book.Other_Qualification__c);

    if (!industryOk || !qualificationOk) {
        isValid = false;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error",
            "message": "Please enter values for Other Profession and Other Qualification when 'Other' is selected.",
            "type": "error",
            "mode": "dismissible",
            "duration": 3000
        });
        toastEvent.fire();
        return false;
    }
}
       
       
       // ✅ Validate co-applicants
       if (applicantList.length > 0) {
           var missingCoFieldsList = [];
           
           applicantList.forEach(function(applicant, index) {  
               // Exclude Aadhar_Number__c for Non-Resident co-applicants
               var mandatoryCoFields = baseCoFields;
               if (applicant.Residential_Status__c === 'Non-Resident') {
                   mandatoryCoFields = baseCoFields.filter(function(f) { return f !== 'Aadhar_Number__c'; });
               }
               
               var missingFields = mandatoryCoFields.filter(function(field) {
                   return !applicant[field];
               });
               
               if (missingFields.length > 0) {
                   var missingFieldsNames = missingFields.map(function(field) {
                       return coappfieldLabels[field];
                   }).join(', ');
                   missingCoFieldsList.push("Co-Applicant " + (index + 1) + ": " + missingFieldsNames);
               }
               
               if (applicant.Industry__c === 'Others' || applicant.Qualification__c === 'Others') {
                   var industryOk = (applicant.Industry__c !== 'Other') || !$A.util.isEmpty(applicant.Other_Industry__c);
                   var qualificationOk = (applicant.Qualification__c !== 'Others') || !$A.util.isEmpty(applicant.Other_Qualification__c);
                   
                   if (!industryOk || !qualificationOk) {
                       isValid = false;
                       
                       var toastEvent = $A.get("e.force:showToast");
                       toastEvent.setParams({
                           "title": "Error",
                           "message": "Co-Applicant " + (index + 1) + ": Please enter " +
                           (!industryOk ? "Other Industry" : "") +
                           (!industryOk && !qualificationOk ? " and " : "") +
                           (!qualificationOk ? "Other Qualification" : "") +
                           " when 'Other/Others' is selected.",
                           "type": "error",
                           "mode": "dismissible",
                           "duration": 3000
                       });
                       toastEvent.fire();
                       
                       return; // only exits this loop iteration
                   }
               }
               
               // ✅ Aadhar validation for co-applicant
               if (applicant.Residential_Status__c !== 'Non-Resident') {
                   if (applicant.Aadhar_Number__c ) {
                       var aadharRegex = /^[2-9]{1}[0-9]{11}$/;
                       if (!aadharRegex.test(applicant.Aadhar_Number__c)) {
                           isValid = false;
                           var toastEvent = $A.get("e.force:showToast");
                           toastEvent.setParams({
                               "title": "Invalid Aadhaar Number",
                               "message": "Co-Applicant " + (index + 1) + " Aadhaar must be a valid 12-digit number starting with 2–9.",
                               "type": "error"
                           });
                           toastEvent.fire();
                       }
                   }
               }
               if(applicant.Marital_Status__c =='Married'){
                   
                   if(!applicant.Spouse_Name__c || !applicant.Spouse_Date_Of_Birth_coapp__c || !applicant.Anniverssary_Date__c){
                       
                       isValid = false;
                       var toastEvent = $A.get("e.force:showToast");
                       toastEvent.setParams({
                           "title": "Invalid",
                           "message": "Co-Applicant " + (index + 1) + " Anniversary ,Spouse Name and Spouse DOB must for married",
                           "type": "error"
                       });
                       toastEvent.fire();
                   }
               }
               
               var prd = applicantList[index];
               
               var cdateOfBirth = prd.Date_of_Birth__c;
               
               
               if (cdateOfBirth) {
                   var birthDate = new Date(cdateOfBirth);
                   var currentDate = new Date();
                   var age = currentDate.getFullYear() - birthDate.getFullYear();
                   var m = currentDate.getMonth() - birthDate.getMonth();
                   
                   if (m < 0 || (m === 0 && currentDate.getDate() < birthDate.getDate())) {
                       age--;
                   }
                   
                   
                   if (age < 18) {
                       if (!applicant.Power_of_Attorney__c || !applicant.Power_of_Attorney_DOB__c ) {
                           isValid = false;
                           var toastEvent = $A.get("e.force:showToast");
                           toastEvent.setParams({
                               "title": "Invalid",
                               "message": "Co-Applicant " + (index + 1) + " Power of Attornery  and Power of Attornery DOB must be filled",
                               "type": "error"
                           });
                           toastEvent.fire();
                       }
                       
                   } 
               }
            
     
           });
           

           
           if (missingCoFieldsList.length > 0) {
               isValid = false;
               var toastEvent = $A.get("e.force:showToast");
               toastEvent.setParams({
                   "title": "Error",
                   "message": "The following mandatory fields are missing: \n" + missingCoFieldsList.join('\n'),
                   "type": "error"
               });
               toastEvent.fire();
           }
       }
       return isValid;
   },
    
    uploadHelper1: function(component, event, fileType) {
        var fileInput = component.find('fuploaders').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    uploadHelper2: function(component, event, fileType) {
        var fileInput = component.find('fuploaderBack').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    uploadHelper3: function(component, event, fileType) {
        var fileInput = component.find('fuploadersBack').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    
    uploadFile: function(component, event, fileInput, fileType) {
    if (!fileInput || fileInput.length === 0) {
        console.error('No file selected for: ' + fileType);
        this.toastMsg(component, null, null, 'error', 'Error!', 'No file selected for ' + fileType);
        return;
    }
    
    var file = fileInput[0];
    var self = this;
    
    console.log('Starting upload for: ' + fileType + ' - ' + file.name);
    
    if (file.size > self.MAX_FILE_SIZE) {
        this.toastMsg(component, null, null, 'error', 'Error!', 
            'File "' + fileType + '" exceeds maximum size of ' + (self.MAX_FILE_SIZE / 1000000) + 'MB');
        return;
    }
    
    var objFileReader = new FileReader();
    objFileReader.onload = $A.getCallback(function() {
        var fileContents = objFileReader.result;
        var base64 = 'base64,';
        var dataStart = fileContents.indexOf(base64) + base64.length;
        fileContents = fileContents.substring(dataStart);
        self.uploadProcess(component, file, fileContents, fileType);
    });
    
    objFileReader.onerror = $A.getCallback(function(error) {
        console.error('File read error for ' + fileType + ':', error);
        self.toastMsg(component, null, null, 'error', 'Error!', 'Failed to read file: ' + fileType);
    });
    
    objFileReader.readAsDataURL(file);
},
    
    uploadProcess: function(component, file, fileContents, fileType) {
        var startPosition = 0;
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '', fileType);
    },
    
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId, fileType) {
    var getchunk = fileContents.substring(startPosition, endPosition);
    var action = component.get('c.saveFile');
    
    var bookingId = component.get('v.bookingid');
    
    if (!bookingId) {
        console.error('No booking ID found');
        this.toastMsg(component, null, null, 'error', 'Error!', 'Booking record not created yet');
        return;
    }
    
    console.log('Uploading chunk for: ' + fileType + ' (' + startPosition + '-' + endPosition + ')');
    
    action.setParams({
        parentId: bookingId,
        fileName: file.name,
        base64Data: encodeURIComponent(getchunk),
        contentType: file.type,
        fileType: fileType               
    });
    
    action.setCallback(this, function(response) {
        var state = response.getState();
        
        if (state === 'SUCCESS') {
            attachId = response.getReturnValue();
            startPosition = endPosition;
            endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
            
            if (startPosition < endPosition) {
                this.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId, fileType);
            } else {
                console.log('✓ File uploaded successfully: ' + fileType);
                this.toastMsg(component, null, null, 'success', 'Success!', fileType + ' uploaded successfully');
            }
        } else if (state === 'ERROR') {
            var errors = response.getError();
            var errorMsg = 'Unknown error';
            
            if (errors && errors[0] && errors[0].message) {
                errorMsg = errors[0].message;
            }
            
            console.error('✗ Upload failed for ' + fileType + ': ' + errorMsg);
            this.toastMsg(component, null, null, 'error', 'Upload Failed', 
                fileType + ': ' + errorMsg);
        }
    });
    
    $A.enqueueAction(action);
},
    
    
    saveRecord : function(component,event,helper) {
        //  1) first validate all normal fields
        var isValid = helper.validateFields(component, event, helper);
        if (!isValid) {
            return;
        }
        
        var book = component.get("v.book");
        var applicantList = component.get("v.applicantList") || [];
        
        //  2) Validate file selection before booking creation
        
        // Aadhaar
        if (book.Aadhaar_Uploaded__c) {
            var aadhaarFiles = component.find("fuploader") ? component.find("fuploader").get("v.files") : null;
            if (!aadhaarFiles || aadhaarFiles.length === 0) {
                helper.toastMsg(component, null, null, "error", "Error!", "Please upload Aadhaar file.");
                return;
            }
        }
        
        // PAN
        if (book.Pan_Uploaded__c) {
            var panFiles = component.find("fuploader2") ? component.find("fuploader2").get("v.files") : null;
            if (!panFiles || panFiles.length === 0) {
                helper.toastMsg(component, null, null, "error", "Error!", "Please upload PAN file.");
                return;
            }
        }
        
        // Applicant Photo
        if (book.Applicant_Photo_Uploaded__c) {
            var appPhotoFiles = component.find("fuploader3") ? component.find("fuploader3").get("v.files") : null;
            if (!appPhotoFiles || appPhotoFiles.length === 0) {
                helper.toastMsg(component, null, null, "error", "Error!", "Please upload Applicant Photo.");
                return;
            }
        }
        
        // Cheque upload (only if cheque mode)
        if (book.Mode_Of_Payment__c === "Cheque" && book.Cheque_Uploaded__c) {
            var chequeFiles = component.find("fuploader4") ? component.find("fuploader4").get("v.files") : null;
            if (!chequeFiles || chequeFiles.length === 0) {
                helper.toastMsg(component, null, null, "error", "Error!", "Please upload Cheque file.");
                return;
            }
        }
        
        // Co-applicant docs only if co-applicant exists
        if (applicantList.length > 0) {
            
            if (book.Co_Applicant_Photo_Uploaded__c) {
                var coPhotoFiles = component.find("fuploader5") ? component.find("fuploader5").get("v.files") : null;
                if (!coPhotoFiles || coPhotoFiles.length === 0) {
                    helper.toastMsg(component, null, null, "error", "Error!", "Please upload Co-Applicant Photo.");
                    return;
                }
            }
            
            if (book.Co_Applicant_Aadhar_Upload__c) {
                var coAadhaarFiles = component.find("fuploader6") ? component.find("fuploader6").get("v.files") : null;
                if (!coAadhaarFiles || coAadhaarFiles.length === 0) {
                    helper.toastMsg(component, null, null, "error", "Error!", "Please upload Co-Applicant Aadhaar.");
                    return;
                }
            }
            
            if (book.Co_Applicant_Pan_Upload__c) {
                var coPanFiles = component.find("fuploader7") ? component.find("fuploader7").get("v.files") : null;
                if (!coPanFiles || coPanFiles.length === 0) {
                    helper.toastMsg(component, null, null, "error", "Error!", "Please upload Co-Applicant PAN.");
                    return;
                }
            }
        }

        var action = component.get("c.convertQuote");
        var book = component.get("v.book");
        console.log( JSON.stringify(book));
        //  alert( JSON.stringify(book))
        
        action.setParams({ 
            recId: component.get("v.recordId"),
            book: component.get("v.book"),
            applicantList : component.get("v.applicantList")
        });
        action.setCallback(this, function(response) {
            var state=response.getState();
            console.log('Response : '+response.getReturnValue()); 
            if(state==='SUCCESS'){
                //  component.set('v.Spinner', false);
                var db = response.getReturnValue();
                //  alert(db);
                if(db.includes('Aadhaar number must be 12 digits and checks if the field contains a numeric value..')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Aadhaar number must be 12 digits and checks if the field contains a numeric value..',
                        "duration":10000
                    });
                    toastEvent.fire();
                }else if(db.includes('Check PAN card format')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'	Check PAN card format',
                        "duration":10000
                    });
                    toastEvent.fire();
                }else if(db =='Unit not available'){
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Unit not available',
                        "duration":10000
                    });
                    toastEvent.fire(); 
                }else if(db =='Not approved'){
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Quote is not approved, you can not create booking',
                        "duration":10000
                    });
                    toastEvent.fire();
                }
                    else{
                        if(db !='' && db !=null){
                            
                            component.set('v.bookingid',db);
                            // var adar = component.get("v.Aadhar");
                            // var pan = component.get("v.PAN");
                            
                            //  helper.uploadHelper(component, event, adar+'__');
                            //  helper.uploadHelper1(component, event, pan+'__');
                            
                            
                            var first = component.get("v.fileName");
                            var second = component.get("v.file2ndName");
                            var third = component.get("v.file3rdName");
                            
                            var forth = component.get("v.file4thName");
                            
                            var fifth = component.get("v.file5thName");
                            var sixth = component.get("v.file6thName");
                            var seventh = component.get("v.file7thName");
                            
                            if(first!='No Aadhaar Photo..'){
                                helper.uploadHelper(component, event, first);
                            }
                            if(second!='No PAN Photo..'){
                                helper.upload2Helper(component, event, second);
                            }
                            if(third!='No Third Photo..'){
                                helper.upload3Helper(component, event, third);
                            }
                            if(forth=='Cheque Copy'){
                                helper.upload4Helper(component, event, forth);
                            }
                            if(fifth=='Co Applicant Photo'){
                                helper.upload5Helper(component, event, fifth);
                            }
                            if(sixth=='Co Applicant Aadhaar'){
                                helper.upload6Helper(component, event, sixth);
                            }
                            if(seventh=='Co Applicant Pan'){
                                helper.upload7Helper(component, event, seventh);
                            }
                            
                            
                            var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": db,
                                "slideDevName": "detail"
                            });
                            navEvt.fire();
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type":'Success',
                                "title": 'Success!',
                                "message":'Booking created successfully',
                                "duration":10000
                            });
                            toastEvent.fire();
                        }
                    }
            }
            /*helper.toastMsg(component, event, helper, "success", "Success!", "Booking creating successfully");
               $A.get("e.force:closeQuickAction").fire();
               $A.get('e.force:refreshView').fire();   
           }
           else{
               component.set('v.Spinner', false);
               helper.toastMsg(component, event, helper, "error", "Error!", "Something went Wrong! Please contact System Admin!");
           }*/
        });
        $A.enqueueAction(action);
    },
    
    
    toastMsg: function(component, event, helper, type, title, msg) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            title: title,
            type: type,
            message: msg,
            mode: "dismissible",
            duration: 3000
        });
        toastEvent.fire();
    },

    
    uploadHelper: function(component, event, fileType) {
        var fileInput = component.find('fuploader').get('v.files');
        
        this.uploadFile(component, event,fileInput,fileType);
    },
    
    upload2Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader2').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    
    upload3Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader3').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    upload4Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader4').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    
    upload5Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader5').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    upload6Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader6').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    upload7Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader7').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    loadCountryOptions : function(component) {
        component.set("v.countryOptions", [
            { label: "Afghanistan", value: "AF" },
            { label: "Åland Islands", value: "AX" },
            { label: "Albania", value: "AL" },
            { label: "Algeria", value: "DZ" },
            { label: "American Samoa", value: "AS" },
            { label: "Andorra", value: "AD" },
            { label: "Angola", value: "AO" },
            { label: "Anguilla", value: "AI" },
            { label: "Antarctica", value: "AQ" },
            { label: "Antigua and Barbuda", value: "AG" },
            { label: "Argentina", value: "AR" },
            { label: "Armenia", value: "AM" },
            { label: "Aruba", value: "AW" },
            { label: "Australia", value: "AU" },
            { label: "Austria", value: "AT" },
            { label: "Azerbaijan", value: "AZ" },
            { label: "Bahamas", value: "BS" },
            { label: "Bahrain", value: "BH" },
            { label: "Bangladesh", value: "BD" },
            { label: "Barbados", value: "BB" },
            { label: "Belarus", value: "BY" },
            { label: "Belgium", value: "BE" },
            { label: "Belize", value: "BZ" },
            { label: "Benin", value: "BJ" },
            { label: "Bermuda", value: "BM" },
            { label: "Bhutan", value: "BT" },
            { label: "Bolivia", value: "BO" },
            { label: "Bonaire, Sint Eustatius and Saba", value: "BQ" },
            { label: "Bosnia and Herzegovina", value: "BA" },
            { label: "Botswana", value: "BW" },
            { label: "Bouvet Island", value: "BV" },
            { label: "Brazil", value: "BR" },
            { label: "British Indian Ocean Territory", value: "IO" },
            { label: "Brunei Darussalam", value: "BN" },
            { label: "Bulgaria", value: "BG" },
            { label: "Burkina Faso", value: "BF" },
            { label: "Burundi", value: "BI" },
            { label: "Cabo Verde", value: "CV" },
            { label: "Cambodia", value: "KH" },
            { label: "Cameroon", value: "CM" },
            { label: "Canada", value: "CA" },
            { label: "Cayman Islands", value: "KY" },
            { label: "Central African Republic", value: "CF" },
            { label: "Chad", value: "TD" },
            { label: "Chile", value: "CL" },
            { label: "China", value: "CN" },
            { label: "Christmas Island", value: "CX" },
            { label: "Cocos (Keeling) Islands", value: "CC" },
            { label: "Colombia", value: "CO" },
            { label: "Comoros", value: "KM" },
            { label: "Congo", value: "CG" },
            { label: "Congo (Democratic Republic)", value: "CD" },
            { label: "Cook Islands", value: "CK" },
            { label: "Costa Rica", value: "CR" },
            { label: "Côte d'Ivoire", value: "CI" },
            { label: "Croatia", value: "HR" },
            { label: "Cuba", value: "CU" },
            { label: "Curaçao", value: "CW" },
            { label: "Cyprus", value: "CY" },
            { label: "Czechia", value: "CZ" },
            { label: "Denmark", value: "DK" },
            { label: "Djibouti", value: "DJ" },
            { label: "Dominica", value: "DM" },
            { label: "Dominican Republic", value: "DO" },
            { label: "Ecuador", value: "EC" },
            { label: "Egypt", value: "EG" },
            { label: "El Salvador", value: "SV" },
            { label: "Equatorial Guinea", value: "GQ" },
            { label: "Eritrea", value: "ER" },
            { label: "Estonia", value: "EE" },
            { label: "Eswatini", value: "SZ" },
            { label: "Ethiopia", value: "ET" },
            { label: "Falkland Islands", value: "FK" },
            { label: "Faroe Islands", value: "FO" },
            { label: "Fiji", value: "FJ" },
            { label: "Finland", value: "FI" },
            { label: "France", value: "FR" },
            { label: "French Guiana", value: "GF" },
            { label: "French Polynesia", value: "PF" },
            { label: "Gabon", value: "GA" },
            { label: "Gambia", value: "GM" },
            { label: "Georgia", value: "GE" },
            { label: "Germany", value: "DE" },
            { label: "Ghana", value: "GH" },
            { label: "Gibraltar", value: "GI" },
            { label: "Greece", value: "GR" },
            { label: "Greenland", value: "GL" },
            { label: "Grenada", value: "GD" },
            { label: "Guadeloupe", value: "GP" },
            { label: "Guam", value: "GU" },
            { label: "Guatemala", value: "GT" },
            { label: "Guernsey", value: "GG" },
            { label: "Guinea", value: "GN" },
            { label: "Guinea-Bissau", value: "GW" },
            { label: "Guyana", value: "GY" },
            { label: "Haiti", value: "HT" },
            { label: "Honduras", value: "HN" },
            { label: "Hong Kong", value: "HK" },
            { label: "Hungary", value: "HU" },
            { label: "Iceland", value: "IS" },
            { label: "India", value: "IN" },
            { label: "Indonesia", value: "ID" },
            { label: "Iran", value: "IR" },
            { label: "Iraq", value: "IQ" },
            { label: "Ireland", value: "IE" },
            { label: "Isle of Man", value: "IM" },
            { label: "Israel", value: "IL" },
            { label: "Italy", value: "IT" },
            { label: "Jamaica", value: "JM" },
            { label: "Japan", value: "JP" },
            { label: "Jersey", value: "JE" },
            { label: "Jordan", value: "JO" },
            { label: "Kazakhstan", value: "KZ" },
            { label: "Kenya", value: "KE" },
            { label: "Kiribati", value: "KI" },
            { label: "Korea (North)", value: "KP" },
            { label: "Korea (South)", value: "KR" },
            { label: "Kuwait", value: "KW" },
            { label: "Kyrgyzstan", value: "KG" },
            { label: "Lao PDR", value: "LA" },
            { label: "Latvia", value: "LV" },
            { label: "Lebanon", value: "LB" },
            { label: "Lesotho", value: "LS" },
            { label: "Liberia", value: "LR" },
            { label: "Libya", value: "LY" },
            { label: "Liechtenstein", value: "LI" },
            { label: "Lithuania", value: "LT" },
            { label: "Luxembourg", value: "LU" },
            { label: "Macao", value: "MO" },
            { label: "Madagascar", value: "MG" },
            { label: "Malawi", value: "MW" },
            { label: "Malaysia", value: "MY" },
            { label: "Maldives", value: "MV" },
            { label: "Mali", value: "ML" },
            { label: "Malta", value: "MT" },
            { label: "Marshall Islands", value: "MH" },
            { label: "Martinique", value: "MQ" },
            { label: "Mauritania", value: "MR" },
            { label: "Mauritius", value: "MU" },
            { label: "Mayotte", value: "YT" },
            { label: "Mexico", value: "MX" },
            { label: "Micronesia", value: "FM" },
            { label: "Moldova", value: "MD" },
            { label: "Monaco", value: "MC" },
            { label: "Mongolia", value: "MN" },
            { label: "Montenegro", value: "ME" },
            { label: "Montserrat", value: "MS" },
            { label: "Morocco", value: "MA" },
            { label: "Mozambique", value: "MZ" },
            { label: "Myanmar", value: "MM" },
            { label: "Namibia", value: "NA" },
            { label: "Nauru", value: "NR" },
            { label: "Nepal", value: "NP" },
            { label: "Netherlands", value: "NL" },
            { label: "New Caledonia", value: "NC" },
            { label: "New Zealand", value: "NZ" },
            { label: "Nicaragua", value: "NI" },
            { label: "Niger", value: "NE" },
            { label: "Nigeria", value: "NG" },
            { label: "Niue", value: "NU" },
            { label: "Norfolk Island", value: "NF" },
            { label: "North Macedonia", value: "MK" },
            { label: "Northern Mariana Islands", value: "MP" },
            { label: "Norway", value: "NO" },
            { label: "Oman", value: "OM" },
            { label: "Pakistan", value: "PK" },
            { label: "Palau", value: "PW" },
            { label: "Palestine, State of", value: "PS" },
            { label: "Panama", value: "PA" },
            { label: "Papua New Guinea", value: "PG" },
            { label: "Paraguay", value: "PY" },
            { label: "Peru", value: "PE" },
            { label: "Philippines", value: "PH" },
            { label: "Pitcairn", value: "PN" },
            { label: "Poland", value: "PL" },
            { label: "Portugal", value: "PT" },
            { label: "Puerto Rico", value: "PR" },
            { label: "Qatar", value: "QA" },
            { label: "Réunion", value: "RE" },
            { label: "Romania", value: "RO" },
            { label: "Russian Federation", value: "RU" },
            { label: "Rwanda", value: "RW" },
            { label: "Saint Barthélemy", value: "BL" },
            { label: "Saint Helena", value: "SH" },
            { label: "Saint Kitts and Nevis", value: "KN" },
            { label: "Saint Lucia", value: "LC" },
            { label: "Saint Martin (French part)", value: "MF" },
            { label: "Saint Pierre and Miquelon", value: "PM" },
            { label: "Saint Vincent and the Grenadines", value: "VC" },
            { label: "Samoa", value: "WS" },
            { label: "San Marino", value: "SM" },
            { label: "Sao Tome and Principe", value: "ST" },
            { label: "Saudi Arabia", value: "SA" },
            { label: "Senegal", value: "SN" },
            { label: "Serbia", value: "RS" },
            { label: "Seychelles", value: "SC" },
            { label: "Sierra Leone", value: "SL" },
            { label: "Singapore", value: "SG" },
            { label: "Sint Maarten", value: "SX" },
            { label: "Slovakia", value: "SK" },
            { label: "Slovenia", value: "SI" },
            { label: "Solomon Islands", value: "SB" },
            { label: "Somalia", value: "SO" },
            { label: "South Africa", value: "ZA" },
            { label: "South Georgia and the South Sandwich Islands", value: "GS" },
            { label: "South Sudan", value: "SS" },
            { label: "Spain", value: "ES" },
            { label: "Sri Lanka", value: "LK" },
            { label: "Sudan", value: "SD" },
            { label: "Suriname", value: "SR" },
            { label: "Svalbard and Jan Mayen", value: "SJ" },
            { label: "Sweden", value: "SE" },
            { label: "Switzerland", value: "CH" },
            { label: "Syrian Arab Republic", value: "SY" },
            { label: "Taiwan", value: "TW" },
            { label: "Tajikistan", value: "TJ" },
            { label: "Tanzania", value: "TZ" },
            { label: "Thailand", value: "TH" },
            { label: "Timor-Leste", value: "TL" },
            { label: "Togo", value: "TG" },
            { label: "Tokelau", value: "TK" },
            { label: "Tonga", value: "TO" },
            { label: "Trinidad and Tobago", value: "TT" },
            { label: "Tunisia", value: "TN" },
            { label: "Turkey", value: "TR" },
            { label: "Turkmenistan", value: "TM" },
            { label: "Turks and Caicos Islands", value: "TC" },
            { label: "Tuvalu", value: "TV" },
            { label: "Uganda", value: "UG" },
            { label: "Ukraine", value: "UA" },
            { label: "United Arab Emirates", value: "AE" },
            { label: "United Kingdom", value: "GB" },
            { label: "United States", value: "US" },
            { label: "Uruguay", value: "UY" },
            { label: "Uzbekistan", value: "UZ" },
            { label: "Vanuatu", value: "VU" },
            { label: "Venezuela", value: "VE" },
            { label: "Vietnam", value: "VN" },
            { label: "Wallis and Futuna", value: "WF" },
            { label: "Western Sahara", value: "EH" },
            { label: "Yemen", value: "YE" },
            { label: "Zambia", value: "ZM" },
            { label: "Zimbabwe", value: "ZW" }
        ]);
    },
    
    loadProvinceOptions : function(component, country) {
        if (country === "IN") {
            component.set("v.provinceOptions",[
                { label: 'Andaman and Nicobar Islands', value: 'AN' },
                { label: 'Andhra Pradesh', value: 'AP' },
                { label: 'Arunachal Pradesh', value: 'AR' },
                { label: 'Assam', value: 'AS' },
                { label: 'Bihar', value: 'BR' },
                { label: 'Chandigarh', value: 'CH' },
                { label: 'Chhattisgarh', value: 'CT' },
                { label: 'Daman and Diu', value: 'DD' },
                { label: 'Delhi', value: 'DL' },
                { label: 'Dadra and Nagar Haveli', value: 'DN' },
                { label: 'Goa', value: 'GA' },
                { label: 'Gujarat', value: 'GJ' },
                { label: 'Himachal Pradesh', value: 'HP' },
                { label: 'Haryana', value: 'HR' },
                { label: 'Jharkhand', value: 'JH' },
                { label: 'Jammu and Kashmir', value: 'JK' },
                { label: 'Karnataka', value: 'KA' },
                { label: 'Kerala', value: 'KL' },
                { label: 'Lakshadweep', value: 'LD' },
                { label: 'Maharashtra', value: 'MH' },
                { label: 'Meghalaya', value: 'ML' },
                { label: 'Manipur', value: 'MN' },
                { label: 'Madhya Pradesh', value: 'MP' },
                { label: 'Mizoram', value: 'MZ' },
                { label: 'Nagaland', value: 'NL' },
                { label: 'Odisha', value: 'OR' },
                { label: 'Punjab', value: 'PB' },
                { label: 'Puducherry', value: 'PY' },
                { label: 'Rajasthan', value: 'RJ' },
                { label: 'Sikkim', value: 'SK' },
                { label: 'Telangana', value: 'TG' },
                { label: 'Tamil Nadu', value: 'TN' },
                { label: 'Tripura', value: 'TR' },
                { label: 'Uttar Pradesh', value: 'UP' },
                { label: 'Uttarakhand', value: 'UT' },
                { label: 'West Bengal', value: 'WB' }
            ]);
        }
        if (country === "US") {
            component.set("v.provinceOptions",[
                { label: "Armed Forces Americas", value: "AA" },
                { label: "Armed Forces Europe", value: "AE" },
                { label: "Alaska", value: "AK" },
                { label: "Alabama", value: "AL" },
                { label: "Armed Forces Pacific", value: "AP" },
                { label: "Arkansas", value: "AR" },
                { label: "American Samoa", value: "AS" },
                { label: "Arizona", value: "AZ" },
                { label: "California", value: "CA" },
                { label: "Colorado", value: "CO" },
                { label: "Connecticut", value: "CT" },
                { label: "District of Columbia", value: "DC" },
                { label: "Delaware", value: "DE" },
                { label: "Florida", value: "FL" },
                { label: "Federated Micronesia", value: "FM" },
                { label: "Georgia", value: "GA" },
                { label: "Guam", value: "GU" },
                { label: "Hawaii", value: "HI" },
                { label: "Iowa", value: "IA" },
                { label: "Idaho", value: "ID" },
                { label: "Illinois", value: "IL" },
                { label: "Indiana", value: "IN" },
                { label: "Kansas", value: "KS" },
                { label: "Kentucky", value: "KY" },
                { label: "Louisiana", value: "LA" },
                { label: "Massachusetts", value: "MA" },
                { label: "Maryland", value: "MD" },
                { label: "Maine", value: "ME" },
                { label: "Marshall Islands", value: "MH" },
                { label: "Michigan", value: "MI" },
                { label: "Minnesota", value: "MN" },
                { label: "Missouri", value: "MO" },
                { label: "Northern Mariana Islands", value: "MP" },
                { label: "Mississippi", value: "MS" },
                { label: "Montana", value: "MT" },
                { label: "North Carolina", value: "NC" },
                { label: "North Dakota", value: "ND" },
                { label: "Nebraska", value: "NE" },
                { label: "New Hampshire", value: "NH" },
                { label: "New Jersey", value: "NJ" },
                { label: "New Mexico", value: "NM" },
                { label: "Nevada", value: "NV" },
                { label: "New York", value: "NY" },
                { label: "Ohio", value: "OH" },
                { label: "Oklahoma", value: "OK" },
                { label: "Oregon", value: "OR" },
                { label: "Pennsylvania", value: "PA" },
                { label: "Puerto Rico", value: "PR" },
                { label: "Palau", value: "PW" },
                { label: "Rhode Island", value: "RI" },
                { label: "South Carolina", value: "SC" },
                { label: "South Dakota", value: "SD" },
                { label: "Tennessee", value: "TN" },
                { label: "Texas", value: "TX" },
                { label: "United States Minor Outlying Islands", value: "UM" },
                { label: "Utah", value: "UT" },
                { label: "Virginia", value: "VA" },
                { label: "US Virgin Islands", value: "VI" },
                { label: "Vermont", value: "VT" },
                { label: "Washington", value: "WA" },
                { label: "Wisconsin", value: "WI" },
                { label: "West Virginia", value: "WV" },
                { label: "Wyoming", value: "WY" }
            ]);
        }
    },
    
    validatePostalCodes: function(component) {
        var book = component.get("v.book");
        var hasInvalidPostal = false;
        
        // Check and clean Correspondence Address postal code
        if (book.Correspondence_Address__PostalCode__s && !/^\d*$/.test(book.Correspondence_Address__PostalCode__s)) {
            book.Correspondence_Address__PostalCode__s = book.Correspondence_Address__PostalCode__s.replace(/\D/g, '');
            hasInvalidPostal = true;
        }
        
        // Check and clean Permanent Address postal code
        if (book.Permanent_Address2__PostalCode__s && !/^\d*$/.test(book.Permanent_Address2__PostalCode__s)) {
            book.Permanent_Address2__PostalCode__s = book.Permanent_Address2__PostalCode__s.replace(/\D/g, '');
            hasInvalidPostal = true;
        }
        
        // Check and clean Office Address postal code
        if (book.Office_Address1__PostalCode__s && !/^\d*$/.test(book.Office_Address1__PostalCode__s)) {
            book.Office_Address1__PostalCode__s = book.Office_Address1__PostalCode__s.replace(/\D/g, '');
            hasInvalidPostal = true;
        }
        
        // Update the component
        component.set("v.book", book);
        
        // Show warning toast if any postal code had invalid characters
        if (hasInvalidPostal) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Invalid Input",
                "message": "Postal Code can only contain numbers. Non-numeric characters have been removed.",
                "type": "warning"
            });
            toastEvent.fire();
        }
        
        // Also validate co-applicant postal codes
        var applicantList = component.get("v.applicantList");
        if (applicantList && applicantList.length > 0) {
            var coAppHasInvalid = false;
            
            applicantList.forEach(function(applicant) {
                // Communication Address
                if (applicant.Communication_Address1__PostalCode__s && !/^\d*$/.test(applicant.Communication_Address1__PostalCode__s)) {
                    applicant.Communication_Address1__PostalCode__s = applicant.Communication_Address1__PostalCode__s.replace(/\D/g, '');
                    coAppHasInvalid = true;
                }
                
                // Permanent Address
                if (applicant.Permanent_Address1__PostalCode__s && !/^\d*$/.test(applicant.Permanent_Address1__PostalCode__s)) {
                    applicant.Permanent_Address1__PostalCode__s = applicant.Permanent_Address1__PostalCode__s.replace(/\D/g, '');
                    coAppHasInvalid = true;
                }
                
                // Office Address
                if (applicant.Office_Address1__PostalCode__s && !/^\d*$/.test(applicant.Office_Address1__PostalCode__s)) {
                    applicant.Office_Address1__PostalCode__s = applicant.Office_Address1__PostalCode__s.replace(/\D/g, '');
                    coAppHasInvalid = true;
                }
            });
            
            component.set("v.applicantList", applicantList);
            
            if (coAppHasInvalid) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Invalid Input",
                    "message": "Co-Applicant Postal Code can only contain numbers. Non-numeric characters have been removed.",
                    "type": "warning"
                });
                toastEvent.fire();
            }
        }
    }
})