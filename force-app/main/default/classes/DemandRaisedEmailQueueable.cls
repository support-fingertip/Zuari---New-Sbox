public class DemandRaisedEmailQueueable implements Queueable {

    private List<Id> demandIds;

    public DemandRaisedEmailQueueable(List<Id> demandIds) {
        this.demandIds = demandIds;
    }

    public void execute(QueueableContext context) {
        DemandRaisedHelper.sendDemandEmailLogic(demandIds);
    }
}