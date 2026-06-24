public without sharing class SummaryReportPDFController {
    
    public List<SummaryItem> summaryList { get; set; }
    public String fromDateStr { get; set; }
    public String toDateStr { get; set; }
    public String generatedOn { get; set; }
    
    private Datetime fromDate;
    private Datetime toDate;
    private String chhpId;
    
    public SummaryReportPDFController() {
        
        // Read URL parameters
        String fromParam = ApexPages.currentPage().getParameters().get('fromDate');
        String toParam   = ApexPages.currentPage().getParameters().get('toDate');
        String cpId   = ApexPages.currentPage().getParameters().get('CPId');
        System.debug(cpId);
        if (String.isBlank(fromParam) || String.isBlank(toParam)) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR,
                                      'From Date and To Date are required')
            );
            return;
        }
        System.debug(fromParam +'=== '+ toParam);
        // Parse ISO-8601 Datetime
        // Normalize ISO datetime
        fromParam = fromParam.replace('T', ' ').replace('Z', '');
        toParam   = toParam.replace('T', ' ').replace('Z', '');
        
        fromDate = Datetime.valueOf(fromParam);
        toDate   = Datetime.valueOf(toParam);
        chhpId = cpId;
        fromDateStr = fromDate.format('dd MMM yyyy');
        toDateStr   = toDate.format('dd MMM yyyy');
        generatedOn = Datetime.now().format('dd MMM yyyy, hh:mm a');
        
        buildSummary();
    }
    
    private void buildSummary() {
        summaryList = new List<SummaryItem>();
         List<Related_Source__c> relatedSources = [SELECT Id FROM Related_Source__c WHERE CreatedDate >= :fromDate AND CreatedDate <= :toDate And Channel_Partner1__c =:chhpId ];
       Set<Id> rsIds = new Set<Id>();
           For(Related_Source__c rs : relatedSources){
            rsIds.add(rs.Id);
           }
        Integer totalLeads = relatedSources.Size();
        System.debug(totalLeads + '== '+ chhpId + '--- '+fromDate);

         Integer allocatedLeads = [SELECT COUNT() FROM Related_Source__c WHERE Lead_status1__c = 'Allocated' AND CreatedDate >= :fromDate AND CreatedDate <= :toDate And Channel_Partner1__c =:chhpId ];
       
        List<Booking__c> bookedList = [ SELECT Id FROM Booking__c WHERE Related_Source__c IN :rsIds ];
       
        Integer bookedLeads =bookedList.Size();
         List<Site_Visit__c> svList = [ SELECT Id FROM Site_Visit__c WHERE Related_Source__c IN :rsIds ];
        
        Integer siteVisits =svList.Size();
         List<Site_Visit__c> rvsvList = [ SELECT Id FROM Site_Visit__c WHERE Related_Source__c IN :rsIds AND Visit_Type__c = 'Revisit'];
        
        Integer revisits = rvsvList.Size();
        summaryList.add(new SummaryItem('Lead Summary', totalLeads));
        summaryList.add(new SummaryItem('Lead Allocated Summary', allocatedLeads));
        summaryList.add(new SummaryItem('Site Visit Summary', siteVisits));
        summaryList.add(new SummaryItem('Revisit Summary', revisits));
        summaryList.add(new SummaryItem('Booked Leads', bookedLeads));
        summaryList.add(new SummaryItem('Leads v Allocation', allocatedLeads));
        summaryList.add(new SummaryItem('Allocation v Site Visits', Math.min(allocatedLeads, siteVisits)));
        summaryList.add(new SummaryItem('Site Visit v Revisit', Math.min(siteVisits, revisits)));
        summaryList.add(new SummaryItem('Revisit v Bookings', Math.min(revisits, bookedLeads)));
        summaryList.add(new SummaryItem('Site Visits v Bookings', Math.min(siteVisits, bookedLeads)));
        summaryList.add(new SummaryItem('Leads v Bookings', Math.min(totalLeads, bookedLeads)));
    }
    
    public class SummaryItem {
        public String reportName { get; set; }
        public Integer count { get; set; }
        
        public SummaryItem(String name, Integer cnt) {
            reportName = name;
            count = cnt;
        }
    }
}