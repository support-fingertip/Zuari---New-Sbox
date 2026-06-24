@IsTest
private class Payment_MobileAPI_Test {

    @IsTest
    static void test_getPayments_FullCoverage() {
        String seed = String.valueOf(System.now().getTime()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));

        // 1. SETUP: Channel Partner
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Name', 'CP' + seed);
        setIfWriteable(cp, 'Email__c', 'pay' + seed + '@test.com');
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 2. SETUP: Parent Payment Record (Required for Master-Detail)
        // This fixes the REQUIRED_FIELD_MISSING: [Payment__c] error
        Payment__c parentPay = new Payment__c();
        setIfWriteable(parentPay, 'Channel_Partner__c', cp.Id);
        insert parentPay;

        // 3. SETUP: Project Picklist Value
        String validProjName = getValidPicklistValue(Payment_Line_Item__c.SObjectType, 'Project__c');
        
        // 4. SETUP: Payment Line Items (Using "Processed" terminology)
        List<Payment_Line_Item__c> lineItems = new List<Payment_Line_Item__c>();
        
        // Record 1: Processed
        Payment_Line_Item__c p1 = new Payment_Line_Item__c(
            Channel_Partner__c = cp.Id,
            Payment__c = parentPay.Id // Linking to parent
        );
        setIfWriteable(p1, 'Project__c', validProjName);
        setIfWriteable(p1, 'Payament_Status__c', 'Processed'); 
        setIfWriteable(p1, 'Commission_Amount__c', 1000);
        lineItems.add(p1);

        // Record 2: Pending
        Payment_Line_Item__c p2 = new Payment_Line_Item__c(
            Channel_Partner__c = cp.Id,
            Payment__c = parentPay.Id // Linking to parent
        );
        setIfWriteable(p2, 'Project__c', validProjName);
        setIfWriteable(p2, 'Payament_Status__c', 'Pending');
        setIfWriteable(p2, 'Pending_Amount__c', 500);
        lineItems.add(p2);

        insert lineItems;

      
        // EXECUTION
        
        Test.startTest();
        
        // Path A: Success with "Processed" Status
        Payment_MobileAPI.PaymentRequestWrapper req = new Payment_MobileAPI.PaymentRequestWrapper();
        req.userId = cp.User_Id__c;
        req.paymentStatusId = 'Processed';
        req.projectId = validProjName;
        req.pageSize = 5;
        
        mock(JSON.serialize(req));
        Payment_MobileAPI.getPayments();

        // Path B: Validations & Exceptions
        mock(JSON.serialize(new Map<String, Object>{ 'userId' => '' }));
        Payment_MobileAPI.getPayments();

        mock('{ "userId": "broken'); 
        Payment_MobileAPI.getPayments();
        
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/GetPaymentAPI/';
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

    private static String getValidPicklistValue(Schema.SObjectType objType, String fieldName) {
        if (!objType.getDescribe().fields.getMap().containsKey(fieldName)) return 'Default Project';
        List<Schema.PicklistEntry> ple = objType.getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues();
        return (ple.isEmpty()) ? 'Default Project' : ple[0].getValue();
    }
}