public without sharing class ChannelPartnerCountHelper {

    public static void updateLeadCount(Set<Id> channelPartnerIds) {
        Map<Id, Integer> countMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Channel_Partner1__c cpId, COUNT(Id) cnt
            FROM Related_Source__c
            WHERE Channel_Partner1__c IN :channelPartnerIds
            GROUP BY Channel_Partner1__c
        ]) {
            countMap.put((Id) ar.get('cpId'), (Integer) ar.get('cnt'));
        }

        List<Channel_Partner__c> toUpdate = new List<Channel_Partner__c>();
        for (Id cpId : channelPartnerIds) {
            toUpdate.add(new Channel_Partner__c(
                Id = cpId,
                No_of_Leads__c = countMap.containsKey(cpId) ? countMap.get(cpId) : 0
            ));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public static void updateCompletedSiteVisitCount(Set<Id> channelPartnerIds) {
        Map<Id, Integer> countMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Related_Source__r.Channel_Partner1__c cpId, COUNT(Id) cnt
            FROM Site_Visit__c
            WHERE Related_Source__r.Channel_Partner1__c IN :channelPartnerIds AND Status__c = 'Completed'
            GROUP BY Related_Source__r.Channel_Partner1__c
        ]) {
            countMap.put((Id) ar.get('cpId'), (Integer) ar.get('cnt'));
        }

        List<Channel_Partner__c> toUpdate = new List<Channel_Partner__c>();
        for (Id cpId : channelPartnerIds) {
            toUpdate.add(new Channel_Partner__c(
                Id = cpId,
                No_of_Completed_Site_Visit__c = countMap.containsKey(cpId) ? countMap.get(cpId) : 0
            ));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    /**
     * On Related Source insert, stamp the Channel Partner's
     * First Lead Captured Date/Time (only if currently null) and refresh
     * Last Lead Captured Date/Time using each related source's CreatedDate.
     */
    public static void updateLeadCapturedDates(List<Related_Source__c> newList) {
        Map<Id, Datetime> cpLatestCapture = new Map<Id, Datetime>();

        for (Related_Source__c rs : newList) {
            if (rs.Channel_Partner1__c == null) continue;

            Datetime capturedAt = rs.CreatedDate != null ? rs.CreatedDate : Datetime.now();
            Datetime existing = cpLatestCapture.get(rs.Channel_Partner1__c);
            if (existing == null || capturedAt > existing) {
                cpLatestCapture.put(rs.Channel_Partner1__c, capturedAt);
            }
        }

        if (cpLatestCapture.isEmpty()) return;

        Map<Id, Channel_Partner__c> cpMap = new Map<Id, Channel_Partner__c>([
            SELECT Id, First_Lead_Captured_Date_Time__c, Last_Lead_Captured_Date_Time__c
            FROM Channel_Partner__c
            WHERE Id IN :cpLatestCapture.keySet()
        ]);

        List<Channel_Partner__c> toUpdate = new List<Channel_Partner__c>();
        for (Id cpId : cpLatestCapture.keySet()) {
            Channel_Partner__c cp = cpMap.get(cpId);
            if (cp == null) continue;

            Datetime capturedAt = cpLatestCapture.get(cpId);
            Boolean changed = false;

            if (cp.First_Lead_Captured_Date_Time__c == null) {
                cp.First_Lead_Captured_Date_Time__c = capturedAt;
                changed = true;
            }

            if (cp.Last_Lead_Captured_Date_Time__c == null || capturedAt > cp.Last_Lead_Captured_Date_Time__c) {
                cp.Last_Lead_Captured_Date_Time__c = capturedAt;
                changed = true;
            }

            if (changed) toUpdate.add(cp);
        }

        if (!toUpdate.isEmpty()) update toUpdate;
    }

    public static void updateBookingCount(Set<Id> channelPartnerIds) {
        Map<Id, Integer> countMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Channel_Partner__c cpId, COUNT(Id) cnt
            FROM Booking__c
            WHERE Channel_Partner__c IN :channelPartnerIds
            GROUP BY Channel_Partner__c
        ]) {
            countMap.put((Id) ar.get('cpId'), (Integer) ar.get('cnt'));
        }

        List<Channel_Partner__c> toUpdate = new List<Channel_Partner__c>();
        for (Id cpId : channelPartnerIds) {
            toUpdate.add(new Channel_Partner__c(
                Id = cpId,
                No_of_Booking__c = countMap.containsKey(cpId) ? countMap.get(cpId) : 0
            ));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}