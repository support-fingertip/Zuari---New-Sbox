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

            var projectName = (record.Project1__r && record.Project1__r.Name) ? record.Project1__r.Name : '';
            
            // DEBUG: Check what project name is coming — remove after testing
            console.log('>>> Project Name: ', projectName);
            console.log('>>> Full Record: ', JSON.stringify(record));

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

            var bookingamount = record.Total_received_Amount__c;
            var defaultEmailContent = '';

            // ========== GANGOTHRI TRIBHUJA TEMPLATE ==========
            if (projectName === 'Zuari Gangotri Tribhuja') {

                defaultEmailContent = `
    <div style="color: black;">
        <p>Dear Mr. <strong>${record.First_Applicant_Name__c || ''}</strong>,</p>

        <p>Greetings from <strong>Zuari Gangothri Tribhuja</strong>,</p>

        <p>We sincerely thank you for choosing to be a part of our prestigious community at Kollur and warmly welcome you to the <strong>Zuari Gangothri Tribhuja</strong> family.</p>

        <p>We acknowledge with thanks the receipt of your application money of <strong>Rs. ${record.Total_received_Amount__c || ''}/- (Rupees ${numberToWords(bookingamount)})</strong> towards booking of Flat No. <strong>${record.Plot__r ? record.Plot__r.Name : ''}</strong> at <strong>Zuari Gangothri Tribhuja</strong>.</p>

        <p>To proceed with the execution of the <strong>Agreement for Sale</strong>, we request you to kindly remit <strong>10%</strong> of the total sale consideration (less the application money of <strong>Rs. ${record.Total_received_Amount__c || ''}/-</strong> already paid), amounting to <strong>Rs. ${record.Application_Amount_For__c || '_________'}/-</strong>, as per the payment plan accepted in your application form.</p>

        <p><strong>Bank Details for Payment:</strong></p>
        <table style="color:black; border-collapse:collapse;">
            <tr><td><strong>Company Name</strong></td><td>: Gangothri Infraedge Private Limited</td></tr>
            <tr><td><strong>Bank Name</strong></td><td>: State Bank of India</td></tr>
            <tr><td><strong>Account No.</strong></td><td>: 44893435823</td></tr>
            <tr><td><strong>Account Type</strong></td><td>: Current Account</td></tr>
            <tr><td><strong>IFSC Code</strong></td><td>: SBIN0020458</td></tr>
            <tr><td><strong>Branch</strong></td><td>: Jubilee Hills, Road No.17, Hyderabad, Telangana-500033</td></tr>
        </table>

        <br/>

        <p><strong>Mandatory KYC Documents Required:</strong></p>
        <ul>
            <li>PAN Card</li>
            <li>Aadhaar Card</li>
            <li>Two Passport Size Photographs of each applicant (in case of joint booking)</li>
        </ul>
        <p>If the above documents have already been submitted, please disregard this request.</p>

        <p>Please note that the Agreement for Sale will be executed upon:</p>
        <ol>
            <li>Receipt of the aforesaid 10% payment (after adjusting application money), and</li>
            <li>Franking charges at 0.5% of the sale consideration, amounting to <strong>Rs. ${record.Franking_Amount__c || '_________'}/-</strong>, to be borne by you.</li>
        </ol>

        <p>Kindly arrange to complete the above formalities within <strong>15 days</strong> from the date of this communication. In case of non-payment within the stipulated period, the application shall stand cancelled and the application amount shall be liable for forfeiture, as per the terms of booking.</p>

        <p>We have enclosed a draft copy of the Agreement for your review and verification. Should you require any clarification or assistance, please feel free to contact us at any time.</p>

        <p>We appreciate your continued trust and look forward to a long and rewarding association.</p>

        <br/>
        <p>Warm regards,<br/>
        For <strong>Gangothri Infraedge Pvt. Ltd.</strong><br/><br/>
        Authorized Signatory</p>
    </div>`;

            } else {

                // ========== DEFAULT TEMPLATE (Zuari Garden City / Others) ==========
                defaultEmailContent = `
    <div style="color: black;">
        <p>Dear Mr. <strong>${record.First_Applicant_Name__c || ''}</strong>,</p>

        <p>Greetings from <strong>Zuari Infraworld</strong>,</p>

        <p>We take this opportunity to thank you for your patronage and welcome you to the family of <strong>Zuari Gangothri Tribhuja</strong>.
        We acknowledge receipt of your application money of <strong>Rs. ${record.Total_received_Amount__c || ''}/- (Rupees ${numberToWords(bookingamount)})</strong> along with your application for 
        Plot No. <strong>${record.Plot__r ? record.Plot__r.Name : ''}</strong> at <strong>Zuari Gangothri Tribhuja</strong>.</p>

        <p>In order to execute your <strong>Agreement for Sale</strong>, we request you to kindly pay 
        <strong>10% (less application money of Rs.${record.Total_received_Amount__c || ''}/-)</strong> i.e. 
        <strong>Rs. ${record.Application_Amount_For__c || '_________'}/-</strong> out of the total consideration,
        as per the payment plan accepted by you in the application form.</p>

        <p>The bank account details for transfer of the above amount are mentioned below:</p>

        <table style="color:black; border-collapse:collapse;">
            <tr><td><strong>Company Name</strong></td><td>: Zuari Infraworld India Ltd</td></tr>
            <tr><td><strong>Bank Name</strong></td><td>: ICICI Bank</td></tr>
            <tr><td><strong>Account No.</strong></td><td>: 000205037142</td></tr>
            <tr><td><strong>Account Type</strong></td><td>: Current Account</td></tr>
            <tr><td><strong>IFSC Code</strong></td><td>: ICIC0000002</td></tr>
            <tr><td><strong>Branch</strong></td><td>: Bangalore</td></tr>
        </table>

        <br/>

        <p>Please organize to share your bank counsellor's contact details in case you are availing a home loan pursuant to execution of the Agreement for Sale.
        This will help us to coordinate and provide all the requisite documents for bank processes.</p>

        <p>We would also require the mandatory KYC documents:
        <ul>
            <li>PAN Card</li>
            <li>Aadhar Card</li>
            <li>2 Passport Size Photographs each of both the applicants (if booking is in joint names)</li>
        </ul>
        If you have already submitted these, please ignore.</p>

        <p>Further, we are enclosing herewith the copy of the Agreement for your verification.
        The Agreement for Sale shall be executed only upon payment of the aforesaid 10% (less application money of Rs.${record.Booking_Amount__c || ''})
        and franking of the same at 0.5% of the sale consideration — i.e., Rs. <strong>${record.Franking_Amount__c || '_________'}/-</strong> by you.</p>

        <p>In the event of default in payment of the above amount, beyond 15 days from this communication, 
        the application shall stand rejected and the application amount shall stand forfeited.</p>

        <p>Should you require any assistance or clarifications, please feel free to call us or write. 
        We look forward to your continued support and cooperation.</p>

        <br/>
        <p>Warm regards,<br/>
        <strong>${record.Owner_Full_Name__c || ''}</strong><br/>
        <strong>${record.Owner_Phone__c || ''}</strong><br/>
        Zuari Infraworld India Ltd</p>
    </div>`;
            }

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
    // Prevent multiple clicks by checking if already sending
    if (component.get("v.isSending")) {
        return;
    }
    
    // Set sending flag to true to disable button
    component.set("v.isSending", true);
    
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
        
        // Re-enable button on error
        component.set("v.isSending", false);
        return;
    }

    var action = component.get("c.sendWelcomeEmail");
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
            
            // Re-enable button on error
            component.set("v.isSending", false);
            
            // Show error toast
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please approve pending receipt before sending welcome email.",
                "type": "error"
            });
            toastEvent.fire();
        }
    });

    $A.enqueueAction(action);
},
    Cancel: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
        
})