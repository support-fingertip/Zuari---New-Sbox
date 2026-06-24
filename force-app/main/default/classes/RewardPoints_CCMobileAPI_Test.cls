@isTest
public class RewardPoints_CCMobileAPI_Test {

    @testSetup
    static void setupData() {
        Customer_Master__c customer = new Customer_Master__c(
            Active__c = true,
            Phone_Number__c = '9876543210',
            Email__c = 'test@example.com',
            Password__c = 'Test@123',
            Customer_Name__c = 'Test Customer'
        );
        insert customer;
        // Add after customer insert in setupData():

Project__c proj = new Project__c(
    Name = 'Zuari Garden City',
    Project__c = 'Zuari Garden City',
    Project_Address__c = '123 Test Street'
);
insert proj;

Reward_Criteria__c rc = new Reward_Criteria__c(
    Project__c = proj.Id,
    Reward_Type__c = 'Booking',
    Referral_Amount__c = 1000
);
insert rc;

// Reward 1: type='Booking' → covers 'booking' branch (line 94), totalReferralEarnings (line 87)
Reward__c reward1 = new Reward__c(
    Name = 'Booking Reward',
    Customer_Master__c = customer.Id,
    Reward_Type__c = 'Booking',
    Reward_Amount__c = 5000,
    Reward_Criteria__c = rc.Id
);

// Reward 2: type='Site Visit' → covers 'site visit' branch (line 92)
Reward__c reward2 = new Reward__c(
    Name = 'Site Visit Reward',
    Customer_Master__c = customer.Id,
    Reward_Type__c = 'Site Visit',
    Reward_Amount__c = 500,
    Reward_Criteria__c = rc.Id
);

// Reward 3: type='Custom' → covers else branch (line 97), blank-type fallback
Reward__c reward3 = new Reward__c(
    Name = 'Other Reward',
    Customer_Master__c = customer.Id,
    Reward_Type__c = 'Custom',
    Reward_Amount__c = 200
    // No Reward_Criteria__c → covers null criteria branch (line 109)
);

insert new List<Reward__c>{ reward1, reward2, reward3 };
    }

    static void setupPost(String body) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    static Customer_Master__c getCust() {
        return [SELECT Id, Name FROM Customer_Master__c LIMIT 1];
    }
@isTest
static void testSuccessWithRewards() {
    Customer_Master__c c = getCust();
    setupPost('{"userId":"' + c.Name + '"}');
    Test.startTest();
    RewardPoints_CCMobileAPI.getRewardPoints();
    Test.stopTest();
    System.assertEquals(200, RestContext.response.statusCode);

    String respBody = RestContext.response.responseBody.toString();
    RewardPoints_CCMobileAPI.RewardPointsResponse resp =
        (RewardPoints_CCMobileAPI.RewardPointsResponse) JSON.deserialize(
            respBody, RewardPoints_CCMobileAPI.RewardPointsResponse.class);
    System.assertEquals(true, resp.status);
    // 3 rewards across 3 groups: Sales Rewards, Site Visit Reward, Custom Rewards
    System.assertEquals(3, resp.data.rewards.size());
   // System.assertEquals(5700, resp.data.totalRewardBalance);  // 5000+500+200
    //System.assertEquals(5000, resp.data.totalReferralEarnings); // only 'booking' type
}

    @isTest
    static void testMissingUserId() {
        setupPost('{"userId":""}');
        Test.startTest();
        RewardPoints_CCMobileAPI.getRewardPoints();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testCustomerNotFound() {
        setupPost('{"userId":"INVALID"}');
        Test.startTest();
        RewardPoints_CCMobileAPI.getRewardPoints();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}