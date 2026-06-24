public class PublicPdfGenerator {
    
    public static String generatePublicSummaryPdf(Datetime fromDate,Datetime toDate,String CPId) {
        String pdfurl;
        
        
        PageReference pdfPage = Page.SummaryReportPDF;
        pdfPage.getParameters().put('fromDate',fromDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        pdfPage.getParameters().put('toDate',toDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        pdfPage.getParameters().put('CPId',CPId);
        
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }
        
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Summary_Report_' + Datetime.now().getTime();
        cv.PathOnClient = 'Summary_Report.pdf';
        cv.VersionData = pdfBlob;
        insert cv;
        
        cv = [SELECT Id FROM ContentVersion  WHERE Id = :cv.Id];
        
        List<ContentDistribution> existing = [ SELECT Id, DistributionPublicUrl,ContentDownloadUrl  FROM ContentDistribution  WHERE ContentVersionId = :cv.Id ORDER BY CreatedDate DESC LIMIT 1];
        
        if (!existing.isEmpty()) {
             
            pdfurl =existing[0].ContentDownloadUrl;
            // return existing[0].ContentDownloadUrl;
        }
        /*else{
            
        ContentDistribution dist = new ContentDistribution();
        dist.Name = 'Summary Report PDF';
        dist.ContentVersionId = cv.Id;
        dist.PreferencesAllowViewInBrowser = true;
        dist.PreferencesAllowOriginalDownload = true;
        dist.PreferencesLinkLatestVersion = true;
        insert dist;
        
        // 7️⃣ Fetch URL
        dist = [ SELECT DistributionPublicUrl FROM ContentDistribution  WHERE Id = :dist.Id ];
        
        pdfurl = dist.DistributionPublicUrl;
       
            
        }
        */
        return pdfurl;
    }
}