@IsTest
private class PublicPdfGeneratorTest {

    @IsTest
    static void testGeneratePublicSummaryPdf() {
        // 1. Setup minimal required data
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Partner',
            Active__c = true,
            Email__c = 'test@example.com' // Ensuring required fields are met
        );
        insert cp;

        // 2. Set up date parameters
        Datetime fDate = System.now().addDays(-7);
        Datetime tDate = System.now();
         String fromDt = Datetime.now().addDays(-1).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String toDt = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
       

        // 3. Call the method to trigger code execution (Coverage)
        Test.startTest();
         PageReference pageRef = Page.SummaryReportPDF; 
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('fromDate', fromDt);
        ApexPages.currentPage().getParameters().put('toDate', toDt);
        ApexPages.currentPage().getParameters().put('CPId', cp.Id);
       
        PublicPdfGenerator.generatePublicSummaryPdf(fDate, tDate, cp.Id);
         PublicPdfGenerator.generatePublicSummaryPdf(fDate, tDate, cp.Id);
       
        Test.stopTest();
    }
}