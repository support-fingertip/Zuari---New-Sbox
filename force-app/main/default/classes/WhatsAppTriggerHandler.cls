public without sharing class WhatsAppTriggerHandler {

    public static void processNewLeads(List<Lead> leadList) {
        List<Lead> leadsToSend = new List<Lead>();
        List<Lead> leadsToUpdateOTP = new List<Lead>();
String otp;
        for (Lead l : leadList) {
            if (String.isNotBlank(l.Phone__C)) {
                leadsToSend.add(l);
                otp = GenerateOTP.generateUniqueOTP();
                 Lead updatedLead = new Lead(
                            Id = l.Id,
                            OTP__c = otp
                        );
                        update updatedLead;
             //   l.OTP__c = GenerateOTP.generateUniqueOTP();
                
                // leadsToUpdateOTP.add(l);
                
            }
        }
        
           if (!leadsToUpdateOTP.isEmpty()) {
           
            // Enqueue SMS queueables for each lead
            for (Lead l : leadsToUpdateOTP) {
                String name = ((l.FirstName != null) ? l.FirstName : '') + ' ' + ((l.LastName != null) ? l.LastName : '');
                System.enqueueJob(new SendSMSQueueable(l.Phone__c, name.trim(), otp));
            }
        }


        if (!leadsToSend.isEmpty()) {
             System.enqueueJob(new WhatsAppBulkSender(leadsToSend));
        }
    }
    public static void processSitevisit(List<Site_Visit__c> lstsv){
         for (Site_Visit__c sv : lstsv) {
             String otp = sv.OTP__c;
             String leadName= sv.Lead_Name__c;
             String phone = sv.Lead_Phone_Number__c;
              //  String name = ((l.FirstName != null) ? l.FirstName : '') + ' ' + ((l.LastName != null) ? l.LastName : '');
                System.enqueueJob(new SendSMSQueueable(phone, leadName, otp));
            }
    }
}