@IsTest
private class AllPayment_MobileAPI_Test {

    @IsTest
    static void test_instantiation() {
        AllPayment_MobileAPI instance = new AllPayment_MobileAPI();
        System.assertNotEquals(null, instance, 'Should be able to instantiate AllPayment_MobileAPI');
    }
}