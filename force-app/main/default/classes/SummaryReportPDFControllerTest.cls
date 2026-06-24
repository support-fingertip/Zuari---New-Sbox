@isTest
public class SummaryReportPDFControllerTest {
    
    @TestSetup
    static void makeTestData() {
        // 1. Project & Related Setup 
        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City', 
            Active__c = true
        );
        insert pjt;
        
        Block__c bc = new Block__c(
            Name = 'A',
            Project__c = pjt.Id
        );
        insert bc;
        
        Plot__c ut = new Plot__c(
            Name = 'Test Plot',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;
        
        // Quote - Linking dynamically to the Project created above
        Quote__c qc = new Quote__c(
            Block_Lookup__c = bc.Id,
            Quote_status__c = 'Converted',
            Project__c = pjt.Project__c, // Dynamic assignment
            Unit__c = ut.Id
        );
        insert qc;
        
        // 2. Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(
            Name = 'Test Partner',
            Email__c ='test@gmail.com'
        );
        insert cp;
        
        // 3. Related Source
        Related_Source__c rs = new Related_Source__c(
            Channel_Partner1__c = cp.Id,
            Lead_status1__c = 'Allocated'
        );
        insert rs;
        
        // 4. Site Visits - One normal, one 'Revisit' to cover the controller filter
        insert new List<Site_Visit__c>{
            new Site_Visit__c(Related_Source__c = rs.Id, Visit_Type__c = 'Site Visit'),
            new Site_Visit__c(Related_Source__c = rs.Id, Visit_Type__c = 'Home visit') 
        };
        
        // 5. Booking
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            Related_Source__c = rs.Id,
            CRM_Manager__c = UserInfo.getUserId()
        );
        insert book;
    }
    
    @isTest
    static void testSummaryReportSuccess() {
        Channel_Partner__c cp = [SELECT Id FROM Channel_Partner__c LIMIT 1];
        
        // Dynamic ISO Date strings
        String fromDt = Datetime.now().addDays(-1).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String toDt = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        Test.startTest();
        PageReference pageRef = Page.SummaryReportPDF; 
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('fromDate', fromDt);
        ApexPages.currentPage().getParameters().put('toDate', toDt);
        ApexPages.currentPage().getParameters().put('CPId', cp.Id);
        
        SummaryReportPDFController controller = new SummaryReportPDFController();
        Test.stopTest();
        
    }

}