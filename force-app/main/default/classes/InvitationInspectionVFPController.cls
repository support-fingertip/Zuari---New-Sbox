public class InvitationInspectionVFPController {
    public Id bookingId { get; set; }
    public String plotName { get; set; }

    public InvitationInspectionVFPController(ApexPages.StandardController stdController) {
        bookingId = stdController.getId();

        Booking__c bookingRecord = [
            SELECT Plot__r.Name
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];

        plotName = bookingRecord.Plot__r != null ? bookingRecord.Plot__r.Name : null;
    }
}