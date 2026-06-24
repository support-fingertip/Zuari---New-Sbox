public without sharing class AddNoteController {
    
    @AuraEnabled
    public static void updateLastNote(String leadId, String newNote) {
        Lead leadRecord = [SELECT Id, Last_Note__c,Execuive_Count__c FROM Lead WHERE Id = :leadId LIMIT 1];
        User us = [select id,name from User where id =: userInfo.getUserId()];
        Datetime dt = Datetime.now();
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        //dt = dt.addSeconds(tz.getOffset(dt)/1000);
       // String strTimeInAMorPM = dt.format('MMMMM dd, yyyy hh:mm a');
           String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a');

        Integer noteCount = 1;
        if (leadRecord.Last_Note__c == null) {
            leadRecord.Last_Note__c = '';
        } else if (!leadRecord.Last_Note__c.trim().equals('')) {
            List<String> notes = leadRecord.Last_Note__c.split('\n');
            noteCount = notes.size() + 1;
        }
        leadRecord.Execuive_Count__c = noteCount;
       // leadRecord.Last_Note__c += '\nNote ' + noteCount +' : ('+us.Name+')' + ' - (' + strTimeInAMorPM + ') :      '+newNote  ;
       leadRecord.Last_Note__c += '\nCall Summary ' + noteCount + ': ' + us.Name + ' [' + strTimeInAMorPM + ']: ' + newNote;
   
        update leadRecord;
    }
    
    @AuraEnabled
    public static void updateTLRHSNote(String leadId, String newNote) {
        Lead leadRecord = [SELECT Id, TL_RHS_Review__c,TL_RHS_Count__c FROM Lead WHERE Id = :leadId LIMIT 1];
        User us = [select id,name from User where id =: userInfo.getUserId()];
        Datetime dt = Datetime.now();
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        //dt = dt.addSeconds(tz.getOffset(dt)/1000);
       // String strTimeInAMorPM = dt.format('MMMMM dd, yyyy hh:mm a');
           String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a');

        Integer noteCount = 1;
        if (leadRecord.TL_RHS_Review__c == null) {
            leadRecord.TL_RHS_Review__c = '';
        } else if (!leadRecord.TL_RHS_Review__c.trim().equals('')) {
            List<String> notes = leadRecord.TL_RHS_Review__c.split('\n');
            noteCount = notes.size() + 1;
        }
       leadRecord.TL_RHS_Count__c = noteCount;
       // leadRecord.Last_Note__c += '\nNote ' + noteCount +' : ('+us.Name+')' + ' - (' + strTimeInAMorPM + ') :      '+newNote  ;
       leadRecord.TL_RHS_Review__c += '\nTL/RHS Comment ' + noteCount + ': ' + us.Name + ' [' + strTimeInAMorPM + ']: ' + newNote;
   
        update leadRecord;
    }
    
    
    @AuraEnabled
    public static List<String> fetchLeadLastNotes(String leadId) {
        Lead leadRecord = [SELECT Id, Last_Note__c FROM Lead WHERE Id = :leadId LIMIT 1];
        List<String> lastNotes = new List<String>();
        
        if (leadRecord != null && leadRecord.Last_Note__c != null) {
            lastNotes = leadRecord.Last_Note__c.split('\n');
            
            // Filter out empty strings or null values
            List<String> filteredNotes = new List<String>();
            for (String note : lastNotes) {
                if (note != null && note != '') {
                    filteredNotes.add(note);
                }
            }
            
            lastNotes = filteredNotes;
             // Reverse the list to get notes in descending order
        List<String> reversedNotes = new List<String>();
        for (Integer i = lastNotes.size() - 1; i >= 0; i--) {
            reversedNotes.add(lastNotes[i]);
        }
            lastNotes = reversedNotes;

        }
        
        return lastNotes;
    }


}