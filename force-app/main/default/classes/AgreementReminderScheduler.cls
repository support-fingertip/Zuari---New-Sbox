global class AgreementReminderScheduler implements Schedulable {
    global void execute(SchedulableContext context) {
        
        List<Booking__c> bookings = [SELECT Id, Booking_Approval_Time__c, CRM_Executive__r.Email, Plot__r.Name,Time_Extension_Requested__c,Time_Extension_Approval_Status__c, Project1__r.Name, Email__c,Agreement_Execution_Date__c
                                     ,First_Applicant_Name__c,Owner_Full_Name__c,CRM_Head__r.Email,Sales_Head__r.Email,COO__r.Email FROM Booking__c 
                                     WHERE Booking_Approval_Time__c != NULL AND  Disable_Automatic_Agreement_Reminders__c != true AND  Agreement_Status__c = 'Not Scheduled' AND Stage__c NOT IN ('Unit Swap', 'Cancellation')];
        
        Map<String, Id> ownerEmailToOrgWideIdMap = new Map<String, Id>();
           OrgWideEmailAddress[] owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'communication@crm.zuariproperties.com'];
         
       /* for (OrgWideEmailAddress ow : [SELECT Id, Address FROM OrgWideEmailAddress]) {
            ownerEmailToOrgWideIdMap.put(ow.Address.toLowerCase(), ow.Id);
        }
        */
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        list<Booking__c> cancelBookings = new list<Booking__c>();
        for (Booking__c booking : bookings) {
            
            Date approvalDate = booking.Booking_Approval_Time__c.date();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { booking.Email__c });
            String ownerEmail = booking.CRM_Executive__r.Email;
           /* if (ownerEmail != null && ownerEmailToOrgWideIdMap.containsKey(ownerEmail.toLowerCase())) {
                mail.setOrgWideEmailAddressId(ownerEmailToOrgWideIdMap.get(ownerEmail.toLowerCase()));
            }*/
            if (owea.size() > 0) {
                mail.setOrgWideEmailAddressId(owea[0].Id);
            }
            
            String mailSubject = '';
            String emailBody = '';
            
            // Handling reminder on the 15th day
            if (approvalDate == System.today().addDays(-15)) {
                mailSubject = 'Reminder for Sale Agreement Confirmation for Plot/Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name;
                emailBody = 'Dear Sir/Madam,\n\n' +
                    'Greetings from Zuari.\n\n' +
                    'This is a gentle reminder to confirm the date for signing the sale agreement concerning Plot/Unit No. ' + booking.Plot__r.Name + 
                    ' at Zuari ' + booking.Project1__r.Name + '. As per our previous correspondence, the final sale agreement is pending your confirmation.\n\n' +
                    'We kindly request you to confirm a suitable date for finalizing the agreement at your earliest convenience.\n\n' +
                    'Should you need any assistance or further clarification, please feel free to reach out. We are happy to assist you.\n\n' +
                    'Thank you for your prompt attention to this matter.\n\n' +
                    'Warm regards,\n\n' +
                    'Zuari Infraworld India Ltd.';
            }
            // Handling second reminder on the 25th day
            else if (approvalDate == System.today().addDays(-25)) {
                mailSubject = 'Final Reminder: Sale Agreement Date Selection for Plot/Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name ;
                emailBody = 'Dear Sir/Madam,\n\n' +
                    'Greetings from Zuari.\n\n' +
                    'This is a final reminder to confirm the date for signing the sale agreement concerning Plot/Unit No. ' + booking.Plot__r.Name + 
                    ' at Zuari ' + booking.Project1__r.Name + '. As per our previous correspondence, the final sale agreement is still pending your confirmation.\n\n' +
                    'We kindly request you to confirm a suitable date for finalizing the agreement at your earliest convenience. Your prompt action will help us proceed without further delay.\n\n' +
                    'Please treat this as an urgent matter and confirm the agreement date as soon as possible.\n\n' +
                    'Should you need any assistance or further clarification, please feel free to reach out. We are here to help.\n\n' +
                    'Thank you for your immediate attention to this matter.\n\n' +
                    'Warm regards,\n\n' +
                    'Zuari Infraworld India Ltd.';
            }
            else if (approvalDate == System.today().addDays(-32) && booking.Time_Extension_Approval_Status__c == 'Approved') {
                mailSubject = 'Final Reminder: Sale Agreement Date Selection for Plot/Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name ;
                emailBody = 'Dear Sir/Madam,\n\n' +
                    'Greetings from Zuari.\n\n' +
                    'This is a final reminder to confirm the date for signing the sale agreement concerning Plot/Unit No. ' + booking.Plot__r.Name + 
                    ' at Zuari ' + booking.Project1__r.Name + '. As per our previous correspondence, the final sale agreement is still pending your confirmation.\n\n' +
                    'We kindly request you to confirm a suitable date for finalizing the agreement at your earliest convenience. Your prompt action will help us proceed without further delay.\n\n' +
                    'Please treat this as an urgent matter and confirm the agreement date as soon as possible.\n\n' +
                    'Should you need any assistance or further clarification, please feel free to reach out. We are here to help.\n\n' +
                    'Thank you for your immediate attention to this matter.\n\n' +
                    'Warm regards,\n\n' +
                    'Zuari Infraworld India Ltd.';
            }
            else if (approvalDate == System.today().addDays(-40) && booking.Time_Extension_Approval_Status__c == 'Approved') {
                mailSubject = 'Final Reminder: Sale Agreement Date Selection for Plot/Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name ;
                emailBody = 'Dear Sir/Madam,\n\n' +
                    'Greetings from Zuari.\n\n' +
                    'This is a final reminder to confirm the date for signing the sale agreement concerning Plot/Unit No. ' + booking.Plot__r.Name + 
                    ' at Zuari ' + booking.Project1__r.Name + '. As per our previous correspondence, the final sale agreement is still pending your confirmation.\n\n' +
                    'We kindly request you to confirm a suitable date for finalizing the agreement at your earliest convenience. Your prompt action will help us proceed without further delay.\n\n' +
                    'Please treat this as an urgent matter and confirm the agreement date as soon as possible.\n\n' +
                    'Should you need any assistance or further clarification, please feel free to reach out. We are here to help.\n\n' +
                    'Thank you for your immediate attention to this matter.\n\n' +
                    'Warm regards,\n\n' +
                    'Zuari Infraworld India Ltd.';
            }
            // Handling termination email on the 45th day
            else if (booking.Agreement_Execution_Date__c == System.today().addDays(-45)) {
                mailSubject = 'Termination Notice: Sale Agreement Not Confirmed for Plot/Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name;
                emailBody = 'Dear Sir/Madam,\n\n' +
                    'Greetings from Zuari.\n\n' +
                    'We regret to inform you that due to the lack of confirmation for the sale agreement, we are forced to terminate your booking for Plot/Unit No. ' + booking.Plot__r.Name + 
                    ' at Zuari ' + booking.Project1__r.Name + '.\n\n' +
                    'Despite our previous reminders, we have not received any communication from you regarding the agreement date, and the booking is now considered canceled.\n\n' +
                    'Please contact us immediately if you wish to resolve this matter or need further assistance.\n\n' +
                    'We sincerely hope to resolve this issue amicably.\n\n' +
                    'Best regards,\n\n' +
                    'Zuari Infraworld India Ltd.';
                // For Sending Termination Confirmation mail to CFO , Sales Head and respective user;
                
                String subject = 'Termination Confirmation Sent to Customer for Unit ' + booking.Plot__r.Name;
                String body = ''
                    + '<p>Dear Team,</p>'
                    + '<p>This is to inform you that a <strong>termination confirmation email</strong> has been successfully sent to the customer regarding <strong>Unit ' + booking.Plot__r.Name + '</strong>.</p>'
                    + '<p><strong>Termination Details:</strong></p>'
                    + '<table style="border-collapse: collapse; border: 1px solid #ddd;">'
                    + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Project Name</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Project1__r.Name + '</td></tr>'
                    + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Customer Name</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.First_Applicant_Name__c + '</td></tr>'
                    + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Customer Email</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Email__c + '</td></tr>'
                    + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Initiated By</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Owner_Full_Name__c + '</td></tr>'
                    + '</table>'
                    + '<br/>'
                    + '<p><strong>Summary:</strong><br/>The termination confirmation mail has been sent to the customer as per the standard communication process. '
                    + 'All concerned departments are requested to update their respective systems accordingly.</p>'
                    + '<ul>'
                    + '<li><strong>Sales Team</strong> – Update lead/opportunity status to Terminated</li>'
                    + '<li><strong>Finance Team</strong> – Process refund or financial settlement as applicable</li>'
                    + '<li><strong>CRM Team</strong> – Ensure CRM record accuracy</li>'
                    + '</ul>'
                    + '<br/>'
                    + '<p>Best Regards,<br/><strong>CRM Notification System</strong><br/>' + 'Zuari' + '</p>';
                List<String> toaddress = new List<String>();
                if(booking.CRM_Executive__r.Email!=null){
                    toaddress.add(booking.CRM_Head__r.Email);
                }
                if(booking.CRM_Head__r.Email!=null){
                    
                    toaddress.add(booking.CRM_Head__r.Email);
                }
                if(booking.Sales_Head__r.Email!=null){
                    
                    toaddress.add(booking.Sales_Head__r.Email);
                }
                if(booking.COO__r.Email!=null){
                    toaddress.add(booking.COO__r.Email);
                }
                Messaging.SingleEmailMessage mailcfo = new Messaging.SingleEmailMessage();
                mailcfo.setToAddresses(toaddress);
                mailcfo.setSubject(subject);
                mailcfo.setHtmlBody(body);
                mailcfo.setSaveAsActivity(false);                
                emails.add(mailcfo);
                
            }
            
            else if (booking.Agreement_Execution_Date__c == System.today().addDays(-49)) {
                cancelBookings.add(booking);
            }
            mail.setSubject(mailSubject);
            mail.setPlainTextBody(emailBody);
            emails.add(mail);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        if(!cancelBookings.isEmpty()){
            BookingController.changeUnitStatus(cancelBookings);
        }
    }
}