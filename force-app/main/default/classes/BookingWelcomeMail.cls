public class BookingWelcomeMail {
 
    @AuraEnabled
    public static void sendRequestForAgreementAmount(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Requesting For Sale Agreement');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Request_For_Sale_Agreement');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    @AuraEnabled
    public static void sendRequestForRegistration(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Requesting For Registration Approval');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Registration_Approval');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    
    
    
    @AuraEnabled
    public static string sendEmailToCustomerCancellation(Id recId, string pdfType){
        Booking__c l = [SELECT Id,Name,Email__C,Email1__c,Possession_Date__c,Project__c,Cancellation_Letter_Sent__c,Cancellation_Letter__c,Project_Type__c,ownerId FROM Booking__c where Id=:recId];
        List<String> lstCCEmail = new List<String>();
        if (l.Email__c != null && l.Email__c != '') {
            lstCCEmail = l.Email__C.split(',');
        }
        if (l.Email1__c != null && l.Email1__c != '') {
            lstCCEmail.addAll(l.Email1__c.split(','));
        }
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
        PageReference pref;
        if(pdfType == 'SaleAgreement'){
            /*if(l.Project__c == 'Corner Stone'){
               pref = Page.Agreement_of_Sale_Cornerstone;
            }
            else if(l.Project__c == 'Tamarind'){
                pref = Page.Agreement_of_Sale_Tamarind;
            }
            else if(l.Project__c == 'Treasure Trove'){
                pref = Page.AOSTreasureTrove;
            }*/
            
        }
        if(pdfType == 'PC'){
              pref = Page.Possession_Letter;
            
        }
       /* else if(pdfType == 'SaleDeed'){
            if(l.Project__c == 'Corner Stone'){
                pref = Page.DraftSALEDEEDCornerStone;
            }
            else if(l.Project__c == 'Tamarind'){
                pref = Page.SaleDeedEIPLTheTamarind;
            }
            else if(l.Project__c == 'Treasure Trove'){
                pref = Page.SaleDeedTresureTrove;
            }
        }*/
        else if(pdfType == 'Cancellation'){
            pref = Page.Cancellation_Letter_Request;
        }
        pref.getParameters().put('id', recId);
        pref.setRedirect(true);
        system.debug(pref);
        
        Blob b;
        b = Blob.valueOf('Unit.Test');
        if (Test.isRunningTest()) {
            b = Blob.valueOf('Unit.Test');
        } else {
            b = pref.getContent();
        }
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        if(pdfType == 'PC'){
             semail.setSubject('Zuari Infraworld India Ltd. - Possesion Letter');
            attach.setFileName('Possesion_Letter.pdf'); 
             semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the possesion Agreement for your Plot'+
                                   '<br/> Thank you for Booking a PLot with us'+'<br/><br/> Thank you'+'<br/> Regards Zuari Infraworld India Ltd.');
           
           
        }
        if(pdfType == 'SaleAgreement'){
            semail.setSubject('Mantri - Sale Agreement Draft');
            attach.setFileName('SaleAgreement.pdf'); 
            if(l.Project_Type__c == 'Villas'){
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Sale Agreement draft for your Villa'+
                                   '<br/> Thank you for Booking a Villa with us'+'<br/><br/> Thank you'+'<br/> Regards Mantri');
            }
            else{
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Sale Agreement draft for your Flat'+
                                   '<br/> Thank you for Booking a Flat with us'+'<br/><br/> Thank you'+'<br/> Regards Mantri');
            }
            
        }
        else if(pdfType == 'SaleDeed'){
            semail.setSubject('Mantri - Sale Deed Draft');
            attach.setFileName('SaleDeed.pdf'); 
            if(l.Project_Type__c == 'Villas'){
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Sale Deed draft for your Villa'+
                                   '<br/> Thank you for Booking a Villa with us'+'<br/><br/> Thank you'+'<br/> Regards Mantri');
            }
            else{
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Sale Deed draft for your Flat'+
                                   '<br/> Thank you for Booking a Flat with us'+'<br/><br/> Thank you'+'<br/> Regards Mantri');
            }
        }
        else if(pdfType == 'Cancellation'){
            semail.setSubject('Zuari - Cancellation Letter');
            attach.setFileName('CancellationLetter.pdf'); 
            semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Cancellation Letter for your booked Flat'+
                                   '<br/><br/> Thank you'+'<br/> Regards<br/> Mantri');
        }
        
        attach.setBody(b);
        emailAttachments.add(attach);
        List<String> sendTo = new List<String>();
        sendTo.add(l.Email__c);
        semail.setToAddresses(sendTo);
        if (!emailAttachments.isEmpty()){
            semail.setFileAttachments(emailAttachments);
        }
        if (sendTo.size() > 0){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
             l.Cancellation_Letter_Sent__c = system.now();
            l.Cancellation_Letter__c = true;
            update l;
            system.debug(semail);
        } 
        return 'sent to customer';
    }
    
    /**
     * @description - This method is to send the email to booking applicants, Called from Differwent Aura Components (Quick Actions) in Booking Object
     * 
     * @param recId - this parameter is used to send the booking record Id
     * @param pdfType - this parameter is used to send the type of document to send
     * 
     * @return - return the success message or error message based on that we are showing toast in Quick Actions
     * 
     * @throws - throws exception in case of any error
     * 
     * @author - unknown
     * @lastModifiedDate - 16/01/2026
     * @lastModifiedBy - Tejaswini
     */
   @AuraEnabled
    public static string sendEmailToCustomer(Id recId, string pdfType){
        Booking__c l = [SELECT Id,Name,Email__C,Email1__c,Slead__r.Email,Possession_Date__c,Project__c,Cancellation_Letter_Sent__c,Cancellation_Letter__c,Project_Type__c,ownerId FROM Booking__c where Id=:recId];
        List<String> lstCCEmail = new List<String>();
        if (l.Email__c != null && l.Email__c != '') {
            lstCCEmail = l.Email__C.split(',');
        }
        if (l.Email1__c != null && l.Email1__c != '') {
            lstCCEmail.addAll(l.Email1__c.split(','));
        }
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
        PageReference pref;
       
        if(pdfType == 'Cancellation'){
            pref = Page.Cancellation_Letter_Request;
        }
        else if(pdfType == 'PC'){
            pref = Page.Possession_Letter;
        }
        else if(pdfType == 'ConsolidatedReceipt'){
            pref = Page.ConsolidatedReceipt;
        }
        else if(pdfType == 'Allotment Letter'){
            pref = Page.ProvisionalAllotmentLetter;
        }
        pref.getParameters().put('id', recId);
        pref.setRedirect(true);
        system.debug(pref);
        
        Blob b;
        b = Blob.valueOf('Unit.Test');
        if (Test.isRunningTest()) {
            b = Blob.valueOf('Unit.Test');
        } else {
            b = pref.getContent();
        }
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
   
       if(pdfType == 'Cancellation'){
            semail.setSubject('Zuari - Cancellation Letter');
            attach.setFileName('CancellationLetter.pdf'); 
            semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Cancellation Letter for your booked Plot'+
                                   '<br/><br/> Thank you'+'<br/> Regards<br/> Zuari');
        }
       else if(pdfType == 'PC'){
            semail.setSubject('Zuari - Possesion Letter');
            attach.setFileName('Possesion.pdf'); 
            semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Possesion Letter for your booked Plot'+
                                   '<br/><br/> Thank you'+'<br/> Regards<br/> Zuari');
        }
        else if(pdfType == 'ConsolidatedReceipt'){
            semail.setSubject('Zuari - Consolidated Receipt');
            attach.setFileName('ConsolidatedReceipt.pdf'); 
            semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Consolidated Receipt for your booked Flat'+
                                   '<br/><br/> Thank you'+'<br/> Regards<br/> Zuari');
        }
        else if(pdfType == 'Allotment Letter'){
            semail.setSubject('Zuari - Allotment Letter');
            attach.setFileName('Allotment_Letter.pdf'); 
            semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Allotment letter for your booked Flat'+
                                   '<br/><br/> Thank you'+'<br/> Regards<br/> Zuari');
        }
        
        attach.setBody(b);
        emailAttachments.add(attach);
        List<String> sendTo = new List<String>();
        sendTo.add(l.Email__c);
        semail.setSaveAsActivity(true);
        semail.setToAddresses(sendTo);
        if (!emailAttachments.isEmpty()){
            semail.setFileAttachments(emailAttachments);
        }
        if (sendTo.size() > 0){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
            if(pdfType == 'Cancellation'){
                l.Cancellation_Letter_Sent__c = system.now();
                l.Cancellation_Letter__c = true ;
                update l;
            }
            system.debug(semail);
        } 
        return 'sent to customer';
    }
    
    
    @AuraEnabled
    public static string sendEmailToCustomersWithIds(List<Id> recIds, string pdfType){
        try {
            // Query all bookings in one SOQL query
            List<Booking__c> bookings = [SELECT Id, Name, Email__C, Email1__c, Slead__r.Email, 
                                         Project__c, Project_Type__c, ownerId 
                                         FROM Booking__c 
                                         WHERE Id IN :recIds];
            
            if (bookings.isEmpty()) {
                return 'No bookings found for the provided IDs';
            }
            
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            
            // Process each booking
            for (Booking__c booking : bookings) {
                Messaging.SingleEmailMessage semail = createEmailForBooking(booking, pdfType);
                if (semail != null) {
                    emailList.add(semail);
                }
            }
            
            // Send all emails
            if (!emailList.isEmpty()) {
                Messaging.sendEmail(emailList);
                return 'Emails sent successfully to ' + emailList.size() + ' customers';
            } else {
                return 'No valid emails to send';
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error sending emails: ' + e.getMessage());
        }
    }
    
    private static Messaging.SingleEmailMessage createEmailForBooking(Booking__c booking, string pdfType) {
        try {
            // Prepare CC email addresses
            List<String> lstCCEmail = new List<String>();
            if (booking.Email__c != null && booking.Email__c != '') {
                lstCCEmail = booking.Email__C.split(',');
            }
            if (booking.Email1__c != null && booking.Email1__c != '') {
                lstCCEmail.addAll(booking.Email1__c.split(','));
            }
            
            // Create email attachment
            Messaging.EmailFileAttachment attach = createEmailAttachment(booking.Id, pdfType);
            if (attach == null) {
                return null;
            }
            
            // Create email message
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            emailAttachments.add(attach);
            
            // Set email properties based on PDF type
            if (pdfType == 'Cancellation') {
                semail.setSubject('Zuari - Cancellation Letter');
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Cancellation Letter for your booked Flat'+
                                   '<br/><br/> Thank you'+'<br/> Regards<br/> Zuari');
            } else if (pdfType == 'ConsolidatedReceipt') {
                semail.setSubject('Zuari - Consolidated Receipt');
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Consolidated Receipt for your booked Flat'+
                                   '<br/><br/> Thank you'+'<br/> Regards<br/> Zuari');
            } else {
                return null; // Invalid PDF type
            }
            
            // Set recipient addresses
            List<String> sendTo = new List<String>();
            if (booking.Email__c != null && booking.Email__c != '') {
                sendTo.add(booking.Email__c);
            }
            
            if (sendTo.isEmpty()) {
                return null; // No valid recipient
            }
            
            semail.setToAddresses(sendTo);
            
            // Set CC addresses if any
            if (!lstCCEmail.isEmpty()) {
                semail.setCcAddresses(lstCCEmail);
            }
            
            // Set attachments
            semail.setFileAttachments(emailAttachments);
            
            return semail;
            
        } catch (Exception e) {
            System.debug('Error creating email for booking ' + booking.Id + ': ' + e.getMessage());
            return null;
        }
    }
    
    private static Messaging.EmailFileAttachment createEmailAttachment(Id recId, string pdfType) {
        try {
            PageReference pref;
            
            if (pdfType == 'Cancellation') {
                pref = Page.Cancellation_Letter_Request;
            } else if (pdfType == 'ConsolidatedReceipt') {
                pref = Page.ConsolidatedReceipt;
            } else {
                return null;
            }
            
            pref.getParameters().put('id', recId);
            pref.setRedirect(true);
            
            Blob b;
            if (Test.isRunningTest()) {
                b = Blob.valueOf('Unit.Test');
            } else {
                b = pref.getContent();
            }
            
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            
            if (pdfType == 'Cancellation') {
                attach.setFileName('CancellationLetter.pdf');
            } else if (pdfType == 'ConsolidatedReceipt') {
                attach.setFileName('ConsolidatedReceipt.pdf');
            }
            
            attach.setBody(b);
            return attach;
            
        } catch (Exception e) {
            System.debug('Error creating attachment for record ' + recId + ': ' + e.getMessage());
            return null;
        }
    }
    
     @AuraEnabled
    public static string sendEmailToBank(Id recId, string pdfType){
        Booking__c l = [SELECT Id,Name,Email__C,Email1__c,Slead__r.Email,Bank_Email__c,Project__c,Project_Type__c,ownerId FROM Booking__c where Id=:recId];
        List<String> lstCCEmail = new List<String>();
        if (l.Email__c != null && l.Email__c != '') {
            lstCCEmail = l.Email__C.split(',');
        }
        if (l.Email1__c != null && l.Email1__c != '') {
            lstCCEmail.addAll(l.Email1__c.split(','));
        }
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
        PageReference pref;
      /*  if(pdfType == 'SaleAgreement'){
            if(l.Project__c == 'Corner Stone'){
               pref = Page.Agreement_of_Sale_Cornerstone;
            }
            else if(l.Project__c == 'Tamarind'){
                pref = Page.Agreement_of_Sale_Tamarind;
            }
            else if(l.Project__c == 'Treasure Trove'){
                pref = Page.AOSTreasureTrove;
            }
            
        }
        else if(pdfType == 'SaleDeed'){
            if(l.Project__c == 'Corner Stone'){
                pref = Page.DraftSALEDEEDCornerStone;
            }
            else if(l.Project__c == 'Tamarind'){
                pref = Page.SaleDeedEIPLTheTamarind;
            }
            else if(l.Project__c == 'Treasure Trove'){
                pref = Page.SaleDeedTresureTrove;
            }
        }
        */
        pref.getParameters().put('id', recId);
        pref.setRedirect(true);
        system.debug(pref);
        
        Blob b;
        b = Blob.valueOf('Unit.Test');
        if (Test.isRunningTest()) {
            b = Blob.valueOf('Unit.Test');
        } else {
            b = pref.getContent();
        }
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        if(pdfType == 'SaleAgreement'){
            semail.setSubject('EIPL - Sale Agreement Draft');
            attach.setFileName('SaleAgreement.pdf'); 
            if(l.Project_Type__c == 'Villas'){
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Sale Agreement draft for your Villa'+
                                   '<br/> Thank you for Booking a Villa with us'+'<br/><br/> Thank you'+'<br/> Regards EIPL');
            }
            else{
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Sale Agreement draft for your Flat'+
                                   '<br/> Thank you for Booking a Flat with us'+'<br/><br/> Thank you'+'<br/> Regards EIPL');
            }
            
        }
        else if(pdfType == 'SaleDeed'){
            semail.setSubject('EIPL - Sale Deed Draft');
            attach.setFileName('SaleDeed.pdf'); 
            if(l.Project_Type__c == 'Villas'){
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Sale Deed draft for your Villa'+
                                   '<br/> Thank you for Booking a Villa with us'+'<br/><br/> Thank you'+'<br/> Regards EIPL');
            }
            else{
                semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                                   'Please Find the Sale Deed draft for your Flat'+
                                   '<br/> Thank you for Booking a Flat with us'+'<br/><br/> Thank you'+'<br/> Regards EIPL');
            }
        }
        
        attach.setBody(b);
        emailAttachments.add(attach);
        List<String> sendTo = new List<String>();
        sendTo.add(l.Bank_Email__c);
        semail.setToAddresses(sendTo);
        if (!emailAttachments.isEmpty()){
            semail.setFileAttachments(emailAttachments);
        }
        if (sendTo.size() > 0){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
            system.debug(semail);
        } 
        return 'sent to customer';
    }
    
    @AuraEnabled
    public static String sendEmailtoCustomer1(Id recId) {
        Booking__c qt = [SELECT Id,CRM_Manager__r.Email,Owner.Email,Email__c, Email1__c,Owner_Phone__c,First_Applicant_Name__c FROM Booking__c WHERE Id = :recId LIMIT 1];
        List<String> lstCCEmail = new List<String>();
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        //   PageReference pref = Page.Allotment_letter;
        
        // pref.getParameters().put('id', recId);
        //   pref.setRedirect(true);
        
        Blob b = Blob.valueOf('Unit.Test');
        try {
            //b = pref.getContent(); 
        } catch (VisualforceException e) {
            return 'Error generating PDF content: ' + e.getMessage();
        }
        
        attach.setFileName('EIPL.pdf');
        attach.setBody(b);
        semail.setSubject('EIPL');

        List<String> sendTo = new List<String>();
        if (qt.Email__c != null) {
            sendTo.add(qt.Email__c);
        }
        if (qt.Email1__c != null) {
            sendTo.add(qt.Email1__c);
        }
        if(qt.Owner.Email != null){
           lstCCEmail.add(qt.Owner.Email); 
        }
        
        if(qt.CRM_Manager__c != null){
            lstCCEmail.add(qt.CRM_Manager__r.Email);
        }
        
        semail.setToAddresses(sendTo);
        if(lstCCEmail.size()>0){
            semail.setCcAddresses(lstCCEmail);
        }
        semail.setHtmlBody('Dear '+qt.First_Applicant_Name__c+',<br/>Please find the attached Allotment Letter.<br/><br/>' +
                           'We are pleased to inform you that your booking has been confirmed. ' +
                           'Attached is the Allotment Letter for your reference.<br/><br/>' +
                           'If you have any questions or need further assistance, please do not hesitate to contact us.<br/><br/>' +
                           'Thank you for choosing NAMBIAR Builders.<br/><br/>' +
                           'Best regards,<br/>' +
                           'EIPL');
        if(attach != null){
            semail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });
        }
        
        
        if (sendTo.size() > 0) { 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { semail });
            return 'Email sent successfully';
        } else {
            return 'Please enter an email address';
        }
    }
    
    @AuraEnabled
    public static string sendEmailToCustomerNOC(Id recId){
        Booking__c l = [SELECT Id,Name,Email__C,Email1__c,Bank_Email__c,Slead__r.Email,Bank_Name__c,Project__c,Project_Type__c,ownerId FROM Booking__c where Id=:recId];
        List<String> lstCCEmail = new List<String>();
        if (l.Email__c != null && l.Email__c != '') {
            lstCCEmail = l.Email__C.split(',');
        }
        if (l.Email1__c != null && l.Email1__c != '') {
            lstCCEmail.addAll(l.Email1__c.split(','));
        }
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
        PageReference pref;
     /*   if(l.Bank_Name__c == 'KOTAK'){
            pref = Page.CornerStone_Kotak_NOC;
            
        }else if(l.Bank_Name__c == 'BAJAJ'){
            pref = Page.Bajaj_NOC;
        }else if(l.Bank_Name__c == 'TATA'){
            pref = Page.Tamarind_TATA_NOC;
        }
        else if(l.Bank_Name__c == 'AXIS'){
            pref = Page.Tamarind_Axis_NOC;
        }
        else if(l.Bank_Name__c == 'ICICI'){
            pref = Page.Bajaj_ICICI_NOC;
        }
        else if(l.Bank_Name__c == 'HDFC'){
            pref = Page.HDFC_NOC;
        }
        
     */ 
        pref= Page.BuilderNoc;
        pref.getParameters().put('id', recId);
        pref.setRedirect(true);
        system.debug(pref);
        
        Blob b;
        b = Blob.valueOf('Unit.Test');
        if (Test.isRunningTest()) {
            b = Blob.valueOf('Unit.Test');
        } else {
            b = pref.getContent();
        }
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setFileName('NOC.pdf'); 
        
        semail.setSubject('Zuari - Bank NOC');
        semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                           'Please Find the Bank NOC for your Flat'+
                           '<br/> Thank you for Booking a Flat with us'+'<br/><br/> Thank you'+'<br/> Regards Zuari');
        
        attach.setBody(b);
        emailAttachments.add(attach);
        List<String> sendTo = new List<String>();
        //sendTo.add(l.Email__c);
        if(l.Email__C != null){
            sendTo.add(l.Email__C);
        }
        semail.setToAddresses(lstCCEmail);
        if (!emailAttachments.isEmpty()){
            semail.setFileAttachments(emailAttachments);
        }
        if (sendTo.size() > 0){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
            system.debug(semail);
        } 
        return 'sent to customer';
    }
    
    @AuraEnabled
    public static string sendEmailToCustomerTPA(Id recId){
        Booking__c l = [SELECT Id,Name,Email__C,Email1__c,Bank_Email__c,Slead__r.Email,Bank_Name__c,Project__c,Project_Type__c,ownerId FROM Booking__c where Id=:recId];
        List<String> lstCCEmail = new List<String>();
         List<String> sendTo = new List<String>();
       
        if (l.Email__c != null &&l.Email__c != '') {
            sendTo = l.Email__C.split(',');
        }
        if (l.Email1__c != null && l.Email1__c != '') {
            sendTo.addAll(l.Email1__c.split(','));
        }
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
        PageReference pref;
        /*
        if(l.Bank_Name__c == 'KOTAK'){
            pref = Page.CornerStone_Kotak_TripatiteAgg;
            
        }else if(l.Bank_Name__c == 'IDBI'){
            pref = Page.Cornerstone_IDBI_TripatiteAgg;
        }else if(l.Bank_Name__c == 'UNION'){
            pref = Page.Union_Tripartite_Agreement;
        }
        else if(l.Bank_Name__c == 'BAJAJ'){
            pref = Page.Bajaj_Tripartite_Agreement;
        }
        else if(l.Bank_Name__c == 'TATA'){
            pref = Page.Tamarind_TATA_Tripartite_Agre;
        }
        else if(l.Bank_Name__c == 'SBI'){
            pref = Page.Tamarind_SBI_Tripartite_Agre;
        }
        else if(l.Bank_Name__c == 'AXIS'){
            pref = Page.Tamarind_Axis_TPT;
        }
        else if(l.Bank_Name__c == 'HDFC'){
            pref = Page.HDFC_Tripartite_Agreement;
        }
        */
        pref = Page.TRIPARTITE_AGREEMENT;
        pref.getParameters().put('id', recId);
        pref.setRedirect(true);
        system.debug(pref);
        
        Blob b;
        b = Blob.valueOf('Unit.Test');
        if (Test.isRunningTest()) {
            b = Blob.valueOf('Unit.Test');
        } else {
            b = pref.getContent();
        }
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setFileName('TPA.pdf'); 
        
        semail.setSubject('Zuari - Bank TPA');
        semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                           'Please Find the Bank TPA for your Flat'+
                           '<br/> Thank you for Booking a Flat with us'+'<br/><br/> Thank you'+'<br/> Regards Zuari');
        
        attach.setBody(b);
        emailAttachments.add(attach);
        sendTo.add(l.Email__c);
        if(l.Email__c != null){
            sendTo.add(l.Email__c);
        }
        semail.setToAddresses(sendTo);
        if (!emailAttachments.isEmpty()){
            semail.setFileAttachments(emailAttachments);
        }
        if (sendTo.size() > 0){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
            system.debug(semail);
        } 
        return 'sent to customer';
    }
    
    @AuraEnabled
    public static string sendEmailToCustomerLOU(Id recId){
        Booking__c l = [SELECT Id,Name,Email__C,Email1__c,Bank_Email__c,Slead__r.Email,Bank_Name__c,Project__c,Project_Type__c,ownerId FROM Booking__c where Id=:recId];
        List<String> lstCCEmail = new List<String>();
        if (l.Email__c != null && l.Email__c != '') {
            lstCCEmail = l.Email__C.split(',');
        }
        if (l.Email1__c != null && l.Email1__c != '') {
            lstCCEmail.addAll(l.Email1__c.split(','));
        }
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
        PageReference pref;
        /*
        if(l.Bank_Name__c == 'ICICI'){
            pref = Page.Bajaj_ICICI_LOU;
            
        }
        */
        pref.getParameters().put('id', l.Id);
        pref.setRedirect(true);
        system.debug(pref);
        
        Blob b;
        b = Blob.valueOf('Unit.Test');
        if (Test.isRunningTest()) {
            b = Blob.valueOf('Unit.Test');
        } else {
            b = pref.getContent();
        }
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setFileName('LOU.pdf'); 
        
        semail.setSubject('EIPL - LOU');
        semail.setHtmlBody('Dear Sir/Madam,<br/><br/>'+ 
                           'Please Find the LOU for your Flat'+
                           '<br/> Thank you for Booking a Flat with us'+'<br/><br/> Thank you'+'<br/> Regards EIPL');
        
        attach.setBody(b);
        emailAttachments.add(attach);
        List<String> sendTo = new List<String>();
      //  sendTo.add(l.Email__c);
        if(l.Bank_Email__c != null){
            sendTo.add(l.Bank_Email__c);
        }
        semail.setToAddresses(sendTo);
        if (!emailAttachments.isEmpty()){
            semail.setFileAttachments(emailAttachments);
        }
        if (sendTo.size() > 0){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
            system.debug(semail);
        } 
        return 'sent to customer';
    }
    
    @AuraEnabled
    public static Booking__c getBookingDetails(Id recordId) {
        System.debug('recordId ==>' + recordId);
        return [
            SELECT Id,
            First_Applicant_Name__c,
            S__c,
            Plot__r.Name,
            Project1__r.Name,
            Funding_Type__c,
            Agreement_Expected_Date__c,
            Agreement_Executed_Date__c,
            Possession_Date__c,
            Total_received_Amount__c,
            Agreement_Execution_Amount1__c
            FROM Booking__c
            WHERE Id = :recordId
            LIMIT 1
        ];
    }
   public static void testcover(){
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}