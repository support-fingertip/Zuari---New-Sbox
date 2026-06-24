public class CoApplicantController {
    public Id bookingId { get; set; }
    public List<Co_Applicant__c> coApplicants { get; set; }

    public CoApplicantController(ApexPages.StandardController stdController) {
        bookingId = stdController.getId();

        coApplicants = [
            SELECT Name
            FROM Co_Applicant__c
            WHERE Booking__c = :bookingId
        ];
    }
}