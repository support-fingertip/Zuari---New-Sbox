@isTest
public class manulaSharingClassTest {
    @isTest
    public static void sendOTO(){
          Profile pr = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User salesUser = new User(
            FirstName = 'Sales',
            LastName = 'Receiver',
            Email = 'salesreceiver@test.com',
            Username = 'salesreceiver' + System.currentTimeMillis() + '@test.com',
            Alias = 'srx',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = pr.Id
        );
        insert salesUser;

        List<Lead> leadList = new List<Lead>();
        Lead ld11 = new Lead();
        ld11.LastName='Test lead';
        ld11.Lead_Assigned__c=true;
        ld11.Allocated_Project__c='Zuari Garden City';
        ld11.Reassigned_By__c=UserInfo.getUserId();
        ld11.Re_assigned_date__c = system.now();
        ld11.Lead_Status__c='New';
        ld11.Email='patil@gmail.com';
        ld11.Source_Type__c='Digital Marketing';
        ld11.Lead_source__c ='Website';
        ld11.Phone__c='9898767998';
        ld11.Company='test';
        leadList.add(ld11);
        insert leadList;
        
        
        Lead ld = new Lead();
        ld.LastName = 'Test Lead';
        ld.Allocated_Project__c='Zuari Garden City';
        ld.Country__c='India';
        ld.Phone__c='6362536253';
        ld.Company='Test';
        ld.Email='test@gmail.com';
        ld.OwnerId = UserInfo.getUserId();
        insert ld;
                Map<String, Id> rtMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Related_Source__c']) {
            rtMap.put(rt.Name, rt.Id);
        }
List<Related_Source__c> rlist = new List<Related_Source__c>();
        
         Related_Source__c rs1 = new Related_Source__c(
                RecordTypeId = rtMap.get('Pre Sales'),
            SLead__c       = ld.Id,
             STM2__c =salesUser.id,
             Pre_Sales_user__c=salesUser.id,
                Source_Type__c = 'Digital Marketing',
                Lead_status1__c = 'Pre-Sales New Enquiry'
            );
        rlist.add(rs1);
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Active__c = true;
        pjt.Finance_User__c = UserInfo.getUserId();
        insert pjt;
        
        
        
        Project__c p = new Project__c();
        p.Name='Zuari Garden City';
        p.Active__c=true;
        p.Project__c='Zuari Garden City';
        insert p;
        
        plot__c ut = new Plot__c();
        ut.Name='Test Unit';
        ut.Project__c=p.id;
        insert ut;
        
        Quote__c Qt = new Quote__c();
        Qt.Quote_status__c = 'Approved';
        Qt.SLead__c = ld.id;
        Qt.Project__c = 'Zuari Garden City';
        Qt.Unit__c = ut.id;
        Qt.Payment_Type__c = 'Standard';
        insert Qt;
        
       /* Payment_schedule__c ps=new Payment_schedule__c();
        ps.Name='installment';
        ps.Payment_percent__c=9.5;
        ps.Amount__c=50000.00;
        ps.S_No__c=20.00;
        ps.status__c='Scheduled';
        ps.Quote__c=Qt.Id;
        insert ps;
      */  
       // Booking__c b = new Booking__c();
       // b.SLead__c=ld.Id;
       // b.Quote__c = Qt.Id;
       // b.Project1__c=p.Id;
       // b.Project__c='Neopolis14';
       // b.Applicant_Name__c='TEst';
        //b.Email_id__c='test@gmail.com';
        //b.Email__c='test1@gmail.com';
       // b.Date_of_Booking__c= system.today();
       // b.First_Applicant_Name__c='chethan';
       // b.Sales_Manager__c = userInfo.getUserId();
       // b.Sales_User__c = userInfo.getUserId();
       // insert b;
        
        List<Booking__c> bookList = new List<Booking__c>();
        //bookList.add(b);
        Map<Id,Id> leadMap = new Map<Id,Id>();
        leadMap.put(ld11.id,ld11.Reassigned_By__c); 
        
        manulaSharingClass.manualShareSiteVisit(leadMap);
        manulaSharingClass.manualShareLeadVisit(leadMap);
        manulaSharingClass.shareAnyRecord(leadList,'Edit');
        manulaSharingClass.shareAnyRecordPreSales(leadList,'Read');
        manulaSharingClass.checkShared(leadList);
        manulaSharingClass.shareWithPreSalesUser(rlist);
        manulaSharingClass.shareWithSalesUser(rlist);
        
    }
    @isTest
    public static void testBookingsToShare_WithSalesUser(){
        
        Lead ld = new Lead();
        ld.LastName = 'Booking Test Lead';
        ld.Allocated_Project__c = 'Zuari Garden City';
        ld.Phone__c = '9876543210';
        ld.Company = 'Test Company';
        ld.Email = 'booklead@gmail.com';
        ld.OwnerId = UserInfo.getUserId();
        insert ld;
        
        Project__c p = new Project__c();
        p.Name = 'Zuari Garden City';
        p.Active__c = true;
        p.Project__c = 'Zuari Garden City';
        insert p;
        
        Plot__c ut = new Plot__c();
        ut.Name = 'Test Plot';
        ut.Project__c = p.Id;
        insert ut;
        
        Quote__c qt = new Quote__c();
        qt.Quote_status__c = 'Approved';
        qt.SLead__c = ld.Id;
        qt.Project__c = 'Zuari Garden City';
        qt.Unit__c = ut.Id;
        qt.Payment_Type__c = 'Standard';
        insert qt;
        
        Booking__c b = new Booking__c();
        b.SLead__c = ld.Id;
        b.Quote__c = qt.Id;
        b.Project1__c = p.Id;
        b.Project__c = 'Zuari Garden City';
        b.Applicant_Name__c = 'Test Applicant';
       // b.Email_id__c = 'test@gmail.com';
       // b.Date_of_Booking__c = System.today();
        b.First_Applicant_Name__c = 'Test First';
       // b.Sales_Manager__c = UserInfo.getUserId();
        b.Sales_User__c = UserInfo.getUserId();
        insert b;
        
        Test.startTest();
        List<Booking__c> bookingsList = [SELECT Id, Sales_User__c FROM Booking__c WHERE Id = :b.Id];
        manulaSharingClass.bookingsToShare(bookingsList);
        Test.stopTest();
    }
    
    
}