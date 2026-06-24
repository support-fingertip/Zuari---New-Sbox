({
    doInit : function(component, event, helper) {
        
        var recordId = component.get("v.recordId");
        var action = component.get("c.getBookingDetails");
        action.setParams({
            "recordId": recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var booking = result.booking;
                if (!booking) {
                    console.error("Booking data is missing!");
                    return;
                }
                if(booking.Total_received_Amount__c < booking.Agreement_Execution_Amount__c){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": 'error',
                        "title": 'Payment Pending',
                        "message": 'Customer has not yet payed the full agreement amount!',
                        "duration": 2000
                    });
                    toastEvent.fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    console.error("Customer has not yet payed the full agreement amount!");
                    return;
                }else if(booking.Agreement_Expected_Date__c == null){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": 'error',
                        "title": 'Missing Expected Date',
                        "message": 'Agreement expected date is missing please update in the agreement section!',
                        "duration": 2000
                    });
                    toastEvent.fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    console.error("Agreement expected date is missing please update in the agreement section!");
                    return;
                }
                
                var applicantName = result.customerNames;
                var phaseDetail = (booking.Plot__r && booking.Plot__r.Phase_Detail__c) ? booking.Plot__r.Phase_Detail__c : '';
                var phaseText = phaseDetail ? ', <strong>' + phaseDetail + '</strong>' : '';
                var agreementDueDate = helper.formatDate(booking.Agreement_Execution_Date__c); 
                var agreementExpectedDate = helper.formatDate(booking.Agreement_Expected_Date__c);
                var ProjectName = (booking.Project1__r && booking.Project1__r.Name) ? booking.Project1__r.Name : '';
                var PlotName = (booking.Plot__r && booking.Plot__r.Name) ? booking.Plot__r.Name : '';
                
                // DEBUG: remove after testing
                console.log('>>> Project Name: ', ProjectName);
                
                var defaultEmailContent = '';
                
                // ========== GANGOTHRI TRIBHUJA TEMPLATE ==========
                /*if (ProjectName === 'Zuari Gangotri Tribhuja') {
                    
                    defaultEmailContent = 
                        "<div style='color: black; font-family: Arial, sans-serif; line-height: 1.6;'>" +
                        "<h3 style='text-align: center; margin-bottom: 20px;'></h3>" +
                        "<p><strong>Dear Sir/Madam,</strong></p><br/>" +
                        "<p>This is to intimate you that we have received Occupancy Certificate for <strong>Zuari Gangothri Tribhuja</strong>. " +
                        "The Project is ready for possession and registration in all aspects. Further to the completion of payment formalities for " +
                        "Flat No. <strong>" + PlotName + "</strong>" + phaseText + "  in " +
                        "<strong>Zuari Gangothri Tribhuja, Kollur</strong>, we hereby request you to kindly initiate the process for registration of the said flat.</p><br/>" +
                        "<p>We confirm that all dues as per the agreed payment schedule have been cleared. " +
                        "Kindly inform us of the proposed registration date and share the list of documents and formalities required from our end to proceed further.</p><br/>" +
                        "<p>We request you to schedule the registration at the earliest and keep us informed of the next steps.</p><br/>" +
                        "<p>Thanking you.</p><br/>" +
                        "<p><strong>Regards,</strong><br/>" +
                        "Name: <strong>" + (booking.First_Applicant_Name__c || '') + "</strong><br/>" +
                        "Unit No: <strong>" + PlotName + "</strong><br/>" +
                        "Contact No: <strong>" + (booking.Owner_Phone__c || '') + "</strong></p>" +
                        "</div>";
                    
                } else {*/
                    
                    // ========== DEFAULT TEMPLATE (Other Projects) ==========
                    defaultEmailContent = 
                        "<div style='color: black; font-family: Arial, sans-serif; line-height: 1.6;'>" +
                        "<p><strong>Dear " + applicantName + ",</strong></p><br/>" +
                        "<p><strong>Greetings from Zuari.</strong></p><br/>" +
                        "<p>This is a gentle reminder to confirm the date for signing the sale agreement concerning " +
                        "<strong>Plot/Unit No. " + PlotName + "</strong> at <strong>Zuari " + ProjectName + "</strong>. " +
                        "As per our previous correspondence, the final sale agreement is pending your confirmation. " +
                        "The <strong>Agreement Expected Date</strong> is <strong>" + agreementExpectedDate + "</strong> " +
                        "and the <strong>Agreement Due Date</strong> is <strong>" + agreementDueDate + "</strong>.</p><br/>" +
                        "<p>We kindly request you to confirm a suitable date for finalizing the agreement at your earliest convenience. " +
                        "Should you need any assistance or further clarification, please feel free to reach out. We are happy to assist you.</p><br/>" +
                        "<p>Thank you for your prompt attention to this matter.</p><br/>" +
                        "<p><strong>Warm regards,</strong><br/>Zuari Infraworld India Ltd.</p>" +
                        "</div>";
                //}
                
                component.set("v.emailContent", defaultEmailContent);
            } else {
                console.error("Error retrieving record data");
            }
        });
        
        $A.enqueueAction(action);
    },
    
    sendEmail: function(component, event, helper) {
        console.log('Here in the sendEmail');
        const modifiedEmailContent = component.get("v.emailContent");
        console.log('modifiedEmailContent' + modifiedEmailContent);
        console.log('Here in the sendEmail 1');
        var action = component.get("c.sendAgreementRequestMail");
        
        action.setParams({
            "recId": component.get("v.recordId"),
            "emailContent": modifiedEmailContent
        });
        console.log('Here in the sendEmail 3');
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                console.log('Here in the sendEmail 4');
                var res_string = response.getReturnValue();
                
                event.stopPropagation();
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                var type = res_string === 'Email sent successfully' ? 'success' : 'error';
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type,
                    "message": res_string,
                    "duration": 10000
                });
                toastEvent.fire();
                
                $A.get('e.force:refreshView').fire();
            } else if (state === 'ERROR') {
                console.log('Here in the sendEmail 5');
                console.log('Failed to send email: ', response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
})