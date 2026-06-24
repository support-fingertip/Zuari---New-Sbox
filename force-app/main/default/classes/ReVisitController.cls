public class ReVisitController {
    @AuraEnabled
    public static void updateLastNote(String SVId, String newNote, DateTime RSVDate) {
        Datetime dt = Datetime.now();
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        String strTimeInAMorPM = RSVDate.format('MMMMM dd, yyyy hh:mm:ss a');
        
        Integer noteCount = 1;
        Site_Visit__c SVRecord = [SELECT Id, Revisit_Count__c,Revisit_Details__c,Reschedule_Date__c,Status__c,Reschedule_Reason__c FROM Site_Visit__c WHERE Id =:SVId LIMIT 1];
        User us = [select id,name from User where id =: userInfo.getUserId()];

        if (SVRecord.Revisit_Details__c == null) {
            SVRecord.Revisit_Details__c = '';
        }
        else if (!SVRecord.Revisit_Details__c.trim().equals('')) {
            List<String> notes = SVRecord.Revisit_Details__c.split('\n');
            noteCount = notes.size() + 1;
        }
        SVRecord.Revisit_Details__c += '\nRe-Visit ' + noteCount + ': (' + strTimeInAMorPM + ') :      ' + newNote;
        SVRecord.Reschedule_Date__c=RSVDate;
        SVRecord.Reschedule_Reason__c=newNote;
        SVRecord.Status__c='Rescheduled';
        SVRecord.Revisit_Count__c+=1;
        update SVRecord;
    }

}