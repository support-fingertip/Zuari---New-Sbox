public without sharing class CustomerQueryUserStampQueueable implements Queueable {

    private Set<Id> userIds;

    public CustomerQueryUserStampQueueable(Set<Id> userIds) {
        this.userIds = userIds;
    }

    public void execute(QueueableContext context) {
        stampNow(this.userIds);
    }

    public static void stampNow(Set<Id> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return;
        }
        DateTime now = System.now();
        List<User> toUpdate = new List<User>();
        for (Id uid : userIds) {
            toUpdate.add(new User(Id = uid, Last_Query_Assigned_Time__c = now));
        }
        update toUpdate;
    }
}