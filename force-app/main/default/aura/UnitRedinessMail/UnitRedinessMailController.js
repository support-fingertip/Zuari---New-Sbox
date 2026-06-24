({
    doInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getRecordData");
        action.setParams({
            "recordId": recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var record = response.getReturnValue();
                component.set("v.record", record);
                
                var customerName = record.First_Applicant_Name__c;
                var project = record.Project__c;
                function numberToWords(num) {
                    if (!num || isNaN(num)) return '';
                    
                    const a = [
                        '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
                        'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
                        'Seventeen', 'Eighteen', 'Nineteen'
                    ];
                    const b = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
                    
                    function inWords(n) {
                        if (n < 20) return a[n];
                        if (n < 100) return b[Math.floor(n / 10)] + (n % 10 ? ' ' + a[n % 10] : '');
                        if (n < 1000) return a[Math.floor(n / 100)] + ' Hundred' + (n % 100 ? ' and ' + inWords(n % 100) : '');
                        if (n < 100000) return inWords(Math.floor(n / 1000)) + ' Thousand' + (n % 1000 ? ' ' + inWords(n % 1000) : '');
                        if (n < 10000000) return inWords(Math.floor(n / 100000)) + ' Lakh' + (n % 100000 ? ' ' + inWords(n % 100000) : '');
                        return inWords(Math.floor(n / 10000000)) + ' Crore' + (n % 10000000 ? ' ' + inWords(n % 10000000) : '');
                    }
                    
                    return inWords(Math.floor(num)) + ' Only';
                }
                
                /*  var defaultEmailContent = 
                "<div style='color: black;'><strong>Dear " + record.First_Applicant_Name__c + ",</strong></div><br/>";
                   defaultEmailContent +=  "<div style='color: black;'>A heartfelt congratulation to you and your family on the purchase of <strong>Unit  in Eipl -"+record.Project__c+"</strong>. On behalf of the entire Eipl family, we extend a warm welcome to you.<br/>"+
                    "We are truly honoured that you have chosen Eipl for your dream home. Your trust and association mean a lot to us, and we assure you that we will do our best to exceed your expectations. <br/>"+
                    "Moving forward, your primary point of contact will be<strong> "+record.Owner_NameFor__c+"</strong> we kindly request you to save<strong> "+record.Owner_Phone__c+"</strong> contact information for future reference.<br/>"+
                    "Your patronage is invaluable to us, and we are committed to providing you with the best service possible. Should you have any queries or require assistance, please do not hesitate to contact me directly.<br/>"+
                    "Once again, thank you for choosing Eipl for your housing needs. We look forward to building a long and fruitful relationship with you.\n\n <br/><br/>"+
                    "Warm regards,<br/>\n\n <strong>"+record.Owner_NameFor__c+ " <br/>\n"+record.Owner_Designation__c+"<br/> </strong>\n\Eipl</div>";

                component.set("v.emailContent", defaultEmailContent);
                */
                var bookingamount = record.Booking_Amount__c
                var defaultEmailContent = `
                <div style="color: black;">
                    <p>Dear ${record.S__c || ''} <strong>${record.First_Applicant_Name__c || ''}</strong>,</p>
                        
                        <p>Greetings from <strong>${record.Project__c}</strong>!</p>
                            
                            <p>We are pleased to inform you that your unit <strong>${record.Unit_No__c || ''}</strong>
                             is now <strong>ready for possession/inspection</strong>.</p>
                                
                                <p>Our team has completed all the internal and external works, and the unit has been inspected to ensure it meets our quality and safety standards. We invite you to schedule your visit to inspect your unit at your convenience.</p>
                                
                                <p><strong>Project Details:</strong></p>
                                    <table style="color:black; border-collapse:collapse;">
                                        <tr><td><strong>Project Name</strong></td><td>: ${record.Project__c}</td></tr>
                                            <tr><td><strong>Unit No.</strong></td><td>: ${record.Unit_No__c || ''}</td></tr>
                                                  
                                                        </table>
                                                    
                                                    <br/>
                                                        
                                                        <p>To initiate the possession process, we request you to kindly ensure the following:</p>
                                                        <ul>
                                                            <li>Settlement of all pending dues as per your payment schedule.</li>
                                                            <li>Submission of post-dated cheques (if applicable).</li>
                                                            <li>Execution of the Sale Deed upon clearance of payments.</li>
                                                            </ul>
                                                            
                                                            <p>Once the above formalities are completed, we will issue your <strong>Possession Letter</strong> and schedule the handover of your unit.</p>
                                                                
                                                                <p><strong>Bank Details for Final Payment:</strong></p>
                                                                    <table style="color:black; border-collapse:collapse;">
                                                                    <tr><td><strong>Company Name</strong></td><td>: ${record.Project1__r.Company_Name__c}</td></tr>
                                                                    <tr><td><strong>Bank Name</strong></td><td>: ${record.Bank_Name__c || 'ICICI Bank'}</td></tr>
                                                                    <tr><td><strong>Account No.</strong></td><td>: ${record.Account_Number__c || '000205037142'}</td></tr>
                                                                    <tr><td><strong>Account Type</strong></td><td>: Current Account</td></tr>
                                                                    <tr><td><strong>IFSC Code</strong></td><td>: ${record.IFSC_Code__c || 'ICIC0000002'}</td></tr>
                                                                    <tr><td><strong>Branch</strong></td><td>: ${record.Branch_Name__c || 'Bangalore'}</td></tr>
                                                                    </table>
                                                                    
                                                                    <br/>
                                                                    
                                                                    <p>Our Customer Relations Team will be happy to assist you with scheduling your inspection visit and clarifying any queries you may have regarding possession or documentation.</p>
                                                                    
                                                                    <p>Please confirm your convenient date and time for the unit inspection by replying to this email or contacting us at <strong>${record.Contact_Number__c || 'our customer service helpline'}</strong>.</p>
                                                                    
                                                                    <p>We sincerely thank you for your continued trust in <strong>${record.Project__c}</strong>. We look forward to welcoming you to your new home!</p>
                                                                    
                                                                    <br/>
                                                                    <p>Warm regards,<br/>
                                                                    <strong>${record.Owner_Full_Name__c || 'Customer Relations Team'}</strong><br/>
                                                                    ${record.Project1__r.Company_Name__c}</p>
                                                                    
                                                                    </div>
                                                                    `;
                                                                    
                                                                    // Set to component variable
                                                                    component.set("v.emailContent", defaultEmailContent);
                                                                                  
                                                                                  
                                                                                  } else {
                                                                                  console.error("Error retrieving record data");
            }
        });
        
        $A.enqueueAction(action);
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },
    sendEmail: function(component, event, helper) {
        var recList = component.get('v.recepients');
        var allFiles = component.get('v.files');
        var contentDocumentIds = component.get('v.filesIDS');
        var modifiedEmailContent = component.get("v.emailContent");
        var record = component.get("v.record");
        
        var toAddresses = [];
        if(recList) {
            var recList = recList.split(',');
            recList.forEach(function(email) {
                toAddresses.push(email.trim());
            });
        }
        if (record.Email__c) {
            toAddresses.push(record.Email__c);
        }
        
        if (toAddresses.length === 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "No email address available to send the email.",
                "type": "error"
            });
            toastEvent.fire();
            return;
        }
        
        var action = component.get("c.sendUnitRedinessMail");
        action.setParams({
            "recordId": component.get("v.record.Id"),
            "toAddresses": toAddresses,
            "emailContent": modifiedEmailContent,
            "contentIds": contentDocumentIds
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Email Sent Successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            } else {
                console.error("Error sending email");
            }
        });
        
        $A.enqueueAction(action);
    },
    Cancel: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
    
})