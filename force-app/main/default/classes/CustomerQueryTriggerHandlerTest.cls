@isTest
public class CustomerQueryTriggerHandlerTest {

    @testSetup
    static void setupData() {

        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9876543210',
            Email__c = 'handlertest_customer@example.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'Handler Test Customer'
        );
        insert customer;

        Project__c proj = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Project_Address__c = '123 Test Street'
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'Plot-HND-1',
            Status__c = 'Available',
            Project__c = proj.Id,
            BHK_Type__c = '2BHK',
            Carpet_Area__c = 1000
        );
        insert plot;

        Lead testLead = new Lead(
            FirstName = 'Hnd',
            LastName = 'Lead',
            Company = 'Test Co',
            Allocated_Project__c = 'Zuari Garden City'
        );
        insert testLead;

        Quote__c quote = new Quote__c(
            SLead__c = testLead.Id,
            Unit__c = plot.Id,
            Project__c = 'Zuari Garden City',
            Quote_date__c = Date.today()
        );
        insert quote;

        Booking__c booking = new Booking__c(
            Quote__c = quote.Id,
            SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City',
            Project1__c = proj.Id,
            Plot__c = plot.Id,
            Stage__c = 'Booked',
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Customer_Master__c = customer.Id,
            Approval_status__c = 'Pending'
        );
        insert booking;
    }

    private static User createUser(String aliasName) {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        Long ts = DateTime.now().getTime();

        return new User(
            FirstName = 'Test',
            LastName = aliasName,
            Alias = aliasName.substring(0,4),
            Email = aliasName + '@test.com',
            Username = aliasName + ts + '@test.com',
            CommunityNickname = aliasName + ts,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
    }

    @isTest
    static void testCustomerQueryHandler_AllCoverage() {

        Customer_Master__c customer =
            [SELECT Id FROM Customer_Master__c LIMIT 1];

        Booking__c booking =
            [SELECT Id FROM Booking__c LIMIT 1];

        User owner1 = createUser('ownA');
        User owner2 = createUser('ownB');

        insert new List<User>{ owner1, owner2 };

        Test.startTest();

        // Insert query with owner
        Customer_Query__c cq = new Customer_Query__c(
            Customer_Master__c = customer.Id,
            Booking__c = booking.Id,
            Subject__c = 'Test Subject',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'Test Description',
            OwnerId = owner1.Id
        );
        insert cq;

        // Owner Change
        cq.OwnerId = owner2.Id;
        update cq;

        // Close Query
        cq.Query_Status__c = 'Closed';
        update cq;

        // Update after close
        cq.Description__c = 'Updated Description';
        update cq;

        // Customer without email
        Customer_Master__c noEmailCustomer =
            new Customer_Master__c(
                Active__c = true,
                Phone_Number__c = '9999999999',
                Password__c = 'Test@123',
                Customer_Name__c = 'No Email Customer'
            );
        insert noEmailCustomer;

        Customer_Query__c cq2 = new Customer_Query__c(
            Customer_Master__c = noEmailCustomer.Id,
            Booking__c = booking.Id,
            Subject__c = 'No Email',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New'
        );
        insert cq2;

        // Customer Master Null
        Customer_Query__c cq3 = new Customer_Query__c(
            Subject__c = 'No Customer',
            Query_Type__c = 'Other Query',
            Query_Status__c = 'New',
            Description__c = 'No Customer Test'
        );
        insert cq3;

        // Bulk Records
        List<Customer_Query__c> bulkQueries =
            new List<Customer_Query__c>();

        for(Integer i=0;i<50;i++) {
            bulkQueries.add(
                new Customer_Query__c(
                    Customer_Master__c = customer.Id,
                    Booking__c = booking.Id,
                    Subject__c = 'Bulk '+i,
                    Query_Type__c = 'Other Query',
                    Query_Status__c = 'New',
                    Description__c = 'Bulk Description'
                )
            );
        }

        insert bulkQueries;

        Test.stopTest();

       // System.assert( [SELECT Count() FROM Customer_Query__c] > 0        );
    }
}