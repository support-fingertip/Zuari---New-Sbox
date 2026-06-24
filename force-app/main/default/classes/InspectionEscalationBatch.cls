/**
 * Batch class to send escalation emails for inspections
 * where Escalation Date is today or has passed
 */
public class InspectionEscalationBatch implements Database.Batchable<sObject> {
    
    // Start method - Query inspections with escalation date <= today
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Date today = Date.today();
        
        return Database.getQueryLocator([
            SELECT Id, 
                   Name, 
                   Escalation_Date__c,
                   Inspection_Date__c,
                   Expected_Completed_Date__c,
                   Extended_Completed_Date__c,
                   Description__c,
                   Status__c,
                   Approval_Status__c,
                   Owner.Name,
                   Owner.Email,
                   Booking__c,
                   Booking__r.Name,
                   Booking__r.Owner.Name,
                   Booking__r.Owner.Email,
                   Booking__r.CRM_Head__c,
                   Booking__r.CRM_Head__r.Email,
                   Customer_Email__c
            FROM Inspection__c
            WHERE Escalation_Date__c <= :today
            AND Approval_Status__c = 'Approved'
        ]);
    }
    
    // Execute method - Process records and send emails
    public void execute(Database.BatchableContext BC, List<Inspection__c> scope) {
        
        // Get CFO user
        List<User> cfoUsers = [
            SELECT Id, Email, Name 
            FROM User 
            WHERE Profile.Name = 'CFO' 
            AND IsActive = true 
            LIMIT 1
        ];
        
        if (cfoUsers.isEmpty()) {
            System.debug('No active CFO user found');
            return;
        }
        
        User cfoUser = cfoUsers[0];
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        // Process each inspection
        for (Inspection__c inspection : scope) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Set TO address - CFO
            email.setToAddresses(new String[] { cfoUser.Email });
            
            // Build CC list
            List<String> ccAddresses = new List<String>();
            
            // Add Inspection Owner to CC
            if (String.isNotBlank(inspection.Owner.Email)) {
                ccAddresses.add(inspection.Owner.Email);
            }
            
            // Add Booking Owner to CC
            if (inspection.Booking__c != null && 
                String.isNotBlank(inspection.Booking__r.Owner.Email)) {
                ccAddresses.add(inspection.Booking__r.Owner.Email);
            }
            
            // Add CRM Head to CC
            if (inspection.Booking__c != null && 
                inspection.Booking__r.CRM_Head__c != null &&
                String.isNotBlank(inspection.Booking__r.CRM_Head__r.Email)) {
                ccAddresses.add(inspection.Booking__r.CRM_Head__r.Email);
            }
            
            if (!ccAddresses.isEmpty()) {
                email.setCcAddresses(ccAddresses);
            }
            
            // Set email subject
            email.setSubject('Inspection Escalation Alert - ' + inspection.Name);
            
            // Build email body
            String emailBody = buildEmailBody(inspection);
            email.setHtmlBody(emailBody);
            
            // Set reply-to as owner email
            if (String.isNotBlank(inspection.Owner.Email)) {
                email.setReplyTo(inspection.Owner.Email);
            }
            
            emailsToSend.add(email);
        }
        
        // Send all emails
        if (!emailsToSend.isEmpty()) {
            try {
                Messaging.sendEmail(emailsToSend);
                System.debug('Successfully sent ' + emailsToSend.size() + ' escalation emails');
            } catch (Exception e) {
                System.debug('Error sending emails: ' + e.getMessage());
            }
        }
    }
    
    // Finish method
    public void finish(Database.BatchableContext BC) {
        System.debug('Inspection Escalation Batch completed');
    }
    
    // Helper method to build email body
    private String buildEmailBody(Inspection__c inspection) {
        String body = '<html><body style="font-family: Arial, sans-serif;">';
        body += '<h2 style="color: #d9534f;">Inspection Escalation Alert</h2>';
        body += '<p>Dear CFO,</p>';
        body += '<p>This is an escalation notification for the following inspection that requires your attention:</p>';
        
        body += '<table style="border-collapse: collapse; width: 100%; margin: 20px 0;">';
        body += '<tr style="background-color: #f5f5f5;">';
        body += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Inspection Name:</td>';
        body += '<td style="padding: 10px; border: 1px solid #ddd;">' + inspection.Name + '</td>';
        body += '</tr>';
        
        if (inspection.Booking__c != null) {
            body += '<tr>';
            body += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Booking:</td>';
            body += '<td style="padding: 10px; border: 1px solid #ddd;">' + inspection.Booking__r.Name + '</td>';
            body += '</tr>';
        }
        
        body += '<tr style="background-color: #f5f5f5;">';
        body += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Owner:</td>';
        body += '<td style="padding: 10px; border: 1px solid #ddd;">' + inspection.Owner.Name + '</td>';
        body += '</tr>';
        
        body += '<tr>';
        body += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Escalation Date:</td>';
        body += '<td style="padding: 10px; border: 1px solid #ddd; color: #d9534f; font-weight: bold;">' 
                + inspection.Escalation_Date__c.format() + '</td>';
        body += '</tr>';
        
        if (inspection.Inspection_Date__c != null) {
            body += '<tr style="background-color: #f5f5f5;">';
            body += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Inspection Date:</td>';
            body += '<td style="padding: 10px; border: 1px solid #ddd;">' + inspection.Inspection_Date__c.format() + '</td>';
            body += '</tr>';
        }
        
        if (inspection.Expected_Completed_Date__c != null) {
            body += '<tr>';
            body += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Expected Completed Date:</td>';
            body += '<td style="padding: 10px; border: 1px solid #ddd;">' + inspection.Expected_Completed_Date__c.format() + '</td>';
            body += '</tr>';
        }
        
        if (String.isNotBlank(inspection.Status__c)) {
            body += '<tr style="background-color: #f5f5f5;">';
            body += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Status:</td>';
            body += '<td style="padding: 10px; border: 1px solid #ddd;">' + inspection.Status__c + '</td>';
            body += '</tr>';
        }
        
        if (String.isNotBlank(inspection.Description__c)) {
            body += '<tr>';
            body += '<td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Description:</td>';
            body += '<td style="padding: 10px; border: 1px solid #ddd;">' + inspection.Description__c + '</td>';
            body += '</tr>';
        }
        
        body += '</table>';
        
        body += '<p style="margin-top: 20px;">Please review this inspection at your earliest convenience.</p>';
        body += '<p>Best regards,<br/>Inspection Management System</p>';
        body += '</body></html>';
        
        return body;
    }
}