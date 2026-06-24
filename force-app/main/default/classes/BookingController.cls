public without sharing class BookingController {
    
    @AuraEnabled
    public static List<Map<String, String>> getCountries() {
        
        List<Schema.PicklistEntry> countryEntries =
            Schema.SObjectType.Account.fields.getMap().get('BillingCountryCode')
            .getDescribe().getPicklistValues();
        
        List<Map<String, String>> countries = new List<Map<String, String>>();
        
        for (Schema.PicklistEntry c : countryEntries) {
            countries.add(new Map<String, String>{
                'label' => c.getLabel(),   // e.g., India
                    'value' => c.getValue()    // e.g., IN
                    });
        }
        
        return countries;
    }
    
    public class PicklistInfo {
        public String validFor;
    }
    
    /* ---------------------------------------------------------
*  MAIN METHOD: RETURN ONLY STATES FOR GIVEN COUNTRY
* --------------------------------------------------------- */
    @AuraEnabled
    public static List<Map<String, String>> getStates(String countryCode) {
        
        List<Map<String, String>> response = new List<Map<String, String>>();
        
        if (String.isBlank(countryCode)) {
            return response;
        }
        
        // Get controlling → dependent mapping for BillingCountryCode → BillingStateCode
        Map<String, List<String>> dependencyMap = getFieldDependencyMap( 'Account', 'BillingCountryCode', 'BillingStateCode');
        
        // The dependent state codes for the given country
        List<String> stateCodes = dependencyMap.get(countryCode);
        
        if (stateCodes == null || stateCodes.isEmpty()) {
            return response;
        }
        
        // Get all state picklist values
        List<Schema.PicklistEntry> stateEntries =
            Schema.SObjectType.Account.fields.getMap()
            .get('BillingStateCode')
            .getDescribe()
            .getPicklistValues();
        
        // Filter only states that belong to the given country
        for (Schema.PicklistEntry s : stateEntries) {
            if (stateCodes.contains(s.getValue())) {
                response.add(new Map<String, String>{
                    'label' => s.getLabel(),
                        'value' => s.getValue()
                        });
            }
        }
        
        return response;
    }
    
    
    
    
    /* ---------------------------------------------------------
*  GENERIC METHOD TO GET CONTROLLING → DEPENDENT MAPPING
* --------------------------------------------------------- */
    public static Map<String, List<String>> getFieldDependencyMap(String objectApiName,String controllingFieldApiName, String dependentFieldApiName) {
        
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
        
        Schema.SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType == null) return controllingInfo;
        
        Schema.DescribeSObjectResult describeResult = sType.getDescribe();
        Map<String, Schema.SObjectField> fm = describeResult.fields.getMap();
        
        // Validate fields exist
        if (!fm.containsKey(controllingFieldApiName) || !fm.containsKey(dependentFieldApiName)) {
            return controllingInfo;
        }
        
        // Load describe data once
        Schema.DescribeFieldResult controllingFieldInfo = fm.get(controllingFieldApiName).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo  = fm.get(dependentFieldApiName).getDescribe();
        
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues  = dependentFieldInfo.getPicklistValues();
        
        // Initialize map with controlling picklist values (keys)
        for (Schema.PicklistEntry cv : controllingValues) {
            controllingInfo.put(cv.getValue(), new List<String>());
        }
        
        // Parse "validFor" bitsets
        List<PicklistInfo> depInfos =
            (List<PicklistInfo>) JSON.deserialize(
                JSON.serialize(dependentValues),
                List<PicklistInfo>.class
            );
        
        // Decode validFor Base64 mapping
        for (Integer i = 0; i < dependentValues.size(); i++) {
            
            Schema.PicklistEntry dep = dependentValues[i];
            PicklistInfo info = depInfos[i];
            
            if (String.isBlank(info.validFor)) continue;
            
            // Base64 → Hex string
            String hexString = EncodingUtil.convertToHex(
                EncodingUtil.base64Decode(info.validFor)
            ).toUpperCase();
            
            Integer baseCount = 0;
            
            // Bitmask decode
            for (Integer curr : hexString.getChars()) {
                
                Integer val = (curr >= 65) ? (curr - 65 + 10) : (curr - 48);
                    
                    if ((val & 8) == 8 && baseCount + 0 < controllingValues.size())
                    controllingInfo.get(controllingValues[baseCount + 0].getValue()).add(dep.getValue());
                
                if ((val & 4) == 4 && baseCount + 1 < controllingValues.size())
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).add(dep.getValue());
                
                if ((val & 2) == 2 && baseCount + 2 < controllingValues.size())
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).add(dep.getValue());
                
                if ((val & 1) == 1 && baseCount + 3 < controllingValues.size())
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).add(dep.getValue());
                
                baseCount += 4;
            }
        }
        
        return controllingInfo;
    }
    
    /*
public static Map<String, Object> getCountryStatePicklists() {

Map<String, Object> result = new Map<String, Object>();

List<Schema.PicklistEntry> countryEntries =
Schema.SObjectType.Account.fields.getMap().get('BillingCountryCode')
.getDescribe().getPicklistValues();

List<Map<String, String>> countries = new List<Map<String, String>>();

for (Schema.PicklistEntry c : countryEntries) {
countries.add(new Map<String, String>{
'label' => c.getLabel(),   // INDIA
'value' => c.getValue()    // IN
});
}
result.put('countries', countries);


List<Schema.PicklistEntry> stateEntries =
Schema.SObjectType.Account.fields.getMap().get('BillingStateCode')
.getDescribe().getPicklistValues();

List<Map<String, String>> states = new List<Map<String, String>>();

for (Schema.PicklistEntry s : stateEntries) {
states.add(new Map<String, String>{
'label' => s.getLabel(),    // Bihar
'value' => s.getValue()     // IN-BR
});
}

result.put('states', states);

return result;
}*/
    /*  
@auraEnabled
public static string convertQuote(string recId, Date bookingDate,Decimal bookingAmount,string paymentMode,string fundingType,String myRecordId){
system.debug(recId);
Quote__c qt = [SELECT Id,Name,SLead__c,SLead__r.Email,Approval_status__c,Quote_status__c,
Maintenance_Charge__c,Corpus_Fund__c,Built_up_area__c,Basic_Price__c,Payment_Type__c,
Infrastructure_Charges_per_sqft__c,Project__c,Property_Type__c,Unit__c,Lead__r.Name,
SLead__r.Secondary_Email__c,Plot_Type__c,Plot_Land_Area__c,
GST1__c,Apartment_No__c,Token_Amount__c,Quote_date__c,Maintenance_Deposite__c,Other_Charges_Payable_on_Possession__c,
Floor_Rise_Charges_Rate__c,Premium_Charge__c,Clubhouse_Charges__c,BESCOM_Deposit_Rs__c,
Legal_Documentation_Charges__c,Development_Charge__c,Block_Lookup__c FROM Quote__c WHERE Id=:recId];
Project__c pro = [select id,name,CRM_executive__c from Project__c where Project__c =: qt.Project__c];
system.debug(recId);
if(qt.Quote_status__c=='sent to customer'){
system.debug(bookingAmount);
system.debug(paymentMode);
Booking__c bk = new Booking__c();
bk.Id = myRecordId;
bk.Quote__c = qt.Id;
bk.SLead__c = qt.SLead__c;
bk.Project__c = qt.Project__c;
bk.Booking_Date__c = bookingDate;
bk.Plot__c = qt.Unit__c;
bk.CRM_Manager__c = pro.CRM_executive__c;
bk.Block__c=qt.Block_Lookup__c;
bk.Booking_Amount__c = bookingAmount;
bk.Funding_Type__c = fundingType;
bk.Date_of_Booking__c =bookingdate;
bk.Plot_Land_Area__c=qt.Plot_Land_Area__c;
bk.GST__c=qt.GST1__c;
bk.Apartment_Number__c=qt.Apartment_No__c;
bk.Payment_Type__c=qt.Payment_Type__c;
bk.Mode_Of_Payment__c = paymentMode;
bk.Maintenance_Charge__c=qt.Maintenance_Charge__c;
bk.Legal_Documentation_Charges__c=qt.Legal_Documentation_Charges__c;
bk.Corpus_Fund__c=qt.Corpus_Fund__c;
bk.Email__c = qt.SLead__r.Email;
bk.Email__c = qt.SLead__r.Email;
bk.Email1__c=qt.SLead__r.Secondary_Email__c;
bk.Applicant_Mobile_Number__c =qt.Lead__r.Phone__c;
bk.Applicant_Name__c = qt.Lead__r.Name;
bk.Club_House__c= qt.Clubhouse_Charges__c;
bk.Infrastructure_Charges_per_sqft__c=qt.Infrastructure_Charges_per_sqft__c;
upsert bk;

Lead ld = new Lead();
ld.Id=qt.SLead__c;
ld.Unit_No__c=qt.Unit__c;
ld.Lead_Status__c='Booked';
ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
//update ld;

Quote__c quot = new Quote__c();
quot.Id = qt.Id;
quot.Quote_status__c = 'Converted';
update quot;

plot__c pt=new plot__c();
pt.id = qt.Unit__c;
System.debug('samp2'+pt.Id);
pt.Status__c='Blocked';
if(pt.Id!=null){
update pt;
}
return bk.Id;
}
else{
return 'Not approved';
}
}
*/ 
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Mode_Of_Payment__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static List<String> getFundingtTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Funding_Type__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static Quote__c quoteRecord(String recId) {
        Quote__c qt = [select id,name,Quote_status__c,Related_Source__c,/*Booking_Amount__c,Basic_Villa_Cost__c, Project_Type__c,RecordType.Name,Basic_Flat_Cost__c,   Block_Lookup__r.Name*/ Unit_Number__c,Unit__r.Unit_Facing_Direction__c, Unit__r.Status__c, Project__c,Wing__c,Block__c,Agreement_Value_Before_GST__c,SLead__r.Email,Rate_per_sqft__c  from Quote__c where Id=:recId ];
        return qt;
    }
    @AuraEnabled
    public static void changeUnitStatus(Map<Id,String> plotIds){
        List<Plot__c> plotList = [Select Id,Name,Status__c from Plot__c where Id in: plotIds.keySet()];
        for(Plot__c plt : plotList){
            plt.Status__c = plotIds.get(plt.Id);
        }
        update plotList;
    }
    
    @AuraEnabled
    public static void requestSaleAgreement(Id recId){
        if (!Test.isRunningTest()) {
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Sale Agreement');
            req1.setObjectId(recId);
            req1.setSubmitterId(userInfo.getUserId()); 
            req1.setProcessDefinitionNameOrId('Request_For_Sale_Agreement');
            req1.setSkipEntryCriteria(true);
            Approval.ProcessResult result = Approval.process(req1);
        }
    }
    @AuraEnabled
    public static boolean sendCancellationApproval(Id recId, string cancellationReason, String cancellationRemarks, Decimal cancellationCharges){
        List<Booking__c> bklist = [Select Id, Name, Cancellation_Charge__c,Cancellation_Reason__c, Cancellation_Description__c From Booking__c Where id =: recId];
        for(Booking__c bk : bklist)
        {
            bk.Cancellation_Reason__c = cancellationReason;
            bk.Cancellation_Description__c = cancellationRemarks;
            bk.Cancellation_Charge__c = cancellationCharges;
        }
        Update bklist;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Cancellation request');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId());
        req1.setProcessDefinitionNameOrId('Cancellation_Approval_For_Booking_heads');
        
        
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
        return true;
    }
    
    @AuraEnabled
    public static Boolean bulkSendCancellationApproval(List<Id> recIds, String cancellationReason, String cancellationRemarks, Decimal cancellationCharges) {
        if (recIds == null || recIds.isEmpty()) {
            return false;
        }
        
        // Fetch all bookings at once
        List<Booking__c> bkList = [
            SELECT Id, Name, Cancellation_Charge__c, Cancellation_Reason__c, Cancellation_Description__c
            FROM Booking__c
            WHERE Id IN :recIds
        ];
        
        // Update booking fields
        for (Booking__c bk : bkList) {
            // bk.Cancellation_Reason__c = cancellationReason;
            bk.Cancellation_Description__c = cancellationRemarks;
            bk.Cancellation_Charge__c = cancellationCharges;
        }
        update bkList;
        
        // Prepare all approval requests in a list
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        for (Id recId : recIds) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Cancellation request');
            req.setObjectId(recId);
            req.setSubmitterId(UserInfo.getUserId());
            req.setProcessDefinitionNameOrId('Cancellation_Approval_For_Booking');
            req.setSkipEntryCriteria(true);
            approvalRequests.add(req);
        }
        
        // Submit all for approval in one go
        if (!approvalRequests.isEmpty()) {
            List<Approval.ProcessResult> results = Approval.process(approvalRequests);
        }
        
        return true;
    }
    
    public static void bookingSwappingApproval(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Booking Swapping');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Swapping_Approval_process1');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    public static void sendReceiptToFinance(Id recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitted for Receipt Apporval');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Receipt_Approval');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    
    public static void changeUnitStatus(List<Booking__c> bookList) {   
        Set<Id> units = new Set<Id>();
        for (Booking__c bcc : bookList) {
            units.add(bcc.Plot__c);
        }
        List<Plot__c> plotList = [SELECT Id, Name, Status__c FROM Plot__c WHERE Id IN :units];
        for (Plot__c plt : plotList) {
            plt.Status__c = 'Available';
        }
        if (!plotList.isEmpty()) {
            update plotList;
        }
        // For Sending Unit Update to related User
        sendEmailtoAllUser(bookList);
    }
    
    Public static void sendEmailtoAllUser(List<Booking__c> bookList){
        
        if (bookList == null || bookList.isEmpty()) return;
        Set<Id> bkId = new Set<Id>();
        
        For(Booking__c bk : bookList){
            bkId.add(bk.CRM_Executive__c);
            bkId.add(bk.CRM_Head__c);
            bkId.add(bk.Finance_Lead__c);
            bkId.add(bk.OwnerId);
            
        }
        List<User> userlist = [Select id , Email from User where Id IN :bkId ];
        List<String> emailList = new List<String>();
        
        for (User u : userList) {
            if (u.Email != null) {
                emailList.add(u.Email);
            }
        }
        
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for(Booking__c  bk : bookList){
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(emailList);
            email.setSubject('Unit Status Update For - ' + bk.Unit_No__c);
            
            email.setPlainTextBody(
                'Hello,' + '\n\n' +
                'Status of the Unit "' + bk.Unit_No__c + '" has been Changed to available.' + '\n\n' +
                'This unit is not available for new booking.'+ '\n\n' +
                'Regards,' + '\n' +
                'CRM Team'
            );
            
            email.setSaveAsActivity(true);
            email.setWhatId(bk.Id);
            emailsToSend.add(email);
            
            
        }
        
        
        if (!emailsToSend.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailsToSend);
            System.debug(results.Size());
        }
        
        
    }
    
    
    
    
    public static void swapUnit(List<Booking__c> swappingBookings){
    system.debug('swappingBookings'+swappingBookings);
    Set<Id> Bookunits = new Set<Id>();
    Set<Id> AvaiUnits = new Set<Id>();
    List<Booking__c> newBookings = new List<Booking__c>();
    for(Booking__c book : swappingBookings){
        Bookunits.add(book.Swap_Unit__c);
        AvaiUnits.add(book.Plot__c);
        Booking__c newBook = book.clone(false,false,false,false);
        newBook.Quote__c = book.Swap_Quote__c;
        newBook.Plot__c = book.Swap_Unit__c;
        newBook.Swap_Quote__c = book.Quote__c;
        newBook.Swap_Unit__c = book.Plot__c;
        newBook.Booking__c = book.id;
        newBook.Swap_Unit_Status__c = '';
        newBook.Stage__c = 'Booked';
        newBook.Remark__c = 'Swapped from '+book.Name;
        newBookings.add(newBook);
    }
    
    List<Plot__c> updateplotList = new List<Plot__c>();
    List<Plot__c> bookplotList = [select id,name,Status__c from Plot__c where id in: Bookunits];
    List<Plot__c> availplotList = [select id,name,Status__c from Plot__c where id in: AvaiUnits];
    for(Plot__c plt : availplotList){
        plt.Status__c = 'Available';
        updateplotList.add(plt);
    }
    for(Plot__c plt1 : bookplotList){
        plt1.Status__c = 'Booked';
        updateplotList.add(plt1);
    }
    if(updateplotList.size() > 0){
        update updateplotList;
    }
    if(newBookings.size() > 0){
        insert newBookings;
    }
    
    // Clone related records from old booking to new booking
    if(newBookings.size() > 0 && swappingBookings.size() > 0){
        cloneBookingFiles(swappingBookings[0].Id, newBookings[0].Id);
        cloneCoApplicants(swappingBookings[0].Id, newBookings[0].Id);
        cloneAdditionalCharges(swappingBookings[0].Id, newBookings[0].Id);
    }
    
    //newly added to reject receipts which are pending while swap unit
    Set<Id> oldBookingIds = new Set<Id>();
    for (Booking__c b : swappingBookings) {
        oldBookingIds.add(b.Id);
    }
    
    rejectPendingReceipts(oldBookingIds);
    Map<String,Id> paymentNumToId = new Map<String,Id>();
    List<Payment_schedule__c> mpsList = [select Id,Project__C,S_No__c,Master_Payment_Schedule__c,Name,Payment_Percent__c,Amount__c,Completed_Date__c,Payment_Due_Date__c,Status__c from payment_schedule__c where Booking__c  =:newBookings[0].Id ORDER BY S_No__c ASC];
    system.debug(mpsList);
    if(mpsList.size() > 0){
        system.debug('doing the things');
        for(Payment_schedule__c paySc : mpsList){
            paymentNumToId.put(paySc.Name,paySc.Id);
        }
    }
    List<Receipt_Line_Item__c> originalReceiptLineItems = [
        SELECT Id, Approval_Status__c, Name, Payment_Schedule__c,Branch__c  , Payment_Schedule__r.Name,
        Booking__c, Amount__c, Received_Amount__c,Drawn_On__c , Cheque_Date__c ,Payment_Type__c, Mode_of_Payment__c,
        Cheque_no_Transaction_Number__c, Bank_Name__c, Additional_Charges__c
        FROM Receipt_Line_Item__c 
        WHERE Booking__c =: swappingBookings[0].Id 
        AND Receipt__r.Approval_status__c = 'Approved'
    ];
    
    if (!originalReceiptLineItems.isEmpty()) {
        Decimal totalPaidAmount = 0;
        for (Receipt_Line_Item__c rli : originalReceiptLineItems) {
            if (rli.Received_Amount__c != null) {
                totalPaidAmount += rli.Received_Amount__c;
            }
        }
        
        Receipt__c originalReceipt = [SELECT Id, Receipt_Name__c, Remarks__c, Receipt_date__c 
                                     FROM Receipt__c 
                                     WHERE Booking__c =: swappingBookings[0].Id 
                                     AND Approval_status__c = 'Approved' 
                                     LIMIT 1];
        
        if(originalReceipt != null){
            Id newReceiptId = ReceiptController.insertReceiptLineItems(
                originalReceiptLineItems,
                'Swapped Booking',
                originalReceipt.Receipt_Name__c,
                'Swapped from original booking: ' + swappingBookings[0].Name,
                String.valueOf(originalReceipt.Receipt_date__c),
                newBookings[0].Id,
                totalPaidAmount,
                0
            );
        }
    }
}


    /**
 * Helper method to clone Co-Applicants from old booking to new booking
 * @param oldBookingId - Source Booking Id
 * @param newBookingId - Destination Booking Id
 */
private static void cloneCoApplicants(Id oldBookingId, Id newBookingId){
    try {
        // Query all Co-Applicants related to the old booking
        List<Co_Applicant__c> oldCoApplicants = [
            SELECT Name, Booking__c,Son_Daughter_Wife_of__c,Salutation__c,Son2_Daughter_Wife_of__c,Date_of_Birth__c,Nationality__c,Residential_Status__c,Power_of_Attorney_DOB__c,Power_of_Attorney__c,Alternate_Contact_No__c,Primary_Phone__c,Email__c,Passport_Number__c,PAN_Number__c,Aadhar_Number__c,Marital_Status__c,
            Anniverssary_Date__c,Spouse_Name__c,Spouse_Date_Of_Birth_coapp__c,Industry__c,Employeed_at__c,Qualification__c,Designation__c,Other_Qualification__c,Other_Industry__c,Communication_Address1__c,Permanent_Address1__c,Office_Address1__c
            FROM Co_Applicant__c 
            WHERE Booking__c = :oldBookingId
        ];
        
        if(oldCoApplicants.isEmpty()){
            system.debug('No Co-Applicants found on old booking to clone');
            return;
        }
        
        // Clone Co-Applicants
        List<Co_Applicant__c> newCoApplicants = new List<Co_Applicant__c>();
        for(Co_Applicant__c coApp : oldCoApplicants){
            Co_Applicant__c newCoApp = coApp.clone(false, true, false, false);
            newCoApp.Booking__c = newBookingId; // Link to new booking
            newCoApplicants.add(newCoApp);
        }
        
        // Insert new Co-Applicants
        if(!newCoApplicants.isEmpty()){
            insert newCoApplicants;
            system.debug('Successfully cloned ' + newCoApplicants.size() + ' Co-Applicants to new booking');
        }
        
    } catch(Exception e){
        system.debug('Error while cloning Co-Applicants: ' + e.getMessage());
        system.debug('Stack Trace: ' + e.getStackTraceString());
    }
}

/**
 * Helper method to clone Additional Charges from old booking to new booking
 * @param oldBookingId - Source Booking Id
 * @param newBookingId - Destination Booking Id
 */
private static void cloneAdditionalCharges(Id oldBookingId, Id newBookingId){
    try {
        // Query all Additional Charges related to the old booking
        List<Additional_Charges__c> oldCharges = [
            SELECT Name, Booking__c,Type__c,GST__c,Amount__c,Total_Additional_Charge__c
            FROM Additional_Charges__c 
            WHERE Booking__c = :oldBookingId
        ];
        
        if(oldCharges.isEmpty()){
            system.debug('No Additional Charges found on old booking to clone');
            return;
        }
        
        // Clone Additional Charges
        List<Additional_Charges__c> newCharges = new List<Additional_Charges__c>();
        for(Additional_Charges__c charge : oldCharges){
            Additional_Charges__c newCharge = charge.clone(false, true, false, false);
            newCharge.Booking__c = newBookingId; // Link to new booking
            newCharges.add(newCharge);
        }
        
        // Insert new Additional Charges
        if(!newCharges.isEmpty()){
            insert newCharges;
            system.debug('Successfully cloned ' + newCharges.size() + ' Additional Charges to new booking');
        }
        
    } catch(Exception e){
        system.debug('Error while cloning Additional Charges: ' + e.getMessage());
        system.debug('Stack Trace: ' + e.getStackTraceString());
    }
}

    
/**
 * Helper method to clone all files from old booking to new booking
 * @param oldBookingId - Source Booking Id
 * @param newBookingId - Destination Booking Id
 */
private static void cloneBookingFiles(Id oldBookingId, Id newBookingId){
    try {
        // Step 1: Get all ContentDocumentLinks related to the old booking
        List<ContentDocumentLink> oldCDLs = [
            SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :oldBookingId
        ];
        
        if(oldCDLs.isEmpty()){
            system.debug('No files found on old booking to clone');
            return;
        }
        
        // Step 2: Get all ContentVersion details for cloning
        Set<Id> contentVersionIds = new Set<Id>();
        for(ContentDocumentLink cdl : oldCDLs){
            if(cdl.ContentDocument.LatestPublishedVersionId != null){
                contentVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
            }
        }
        
        List<ContentVersion> originalVersions = [
            SELECT Title, PathOnClient, VersionData, FileType, 
                   Description, FileExtension, ContentLocation
            FROM ContentVersion 
            WHERE Id IN :contentVersionIds
        ];
        
        if(originalVersions.isEmpty()){
            system.debug('No content versions found to clone');
            return;
        }
        
        // Step 3: Clone ContentVersions
        List<ContentVersion> newContentVersions = new List<ContentVersion>();
        for(ContentVersion cv : originalVersions){
            ContentVersion newCV = new ContentVersion();
            newCV.Title = cv.Title;
            newCV.PathOnClient = cv.PathOnClient;
            newCV.VersionData = cv.VersionData;
            newCV.Description = cv.Description;
            newCV.FirstPublishLocationId = newBookingId; // Link to new booking
            newContentVersions.add(newCV);
        }
        
        // Step 4: Insert new ContentVersions
        if(!newContentVersions.isEmpty()){
            insert newContentVersions;
            system.debug('Successfully cloned ' + newContentVersions.size() + ' files to new booking');
        }
        
    } catch(Exception e){
        system.debug('Error while cloning files: ' + e.getMessage());
        system.debug('Stack Trace: ' + e.getStackTraceString());
        // You may want to handle this error based on your requirements
        // throw e; // Uncomment if you want to fail the entire transaction
    }
}


//Newly added on 26/12/2025/ when unit swap pending receipts need to be rejected
    public static void rejectPendingReceipts(Set<Id> bookingIds) {
        
        List<Receipt__c> receiptsToReject = [
            SELECT Id, Approval_status__c,Remarks__c
            FROM Receipt__c
            WHERE Booking__c IN :bookingIds
            AND Approval_status__c = 'Pending'
        ];
        
        for (Receipt__c rec : receiptsToReject) {
            rec.Approval_status__c = 'Rejected';
            rec.Remarks__c = 'Rejected due to unit swap';
        }
        
        if (!receiptsToReject.isEmpty()) {
            update receiptsToReject;
        }
    }
    
    
    
    @AuraEnabled
    public static Id saveFile1(Id parentId, String fileName, String base64Data, String contentType, String fileType) {
        system.debug('Incoming fileName => ' + fileName);
        system.debug('Incoming fileType => ' + fileType);
        Attachment attach = new Attachment();
        system.debug(parentId);
        if(parentId != null){
            //  Quote__c quote = [select Id,Name,Leads__c from Quote__c where Id=:parentId];
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            attach.parentId = parentId;
            attach.Body = EncodingUtil.base64Decode(base64Data);
            if (!String.isBlank(fileType)) {
                attach.Name = fileType + fileName;
            } else {
                attach.Name = fileName;
            }attach.ContentType = contentType;
            Insert attach; 
            
        }
        system.debug('attach.Id'+attach.Id);
        return attach.Id; 
        
    }
    
@AuraEnabled
public static Id saveFile(Id parentId, String fileName, String base64Data, String contentType, String fileType) {
    try {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Blob fileBody = EncodingUtil.base64Decode(base64Data);

        // Extract extension
        String extension = '';
        if (fileName.contains('.')) {
            extension = fileName.substring(fileName.lastIndexOf('.'));
        }

        // Use fileType as title (this is what GenricFileUploadComponent expects)
        String title = !String.isBlank(fileType) ? fileType.trim() : fileName.replace(extension, '');

        System.debug('Uploading file - Title: ' + title + ', FileName: ' + fileName);

        // Check if document with this title already exists
        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentId
            AND ContentDocument.Title = :title
            LIMIT 1
        ];

        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = fileName; // Keep original filename with extension
        cv.VersionData = fileBody;
        cv.IsMajorVersion = true;

        if (!existingLinks.isEmpty()) {
            // Replace existing file by creating new version
            cv.ContentDocumentId = existingLinks[0].ContentDocumentId;
            System.debug('Replacing existing document: ' + existingLinks[0].ContentDocumentId);
        }

        insert cv;
        System.debug('ContentVersion created: ' + cv.Id);

        // Get ContentDocumentId
        Id contentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id 
            LIMIT 1
        ].ContentDocumentId;

        // If new document (not replacement), link to parent
        if (existingLinks.isEmpty()) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = parentId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
            System.debug('New ContentDocumentLink created');
        }

        System.debug('File uploaded successfully: ' + title);
        return contentDocumentId;

    } catch (Exception e) {
        System.debug('Error in saveFile: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
        throw new AuraHandledException('Error uploading file: ' + e.getMessage());
    }
}
    @AuraEnabled
public static String convertQuote(String recId, Booking__c book, List<Co_Applicant__c> applicantList) {
    System.debug(applicantList);
    System.debug(book);

    Quote__c qt = [
        SELECT Id, Name,
               RecordTypeId, RecordType.DeveloperName,
               SLead__c, SLead__r.Email, SLead__r.Secondary_Email__c,Total_Infrastructure_Charges__c,Total_Maintenance_Amount__c, SLead__r.Name,SLead__r.Channel_Partner__c,
               Approval_status__c, Quote_status__c,Related_Source__r.Source_Type__c,Related_Source__r.Secondary_source__c,Related_Source__r.Tertiary_Source__c,
               Maintenance_Charge__c, Corpus_Fund__c, Built_up_area__c, Payment_Type__c,
               Infrastructure_Charges_per_sqft__c, Project__c, Property_Type__c, Unit__c,
               Plot_Type__c, Plot_Land_Area__c,
               Quote_date__c,
               Floor_Rise_Charges_Rate__c, Clubhouse_Charges__c,
               Unit__r.Status__c, Unit__r.Name,
               Legal_Documentation_Charges__c
        FROM Quote__c
        WHERE Id = :recId
    ];

    Payment_Schedule__c paySch = [
        SELECT Id, Name, Amount1__c, AmountB__c
        FROM Payment_Schedule__c
        WHERE S_No__c = 1 AND Quote__c = :qt.Id
        LIMIT 1
    ];

    Project__c pro = [
        SELECT Id, Name, CRM_executive__c, CRM_Manager__c, Sales_Head__c, Finance_User__c, COO__c
        FROM Project__c
        WHERE Project__c = :qt.Project__c
    ];

    if (qt.Unit__r.Status__c == 'Sold' || qt.Unit__r.Status__c == 'Booked') {
        return 'Unit not available';
    }

    // --- RECORD TYPE SYNC (Quote -> Booking) ---
    // Assumption: Quote__c and Booking__c have record types with the SAME DeveloperName.
    // If you want to match by RecordType.Name instead, tell me and I'll switch it.
    Map<String, Id> bookingRtByDevName = new Map<String, Id>();
    for (RecordType rt : [
        SELECT Id, DeveloperName
        FROM RecordType
        WHERE SObjectType = 'Booking__c'
    ]) {
        bookingRtByDevName.put(rt.DeveloperName, rt.Id);
    }

    Id bookingRtId = bookingRtByDevName.get(qt.RecordType.DeveloperName);
    if (bookingRtId == null) {
        // Fail fast - otherwise you'll silently insert wrong record type
        throw new AuraHandledException(
            'No matching Booking__c RecordType found for Quote__c record type: ' + qt.RecordType.DeveloperName
        );
    }
    // ------------------------------------------

    Booking__c bk = book;
    bk.RecordTypeId = bookingRtId;          // ✅ same record type as Quote (by DeveloperName)
    bk.Quote__c = qt.Id;
    bk.Stage__c = 'New';
    bk.SLead__c = qt.SLead__c;
    bk.Project__c = qt.Project__c;
    bk.Project1__c = pro.Id;
    bk.Plot__c = qt.Unit__c;
    bk.COO__c = pro.COO__c;
    bk.Finance_Lead__c = pro.Finance_User__c;
    bk.CRM_Head__c = pro.CRM_Manager__c;
    bk.Sales_Head__c = pro.Sales_Head__c;
    bk.Application_Amount__c = paySch.Amount1__c - bk.Booking_Amount__c;
    bk.Agreement_Execution_Amount1__c = paySch.Amount1__c;
    bk.Project_Type__c = qt.Property_Type__c;
    bk.Payment_Type__c = qt.Payment_Type__c;
    bk.Email1__c = qt.SLead__r.Secondary_Email__c;
    bk.Applicant_Name__c = qt.SLead__r.Name;
    bk.Club_House__c = qt.Clubhouse_Charges__c;
    bk.Clubhouse_Charges__c = qt.Clubhouse_Charges__c;
    bk.Total_Maintenance_Amount__c = qt.Total_Maintenance_Amount__c;
    bk.Total_Infrastructure_Charges__c = qt.Total_Infrastructure_Charges__c;
    if(qt.SLead__r.Channel_Partner__c !=null){
          bk.Channel_Partner__c = qt.SLead__r.Channel_Partner__c;// Added on 10-03-20226 by Praveen
    }

    bk.Flat_no__c = qt.Unit__r.Name;
    bk.Sales_User__c = UserInfo.getUserId();// Added on 18-03-20226 by Tejaswini Y
    bk.Sales_RM_Name__c = UserInfo.getUserName();// Added on 18-03-20226 by Tejaswini Y
    bk.Source__c = qt.Related_Source__r.Source_Type__c;// Added on 18-03-20226 by Tejaswini Y
    bk.Sub_Source__c = qt.Related_Source__r.Secondary_source__c;// Added on 18-03-20226 by Tejaswini Y
    bk.Tertiary_Source__c = qt.Related_Source__r.Tertiary_Source__c;// Added on 18-03-20226 by Tejaswini Y    

    insert bk;

    List<Co_Applicant__c> applicantListToInsert = new List<Co_Applicant__c>();
    for (Co_Applicant__c coA : applicantList) {
        if (coA.Name != null && coA.Name.trim() != '') {
            coA.Booking__c = bk.Id;
            applicantListToInsert.add(coA);
        }
    }
    if (!applicantListToInsert.isEmpty()) {
        insert applicantListToInsert;
    }

    if (bk.Booking_Amount__c != null && bk.Booking_Amount__c != 0) {
        List<Receipt_Line_Item__c> replineItems = new List<Receipt_Line_Item__c>();
        Receipt_Line_Item__c repItem = new Receipt_Line_Item__c();
        repItem.Payment_Type__c = 'Plot Amount';
        repItem.Bank_Name__c = bk.Bank_Name__c;
        repItem.Mode_of_Payment__c = bk.Mode_Of_Payment__c;
        repItem.Received_Amount__c = bk.Booking_Amount__c;
        repItem.Branch__c = bk.Branch_Name__c;
        repItem.Cheque_Date__c = bk.Cheque_Date__c;

        if (bk.Mode_Of_Payment__c == 'Cheque') {
            repItem.Drawn_On__c = bk.Posting_in_Date__c;
        } else {
            repItem.Drawn_On__c = bk.Date_of_Payment__c;
        }

        repItem.Cheque_no_Transaction_Number__c = bk.Transaction_ID__c;
        replineItems.add(repItem);

        ReceiptController.insertReceiptLineItems(
            replineItems,
            'Customer',
            String.valueOf(bk.Booking_Date__c),
            'Booking Amount',
            String.valueOf(bk.Booking_Date__c),
            bk.Id,
            bk.Booking_Amount__c,
            0
        );
    }

    Lead ld = new Lead();
    ld.Id = qt.SLead__c;
    ld.Lead_Status__c = 'Booked';
    ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
    update ld;

    Quote__c quot = new Quote__c();
    quot.Id = qt.Id;
    quot.Quote_status__c = 'Converted';
    update quot;

    plot__c pt = new plot__c();
    pt.Id = qt.Unit__c;
    pt.Status__c = 'Booked';
    update pt;

    return bk.Id;
}

    /* public static void sendCustomNotification(Set<String> recepientIds, String Title, String Body, String recId, String notificationName){

CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
Notification.setNotificationTypeId(closedWonNotification.id); 
Notification.setSenderId(Userinfo.getUserId()); 
Notification.setBody(Body); 
Notification.setTitle(Title); 
Notification.setTargetId(recId); 
Notification.send(recepientIds);
}*/
    public static void Roundrobine(List<Booking__c> booklist){
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true and User_Type__c='CRM'  order by Last_Assigned_time_user__c,createddate asc nulls first limit 1) from Round_Robin__c where Project_Assigned__c != NULL and Active__c = true ];
        Map<String,Round_Robin__c> MapRobin = new Map<String,Round_Robin__c>();
        for(Round_Robin__c rb : RRAvaliablequeList){
            
            MapRobin.put(rb.Project_Assigned__c,rb);
        }
        List<User> userlist = new List<User>();
        for(Booking__c bb : booklist){
            Round_Robin__c rr = MapRobin.get(bb.Project__c);
            if (rr != null && rr.Round_Robin_Members__r != null && !rr.Round_Robin_Members__r.isEmpty()) {
                bb.OwnerId = rr.Round_Robin_Members__r[0].User__c;
                User newuser = new User();
                newuser.id = rr.Round_Robin_Members__r[0].User__c;
                newuser.LastAssignmentTime1__c = system.now().getTime();
                userlist.add(newuser);
            }
        }
        if(userlist.size()>0){
            update userlist;
        }
    }
    
    public static void sendNotificationsFromBooking(List<Booking__c> bklist) {
        String body,title;
        Set<String> userId = new Set<String>();
        
        for( Booking__c bk : bklist){
            if(bk.Approval_status__c=='Approved'){
                title ='Booking Approved';
                body = 'This is to notify that Booking ' + bk.Name + ' is Approved by the Team Lead';
                userId.add(bk.OwnerId);
                userId.add(bk.Sales_Head__c);
                userId.add(bk.Sales_User__c);
            }
            if(bk.Approval_status__c == 'Rejected'){
                title ='Booking Rejected';
                body = 'This is to notify that Booking ' + bk.Name + ' is Rejected by the Team Lead';
                userId.add(bk.OwnerId);
                userId.add(bk.Sales_Head__c);
                userId.add(bk.Sales_User__c);
            }
            
            sendCustomNotification(userId, title, body, bk.Id, 'Booking_Notification');
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
            System.debug('Sent');
            
        }catch(exception e){
            System.debug('ERROR sending notification: ' + e.getMessage());
        }
    }
    
    public static void moveStageToAgreement(Set<Id> bookingIds) {
        System.debug('bookingIds '+bookingIds);
        if (bookingIds == null || bookingIds.isEmpty()) return;
        
        List<Booking__c> eligibleBookings = [
            SELECT Id, OwnerId, Stage__c, Agreement_Execution_Amount1__c
            FROM Booking__c
            WHERE Id IN :bookingIds AND Stage__c = 'Booked' AND Welcome_Email_Sent_to_Customer__c = true
        ];
        if (eligibleBookings.isEmpty()) return;
        
        // 2. Fetch the total advance amount from approved receipts
        Map<Id, Decimal> bookingIdToTotal = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Booking__c bookingId, SUM(Total_Received_Amount__c) total
            FROM Receipt__c
            WHERE Booking__c IN :bookingIds
            AND Approval_Status__c = 'Approved'
            GROUP BY Booking__c
        ]) {
            bookingIdToTotal.put((Id) ar.get('bookingId'), (Decimal) ar.get('total'));
        }
        
        Map<Id, Booking__c> bookingsById = new Map<Id, Booking__c>();
        Set<Id> eligibleBookingIds = new Set<Id>();
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        for (Booking__c booking : eligibleBookings) {
            Decimal totalReceived = bookingIdToTotal.get(booking.Id);
            system.debug('totalReceived'+ totalReceived+' Agreement_Execution_Amount1__c'+ booking.Agreement_Execution_Amount1__c);
            if (totalReceived != null && totalReceived >= booking.Agreement_Execution_Amount1__c.setScale(0)) {
                bookingsToUpdate.add(booking);
                eligibleBookingIds.add(booking.Id);
                bookingsById.put(booking.Id, booking);
            }
        }
        
        if (!eligibleBookingIds.isEmpty()) {
            for (Booking__c booking : bookingsToUpdate) {
                booking.Stage__c = 'Agreement';
            }
            
            if (!bookingsToUpdate.isEmpty()) {
                update bookingsToUpdate;
            }
        }
        
    }
    
    public static void moveStageToAgreementTR(Set<Booking__c> bookings) {
        
        if (bookings == null || bookings.isEmpty()) return;
        Set<Id> bookingIds = new set<Id>();
        for(Booking__c book :bookings){
            bookingIds.add(book.Id);
        }
        // 2. Fetch the total advance amount from approved receipts
        Map<Id, Decimal> bookingIdToTotal = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Booking__c bookingId, SUM(Total_Received_Amount__c) total
            FROM Receipt__c
            WHERE Booking__c IN :bookingIds
            AND Approval_Status__c = 'Approved'
            GROUP BY Booking__c
        ]) {
            bookingIdToTotal.put((Id) ar.get('bookingId'), (Decimal) ar.get('total'));
        }
        
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        for (Booking__c booking : bookings) {
            Decimal totalReceived = bookingIdToTotal.get(booking.Id);
            system.debug('totalReceived'+ totalReceived+' Agreement_Execution_Amount__c'+ booking.Agreement_Execution_Amount__c);
            if (totalReceived != null && totalReceived >= booking.Agreement_Execution_Amount__c.setScale(0)) {
                booking.Stage__c = 'Agreement';
            }
        }
        
    }
    @AuraEnabled
    public static void agreementTimeEXtensionApproval(Id recordId) {
        try {
            // Fetch the record
            Booking__c agreement = [SELECT Id, Time_Extension_Approval_Status__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
            
            // Check if the Agreement is eligible for approval
            if (agreement.Time_Extension_Approval_Status__c != null) {
                throw new CustomException('Agreement is not in a state that can be submitted for approval.');
            }
            
            String approvalProcessName = 'Approval_Process_for_Time_Extensions';
            
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Sale Agreement Time Extension Request');
            req1.setObjectId(recordId);
            req1.setSubmitterId(userInfo.getUserId()); 
            req1.setProcessDefinitionNameOrId('Approval_Process_for_Time_Extensions	');
            req1.setSkipEntryCriteria(true);
            Approval.ProcessResult result = Approval.process(req1);
            
            if (result.isSuccess()) {
                // Successfully submitted for approval
                System.debug('Approval Process started successfully for ' + approvalProcessName);
            } else {
                throw new CustomException('Failed to submit for approval: ' + result.getErrors());
            }
        } catch (Exception e) {
            throw new CustomException('Error during approval submission: ' + e.getMessage());
        }
    }
    
    // Custom exception class for better error handling
    public class CustomException extends Exception {}
    @AuraEnabled
    public static String requestSwapApproval(Id bookingId, String reason) {
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Id = :bookingId];
        
        // Mark swap request
        bk.Swap_Applicant_Request__c = true;
        bk.Reason_For_Swapping_Applicant__c=reason;
        update bk;
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(bookingId);
        req.setProcessDefinitionNameOrId('Swapping_First_Applicant_Approval'); // Ensure this process exists
        
        
        Approval.ProcessResult res = Approval.process(req);
        return res.getInstanceId(); 
    }
    
    @AuraEnabled
    public static String checkCoApplicant(Id bookingId) {
        Booking__c bk = [SELECT Id FROM Booking__c WHERE Id = :bookingId];
        
        List<Co_Applicant__c> coApps = [SELECT Id FROM Co_Applicant__c where Booking__c =:bk.Id];
        if(!coApps.isEmpty()){
            return 'Co Applicant Exist';
        }else{
            return 'Co Applicant not Exist';
        }
        
    }
    public static void swapApplicantData(List<Id> bookingIds) {
        
        List<Booking__c> bookings = [
            SELECT Id,
            First_Applicant_Name__c, Son_Daughter_Wife_of1__c, Date_of_Birth1__c,Power_of_Attorney__c, Power_of_Attorney_DOB__c, Marital_Status__c,
            Anniverssary_Date1__c, Spouse_Name__c, Spouse_Date_Of_Birth__c,Aadhar_No__c, PAN_Number__c, Passport_PI_no__c, Email__c, Mobile__c, Alternate_Contact_No__c,
            Swap_Applicant_Request__c,
            Correspondence_Address__Street__s,Correspondence_Address__City__s,Correspondence_Address__CountryCode__s,Correspondence_Address__PostalCode__s,Correspondence_Address__StateCode__s,
            Permanent_Address2__Street__s,Permanent_Address2__City__s,Permanent_Address2__CountryCode__s,Permanent_Address2__StateCode__s,Permanent_Address2__PostalCode__s,
            Office_Address1__Street__s,Office_Address1__City__s,Office_Address1__CountryCode__s,Office_Address1__StateCode__s,Office_Address1__PostalCode__s
            FROM Booking__c
            WHERE Id IN :bookingIds
        ];
        
        List<Co_Applicant__c> coApps = [SELECT Id, Booking__c, Name, Son_Daughter_Wife_of__c, Date_of_Birth__c,
                                        Power_of_Attorney__c, Power_of_Attorney_DOB__c, Marital_Status__c,Anniverssary_Date__c, Spouse_Name__c, Spouse_Date_Of_Birth_coapp__c,
                                        Aadhar_Number__c, PAN_Number__c, Passport_Number__c, Email__c, Primary_Phone__c, Alternate_Contact_No__c,
                                        Communication_Address1__Street__s,Communication_Address1__City__s,Communication_Address1__CountryCode__s,Communication_Address1__PostalCode__s,Communication_Address1__StateCode__s,
                                        Permanent_Address1__Street__s,Permanent_Address1__City__s,Permanent_Address1__CountryCode__s,Permanent_Address1__PostalCode__s,Permanent_Address1__StateCode__s,
                                        Office_Address1__Street__s,Office_Address1__City__s,Office_Address1__CountryCode__s,Office_Address1__PostalCode__s,Office_Address1__StateCode__s
                                        FROM Co_Applicant__c    WHERE Booking__c IN :bookingIds    ORDER BY CreatedDate ASC   limit 1];
        
        Map<Id, Co_Applicant__c> firstCoAppMap = new Map<Id, Co_Applicant__c>();
        for (Co_Applicant__c c : coApps) {
            if (!firstCoAppMap.containsKey(c.Booking__c)) {
                firstCoAppMap.put(c.Booking__c, c);
            }
        }
        
        List<Booking__c> updateBookings = new List<Booking__c>();
        List<Co_Applicant__c> updateCoApps = new List<Co_Applicant__c>();
        
        for (Booking__c bk : bookings) {
            
            if (!firstCoAppMap.containsKey(bk.Id)) continue;
            
            Co_Applicant__c ca = firstCoAppMap.get(bk.Id);
            
            // Clone old values
            Booking__c oldB = bk.clone(false, false, false, false);
            Co_Applicant__c oldC = ca.clone(false, false, false, false);
            
            // Swap → Booking ← CoApplicant
            bk.First_Applicant_Name__c = oldC.Name;
            bk.Son_Daughter_Wife_of1__c = oldC.Son_Daughter_Wife_of__c;
            bk.Date_of_Birth1__c = oldC.Date_of_Birth__c;
            bk.Power_of_Attorney__c = oldC.Power_of_Attorney__c;
            bk.Power_of_Attorney_DOB__c = oldC.Power_of_Attorney_DOB__c;
            bk.Marital_Status__c = oldC.Marital_Status__c;
            bk.Anniverssary_Date1__c = oldC.Anniverssary_Date__c;
            bk.Spouse_Name__c = oldC.Spouse_Name__c;
            bk.Spouse_Date_Of_Birth__c = oldC.Spouse_Date_Of_Birth_coapp__c;
            bk.Aadhar_No__c = oldC.Aadhar_Number__c;
            bk.PAN_Number__c = oldC.PAN_Number__c;
            bk.Passport_PI_no__c = oldC.Passport_Number__c;
            bk.Email__c = oldC.Email__c;
            bk.Mobile__c = oldC.Primary_Phone__c;
            bk.Alternate_Contact_No__c = oldC.Alternate_Contact_No__c;
            
            bk.Correspondence_Address__Street__s= oldC.Communication_Address1__Street__s;
            bk.Correspondence_Address__City__s = oldC.Communication_Address1__City__s;
            bk.Correspondence_Address__StateCode__s = oldC.Communication_Address1__StateCode__s;
            bk.Correspondence_Address__PostalCode__s = oldC.Communication_Address1__PostalCode__s;
            bk.Correspondence_Address__CountryCode__s = oldC.Communication_Address1__CountryCode__s;
            
            bk.Permanent_Address2__Street__s = oldC.Permanent_Address1__Street__s;
            bk.Permanent_Address2__City__s = oldC.Permanent_Address1__City__s;
            bk.Permanent_Address2__StateCode__s = oldC.Permanent_Address1__StateCode__s;
            bk.Permanent_Address2__PostalCode__s = oldC.Permanent_Address1__PostalCode__s;
            bk.Permanent_Address2__CountryCode__s = oldC.Permanent_Address1__CountryCode__s;
            
            bk.Office_Address1__Street__s = oldC.Office_Address1__Street__s;
            bk.Office_Address1__City__s =oldC.Office_Address1__City__s ;
            bk.Office_Address1__StateCode__s = oldC.Office_Address1__StateCode__s;
            bk.Office_Address1__PostalCode__s = oldC.Office_Address1__PostalCode__s;
            bk.Office_Address1__CountryCode__s = oldC.Office_Address1__CountryCode__s;
            
            
            // Swap → CoApplicant ← Booking(old)
            ca.Name = oldB.First_Applicant_Name__c;
            ca.Son_Daughter_Wife_of__c = oldB.Son_Daughter_Wife_of1__c;
            ca.Date_of_Birth__c = oldB.Date_of_Birth1__c;
            ca.Power_of_Attorney__c = oldB.Power_of_Attorney__c;
            ca.Power_of_Attorney_DOB__c = oldB.Power_of_Attorney_DOB__c;
            ca.Marital_Status__c = oldB.Marital_Status__c;
            ca.Anniverssary_Date__c = oldB.Anniverssary_Date1__c;
            ca.Spouse_Name__c = oldB.Spouse_Name__c;
            ca.Spouse_Date_Of_Birth_coapp__c = oldB.Spouse_Date_Of_Birth__c;
            ca.Aadhar_Number__c = oldB.Aadhar_No__c;
            ca.PAN_Number__c = oldB.PAN_Number__c;
            ca.Passport_Number__c = oldB.Passport_PI_no__c;
            ca.Email__c = oldB.Email__c;
            ca.Primary_Phone__c = oldB.Mobile__c;
            ca.Alternate_Contact_No__c = oldB.Alternate_Contact_No__c;
            
            ca.Communication_Address1__Street__s = oldB.Correspondence_Address__Street__s;
            ca.Communication_Address1__City__s = oldB.Correspondence_Address__City__s;
            ca.Communication_Address1__StateCode__s = oldB.Correspondence_Address__StateCode__s;
            ca.Communication_Address1__PostalCode__s = oldB.Correspondence_Address__PostalCode__s;
            ca.Communication_Address1__CountryCode__s = oldB.Correspondence_Address__CountryCode__s;
            
            ca.Permanent_Address1__Street__s = oldB.Permanent_Address2__Street__s;
            ca.Permanent_Address1__City__s = oldB.Permanent_Address2__City__s;
            ca.Permanent_Address1__StateCode__s = oldB.Permanent_Address2__StateCode__s;
            ca.Permanent_Address1__PostalCode__s = oldB.Permanent_Address2__PostalCode__s;
            ca.Permanent_Address1__CountryCode__s = oldB.Permanent_Address2__CountryCode__s;
            
            ca.Office_Address1__Street__s = oldB.Office_Address1__Street__s;
            ca.Office_Address1__City__s = oldB.Office_Address1__City__s;
            ca.Office_Address1__StateCode__s = oldB.Office_Address1__StateCode__s;
            ca.Office_Address1__PostalCode__s = oldB.Office_Address1__PostalCode__s;
            ca.Office_Address1__CountryCode__s = oldB.Office_Address1__CountryCode__s;
            
            updateBookings.add(bk);
            updateCoApps.add(ca);
        }
        
        if (!updateBookings.isEmpty()) update updateBookings;
        if (!updateCoApps.isEmpty())   update updateCoApps;
    }
    
    
    @Future(callout=true)
    public static void sendHandOverEmailToCustomer(List<Id> bookingId) {
        if (bookingId == null || bookingId.isEmpty()) return;
        
        List<Booking__c> bookinglist = [SELECT Id, Email__c, First_Applicant_Name__c, Email1__c, Owner.Email, Project1__r.Project__c,Project1__r.Project_Address__c FROM Booking__c WHERE Id IN :bookingId];
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<ContentVersion> cvs = new List<ContentVersion>();
        
        for (Booking__c booking : bookinglist) {
            
            System.debug('Called for Handover Mail');
            if (String.isBlank(booking.Email__c)) continue;

            String projectName = (booking.Project1__r != null && !String.isBlank(booking.Project1__r.Project__c))
                ? booking.Project1__r.Project__c
                : 'our project';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { booking.Email__c });
            email.setSubject('Key Handover Confirmation – ' + projectName);
            
            // ===== 3. Email Body (HTML) =====
            String body = ''
                + '<p>Dear ' + booking.First_Applicant_Name__c + ',</p>'
                + '<p>We are delighted to inform you that the keys for your unit at '
                + '<strong>' + projectName + '</strong>, '
                + booking.Project1__r.Project_Address__c +'</p>'
                
                + '<p>Please find the attached letter for your reference.</p>'
                
                + '<p>Kindly acknowledge receipt by signing the attached document, confirming that '
                + 'you have inspected all the keys and verified their working condition prior to the handover.</p>'
                
                + '<p>Thank you for choosing <strong>Zuari Infraworld India Limited</strong>. '
                + 'We look forward to serving you.</p>'
                
                + '<br/>'
                + '<p>Best regards,<br/>'
                + 'CRM Representative<br/>'
                + 'Zuari Infraworld India Limited</p>';
            
            email.setHtmlBody(body);
            
            PageReference pdfPage = Page.Key_Handover_Letter;
            pdfPage.getParameters().put('id', booking.Id);
            
            Blob pdfBlob = !Test.isRunningTest()
                ? pdfPage.getContentAsPDF()
                : Blob.valueOf('testblob');
            
            
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Handover-' + booking.Id + '.pdf');
            attachment.setBody(pdfBlob);
            email.setFileAttachments(
                new Messaging.EmailFileAttachment[] { attachment }
            );
            attachments.add(attachment);
            
            email.setFileAttachments(attachments);
            email.setSaveAsActivity(true);
            email.setWhatId(booking.Id);
            
            emailsToSend.add(email);
            
        }
        
        if(!emailsToSend.IsEmpty()){
            
            System.debug('Called for Handover Mail');
            Messaging.SendEmailResult[] results= Messaging.sendEmail(emailsToSend);
            System.debug(results);
        }
    }
    //Added Newly to send Notification and Mail
    public static void sendOwnerChangeNotifications(List<Id> bookingIds, Map<Id, Id> oldOwnerMap) {
        
        if (bookingIds == null || bookingIds.isEmpty()) return;
        
        // Query all bookings
        List<Booking__c> bookings = [
            SELECT Id, Name, OwnerId
            FROM Booking__c 
            WHERE Id IN :bookingIds
        ];
        
        if (bookings.isEmpty()) return;
        
        // Collect all required User IDs (new owners + old owners)
        Set<Id> userIds = new Set<Id>();
        for (Booking__c b : bookings) {
            userIds.add(b.OwnerId);
            if (oldOwnerMap.containsKey(b.Id) && oldOwnerMap.get(b.Id) != null) {
                userIds.add(oldOwnerMap.get(b.Id));
            }
        }
        
        // Bulk query all User emails
        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, Email FROM User WHERE Id IN :userIds]
        );
        
        // Query OrgWideEmailAddress as a list
        List<OrgWideEmailAddress> owEmailList = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'communication@crm.zuariproperties.com'];
            
        
        // Pick one if available
        Id orgWideId = owEmailList.isEmpty() ? null : owEmailList[0].Id;
        
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for (Booking__c b : bookings) {
            
            User newOwner = userMap.get(b.OwnerId);
            User oldOwner = userMap.get(oldOwnerMap.get(b.Id));
            
            // Safety: if no email, skip this record
            if (newOwner == null || String.isBlank(newOwner.Email)) {
                System.debug('Skipping booking ' + b.Id + ' — new owner has no email.');
                continue;
            }
            
            // Build record link
            String bookingLink = baseUrl + '/' + b.Id;
            
            // Create email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { newOwner.Email });
            mail.setSubject('Booking Owner Changed - ' + b.Name);
            
            // Set org-wide email only if exists
            if (orgWideId != null) {
                mail.setOrgWideEmailAddressId(orgWideId);
            }
            
            mail.setPlainTextBody(
                'Hello,' + '\n\n' +
                'Ownership of the booking "' + b.Name + '" has been transferred to you.' + '\n\n' +
                'Open booking:' + '\n' +
                bookingLink + '\n\n' +
                'Regards,' + '\n' +
                'CRM Team'
            );
            
            emailList.add(mail);
            
            // Custom Notification
            sendCustomNotification(
                new Set<String>{ b.OwnerId },
                'Booking Owner Changed',
                'Booking ' + b.Name + ' is now assigned to you.',
                b.Id,
                'Booking_Notification'
            );
        }
        
        // Send all emails in bulk
        if (!emailList.isEmpty()) {
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
            
            for (Integer i = 0; i < results.size(); i++) {
                Messaging.SendEmailResult r = results[i];
                Messaging.SingleEmailMessage sentEmail = emailList[i];
                
                if (r.isSuccess()) {
                    System.debug('Email sent successfully to: ' + String.join(sentEmail.getToAddresses(), ', '));
                } else {
                    for (Messaging.SendEmailError err : r.getErrors()) {
                        System.debug('Email FAILED to: ' + String.join(sentEmail.getToAddresses(), ', ')
                                     + ' — Error: ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    
    public static void sendApprovalStatusNotification(Booking__c bk, String fieldLabel, String oldValue, String newValue) {
        try {
            // Only notify when status changed
            if (oldValue == newValue) return;
            
            // Get booking owner
            String ownerId = bk.OwnerId;
            String financId = bk.Finance_Lead__c;
            if (ownerId == null) return;
            
            // ====================================================================
            // CUSTOM NOTIFICATION
            // ====================================================================
            String notifBody = 
                'Booking ' + bk.Name + 
                ' - ' + fieldLabel + 
                ' updated from "' + oldValue + '" to "' + newValue + '".';
            
            Set<String> userIds = new Set<String>{ ownerId };
                
                BookingController.sendCustomNotification(
                    userIds,
                    fieldLabel + ' Updated',
                    notifBody,
                    bk.Id,
                    'Booking_Notification'
                );
            
            // ====================================================================
            // EMAIL
            // ====================================================================
            User u = [SELECT Id, Email FROM User WHERE Id = :ownerId LIMIT 1];
            User fu = [select id , Email from User where Id =:financId limit 1];
            if (u.Email != null && fu.Email != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{ u.Email,fu.Email });
                mail.setSubject('Booking Update - ' + fieldLabel);
                mail.setPlainTextBody(notifBody);
                
                List<Messaging.SendEmailResult> result = Messaging.sendEmail(
                    new List<Messaging.SingleEmailMessage>{ mail }
                );
                
                System.debug('Email Sent: ' + result[0].isSuccess());
            }
        }
        catch (Exception e) {
            System.debug('Error sending approval status notification: ' + e.getMessage());
        }
    }
    
}