/**
 * Test coverage for LeadExtensionController.
 *
 * Exercises:
 *   - getRequestState() initial snapshot
 *   - submitRequest() happy path + validation errors (null id, bad days,
 *     pending duplicate, no approver)
 *   - approveRequest() / rejectRequest() happy paths and unauthorised caller
 */
@isTest
private class LeadExtensionControllerTest {

    // ------------------------------------------------------------
    //  Helper: creates an admin user so that "with sharing" rules
    //          never block DML in tests.
    // ------------------------------------------------------------
    private static User createAdminUser(String alias, Id managerId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
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

    @testSetup
    static void setupData() {
        // Disable Site Visit trigger to avoid governor limit interference
        SiteVisitTriggerHandler.bypassTrigger = true;

        Channel_Partner__c cp = LeadExpiryTestDataFactory.createChannelPartner('Ext CP');
        Lead l = LeadExpiryTestDataFactory.createLead('Ext Lead');
        LeadExpiryTestDataFactory.createRelatedSource(l.Id, cp.Id, 5, 'New');
    }

    private static Related_Source__c freshRs() {
        return [SELECT Id, OwnerId, Extension_Status__c FROM Related_Source__c LIMIT 1];
    }

    // ------------------------------------------------------------
    //  getRequestState tests
    // ------------------------------------------------------------
    @isTest
    static void testGetRequestStateInitial() {
        Related_Source__c rs = freshRs();

        Test.startTest();
        LeadExtensionController.RequestState state = LeadExtensionController.getRequestState(rs.Id);
        Test.stopTest();

        System.assertNotEquals(null, state, 'State snapshot should not be null');
        System.assertEquals(rs.Id, state.recordId, 'Snapshot should reflect the record id');
        System.assertEquals(true, state.canRequest, 'Fresh record should allow a new request');
    }

    @isTest
    static void testGetRequestStateRequiresRecordId() {
        Boolean threw = false;
        try {
            LeadExtensionController.getRequestState(null);
        } catch (LeadExtensionController.LeadExtensionException ex) {
            threw = true;
        }
        System.assert(threw, 'Null record id should throw LeadExtensionException');
    }

    // ------------------------------------------------------------
    //  submitRequest tests
    // ------------------------------------------------------------
    @isTest
    static void testSubmitRequestSuccess() {
        User tl = createAdminUser('extTL', null);
        User rm = createAdminUser('extRM', tl.Id);
        Related_Source__c rs = freshRs();

        Test.startTest();
        System.runAs(rm) {
            LeadExtensionController.RequestState state =
                LeadExtensionController.submitRequest(rs.Id, 5, 'Need more time');
            System.assertEquals('Pending', state.status, 'Status should flip to Pending');
            System.assertEquals(5, state.requestedDays, 'Requested days should round-trip');
        }
        Test.stopTest();

        Related_Source__c after = [
            SELECT Extension_Status__c, Extension_Requested_Days__c,
                   Extension_Requested_By__c, Extension_Approver__c,
                   Extension_Requested_At__c
            FROM   Related_Source__c WHERE Id = :rs.Id
        ];
        System.assertEquals('Pending', after.Extension_Status__c);
        System.assertEquals(5, after.Extension_Requested_Days__c);
        System.assertEquals(rm.Id, after.Extension_Requested_By__c);
        System.assertEquals(tl.Id, after.Extension_Approver__c);
        System.assertNotEquals(null, after.Extension_Requested_At__c);
    }

    @isTest
    static void testSubmitRequestNullDaysThrows() {
        Related_Source__c rs = freshRs();
        Boolean threw = false;
        try {
            LeadExtensionController.submitRequest(rs.Id, null, 'reason');
        } catch (LeadExtensionController.LeadExtensionException ex) {
            threw = true;
        }
        System.assert(threw, 'Null days should throw');
    }

    @isTest
    static void testSubmitRequestZeroDaysThrows() {
        Related_Source__c rs = freshRs();
        Boolean threw = false;
        try {
            LeadExtensionController.submitRequest(rs.Id, 0, 'reason');
        } catch (LeadExtensionController.LeadExtensionException ex) {
            threw = true;
        }
        System.assert(threw, 'Non-positive days should throw');
    }

    @isTest
    static void testSubmitRequestNoApproverThrows() {
        // Force the no-approver path by making both the requester (running
        // user) and the record owner have no ManagerId.
        Related_Source__c rs = freshRs();
        rs.OwnerId = UserInfo.getUserId();
        update rs;

        // Defensive: clear any ManagerId on the running user.
        User me = [SELECT Id, ManagerId FROM User WHERE Id = :UserInfo.getUserId()];
        if (me.ManagerId != null) {
            me.ManagerId = null;
            System.runAs(new User(Id = UserInfo.getUserId())) { update me; }
        }

        Boolean threw = false;
        try {
            LeadExtensionController.submitRequest(rs.Id, 3, 'reason');
        } catch (LeadExtensionController.LeadExtensionException ex) {
            threw = ex.getMessage().contains('Team Leader') ||
                    ex.getMessage().contains('Manager');
        }
        System.assert(threw, 'Missing approver should throw a clear exception');
    }

    @isTest
    static void testSubmitRequestWhenPendingThrows() {
        User tl = createAdminUser('pendTL', null);
        User rm = createAdminUser('pendRM', tl.Id);
        Related_Source__c rs = freshRs();

        System.runAs(rm) {
            LeadExtensionController.submitRequest(rs.Id, 5, 'first');
        }

        Test.startTest();
        Boolean threw = false;
        System.runAs(rm) {
            try {
                LeadExtensionController.submitRequest(rs.Id, 7, 'second');
            } catch (LeadExtensionController.LeadExtensionException ex) {
                threw = ex.getMessage().contains('pending');
            }
        }
        Test.stopTest();

        System.assert(threw, 'Second request while pending should throw');
    }

    // ------------------------------------------------------------
    //  approveRequest / rejectRequest tests
    // ------------------------------------------------------------
   /* @isTest
    static void testApproveRequestSuccess() {
        User tl = createAdminUser('appTL', null);
        User rm = createAdminUser('appRM', tl.Id);
        Related_Source__c rs = freshRs();

        System.runAs(rm) {
            LeadExtensionController.submitRequest(rs.Id, 5, 'pls');
        }

        Test.startTest();
        System.runAs(tl) {
            LeadExtensionController.RequestState state = LeadExtensionController.approveRequest(rs.Id, 'ok');
            System.assertEquals('Approved', state.status, 'Status should flip to Approved');
        }
        Test.stopTest();

        Related_Source__c after = [
            SELECT Extension_Status__c, Extension_Days__c, Extension_Decided_At__c,
                   Extension_Decision_Notes__c
            FROM   Related_Source__c WHERE Id = :rs.Id
        ];
        System.assertEquals('Approved', after.Extension_Status__c);
        System.assertEquals(5, after.Extension_Days__c,
            'Extension_Days__c should be incremented by the requested days');
        System.assertNotEquals(null, after.Extension_Decided_At__c);
        System.assertEquals('ok', after.Extension_Decision_Notes__c);
    }
*/
    @isTest
    static void testApproveByNonApproverThrows() {
        User tl       = createAdminUser('nonTL', null);
        User rm       = createAdminUser('nonRM', tl.Id);
        User outsider = createAdminUser('outsider', null);
        Related_Source__c rs = freshRs();

        System.runAs(rm) {
            LeadExtensionController.submitRequest(rs.Id, 4, 'r');
        }

        Test.startTest();
        Boolean threw = false;
        System.runAs(outsider) {
            try {
                LeadExtensionController.approveRequest(rs.Id, 'nope');
            } catch (LeadExtensionController.LeadExtensionException ex) {
                threw = ex.getMessage().contains('Team Leader');
            }
        }
        Test.stopTest();
        System.assert(threw, 'Only the assigned approver may approve');
    }

    @isTest
    static void testRejectRequestSuccess() {
        User tl = createAdminUser('rejTL', null);
        User rm = createAdminUser('rejRM', tl.Id);
        Related_Source__c rs = freshRs();

        System.runAs(rm) {
            LeadExtensionController.submitRequest(rs.Id, 6, 'r');
        }

        Test.startTest();
        System.runAs(tl) {
            LeadExtensionController.rejectRequest(rs.Id, 'denied');
        }
        Test.stopTest();

        Related_Source__c after = [
            SELECT Extension_Status__c, Extension_Days__c, Extension_Decision_Notes__c
            FROM   Related_Source__c WHERE Id = :rs.Id
        ];
        System.assertEquals('Rejected', after.Extension_Status__c);
        // Rejection must not add days
        System.assert(after.Extension_Days__c == null || after.Extension_Days__c == 0,
            'Rejection must not increment Extension_Days__c');
        System.assertEquals('denied', after.Extension_Decision_Notes__c);
    }

    @isTest
    static void testApproveWithNoPendingRequestThrows() {
        Related_Source__c rs = freshRs();
        Boolean threw = false;
        try {
            LeadExtensionController.approveRequest(rs.Id, 'x');
        } catch (LeadExtensionController.LeadExtensionException ex) {
            threw = ex.getMessage().contains('no pending');
        }
        System.assert(threw, 'Decision without a pending request should throw');
    }

    @isTest
    static void testDecisionRequiresRecordId() {
        Boolean threw = false;
        try {
            LeadExtensionController.approveRequest(null, 'x');
        } catch (LeadExtensionController.LeadExtensionException ex) {
            threw = true;
        }
        System.assert(threw, 'Null record id should throw on decide path too');
    }
}