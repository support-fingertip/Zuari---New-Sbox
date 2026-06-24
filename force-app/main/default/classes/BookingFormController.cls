public with sharing class BookingFormController {
    @AuraEnabled
    public Booking__c booking { get; set; }
    public String imageUrl { get; set; }

    public BookingFormController( ApexPages.StandardController controller) {
        Id bookingId = ApexPages.currentPage().getParameters().get('id');
        if (bookingId != null) {
            booking = [SELECT Id,Notes_and_Comments__c, Plot__r.Name, Plot__r.Block_Lookup__r.Name   FROM Booking__c WHERE Id = :bookingId LIMIT 1];

            // Fetch first image (JPG/PNG) linked to this booking
           // List<ContentDocumentLink> links = [SELECT ContentDocument.LatestPublishedVersionId   FROM ContentDocumentLink    WHERE LinkedEntityId = :bookingId  LIMIT 1 ];
  List<ContentDocumentLink> links = [SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title   FROM ContentDocumentLink   WHERE LinkedEntityId = :bookingId AND ContentDocument.FileExtension IN ('jpg','jpeg','png')   AND ContentDocument.Title LIKE '%Applicant Passport Size Photo%' limit 1 ];
        
            if (!links.isEmpty()) {
                Id versionId = links[0].ContentDocument.LatestPublishedVersionId;
                imageUrl = '/sfc/servlet.shepherd/version/download/' + versionId;
            }
        }
    }
}