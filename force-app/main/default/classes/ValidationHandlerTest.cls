@isTest(SeeAllData=true)
public class ValidationHandlerTest {
		
     Public static testmethod void method(){
        Profile profile = [SELECT Id FROM Profile WHERE Name='Pre Sales'];
        User testUser = new User(
            FirstName = 'Test123',
            LastName = 'User',
            Email = 'testuser@gmail.com',
            Username = 'testuse2r@fingertip23.com',
            ProfileId = profile.Id,
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
         
         Lead ld11 = new Lead();
            ld11.LastName='Test lead';
            ld11.Lead_Assigned__c=true;

            ld11.Allocated_Project__c='Zuari Garden City';
            ld11.Reassigned_By__c=UserInfo.getUserId();
            ld11.Re_assigned_date__c = system.now();
            // ld11.Lead_status__c='New';
            ld11.Source_Type__c='Digital Marketing';
            ld11.Lead_source__c ='Website';
            ld11.Phone__c='9898767998';
            ld11.Secondary_Phone__c='8763748300';
            ld11.Company='test';
        //    ld11.Master_Lead__c=msl.id;
         ld11.OwnerId=UserInfo.getUserId();
            insert ld11;
            
         // Follow_up__c fp1=new Follow_up__c();
           // fp1.SLead__c=ld11.Id;
            //fp1.Scheduled_Date__c=Datetime.now().addDays(1);
            //fp1.Status__c='Scheduled';
            //insert fp1;
            Site_Visit__c s1 = new Site_Visit__c();
            s1.SLead__c=ld11.Id;
            s1.Date__c = Datetime.now().addDays(1);
            s1.Project__c='Zuari Garden City';
            s1.Date__c=System.today()+1;
            s1.Status__c='Scheduled';
            insert s1;
           
         
       /*  Call_Detail__c cd = new Call_Detail__c();
         cd.Lead__c=ld11.id;
         insert cd;*/
         List<Lead> ldlst= new List<Lead>();
         ldlst.add(ld11);
         
         
         ValidationHandler.CheckScheduleSiteVist(ldlst);
         

         
       //  ValidationHandler.CheckCallDetail(ldlst);
        
         try{      
        // ValidationHandler.createSiteVisit(ldlst);
         }catch(DmlException e){
             system.debug('error');
         }
         
         
     }
}