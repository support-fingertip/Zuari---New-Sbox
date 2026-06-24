public class BookingPDFController {
    public Booking__c booking { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public List<String> textLines { get; set; }
    public String imagepicUrl { get; set; }
    public String bookingAmount { get; set; }
    public String plotAreaInSqareMeters { get; set; }
    public String imageUrl { get; set; }
    public String imageUrl2 { get; set; }

    // New formatted date fields
    public String dobFormattedWithBars { get; set; }
    public String spouseDobFormattedWithBars { get; set; }
    public String anniversaryFormattedWithBars { get; set; }
    public String codobFormattedWithBars { get; set; }
    public String cospouseDobFormattedWithBars { get; set; }
    public String coanniversaryFormattedWithBars { get; set; }
    
    private static Map<String, String> stateCodeToLabel;
    private static Map<String, String> countryCodeToLabel;
    
    private Boolean bookingAddressesLoaded = false;
    private Address permanentAddress;          
    private Address correspondenceAddress;     
    private Address officeAddress;             
    
    private Boolean firstCoApplicantAddressesLoaded = false;
    private Address firstCoApplicantPermanentAddress;        
    private Address firstCoApplicantCommunicationAddress;   
    private Address firstCoApplicantOfficeAddress;
   


    public BookingPDFController(ApexPages.StandardController controller) {
        Id bookingId = controller.getId();
        booking = [ SELECT Id, Notes_and_Comments__c, Date_of_Birth1__c, Spouse_Date_Of_Birth__c,Anniverssary_Date1__c,
                   Plot__r.Name, Plot__r.Block_Lookup__r.Name, Booking_Amount__c, Quote__r.Super_Built_UpArea__c FROM Booking__c WHERE Id = :bookingId ];

        System.debug(booking);
        
        // Try fetching from classic Attachment first
        List<Attachment> attList = [SELECT Id, Name  FROM Attachment WHERE ParentId = :bookingId AND Name LIKE '%Applicant Passport Size Photo%'  LIMIT 1];
        
        if (!attList.isEmpty()) {
            // Build URL for attachment
            imageUrl = '/servlet/servlet.FileDownload?file=' + attList[0].Id;
        } else {
            // Fallback to Salesforce Files
            List<ContentDocumentLink> links = [ SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title  FROM ContentDocumentLink  WHERE LinkedEntityId = :bookingId AND ContentDocument.FileExtension IN ('jpg', 'jpeg', 'png')  AND ContentDocument.Title LIKE '%Applicant Passport Size Photo%' LIMIT 1 ];
            
            if (!links.isEmpty()) {
                Id versionId = links[0].ContentDocument.LatestPublishedVersionId;
                imageUrl = '/sfc/servlet.shepherd/version/download/' + versionId;
            }
        }


        // Fetch applicant photo
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title  FROM ContentDocumentLink WHERE LinkedEntityId = :bookingId  AND ContentDocument.FileExtension IN ('jpg', 'jpeg', 'png')    AND ContentDocument.Title LIKE '%Picture1%' LIMIT 1];
        List<ContentDocumentLink> clinks = [
            SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :bookingId AND ContentDocument.FileExtension IN ('jpg', 'jpeg', 'png') AND ContentDocument.Title LIKE '%Co Applicant Photo%' LIMIT 1 ];
        system.debug('links'+ links);
         system.debug('clinks'+ clinks);
         system.debug('bookingId'+ bookingId);
        if (!links.isEmpty()) {
            Id versionId = links[0].ContentDocument.LatestPublishedVersionId;
           // imageUrl = '/sfc/servlet.shepherd/version/download/' + versionId;
        }

        if (!clinks.isEmpty()) {
            Id versionId = clinks[0].ContentDocument.LatestPublishedVersionId;
            imageUrl2 = '/sfc/servlet.shepherd/version/download/' + versionId;
        }

        if (booking.Quote__r.Super_Built_UpArea__c != null) {
            plotAreaInSqareMeters = String.valueOf(
                (booking.Quote__r.Super_Built_UpArea__c * 0.092903)
                .setScale(2, System.RoundingMode.HALF_UP)
            );
        }

        if (booking.Booking_Amount__c != null) {
            bookingAmount = NumberToWords.numberToWords(booking.Booking_Amount__c.intValue());
        }

        textLines = (booking.Notes_and_Comments__c != null)
            ? booking.Notes_and_Comments__c.split('\r\n')
            : new List<String>();

        // Fetch Co-Applicant details
        List<Co_Applicant__c> coApplicants = [
            SELECT Name, Salutation__c, Date_of_Birth__c, Spouse_Date_Of_Birth_coapp__c,Spouse_Name__c,
                   Permanent_Address__c, Communication_Address__c, Pincode_office__c,Other_Qualification__c,
                   Qualification__c, Pincode_commmunication__c, Pincode_permanent__c,Other_Industry__c,
                   Office_Address__c, Anniverssary_Date__c, Son_Daughter_Wife_of__c,
                   Nationality__c, Co_Applicant__c.Aadhar_Number__c, Alternate_Contact_No__c,Country_of_Residence__c,
                   Passport_Number__c, PAN_Number__c, Email__c, Primary_Phone__c,Office_Pincode__c,
                   Residential_Status__c, Profession__c, Industry__c, Employeed_at__c, Designation__c,Communication_Address1__Street__s,
            Communication_Address1__City__s,Communication_Address1__CountryCode__s,Communication_Address1__PostalCode__s,Communication_Address1__StateCode__s,
            Permanent_Address1__Street__s,Permanent_Address1__City__s,Permanent_Address1__CountryCode__s,Permanent_Address1__PostalCode__s,Permanent_Address1__StateCode__s,
            Office_Address1__Street__s,Office_Address1__City__s,Office_Address1__CountryCode__s,Office_Address1__PostalCode__s,Office_Address1__StateCode__s
            FROM Co_Applicant__c
            WHERE Booking__c = :bookingId
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        if (!coApplicants.isEmpty()) {
            firstCoApplicant = coApplicants[0];
            
        codobFormattedWithBars = formatDateWithBars(coApplicants[0].Date_of_Birth__c);
        cospouseDobFormattedWithBars = formatDateWithBars(coApplicants[0].Spouse_Date_Of_Birth_coapp__c);
        coanniversaryFormattedWithBars = formatDateWithBars(coApplicants[0].Anniverssary_Date__c);
        }

        // Fetch applicant Aadhar photo
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :bookingId
            AND ContentDocument.FileExtension IN ('jpg', 'jpeg', 'png')
            AND ContentDocument.Title LIKE '%Applicant Aadhar Card%'
            LIMIT 1
        ];

        if (!docLinks.isEmpty()) {
            Id versionId = docLinks[0].ContentDocument.LatestPublishedVersionId;
            imagepicUrl = '/sfc/servlet.shepherd/version/download/' + versionId;
        }

        // Format date fields with bars
        dobFormattedWithBars = formatDateWithBars(booking.Date_of_Birth1__c);
        spouseDobFormattedWithBars = formatDateWithBars(booking.Spouse_Date_Of_Birth__c);
        anniversaryFormattedWithBars = formatDateWithBars(booking.Anniverssary_Date1__c);
       //For Co applicant
      
    }

    // 🔹 Helper Method to Format Date with Bars (DDMMYYYY)
    private String formatDateWithBars(Date inputDate) {
        if (inputDate == null) return '';
        String day = String.valueOf(inputDate.day());
        if (day.length() == 1) day = '0' + day;
        String month = String.valueOf(inputDate.month());
        if (month.length() == 1) month = '0' + month;
        String year = String.valueOf(inputDate.year());

        String ddmmyyyy = day + month + year;
        List<String> chars = new List<String>();
        for (Integer i = 0; i < ddmmyyyy.length(); i++) {
            chars.add(ddmmyyyy.substring(i, i + 1));
        }
        return String.join(chars, '|');
    }

    // Load all Booking addresses once
    private void loadBookingAddresses() {
        if (bookingAddressesLoaded) return;
        
        Booking__c b = [
            SELECT Permanent_Address2__c,
            Correspondence_Address__c,
            Office_Address1__c
            FROM Booking__c
            WHERE Id = :booking.Id
            LIMIT 1
        ];
        
        permanentAddress      = b.Permanent_Address2__c;
        correspondenceAddress = b.Correspondence_Address__c;
        officeAddress         = b.Office_Address1__c;
        
        bookingAddressesLoaded = true;
    }
    
    // Load all first Co-Applicant addresses once
    private void loadFirstCoApplicantAddresses() {
        if (firstCoApplicantAddressesLoaded) return;
        
        // Ensure firstCoApplicant is properly queried
        if (firstCoApplicant != null) {
            // Query the firstCoApplicant object to retrieve addresses
            firstCoApplicant = [
                SELECT Permanent_Address1__c,
                Communication_Address1__c,
                Office_Address1__c
                FROM Co_Applicant__c
                WHERE Id = :firstCoApplicant.Id
                LIMIT 1
            ];
            
            // Assign addresses
            firstCoApplicantPermanentAddress     = (Address) firstCoApplicant.Permanent_Address1__c;
            firstCoApplicantCommunicationAddress = (Address) firstCoApplicant.Communication_Address1__c;
            firstCoApplicantOfficeAddress        = (Address) firstCoApplicant.Office_Address1__c;
        }
        
        firstCoApplicantAddressesLoaded = true;
    }
    
   // ======================
// Generic helpers
// ======================
private String getStateFromAddress(Address addr) {
    if (addr == null) return '';
    String stateName = addr.state;
    return String.isBlank(stateName) ? '' : stateName;
}

private String getCountryFromAddress(Address addr) {
    if (addr == null) return '';
    String countryName = addr.country;
    return String.isBlank(countryName) ? '' : countryName;
}

// Build "Street, City, State, Country" but skip blanks and commas for null parts
private String formatAddress(Address addr) {
    if (addr == null) return '';
    
    List<String> parts = new List<String>();
    
    if (!String.isBlank(addr.street))  parts.add(addr.street);
    if (!String.isBlank(addr.city))    parts.add(addr.city);
    if (!String.isBlank(addr.state))   parts.add(addr.state);
    if (!String.isBlank(addr.country)) parts.add(addr.country);
    
    return String.join(parts, ', ');
}

    // ======================
    // Booking – full addresses
    // ======================
    public String getPermanentFullAddress() {
        loadBookingAddresses();            // you already have this
        return formatAddress(permanentAddress);
    }
    
    public String getCorrespondenceFullAddress() {
        loadBookingAddresses();
        return formatAddress(correspondenceAddress);
    }
    
    public String getOfficeFullAddress() {
        loadBookingAddresses();
        return formatAddress(officeAddress);
    }
    
    // ======================
    // firstCoApplicant – full addresses
    // ======================
    public String getFirstCoApplicantPermanentFullAddress() {
        loadFirstCoApplicantAddresses();
        return formatAddress(firstCoApplicantPermanentAddress);
    }
    
    public String getFirstCoApplicantCommunicationFullAddress() {
        loadFirstCoApplicantAddresses();
        return formatAddress(firstCoApplicantCommunicationAddress);
    }
    
    public String getFirstCoApplicantOfficeFullAddress() {
        loadFirstCoApplicantAddresses();
        return formatAddress(firstCoApplicantOfficeAddress);
    }

    
    // ======================
    // Booking – Permanent
    // ======================
    public String getPermanentStateName() {
        loadBookingAddresses();
        return getStateFromAddress(permanentAddress);
    }
    
    public String getPermanentCountryName() {
        loadBookingAddresses();
        return getCountryFromAddress(permanentAddress);
    }
    
    // ======================
    // Booking – Correspondence
    // ======================
    public String getCorrespondenceStateName() {
        loadBookingAddresses();
        return getStateFromAddress(correspondenceAddress);
    }
    
    public String getCorrespondenceCountryName() {
        loadBookingAddresses();
        return getCountryFromAddress(correspondenceAddress);
    }
    
    // ======================
    // Booking – Office
    // ======================
    public String getOfficeStateName() {
        loadBookingAddresses();
        return getStateFromAddress(officeAddress);
    }
    
    public String getOfficeCountryName() {
        loadBookingAddresses();
        return getCountryFromAddress(officeAddress);
    }
    
    // ======================
    // firstCoApplicant – Permanent
    // ======================
    public String getFirstCoApplicantPermanentStateName() {
        loadFirstCoApplicantAddresses();
        return getStateFromAddress(firstCoApplicantPermanentAddress);
    }
    
    public String getFirstCoApplicantPermanentCountryName() {
        loadFirstCoApplicantAddresses();
        return getCountryFromAddress(firstCoApplicantPermanentAddress);
    }
    
    // ======================
    // firstCoApplicant – Communication
    // ======================
    public String getFirstCoApplicantCommunicationStateName() {
        loadFirstCoApplicantAddresses();
        return getStateFromAddress(firstCoApplicantCommunicationAddress);
    }
    
    public String getFirstCoApplicantCommunicationCountryName() {
        loadFirstCoApplicantAddresses();
        return getCountryFromAddress(firstCoApplicantCommunicationAddress);
    }
    
    // ======================
    // firstCoApplicant – Office
    // ======================
    public String getFirstCoApplicantOfficeStateName() {
        loadFirstCoApplicantAddresses();
        return getStateFromAddress(firstCoApplicantOfficeAddress);
    }
    
    public String getFirstCoApplicantOfficeCountryName() {
        loadFirstCoApplicantAddresses();
        return getCountryFromAddress(firstCoApplicantOfficeAddress);
    }

    @AuraEnabled
    public static String sendEmailtoCustomer(String recId) {
        Booking__c bk = [SELECT Id, Project__c, Email__c FROM Booking__c WHERE Id = :recId];

        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();

        OrgWideEmailAddress[] owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'communication@crm.zuariproperties.com'];
        if (owea.size() > 0) {
            semail.setOrgWideEmailAddressId(owea[0].Id);
        }
        PageReference pref = Page.BookingFormZGC;
        pref.getParameters().put('id', recId);
        pref.setRedirect(true);

        Blob b;
        Boolean isTest = System.Test.isRunningTest();
        b = isTest ? Blob.valueOf('Unit.Test') : pref.getContent();

        attach.setFileName('Zuari_BookingForm.pdf');
        attach.setBody(b);
        semail.setSubject('Zuari Booking Form');

        List<String> sendTo = new List<String>();
        if (bk.Email__c != null) sendTo.add(bk.Email__c);

        semail.setToAddresses(sendTo);
        semail.setHtmlBody(
            'Dear Sir/Madam,<br/><br/>' +
            'Thank you very much for your interest in ' + bk.Project__c + '.<br/><br/>' +
            'Please find the attached booking form.<br/><b>Note:</b> This is a sample booking form purely for reference.<br/><br/>' +
            'Please feel free to contact us for any clarification.<br/><br/>Best Regards,<br/>Zuari'
        );
        semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});

        if (!sendTo.isEmpty()) {
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
                return 'Booking form sent to customer';
            } catch (Exception e) {
                System.debug('Error sending email: ' + e.getMessage());
                return 'Error: ' + e.getMessage();
            }
        } else {
            return 'Please enter email address';
        }
        
    }
}