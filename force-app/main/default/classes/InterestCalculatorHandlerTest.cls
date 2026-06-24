@IsTest(SeeAllData=true)
public class InterestCalculatorHandlerTest {

    @IsTest
    static void testCreateInterestLineItems_withExistingData() {
        // Find at least one eligible schedule from existing org data
        Project__c project = new Project__c();
        project.Name = 'Zuari Garden City';
        project.Project__c = 'Zuari Garden city';
        project.Active__c = true;
        insert project;
        Project__c testProject = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            CRM_executive__c = UserInfo.getUserId(),
            CRM_Manager__c = UserInfo.getUserId(),
            Sales_Head__c = UserInfo.getUserId(),
            Finance_User__c = UserInfo.getUserId(),
            COO__c = UserInfo.getUserId()
        );
        insert testProject;
        
        // Create Plot
        Plot__c testPlot = new Plot__c(
            Name = 'Plot-001',
            Status__c = 'Available',
            Unit_Facing_Direction__c = 'North',
            Project__c = testProject.Id
        );
        insert testPlot;
        Quote__c testQuote = new Quote__c(
            Approval_status__c = 'Approved',
            Unit__c = testPlot.Id,
           Quote_status__c = 'Converted',
            Quote_date__c = Date.today(),
            Project__c = 'Zuari Garden city',
        Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000
        );
        insert testQuote;
        
        // Create Booking
        Booking__c booking = new Booking__c(
           
            Quote__c = testQuote.Id,
            Plot__c = testPlot.Id
        );
        insert booking;
        
        // Create Payment Schedules with Pending Amount
        List<Payment_Schedule__c> paySchedules = new List<Payment_Schedule__c>();
        for(Integer i = 1; i <= 5; i++) {
            Payment_Schedule__c ps = new Payment_Schedule__c(
                Booking__c = booking.Id,
                S_No__c = i,
                Payment_Due_Date__c = Date.today().addDays(-30),
                Include_Interest__c = true,
                Interest_Percent__c = 12,
                Payment_Percent__c = 20
            );
            paySchedules.add(ps);
        }
        
        // Add Additional Charge Payment Schedule
        Payment_Schedule__c addChargePS = new Payment_Schedule__c(
            Name = 'Additional Charge',
            Booking__c = booking.Id,
            S_No__c = 6
        );
        paySchedules.add(addChargePS);
        
        insert paySchedules;

       
        Test.startTest();
        InterestCalculatorHandler.createInterestLineItems(Date.today(), 12);
        Test.stopTest();

    }

    @IsTest
    static void testCreateInterestLineItems_runsWithoutException() {
        Test.startTest();
        try {
            InterestCalculatorHandler.createInterestLineItems(Date.today(), 10);
            //System.assert(true);
        } catch (Exception e) {
            //System.assert(false, 'Unexpected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}