trigger ReportSummaryTrigger on Report_Summary__c (after insert) {

    
    Set<Id> rpsid = new Set<Id>();
    
    for (Report_Summary__c rs : Trigger.new) {
        rpsid.add(rs.Id);
       // ReportSummaryPdfService.generatePdf(rs.Id);
    }
    
      if (!rpsid.isEmpty()) {
    System.enqueueJob(new ReportSummaryPdfService(new List<Id>(rpsid)));
      }
}