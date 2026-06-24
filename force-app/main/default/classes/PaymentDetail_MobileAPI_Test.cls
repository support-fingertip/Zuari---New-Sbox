@IsTest
private class PaymentDetail_MobileAPI_Test {

    @IsTest
    static void test_getPaymentDetail_FullCoverage() {
        // 1. SETUP: Dynamic Unique Data
        String seed = String.valueOf(System.now().getTime()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));

        // Create Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Name', 'CP' + seed);
        setIfWriteable(cp, 'Email__c', 'pay' + seed + '@test.com');
        insert cp;
        
        // Re-query for auto-populated User_Id__c
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // Create Parent Payment
        Payment__c parentPay = new Payment__c(Channel_Partner__c = cp.Id);
        insert parentPay;

        // Create Payment Line Item (The specific detail record)
        Payment_Line_Item__c pli = new Payment_Line_Item__c(
            Payment__c = parentPay.Id,
            Channel_Partner__c = cp.Id
        );
        setIfWriteable(pli, 'Name', 'Customer ' + seed);
        setIfWriteable(pli, 'Payament_Status__c', 'Processed');
        setIfWriteable(pli, 'Booking_Amount__c', 10000);
        insert pli;
        
        // Re-query for system-generated ID field used in API filter
        pli = [SELECT Id, Payment_Line_Item__c FROM Payment_Line_Item__c WHERE Id = :pli.Id];

        // -----------------------------------------------------------------------
        // EXECUTION PATHS
        // -----------------------------------------------------------------------
        Test.startTest();
        
        // Path A: SUCCESS (Fetch specific detail)
        Map<String, Object> successPayload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'paymentId' => pli.Payment_Line_Item__c
        };
        mock(JSON.serialize(successPayload));
        PaymentDetail_MobileAPI.getPaymentDetail();

        // Path B: VALIDATIONS (Missing Parameters)
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '', 'paymentId' => '' }));
        PaymentDetail_MobileAPI.getPaymentDetail();

        // Path C: NOT FOUND
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => cp.User_Id__c, 'paymentId' => 'FAKE-999' }));
        PaymentDetail_MobileAPI.getPaymentDetail();

        // Path D: EXCEPTIONS (Catch Block)
        mock('{ "userId": "broken'); 
        PaymentDetail_MobileAPI.getPaymentDetail();
        
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/PaymentDetailAPI/';
        req.httpMethod = 'POST';
        req.requestBody = (body == null) ? null : Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfWriteable(SObject sob, String field, Object val) {
        Map<String, Schema.SObjectField> fm = sob.getSObjectType().getDescribe().fields.getMap();
        if (fm.containsKey(field) && fm.get(field).getDescribe().isCreateable()) {
            sob.put(field, val);
        }
    }
}