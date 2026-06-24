public class SalesAgreementController {
    public Booking__c booking { get; set; }
    public String bookingId {get; set;}
    public String agreementDay{get; set;} 
    public String agreementMonth{get; set;} 
    public string agreementYearWords{get; set;}
    public List<Co_Applicant__c> coapplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public String formattedAgreementDate { get; set; }
    public String agreementDayOrdinal  { get; set; }
    public String applicantDetailsFormatted { get; set; }
    public string bookingAmountInWords { get; set; }
    public List<Payment_schedule__c> paymentSchedules { get; set; }
    public String grandTotalWords { get; set; }
    public string formattedBookingAmount { get; set; }
    public string formattedGrandTotal { get; set; }
    public String plotImageBase64 { get; set; }
    public String applicantNamesAndAddressFormatted { get; set; }
    public Integer applicantage{get;set;}
    public Integer coapplicantage{get;set;}
    
    public String applicantAadhaar { get; set; }
    public String coapplicantAadhaar { get; set; }
    
    private Boolean bookingAddressesLoaded = false;
    private Address permanentAddress;
    public SalesAgreementController(ApexPages.StandardController controller){
        bookingId = ApexPages.currentPage().getparameters().get('id');
        if(String.isNotBlank(bookingId)){
            fetchBookingDetails();
            fetchPlotImage();
        }
        
    }
    public void  fetchBookingDetails(){
        booking = [Select Id,
                   First_Applicant_Name__c,
                   Agreement_Execution_Date__c,
                   S__c,
                   Son_Daughter_Wife_of1__c,
                   PAN_Number__c,
                   Agreement_Executed_Date__c,
                   Aadhar_No__c,
                   Address__c,
                   Date_of_Birth1__c,
                   Son_Daughter_Wife_of__c,
                   Booking_Amount__c,
                   GRAND_TOTAL__c,
                   Agreement_Value_Before_GST__c,
                   Permanent_Address1__c,
                   Correspondence_Address__Street__s,
                   Correspondence_Address__City__s,
                   Correspondence_Address__PostalCode__s,
                   Correspondence_Address__StateCode__s,
                   Pincode1__c,
                   Permanent_Address2__c,
                   Plot__c
                   
                   
                   From Booking__c Where Id=:bookingId];
        coapplicants=[
            SELECT Name, Salutation__c, Date_of_Birth__c, Spouse_Date_Of_Birth_coapp__c,Spouse_Name__c,
            Permanent_Address__c, Communication_Address__c, Pincode_office__c,Other_Qualification__c,
            Qualification__c, Pincode_commmunication__c, Pincode_permanent__c,Other_Industry__c,
            Office_Address__c, Anniverssary_Date__c, Son_Daughter_Wife_of__c,Son2_Daughter_Wife_of__c,
            Nationality__c, Co_Applicant__c.Aadhar_Number__c, Alternate_Contact_No__c,Country_of_Residence__c,
            Passport_Number__c, PAN_Number__c, Email__c, Primary_Phone__c,Office_Pincode__c,
            Residential_Status__c, Profession__c, Industry__c, Employeed_at__c, Designation__c,Communication_Address1__Street__s,
            Communication_Address1__City__s,Communication_Address1__CountryCode__s,Communication_Address1__PostalCode__s,Communication_Address1__StateCode__s,
            Permanent_Address1__Street__s,Permanent_Address1__City__s,Permanent_Address1__CountryCode__s,Permanent_Address1__PostalCode__s,Permanent_Address1__StateCode__s,
            Office_Address1__Street__s,Office_Address1__City__s,Office_Address1__CountryCode__s,Office_Address1__PostalCode__s,Office_Address1__StateCode__s
            FROM Co_Applicant__c WHERE Booking__c = :bookingId  ];
        
        permanentAddress      = booking.Permanent_Address2__c;
        if (!coapplicants.isEmpty()) {
            firstCoApplicant = coapplicants[0];
        }
        paymentSchedules = [Select Id, Name,Payment_percent__c,S_No__c,Total_Payable_Amount__c from Payment_schedule__c Where Booking__c =: bookingId  ];
        
        List<String> lines = new List<String>();
        ///Formatting amount
        NumberTOWordConvertion nwcObj = new NumberTOWordConvertion();
        formattedBookingAmount = formatIndianCurrency(booking.Booking_Amount__c);
        formattedGrandTotal = formatIndianCurrency(booking.Agreement_Value_Before_GST__c);
        
        applicantAadhaar =formatAadhaar(booking.Aadhar_No__c) ;
        // Primary applicant
        String primary = '';
        primary += '<b>'+(String.isNotBlank(booking.S__c) ? booking.S__c + ' ' : '') + booking.First_Applicant_Name__c+'</b>';
        if (booking.Date_of_Birth1__c != null) {
            Integer age = calculateAge(booking.Date_of_Birth1__c);
            applicantage= calculateAge(booking.Date_of_Birth1__c);
            primary += ', aged about ' + age + ' years';
        }
        if ( String.isNotBlank(booking.Son_Daughter_Wife_of__c) && String.isNotBlank(booking.Son_Daughter_Wife_of1__c)) {
            primary += ', ' + ' ' + booking.Son_Daughter_Wife_of__c +' '+ booking.Son_Daughter_Wife_of1__c;
        }
        primary += '<br/>';
        if (String.isNotBlank(booking.Aadhar_No__c)) {
            primary += '<b>(Aadhaar No. ' + formatAadhaar(booking.Aadhar_No__c) + ')</b> ';
        }
        if (String.isNotBlank(booking.PAN_Number__c)) {
            primary += '<b>(PAN No: ' + booking.PAN_Number__c + ')</b>';
        }
        
        lines.add(primary);
        
        // Co-applicant
        for (Co_Applicant__c co : coapplicants) {
            String coLine = '';
            coLine += '<b>'+ (String.isNotBlank(co.Salutation__c) ? co.Salutation__c + ' ' : '') + co.Name+'</b>';
            
            if (co.Date_of_Birth__c != null) {
                Integer age = calculateAge(co.Date_of_Birth__c);
                coapplicantage= calculateAge(co.Date_of_Birth__c);
                
                coLine += ', aged about ' + age + ' years';
            }
            
            if (!String.isBlank(co.Son2_Daughter_Wife_of__c) && !String.isBlank(co.Son_Daughter_Wife_of__c)) {
                coLine += ', ' + co.Son2_Daughter_Wife_of__c +' '+ co.Son_Daughter_Wife_of__c;
            }
            
            
            coLine += '<br/>';
            if (!String.isBlank(co.Aadhar_Number__c)) {
                coLine += '<b>(Aadhaar No. ' + formatAadhaar(co.Aadhar_Number__c) + ')</b> ';
                coapplicantAadhaar=formatAadhaar(co.Aadhar_Number__c);
            }
            if (!String.isBlank(co.PAN_Number__c)) {
                coLine += '<b>(PAN No: ' + co.PAN_Number__c + ')</b>';
            }
            
            lines.add(coLine);
        }
        
        // Combine both sections with &
        applicantDetailsFormatted = String.join(lines, '<br/>&<br/>');
        
        //Fetching Allotte details
        
        List<String> nameLines = new List<String>();
        
        // Primary applicant
        String primaryName = (String.isNotBlank(booking.S__c) ? booking.S__c + ' ' : '') + booking.First_Applicant_Name__c;
        nameLines.add(primaryName);
        
        // If there are co-applicants, add '&' and list them
        if (!coapplicants.isEmpty()) {
            nameLines[nameLines.size() - 1] += ' &'; // add & to end of primary line
            for (Co_Applicant__c co : coapplicants) {
                String coName = (String.isNotBlank(co.Salutation__c) ? co.Salutation__c + ' ' : '') + co.Name;
                nameLines.add(coName);
            }
        }
        
        // Add fixed "Resident at:" line
        nameLines.add('Resident at:');
        
        // Add the address with manual line breaks
        String fullAddress = booking.Permanent_Address1__c;
        String pincode = booking.Pincode1__c;
        
        // Ensure we preserve line breaks (split on newline)
        if (!String.isBlank(fullAddress)) {
            List<String> addressLines = fullAddress.split('\n');
            nameLines.addAll(addressLines);
        }
        
        if (!String.isBlank(pincode)) {
            nameLines.add(booking.Pincode1__c + '.');
        }
        
        // Join lines with <br/> to be rendered correctly in PDF
        applicantNamesAndAddressFormatted = String.join(nameLines, '<br/>');
        
        
        
        
        
        
        
        
        
        
        
        if(booking.Agreement_Executed_Date__c !=null){
            
            Date agreementExecutedDate = booking.Agreement_Executed_Date__c;
            agreementDay = String.valueOf(agreementExecutedDate.Day());
            DateTime agreementDateTime = DateTime.newInstance(agreementExecutedDate, Time.newInstance(0, 0, 0, 0));
            agreementMonth = agreementDateTime.format('MMMM', 'en_US');
            
            Integer day = agreementExecutedDate.day();
            //Getting ordinal Day
            agreementDayOrdinal = getOrdinal(day);
            
            Integer month = agreementExecutedDate.month();
            Integer year1 = agreementExecutedDate.year();
            
            String dayStr = (day < 10 ? '0' + String.valueOf(day) : String.valueOf(day));
            String monthStr = (month < 10 ? '0' + String.valueOf(month) : String.valueOf(month));
            String yearStr = String.valueOf(year1);
            formattedAgreementDate = dayStr + '/' + monthStr + '/' + yearStr;
            
            // Getting Last two digits of year
            Integer year = agreementExecutedDate.year();
            Integer lastTwoDigits = Math.mod(year, 100);
            
            // Convert to words
            agreementYearWords = new NumberToWords().numberToWords(lastTwoDigits);
        }
        bookingAmountInWords = new NumberToWords().numberToWords(booking.Booking_Amount__c.intValue());
        grandTotalWords = nwcObj.getNumberTOWordConvertion(booking.Agreement_Value_Before_GST__c);
        
        // agreementYearWords = numberToWords(lastTwoDigits); 
        
        
        
    }
    public class NumberToWords {
        
        public String numberToWords(Integer num) {
            if (num == 0) return 'Zero Only';
            
            return convert(num).trim() + ' Only';
        }
        
        private  String convert(Integer num) {
            List<String> ones = new List<String>{
                'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
                    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
                    'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
                    };
                        
                        List<String> tens = new List<String>{
                            '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
                                };
                                    
                                    String result = '';
            
            if (num >= 10000000) { // Crores
                result += convert(num / 10000000) + ' Crore ';
                num = Math.mod(num, 10000000);
            }
            
            if (num >= 100000) { // Lakhs
                result += convert(num / 100000) + ' Lakh ';
                num = Math.mod(num, 100000);
            }
            
            if (num >= 1000) { // Thousands
                result += convert(num / 1000) + ' Thousand ';
                num = Math.mod(num, 1000);
            }
            
            if (num >= 100) { // Hundreds
                result += ones[num / 100] + ' Hundred ';
                num = Math.mod(num, 100);
            }
            
            if (num > 0) {
                if (!result.endsWith(' ') && result != '') {
                    result += 'and ';
                }
                
                if (num < 20) {
                    result += ones[num];
                } else {
                    result += tens[num / 10];
                    if (Math.mod(num, 10) > 0) {
                        result += ' ' + ones[Math.mod(num, 10)];
                    }
                }
            }
            
            return result;
        }
    }
    
    /////////////GettingOrdinal////
    public String getOrdinal(Integer num) {
        if (num >= 11 && num <= 13) {
            return num + 'th';
        }
        Integer lastDigit = Math.mod(num, 10);
        switch on lastDigit {
            when 1 { return num + 'st'; }
            when 2 { return num + 'nd'; }
            when 3 { return num + 'rd'; }
            when else { return num + 'th'; }
        }
    }
    //////////formating Aadhar////////
    public String formatAadhaar(String aadhaar) {
        if (String.isBlank(aadhaar)) return '';
        aadhaar = aadhaar.replaceAll('[^0-9]', '');
        if (aadhaar.length() != 12) return aadhaar;
        return aadhaar.substring(0, 4) + ' ' + aadhaar.substring(4, 8) + ' ' + aadhaar.substring(8, 12);
    }
    //////////Calculating age/////
    public Integer calculateAge(Date dob) {
        Date today = Date.today();
        Integer age = today.year() - dob.year();
        if (today.month() < dob.month() || (today.month() == dob.month() && today.day() < dob.day())) {
            age--;
        }
        return age;
    }
    
    public String formatIndianCurrency(Decimal amount) {
        String numStr = String.valueOf(amount.setScale(0)); // remove decimal
        String result = '';
        Integer len = numStr.length();
        
        if (len <= 3) {
            return numStr;
        }
        
        // Last 3 digits
        result = numStr.substring(len - 3, len);
        
        // Remaining part (left of last 3 digits)
        String rem = numStr.substring(0, len - 3);
        
        // Insert commas after every 2 digits in the remaining part
        while (rem.length() > 2) {
            result = rem.substring(rem.length() - 2, rem.length()) + ',' + result;
            rem = rem.substring(0, rem.length() - 2);
        }
        
        // Append the leftover (1 or 2 digits)
        if (rem.length() > 0) {
            result = rem + ',' + result;
        }
        
        return result;
    }
    ///////////fetching image///////
    
    
    public void fetchPlotImage() {
        Id plotId = booking.Plot__c;
        if (plotId != null) {
            // Get the ContentDocument linked to Plot
            List<ContentDocumentLink> cdlList = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :plotId 
                AND ShareType = 'V' LIMIT 1
            ];
            
            if (!cdlList.isEmpty()) {
                // Get latest ContentVersion of the ContentDocument
                ContentVersion cv = [
                    SELECT Id 
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :cdlList[0].ContentDocumentId 
                    AND IsLatest = true 
                    LIMIT 1
                ];
                
                if (cv != null) {
                    
                    // Convert the binary to base64 string
                    plotImageBase64 = EncodingUtil.base64Encode(cv.VersionData);
                }
            }
        }
    }
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
        
        bookingAddressesLoaded = true;
    }
    public String getPermanentFullAddress() {
        loadBookingAddresses();            // you already have this
        return formatAddress(permanentAddress);
    }
    private String formatAddress(Address addr) {
        if (addr == null) return '';
        
        List<String> parts = new List<String>();
        
        if (!String.isBlank(addr.street))  parts.add(addr.street);
        if (!String.isBlank(addr.city))    parts.add(addr.city);
        if (!String.isBlank(addr.state))   parts.add(addr.state);
        if (!String.isBlank(addr.postalcode))   parts.add(addr.postalcode);
        if (!String.isBlank(addr.country)) parts.add(addr.country);
        
        return String.join(parts, ', ');
    }
    
    
    
}