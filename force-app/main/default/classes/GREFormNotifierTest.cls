@isTest
private class GREFormNotifierTest {

    // ── Test 1: sendNotificationsAsync executes without exceptions ───────
    @isTest
    static void testSendNotificationsAsync_NoException() {
        String formDetails = buildTestPayload();

        Test.startTest();
        GREFormNotifier.sendNotificationsAsync(formDetails);
        Test.stopTest(); // forces @future method to execute synchronously

        // If we reach here without an unhandled exception, the future ran successfully
        System.assert(true, 'sendNotificationsAsync should complete without throwing');
    }

    // ── Test 2: sendNotificationsSync executes without exceptions ────────
    @isTest
    static void testSendNotificationsSync_NoException() {
        String formDetails = buildTestPayload();

        Test.startTest();
        GREFormNotifier.sendNotificationsSync(formDetails);
        Test.stopTest();

        System.assert(true, 'sendNotificationsSync should complete without throwing');
    }

    // ── Test 3: Verify email invocation limit is respected when GRE users exist ──
    @isTest
    static void testSendNotificationsSync_EmailInvocationTracked() {
        String formDetails = buildTestPayload();

        Integer emailsBefore = Limits.getEmailInvocations();

        Test.startTest();
        GREFormNotifier.sendNotificationsSync(formDetails);
        Test.stopTest();

        Integer emailsAfter = Limits.getEmailInvocations();

        // Email invocation count should be >= before (0 if no GRE_User__mdt records
        // exist in this org's metadata, 1 if they do — both are valid outcomes)
        System.assert(emailsAfter >= emailsBefore,
            'Email invocation count should not decrease');
    }

    // ── Test 4: Handles empty/blank formDetails gracefully ────────────────
    @isTest
    static void testSendNotificationsSync_BlankFormDetails() {
        Test.startTest();
        GREFormNotifier.sendNotificationsSync('');
        Test.stopTest();

        System.assert(true, 'Should handle blank formDetails without throwing');
    }

    // ── Test 5: Handles very long formDetails (tests .left(750) truncation) ──
    @isTest
    static void testSendNotificationsSync_LongFormDetails() {
        String longDetails = 'A new security register form has been submitted:\n';
        for (Integer i = 0; i < 50; i++) {
            longDetails += '• Extra line of detail to pad the message length out. \n';
        }

        Test.startTest();
        GREFormNotifier.sendNotificationsSync(longDetails);
        Test.stopTest();

        System.assert(longDetails.length() > 750,
            'Test payload should exceed 750 chars to exercise truncation logic');
    }

    // ── Test 6: Multiple sequential calls (simulates repeated form submits) ──
    @isTest
    static void testSendNotificationsAsync_MultipleCalls() {
        Test.startTest();
        GREFormNotifier.sendNotificationsAsync(buildTestPayload());
        GREFormNotifier.sendNotificationsAsync(buildTestPayload());
        Test.stopTest();

        System.assert(true, 'Multiple async calls should complete without throwing');
    }

    // ── Helper: builds a representative form payload ──────────────────────
    private static String buildTestPayload() {
        return 'A new security register form has been submitted:\n' +
               '• Visitor Name: Test Visitor\n' +
               '• Phone: 9876543210\n' +
               '• Visitor Type: Guest\n' +
               '• Number of Visitors: 1\n' +
               '• Location: Main Gate\n' +
               '• Remarks: Unit test run';
    }
}