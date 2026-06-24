public without sharing class ReportSummaryPdfService implements Queueable{
    private List<Id> reportsummaryId;
    
    public ReportSummaryPdfService(List<Id> demandIds) {
        this.reportsummaryId = demandIds;
    }

    public void execute(QueueableContext context) {
        //PublicPdfGenerator.generatePublicSummaryPdf(reportsummaryId);
    }


   
}