trigger BookingFileTrigger on ContentDocumentLink (after insert) {
    System.debug('He');
    // Collect ContentDocumentIds
    Set<Id> docIds = new Set<Id>();
    for (ContentDocumentLink link : Trigger.new) {
        docIds.add(link.ContentDocumentId);
    }
    
    // Query document titles
    Map<Id, ContentDocument> docMap = new Map<Id, ContentDocument>(
        [SELECT Id, Title FROM ContentDocument WHERE Id IN :docIds]
    );
    
    List<Booking__c> updates = new List<Booking__c>();
    /*
    for (ContentDocumentLink link : Trigger.new) {
        if (link.LinkedEntityId.getSObjectType() == Booking__c.SObjectType) {
            ContentDocument doc = docMap.get(link.ContentDocumentId);
            
            if (doc != null) {
                Booking__c booking = new Booking__c(Id = link.LinkedEntityId);
                
                String title = doc.Title != null ? doc.Title.trim().toLowerCase() : '';
                
                if (title == 'sale agreement') {
                    booking.Sale_Agreement_Sent__c = true;
                }
                else if (title == 'sale deed') {
                    booking.Sale_Deed_Uploaded__c = true;
                }
                else if (title == 'maintenance agreement' || title == 'Maintenanace Letter') {
                 
                    booking.Maintenance_Agreement_Uploaded__c = 'Yes';
                }
                
                updates.add(booking);
            }
        }
    }
    
    if (!updates.isEmpty()) {
        update updates;
    }
    */
}