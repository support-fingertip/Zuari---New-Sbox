public class PushToCrmController {
    
    @AuraEnabled
    public static Decimal moveToCRMPreCheck(String bookingId){
        //List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:bookingId];
        return 0;
        
    }
    
    /*    @AuraEnabled
public static String moveToCRM(String bookingId){
try {

Booking__c bk = [SELECT Id, Name,CRM_Manager__c, Push_To_CRM__c,Push_To_CRM_Date__c,OwnerId, Status__c, Assigned_by__c, Project__c,Quote__r.OwnerId,Aadhaar_Uploded__c FROM Booking__c WHERE Id = :bookingId];
List<Booking__c> bklist = new List<Booking__c>();
bklist.add(bk);

if(bk != null && bk.Project__c != null) {
Project__c prj = [SELECT Id, Name, Project__c,CRM_executive__c	 FROM Project__c WHERE Project__c = :bk.Project__c];
//bk.Stage__c = 'Booked';
bk.Assigned_by__c = UserInfo.getUserId();
bk.Push_To_CRM_Date__c = System.Now();
bk.Push_To_CRM__c = true;
String bookingOwner = returnCRMUser(bklist);
bk.OwnerId =bookingOwner;
bk.CRM_executive__c = bookingOwner;
// bk.OwnerId = bk.CRM_Manager__c; 
update bk;
system.debug(prj.CRM_executive__c);
ListView lw = [SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE SobjectType = 'Booking__c' AND DeveloperName = 'Today_s_Bookings' LIMIT 1];
return lw.Name;

}
}
catch (QueryException e) {
System.debug('Query Exception occurred: ' + e.getMessage());
} 
return null; 
}*/
    @AuraEnabled
    public static String moveToCRM(String bookingId) {
        try {
            Booking__c bk = [
                SELECT Id, Name, CRM_Manager__c, Push_To_CRM__c, Push_To_CRM_Date__c, OwnerId,
                Status__c, Assigned_by__c, Project__c, Quote__r.OwnerId, Aadhaar_Uploded__c,
                Booking_Form_Signature_Uploaded__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];
            
            // Block if signature not uploaded
            if (bk.Booking_Form_Signature_Uploaded__c != true) {
                throw new AuraHandledException('Please upload Booking Signature.');
            }
            
            if (bk.Project__c == null) {
                throw new AuraHandledException('Project is missing on this Booking.');
            }
            
            // (You can keep this query if you really need it)
            Project__c prj = [
                SELECT Id, Name, Project__c, CRM_executive__c
                FROM Project__c
                WHERE Project__c = :bk.Project__c
                LIMIT 1
            ];
            
            List<Booking__c> bklist = new List<Booking__c>{ bk };
                
                bk.Assigned_by__c = UserInfo.getUserId();
            bk.Push_To_CRM_Date__c = System.now();
            bk.Push_To_CRM__c = true;
            
            String bookingOwner = returnCRMUser(bklist);
            bk.OwnerId = bookingOwner;
            bk.CRM_executive__c = bookingOwner;
            
            update bk;
            
            ListView lw = [
                SELECT Id, Name
                FROM ListView
                WHERE SobjectType = 'Booking__c'
                AND DeveloperName = 'Today_s_Bookings'
                LIMIT 1
            ];
            
            return lw.Name; // ✅ always returns here when successful
            
        } catch (AuraHandledException e) {
            // keep your custom message
            throw e;
            
        } catch (Exception e) {
            // show real error to Aura
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    public static String returnCRMUser(List<Booking__c> booklist){
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true and User_Type__c='CRM'  order by Last_Assigned_time_user__c,createddate asc nulls first limit 1) from Round_Robin__c where Project_Assigned__c != NULL and Active__c = true and Lead_Source_Type__c = null];
        system.debug(RRAvaliablequeList);
        Map<String,Round_Robin__c> MapRobin = new Map<String,Round_Robin__c>();
        for(Round_Robin__c rb : RRAvaliablequeList){
            
            MapRobin.put(rb.Project_Assigned__c,rb);
        }
        system.debug(MapRobin);
        List<User> userlist = new List<User>();
        String bkuser;
        for(Booking__c bb : booklist){
            Round_Robin__c rr = MapRobin.get(bb.Project__c);
            system.debug(rr);
            system.debug(!rr.Round_Robin_Members__r.isEmpty());
            system.debug(rr.Round_Robin_Members__r);
            if (rr != null && rr.Round_Robin_Members__r != null && !rr.Round_Robin_Members__r.isEmpty()) {
                //  bb.OwnerId = rr.Round_Robin_Members__r[0].User__c;
                system.debug('Inside for');
                bkuser=rr.Round_Robin_Members__r[0].User__c;
                
                User newuser = new User();
                newuser.id = rr.Round_Robin_Members__r[0].User__c;
                newuser.LastAssignmentTime1__c = system.now().getTime();
                userlist.add(newuser);
            }
        }
        if(userlist.size()>0){
            update userlist;
        }
        system.debug(bkuser);
        return bkuser;
    }
    
}