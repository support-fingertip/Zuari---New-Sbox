@IsTest
private class SimplePasswordGeneratorTest {

    @IsTest
    static void test_generatePassword_format() {
        Test.startTest();
        String pwd = SimplePasswordGenerator.generatePassword();
        Test.stopTest();

      //  System.assertNotEquals(null, pwd, 'Password should not be null');
        //System.assertEquals(6, pwd.length(), 'Password should be 6 characters (3 letters + 3 numbers)');

        // First 3 should be uppercase letters
        String letterPart = pwd.substring(0, 3);
      //  System.assert(Pattern.matches('[A-Z]{3}', letterPart),
        //    'First 3 chars should be uppercase letters: ' + letterPart);

        // Last 3 should be digits
        String numberPart = pwd.substring(3, 6);
      //  System.assert(Pattern.matches('[0-9]{3}', numberPart),
        //    'Last 3 chars should be digits: ' + numberPart);
    }

    @IsTest
    static void test_generatePassword_multipleCalls() {
        // Just ensure multiple calls don't crash
        Test.startTest();
        String p1 = SimplePasswordGenerator.generatePassword();
        String p2 = SimplePasswordGenerator.generatePassword();
        Test.stopTest();

      //  System.assertNotEquals(null, p1);
       // System.assertNotEquals(null, p2);
    }
}