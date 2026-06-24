public class ReceiptTriggerHandler {
    
    public static void processApprovedReceipts(List<Receipt__c> newReceipts) {
        List<Id> approvedReceiptIds = new List<Id>();
        
        for (Receipt__c newReceipt : newReceipts) {
            if (newReceipt.Approval_Status__c == 'Approved') {
                approvedReceiptIds.add(newReceipt.Id);
            }
        }
        
        if (!approvedReceiptIds.isEmpty()) {
            List<Receipt_Line_Item__c> lineItems = [
                SELECT Id, Additional_Charges__c, Amount__c
                FROM Receipt_Line_Item__c
                WHERE Receipt__c IN :approvedReceiptIds
                AND Payment_Type__c = 'Additional Charges'
                AND Additional_Charges__c != null
            ];
            
            Map<Id, Decimal> additionalChargesSumMap = new Map<Id, Decimal>();
            for (Receipt_Line_Item__c item : lineItems) {
                if (!additionalChargesSumMap.containsKey(item.Additional_Charges__c)) {
                    additionalChargesSumMap.put(item.Additional_Charges__c, 0);
                }
                additionalChargesSumMap.put(
                    item.Additional_Charges__c, 
                    additionalChargesSumMap.get(item.Additional_Charges__c) + item.Amount__c
                );
            }
            
            // FIX: Query all Additional Charges at once
            Map<Id, Additional_Charges__c> existingChargesMap = new Map<Id, Additional_Charges__c>([
                SELECT Id, Total_Received_Amount__c
                FROM Additional_Charges__c
                WHERE Id IN :additionalChargesSumMap.keySet()
            ]);
            
            List<Additional_Charges__c> additionalChargesToUpdate = new List<Additional_Charges__c>();
            
            for (Id additionalChargeId : additionalChargesSumMap.keySet()) {
                Additional_Charges__c existingCharge = existingChargesMap.get(additionalChargeId);
                
                Decimal newTotalAmount = (existingCharge.Total_Received_Amount__c != null 
                    ? existingCharge.Total_Received_Amount__c 
                    : 0) + additionalChargesSumMap.get(additionalChargeId);
                
                additionalChargesToUpdate.add(new Additional_Charges__c(
                    Id = additionalChargeId,
                    Total_Received_Amount__c = newTotalAmount
                ));
            }
            
            if (!additionalChargesToUpdate.isEmpty()) {
                try {
                    update additionalChargesToUpdate;
                } catch (DmlException e) {
                    System.debug('Error updating Additional Charges: ' + e.getMessage());
                }
            }
        }
    }
    
    public static void sendNotificationsFromReceipts(String title, List<Receipt__c> receipts) {
        
        for (Receipt__c rcp : receipts) {
            String body = '';
            Set<String> userIds = new Set<String>();
            userIds.add(rcp.CreatedById);
            if(title == 'Receipt Approved'){
                body = 'This is to notify that Booking ' + rcp.Booking_ID__c + 
                    ', The Receipt ' + rcp.Name + ' is Approved by the Finance Team';
            }
            if(title == 'Receipt Rejected'){
                body = 'This is to notify that Booking ' + rcp.Booking_ID__c + 
                    ', The Receipt ' + rcp.Name + ' is Rejected by the Finance Team';
            }
            sendCustomNotification(userIds, title, body, rcp.Id, 'Receipt_Notification');
        }
    }
    
    public static void sendCustomNotification(Set<String> recepientIds, String title, String body, Id recId, String notificationName){
        CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
        Notification.setNotificationTypeId(closedWonNotification.id); 
        Notification.setSenderId(Userinfo.getUserId()); 
        Notification.setBody(body); 
        Notification.setTitle(title); 
        Notification.setTargetId(recId);
        try{
            Notification.send(recepientIds);
        }catch(exception e){
            System.debug('Error sending notification: ' + e.getMessage());
        }
    }
    
    public static void sendNotificationAndEmail(String title, List<Receipt__c> recList) {

        if (recList.isEmpty()) return;

        // Query Sales user (adjust filter if needed: Role, Alias, etc.)
        List<User> salesUsers = [
            SELECT Id, Email
            FROM User
            WHERE Profile.Name = 'Sales'
            LIMIT 1
        ];
        User salesUser = salesUsers.isEmpty() ? null : salesUsers[0];

        // Query CFO
        List<User> cfoUsers = [
            SELECT Id, Email
            FROM User
            WHERE Profile.Name = 'CFO'
            LIMIT 1
        ];
        User cfo = cfoUsers.isEmpty() ? null : cfoUsers[0];

        // Collect Booking Ids
        Set<Id> bookingIds = new Set<Id>();
        for (Receipt__c rcp : recList) {
            if (rcp.Booking__c != null) {
                bookingIds.add(rcp.Booking__c);
            }
        }

        // Query Booking with Owner & Owner Email & Customer Email
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>(
            [SELECT Id,
                    Name,
                    OwnerId,
                    Owner.Email,
                    Owner.Name,
                    Email__c,
                    First_Applicant_Name__c
             FROM Booking__c
             WHERE Id IN :bookingIds]
        );

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        for (Receipt__c rcp : recList) {

            String body = '';
            Set<String> userIds = new Set<String>();

            Booking__c booking = bookingMap.get(rcp.Booking__c);

            // -------------------------------
            // Notification Receiver = Booking Owner
            // -------------------------------
            if (booking != null && booking.OwnerId != null) {
                userIds.add(booking.OwnerId);
            }

            // -------------------------------
            // Build Body Message
            // -------------------------------
            if (title == 'Receipt Approved') {
                body = 'This is to notify that Booking ' + rcp.Booking_ID__c +
                       ', The Receipt ' + rcp.Name + ' is Approved by the Finance Team';
            } else if (title == 'Receipt Rejected') {
                body = 'This is to notify that Booking ' + rcp.Booking_ID__c +
                       ', The Receipt ' + rcp.Name + ' is Rejected by the Finance Team';
            }

            // -------------------------------
            // SEND CUSTOM NOTIFICATION
            // -------------------------------
            sendCustomNotification(
                userIds,
                title,
                body,
                rcp.Id,
                'Receipt_Notification'
            );

            // -------------------------------
            // SEND EMAIL TO BOOKING OWNER, CUSTOMER & SALES USER
            // -------------------------------
            if (booking != null) {
                List<String> toAddresses = new List<String>();

                if (booking.Owner != null && booking.Owner.Email != null) {
                    toAddresses.add(booking.Owner.Email);
                }
                if (booking.Email__c != null) {
                    toAddresses.add(booking.Email__c);
                }
                if (salesUser != null && salesUser.Email != null) {
                    toAddresses.add(salesUser.Email);
                }

                if (!toAddresses.isEmpty()) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(toAddresses);
                    mail.setSubject(title + ' - ' + rcp.Name);

                    // -------------------------------
                    // Enhanced Email Body
                    // -------------------------------
                    String emailBody = buildEmailBody(title, rcp, booking);
                    mail.setHtmlBody(emailBody);

                    // -------------------------------
                    // Attach PDF for Approved Receipts
                    // -------------------------------
                   
                    emailList.add(mail);
                }
            }
        }

        // -------------------------------
        // Send Emails (after loop)
        // -------------------------------
        if (!emailList.isEmpty()) {
            /*try {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);

                for (Messaging.SendEmailResult res : results) {
                    System.debug('=== EMAIL STATUS ===');
                    System.debug('Success?  → ' + res.isSuccess());

                    if (!res.isSuccess()) {
                        for (Messaging.SendEmailError err : res.getErrors()) {
                            System.debug('Error Code → ' + err.getStatusCode());
                            System.debug('Error Msg  → ' + err.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error sending emails: ' + e.getMessage());
            }*/
        }
    }

    // -------------------------------
    // Helper Method: Build Professional Email Body
    // -------------------------------
    private static String buildEmailBody(String title, Receipt__c receipt, Booking__c booking) {
        String status = receipt.Approval_status__c;
        String statusColor = (title == 'Receipt Approved') ? '#28a745' : '#dc3545';
        
        String htmlBody = '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
        htmlBody += '<div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">';
        
        // Header
        htmlBody += '<h2 style="color: ' + statusColor + '; border-bottom: 2px solid ' + statusColor + '; padding-bottom: 10px;">';
        htmlBody += title + '</h2>';
        
        // Greeting
        htmlBody += '<p>Dear ' + (booking.First_Applicant_Name__c != null ? booking.First_Applicant_Name__c : 'Team Member') + ',</p>';
        
        // Main message
        if (title == 'Receipt Approved') {
            htmlBody += '<p>We are pleased to inform you that the receipt for your booking has been <strong style="color: #28a745;">approved</strong> by our Finance Team.</p>';
        } else {
            htmlBody += '<p>This is to inform you that the receipt for your booking has been <strong style="color: #dc3545;">rejected</strong> by our Finance Team.</p>';
        }
        
        // Details table
        htmlBody += '<table style="width: 100%; margin: 20px 0; border-collapse: collapse;">';
        htmlBody += '<tr style="background-color: #f8f9fa;">';
        htmlBody += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Receipt Number:</td>';
        htmlBody += '<td style="padding: 10px; border: 1px solid #ddd;">' + receipt.Name + '</td>';
        htmlBody += '</tr>';
        htmlBody += '<tr>';
        htmlBody += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Booking Reference:</td>';
        htmlBody += '<td style="padding: 10px; border: 1px solid #ddd;">' + booking.Name + '</td>';
        htmlBody += '</tr>';
        htmlBody += '<tr style="background-color: #f8f9fa;">';
        htmlBody += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Status:</td>';
        htmlBody += '<td style="padding: 10px; border: 1px solid #ddd; color: ' + statusColor + '; font-weight: bold;">' + status + '</td>';
        htmlBody += '</tr>';
        htmlBody += '</table>';
        
        // Additional message for approved receipts
        if (title == 'Receipt Approved') {
            htmlBody += '<p>Please find the approved receipt attached to this email for your records.</p>';
        } else {
            htmlBody += '<p>If you have any questions regarding this rejection, please contact our Finance Team.</p>';
        }
        
        // Closing
        htmlBody += '<p style="margin-top: 30px;">Best regards,<br/>';
        htmlBody += '<strong>CRM Finance Team</strong></p>';
        
        // Footer
        htmlBody += '<div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #777;">';
        htmlBody += '<p>This is an automated notification. Please do not reply to this email.</p>';
        htmlBody += '</div>';
        
        htmlBody += '</div></body></html>';
        
        return htmlBody;
    }
}