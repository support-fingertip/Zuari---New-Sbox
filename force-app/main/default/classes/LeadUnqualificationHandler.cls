/**
 * Class Name   : LeadUnqualificationHandler
 * Description  : Updates Related_Source__c only when
 *                the latest Lead_Unqualification__c is newer
 * Author       : Sandeep
 * Created Date : 21-Jan-2026
 */
public class LeadUnqualificationHandler {

    public static void mapToRelatedSource(List<Lead_Unqualification__c> records) {

        if (records == null || records.isEmpty()) return;

        Map<Id, Lead_Unqualification__c> rsToLUMap = new Map<Id, Lead_Unqualification__c>();

        for (Lead_Unqualification__c lu : records) {
            if (lu.Related_Source__c != null && lu.Unqualified_At__c != null) {
                rsToLUMap.put(lu.Related_Source__c, lu);
            }
        }

        if (rsToLUMap.isEmpty()) return;

        List<Related_Source__c> rsToUpdate = new List<Related_Source__c>();

        for (Related_Source__c rs : [
            SELECT Id, Last_Unqualified_Date__c, Unqualified_Reason1__c
            FROM Related_Source__c
            WHERE Id IN :rsToLUMap.keySet()
        ]) {

            Lead_Unqualification__c lu = rsToLUMap.get(rs.Id);

            // CRITICAL COMPARISON
            if (
                rs.Last_Unqualified_Date__c == null ||
                lu.Unqualified_At__c > rs.Last_Unqualified_Date__c
            ) {
                rs.Last_Unqualified_Date__c = lu.Unqualified_At__c;
                rs.Unqualified_Reason1__c   = lu.Unqualified_Reason__c;
                rsToUpdate.add(rs);
            }
        }

        if (!rsToUpdate.isEmpty()) {
            update rsToUpdate;
        }
    }
}