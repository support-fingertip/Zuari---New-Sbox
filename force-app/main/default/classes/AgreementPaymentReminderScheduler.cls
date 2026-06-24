public class AgreementPaymentReminderScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        
        List<Booking__c> bookingsToProcess = [
            SELECT Id, Booking_Approval_Time__c, Total_received_Amount__c,Unit_No__c,OwnerId,Finance_Lead__c,CRM_Executive__r.Email,Agreement_Execution_Amount1__c, Email__c, Plot__r.Name, Project1__r.Name
            ,First_Applicant_Name__c,Owner_Full_Name__c,CRM_Head__r.Email,Sales_Head__r.Email,COO__r.Email FROM Booking__c
            WHERE Booking_Approval_Time__c != NULL AND Disable_Automatic_Payment_Reminders__c != true AND Stage__c NOT IN ('Unit Swap', 'Cancellation')
        ];
        
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        list<Booking__c> cancelBookings = new list<Booking__c>();
        for (Booking__c booking : bookingsToProcess) {
            
            if (booking.Agreement_Execution_Amount1__c > booking.Total_received_Amount__c) {
                
                Decimal balanceAmount = booking.Agreement_Execution_Amount1__c - booking.Total_received_Amount__c;
                
                Integer daysPast = System.today().daysBetween(booking.Booking_Approval_Time__c.date());
                
                if (daysPast == 15) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { booking.Email__c });
                    email.setSubject('Payment Reminder for Plot/Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name);
                    email.setPlainTextBody(
                        'Dear Sir/Madam,\n\n' +
                        'Greetings from Zuari.\n\n' +
                        'This is a gentle reminder that the payment of Rs. ' + balanceAmount + ' towards Plot/Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name + 
                        ' was due as per the Final Demand Letter previously sent to you.\n\n' +
                        'We kindly request you to treat this reminder as a priority and make the payment at the earliest along with interest thereon.\n\n' +
                        'Should you require any clarification or assistance, please feel free to contact us. We’ll be happy to help.\n\n' +
                        'Thank you for your prompt attention to this matter.\n\n' +
                        'Warm regards,\n' +
                        'Zuari Infraworld India Ltd.'
                    );
                    emailMessages.add(email);
                }
                
                if (daysPast == 25) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { booking.Email__c });
                    email.setSubject('Second Reminder: Overdue Payment for Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name);
                    email.setPlainTextBody(
                        'Dear Sir/Madam,\n\n' +
                        'Greetings from Zuari.\n\n' +
                        'This is in reference to our earlier communication dated ' + booking.Booking_Approval_Time__c.format() + ', where we reminded you about the outstanding payment of Rs. ' + balanceAmount + 
                        ' towards Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name + '.\n\n' +
                        'To date, we have neither received the payment nor any communication explaining the reason for the delay. Please note that the amount is now seriously overdue.\n\n' +
                        'As the payment deadline has passed, we request you to either settle the outstanding amount or contact us to discuss the matter within the next 7 days.\n\n' +
                        'Kindly be advised that failure to make the payment or respond within this period may lead to the cancellation of your booking as per the applicable terms.\n\n' +
                        'We look forward to hearing from you within the next 7 days.\n\n' +
                        'Warm regards,\n' +
                        'Zuari Infraworld India Ltd.'
                    );
                    emailMessages.add(email);
                }
                
                if (daysPast == 35) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { booking.Email__c });
                    email.setSubject('Final Reminder: Immediate Action Required – Overdue Payment for Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name);
                    email.setPlainTextBody(
                        'Dear Sir/Madam,\n\n' +
                        'Greetings from Zuari.\n\n' +
                        'This is to formally inform you that, despite multiple reminders—including our last communication dated ' + booking.Booking_Approval_Time__c.format() + ' — the payment of Rs. ' + balanceAmount + 
                        ' towards Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name + ' remains unpaid.\n\n' +
                        'We have also attempted to reach you through phone calls, messages, and emails, but have not received any confirmation or commitment regarding the clearance of the outstanding amount. We would greatly appreciate a prompt update on the current status of your payment.\n\n' +
                        'As previously communicated, delayed payments are subject to interest on the outstanding amount. Continued non-response will leave us with no choice but to escalate this matter to higher authorities for appropriate action.\n\n' +
                        'Please note, this is our final reminder, and the payment is now critically overdue.\n\n' +
                        'We urge you to take immediate action by either:\n' +
                        '• Clearing the outstanding dues, or\n' +
                        '• Getting in touch with us within the next 7 days to discuss your situation.\n\n' +
                        'Failure to do so will result in further steps being taken, which may include:\n' +
                        '• Cancellation of your booking, and/or\n' +
                        '• Forfeiture of any amounts already paid, as per the terms and conditions of your agreement.\n\n' +
                        'We sincerely hope this matter can be resolved amicably, and we request your urgent attention and cooperation.\n\n' +
                        'Thank you.\n\n' +
                        'Warm regards,\n' +
                        'Zuari Infraworld India Ltd.'
                    );
                    emailMessages.add(email);
                }
                
                // termination email
                if (daysPast == 45) {
                    Messaging.SingleEmailMessage terminationEmail = new Messaging.SingleEmailMessage();
                    terminationEmail.setToAddresses(new String[] { booking.Email__c });
                    terminationEmail.setSubject('Termination Notice: Payment Not Received for Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name);
                    terminationEmail.setPlainTextBody(
                        'Dear Sir/Madam,\n\n' +
                        'Greetings from Zuari.\n\n' +
                        'Unfortunately, due to non-payment, we are terminating your booking for Unit No. ' + booking.Plot__r.Name + ' at Zuari ' + booking.Project1__r.Name + '.\n\n' +
                        'Your booking details are as follows:\n' +
                        'Booking ID: ' + booking.Id + '\n' +
                        'Booking Approval Time: ' + booking.Booking_Approval_Time__c.format() + '\n' +
                        'Total Agreement Amount: ' + booking.Agreement_Execution_Amount1__c + '\n' +
                        'Amount Paid: ' + booking.Total_received_Amount__c + '\n' +
                        'Remaining Balance: ' + balanceAmount + '\n\n' +
                        'We regret that we were unable to complete the service. Please contact us for further assistance.\n\n' +
                        'Warm regards,\n' +
                        'Zuari Infraworld India Ltd.'
                    );
                    emailMessages.add(terminationEmail);
                    
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
                    emailMessages.add(mailcfo);
                    
                }
                
                if (daysPast == 49) {
                    cancelBookings.add(booking);
                }
            }
        }
        
        // Step 7: Send all emails at once
        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }
        if(!cancelBookings.isEmpty()){
            BookingController.changeUnitStatus(cancelBookings);
        }
    }
}