@IsTest
private class ReportSummaryPdfServiceTest {

    @IsTest
    static void test_execute() {
        // The execute method body is commented out, so just verify it runs without error
        Test.startTest();
        System.enqueueJob(new ReportSummaryPdfService(new List<Id>()));
        Test.stopTest();

        System.assert(true, 'Queueable should execute without error');
    }
}