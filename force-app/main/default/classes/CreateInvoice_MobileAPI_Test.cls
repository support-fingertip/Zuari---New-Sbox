@IsTest
private class CreateInvoice_MobileAPI_Test {

    @IsTest
    static void test_createInvoice_FullSuccess() {
        // 1. Setup Unique Data
        String seed = String.valueOf(System.now().getTime());
        
        Channel_Partner__c cp = new Channel_Partner__c(Active__c = true);
        setIfWriteable(cp, 'Email__c', 'cp' + seed + '@test.com');
        insert cp;
        cp = [SELECT Id, User_Id__c FROM Channel_Partner__c WHERE Id = :cp.Id];

        // 2. Create Booking linked to CP
        Booking__c bk = new Booking__c();
        setIfWriteable(bk, 'Channel_Partner__c', cp.Id);
        // Add other required booking fields here if necessary
        insert bk;
        bk = [SELECT Id, Name FROM Booking__c WHERE Id = :bk.Id];

        // 3. Payload for Success Creation
        Map<String, Object> payload = new Map<String, Object>{
            'userId' => cp.User_Id__c,
            'bookingId' => new List<String>{ bk.Name },
            'invoiceDate' => System.now(),
            'agreementAmount' => 10000,
            'commissionAmount' => 500,
            'tds' => 50,
            'gst' => 90,
            'netInvoiceAmount' => 540
        };

        Test.startTest();
        mock(JSON.serialize(payload));
        CreateInvoice_MobileAPI.createOrUpdateInvoice();

        // 4. Test Update Logic (Update the invoice we just created)
        // API usually identifies existing invoices by the booking link or an invoiceId
        payload.put('agreementAmount', 20000);
        mock(JSON.serialize(payload));
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();
    }

    @IsTest
    static void test_errorBranches() {
        // Missing userId
        mock(JSON.serialize(new Map<String, Object>{'bookingId' => new List<String>{'B1'}}));
        CreateInvoice_MobileAPI.createOrUpdateInvoice();

        // Missing bookingId
        mock(JSON.serialize(new Map<String, Object>{'userId' => 'fake_user'}));
        CreateInvoice_MobileAPI.createOrUpdateInvoice();

        // Catch Block (Malformed JSON)
        Test.startTest();
        mock('{ "userId": "incomplete'); 
        CreateInvoice_MobileAPI.createOrUpdateInvoice();
        Test.stopTest();
    }

    /* ========================= HELPERS ========================= */

    private static void mock(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateInvoiceAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static void setIfWriteable(SObject sob, String field, Object val) {
        if (sob.getSObjectType().getDescribe().fields.getMap().containsKey(field)) {
            Schema.DescribeFieldResult d = sob.getSObjectType().getDescribe().fields.getMap().get(field).getDescribe();
            if (d.isCreateable() || d.isUpdateable()) {
                sob.put(field, val);
            }
        }
    }
}