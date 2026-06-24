/**
 * Shared test-data factory for the Lead Expiry test suite. Centralises object
 * construction so each test class can stay focused on its own assertions.
 *
 * Used by:
 *   - RelatedSourceLeadExpirySchedulerTest
 *   - Batch_RelatedSourceLeadExpiryTest
 *   - RelatedSourceLeadExpiryServiceTest
 *   - LeadExtensionControllerTest
 */
@isTest
public class LeadExpiryTestDataFactory {

    public static Channel_Partner__c createChannelPartner(String name) {
        Channel_Partner__c cp = new Channel_Partner__c(
            Name    = name,
            Email__c = (name + '@cp.test.example.com').toLowerCase().replaceAll(' ', '')
        );
        if (Schema.sObjectType.Channel_Partner__c.fields.getMap().containsKey('Active__c')) {
            cp.put('Active__c', true);
        }
        insert cp;
        return cp;
    }

    public static Lead createLead(String lastName) {
        Lead l = new Lead(
            LastName = lastName,
            Company  = lastName + ' Co'
        );
        insert l;
        return l;
    }

    /**
     * Inserts a CP Related Source and backdates its CreatedDate so it can
     * fall inside / outside the 30 / 45-day expiry windows.
     */
    public static Related_Source__c createRelatedSource(
        Id leadId, Id cpId, Integer createdDaysAgo, String leadStatus
    ) {
        
         SiteVisitTriggerHandler.bypassTrigger = true; //Added By Siddaling On 09/06/2026
         RelatedSourceHandler.bypassTrigger = true;  //Added By Siddaling On 09/06/2026
        
        Related_Source__c rs = new Related_Source__c(
            SLead__c            = leadId,
            Channel_Partner1__c = cpId,
            Source_Type__c      = 'Channel partner', Allocated_Project__c = 'Zuari Gangothri Tribhuja',
            Is_Locked__c        = false,
            Lead_status1__c     = (leadStatus == null) ? 'New' : leadStatus,
            Lead_Expired__c     = false
        );
        insert rs;
        if (createdDaysAgo != null && createdDaysAgo > 0) {
            Test.setCreatedDate(rs.Id, System.now().addDays(-createdDaysAgo));
        }
        return rs;
    }

    public static Site_Visit__c createSiteVisit(
        Id leadId, Id rsId, String status, Integer createdDaysAgo
    ) {
        Site_Visit__c sv = new Site_Visit__c(
            SLead__c                  = leadId,
            Related_Source__c         = rsId,
            Source_Type__c            = 'Channel partner',
            Status__c                 = status,
            SV_Completed_Date_Time__c = (status == 'Completed') ? System.now().addDays(-createdDaysAgo) : null,
            OTP__c                    = '0000'
        );
        insert sv;
        if (createdDaysAgo != null && createdDaysAgo > 0) {
            Test.setCreatedDate(sv.Id, System.now().addDays(-createdDaysAgo));
        }
        return sv;
    }

    /**
     * Creates a Booking__c skeleton. Booking has many required lookups in
     * the real schema but for the expiry batch only Related_Source__c is
     * read - so we insert with that lookup alone and rely on best-effort
     * DML. If the org enforces other required fields the caller can catch.
     */
    public static Booking__c createBooking(Id rsId) {
        Booking__c b = new Booking__c(
            Related_Source__c = rsId
        );
        Database.SaveResult sr = Database.insert(b, false);
        // Return whatever we got - tests that need the Id can check sr.isSuccess()
        return b;
    }

    /**
     * Creates and inserts a Standard User. Used as the lead owner, RM,
     * approver, etc. in the extension flow.
     *
     * Wrapped in System.runAs(currentUser) to avoid MIXED_DML_OPERATION when
     * the same test method later updates non-setup objects like
     * Related_Source__c.
     */
    public static User createUser(String alias, Id managerId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniq = String.valueOf(DateTime.now().getTime()) +
                      String.valueOf(Math.abs(Crypto.getRandomInteger()));
        User u = new User(
            Alias             = alias.left(8),
            Email             = alias + '@expiry.test.example.com',
            EmailEncodingKey  = 'UTF-8',
            LastName          = alias,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey      = 'en_US',
            ProfileId         = p.Id,
            TimeZoneSidKey    = 'America/Los_Angeles',
            Username          = alias + uniq + '@expiry.test.example.com',
            ManagerId         = managerId
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert u;
        }
        return u;
    }
}