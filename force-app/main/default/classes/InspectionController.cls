public without sharing class InspectionController{
    
    @AuraEnabled
    public static String saveInspectionWithSnags( String bookingId,  Date inspectionDate,   String inspectionDescription,  String snagListJson) {
        try {
            // Validate Booking exists
            if (String.isBlank(bookingId)) {
                throw new AuraHandledException('Booking ID is required');
            }
            
            // Verify booking exists
            List<Booking__c> bookings = [SELECT Id,Project1__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            if (bookings.isEmpty()) {
                throw new AuraHandledException('Booking not found');
            }
            Project__c prj = [select id,Inspection_Executive__c from Project__c Where id =: bookings[0].Project1__c];
            
            // Create Inspection record
            Inspection__c inspection = new Inspection__c();
            inspection.Booking__c = bookingId;
            inspection.Inspection_Date__c = inspectionDate;
            inspection.Description__c = inspectionDescription;
            inspection.OwnerId = prj.Inspection_Executive__c;
            insert inspection;
            System.debug('Inspection created with ID: ' + inspection.Id);
            
            // Parse snag list JSON
            List<Object> snagDataList = (List<Object>) JSON.deserializeUntyped(snagListJson);
            
            List<String> snagIds = new List<String>();
            
            // Create Snag List records
            if (snagDataList != null && !snagDataList.isEmpty()) {
                List<Snag_List__c> snags = new List<Snag_List__c>();
                
                for (Integer i = 0; i < snagDataList.size(); i++) {
                    Map<String, Object> snagData = (Map<String, Object>) snagDataList[i];
                    
                    Snag_List__c snag = new Snag_List__c();
                    snag.Inspection__c = inspection.Id;
                    snag.Description__c = (String) snagData.get('Description__c');
                    snag.Status__c = (String) snagData.get('Status__c');
                    snag.Priority__c = (String) snagData.get('Priority__c');
                    snag.Inspection_Type__c = (String) snagData.get('Inspection_Type__c');
                    snags.add(snag);
                }
                
                insert snags;
                
                System.debug('Created ' + snags.size() + ' snag records');
                
                // Get the IDs of created snags
                for (Snag_List__c snag : snags) {
                    snagIds.add(snag.Id);
                    System.debug('Snag ID: ' + snag.Id);
                }
            }
            
            // Return inspection ID and snag IDs
            Map<String, Object> result = new Map<String, Object>();
            result.put('inspectionId', inspection.Id);
            result.put('snagIds', snagIds);
            
            System.debug('Returning result: ' + JSON.serialize(result));
            
            return JSON.serialize(result);
            
        } catch (Exception e) {
            System.debug('Error in saveInspectionWithSnags: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving inspection: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String uploadFileToSnag(String snagId, String fileName, String base64Data, String contentType) {
        try {
            System.debug('Starting file upload');
            System.debug('Snag ID: ' + snagId);
            System.debug('File Name: ' + fileName);
            System.debug('Content Type: ' + contentType);
            
            // Validate inputs
            if (String.isBlank(snagId)) {
                throw new AuraHandledException('Snag ID is required');
            }
            
            if (String.isBlank(fileName)) {
                throw new AuraHandledException('File name is required');
            }
            
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('File data is required');
            }
            
            // Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            
            insert cv;
            
            System.debug('ContentVersion created with ID: ' + cv.Id);
            
            // Get ContentDocumentId
            ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            Id contentDocumentId = insertedCV.ContentDocumentId;
            
            System.debug('ContentDocument ID: ' + contentDocumentId);
            
            // Create ContentDocumentLink to link file to Snag record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = snagId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            
            insert cdl;
            
            System.debug('ContentDocumentLink created with ID: ' + cdl.Id);
            System.debug('File successfully linked to Snag: ' + snagId);
            
            return 'Success';
            
        } catch (Exception e) {
            System.debug('Error in uploadFileToSnag: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static String requestSwapApproval(Id bookingId, Date reason) {
        Inspection__c bk = [SELECT Id,Extended_Completed_Date__c,OwnerId FROM Inspection__c WHERE Id = :bookingId];
        
        // Mark swap request
        bk.Extended_Completed_Date__c=reason;
        update bk;
        List<Snag_List__c> snglist = [select id,Expected_Completed_Date__c from Snag_List__c where Inspection__c	=: bookingId];
        List<Snag_List__c> updatelist = new List<Snag_List__c>();
        
        for(Snag_List__c sg : snglist){
            sg.Expected_Completed_Date__c = reason;
            updatelist.add(sg);
        }
        if(!updatelist.IsEmpty()){
            update updatelist;
        }
        
        User currentUser = [SELECT Id, Manager.Id FROM User WHERE Id = :UserInfo.getUserId()];
        system.debug('Owner Id'+userInfo.getUserId());
        system.debug('Manager Id'+currentUser.Manager.Id);
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(bk.Id);
        req.setSubmitterId(UserInfo.getUserId()); 
        req.setProcessDefinitionNameOrId('Inspection_Extended_Date_Approval_new'); // Ensure this process exists
        
        
        Approval.ProcessResult res = Approval.process(req);
        return res.getInstanceId(); 
    }
    
}