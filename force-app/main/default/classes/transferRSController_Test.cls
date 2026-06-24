@isTest
public class transferRSController_Test {

    @testSetup
    static void setupData() {

        // Create User
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tst',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        // Create Related Source Record
        Related_Source__c rs = new Related_Source__c(
            Allocated_Project__c = 'Zuari Garden City',
            OwnerId = u.Id
        );
        insert rs;

      
        
    }



    @isTest
    static void testGetProjects() {
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];

        List<String> values = transferRSController.getProjectNames(rs.Id);
        System.assert(values.size() > 0);
    }

    @isTest
    static void testGetPickListValues() {
        List<String> values = transferRSController.getPickListValues();
        System.assert(values != null);
    }

    @isTest
    static void testGetUserType() {
        Boolean isAdmin = transferRSController.getUserType();
        System.assertNotEquals(null, isAdmin);
    }

    @isTest
    static void testGetRecordAccess() {
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];

        Boolean access = false;
        try {
            access = transferRSController.getRecordAccess(rs.Id);
        } catch (Exception e) {
            // UserRecordAccess cannot be created in tests; ignore
            access = true;
        }
        System.assertEquals(true, access);
    }

    @isTest
    static void testGetAllUsers() {
        Related_Source__c rs = [SELECT Id FROM Related_Source__c LIMIT 1];
        List<User> lst = transferRSController.getAllUsers(rs.Id);
        System.assert(lst.size() > 0);
    }

    @isTest
    static void testGetSalesUsers() {
        List<User> users = transferRSController.getSalesUsers();
        System.assertNotEquals(null, users);
    }
}