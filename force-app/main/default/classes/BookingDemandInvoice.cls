public with sharing class BookingDemandInvoice {
    public Booking__c booking { get; set; }
    public List<Co_Applicant__c> coApplicants { get; set; }
    public String demandName{ get; set; }
    public decimal taxableValue{ get; set; }
    public decimal totalvalue{ get; set; }
    public decimal cgstvalue{ get; set; }
    
    public decimal sgstvalue{ get; set; }
    public decimal cgst{get;set;}
    public decimal sgst{get;set;}

    public BookingDemandInvoice(ApexPages.StandardController stdCtrl) {
        booking = (Booking__c) stdCtrl.getRecord();
        System.debug(booking);
        coApplicants = new List<Co_Applicant__c>();
      
        
        List<Booking__c> bookingList = [ SELECT Id,Project1__c,Project1__r.GST_on_Aggrement__c, Name, Applicant_Name__c, First_Applicant_Name__c, Mobile__c, Email__c, Address__c, Permanent_Address__c, Project__c, Project1__r.Name, Flat_no__c, Unit_No__c, GRAND_TOTAL__c, Booking_Date__c, Application_Amount__c, Booking_Amount__c, Total__c, Total_received_Amount__c, Pending_Amount__c, PAN_Number__c, Aadhar_No__c FROM Booking__c WHERE Id = :booking.Id LIMIT 1 ];


        if (!bookingList.isEmpty()) {
            booking = bookingList[0];
        }
        System.debug(bookingList);
        coApplicants = [ SELECT Id, Name, PAN_Number__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id ];
        Demand_Raised__c dr = [select id,Name,Amount_Demanded__c from Demand_Raised__c where Booking__c =: booking.Id];
        system.debug(dr);
        demandName = dr.Name;
        taxableValue = dr.Amount_Demanded__c;
        cgstvalue=dr.Amount_Demanded__c *bookingList[0].Project1__r.GST_on_Aggrement__c;
        sgstvalue=dr.Amount_Demanded__c *bookingList[0].Project1__r.GST_on_Aggrement__c;
        cgst=bookingList[0].Project1__r.GST_on_Aggrement__c/2;
         sgst=bookingList[0].Project1__r.GST_on_Aggrement__c/2;              
    }
    
}