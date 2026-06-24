@IsTest
public class NumberTOWordConvertionActualTest {

    @IsTest
    static void testStandardControllerConstructor_setsDaySuffix() {
        Test.startTest();
        // StandardController can be created with any sObject instance
        ApexPages.StandardController sc = new ApexPages.StandardController(new Account(Name = 'Test'));
        NumberTOWordConvertionActual obj = new NumberTOWordConvertionActual(sc);
        Test.stopTest();

        System.assertNotEquals(null, obj.day, 'day should be set');
        System.assert(
            new Set<String>{'st','nd','rd','th'}.contains(obj.day),
            'day must be a valid suffix'
        );
    }

    @IsTest
    static void testGetDayOfMonthSuffix_allBranches() {
        NumberTOWordConvertionActual obj = new NumberTOWordConvertionActual();

        System.assertEquals('', obj.getDayOfMonthSuffix(null));
        System.assertEquals('th', obj.getDayOfMonthSuffix(11));
        System.assertEquals('th', obj.getDayOfMonthSuffix(12));
        System.assertEquals('th', obj.getDayOfMonthSuffix(13));

        System.assertEquals('st', obj.getDayOfMonthSuffix(1));
        System.assertEquals('nd', obj.getDayOfMonthSuffix(2));
        System.assertEquals('rd', obj.getDayOfMonthSuffix(3));

        System.assertEquals('th', obj.getDayOfMonthSuffix(4));
        System.assertEquals('th', obj.getDayOfMonthSuffix(20));
        System.assertEquals('st', obj.getDayOfMonthSuffix(21));
        System.assertEquals('nd', obj.getDayOfMonthSuffix(22));
        System.assertEquals('rd', obj.getDayOfMonthSuffix(23));
        System.assertEquals('th', obj.getDayOfMonthSuffix(24));
    }

    @IsTest
    static void testReverse_basic() {
        NumberTOWordConvertionActual obj = new NumberTOWordConvertionActual();

        List<String> input = new List<String>{'1','2','3'};
        List<String> outList = obj.reverse(input);

        // reverse() adds an extra '' at the end
        System.assertEquals(4, outList.size());
        System.assertEquals('3', outList[0]);
        System.assertEquals('2', outList[1]);
        System.assertEquals('1', outList[2]);
        System.assertEquals('', outList[3]);
    }

   @IsTest
static void testConvertInWords_variousPatterns() {
    NumberTOWordConvertionActual obj = new NumberTOWordConvertionActual();

    // Helper inline logic to build actnum as String[] with trailing ''
    // exactly like reverse() does (but as array)
    // NOTE: split('') returns String[] in your org (because your main class compiles).
    
    // ---- 105 ----
    try {
        String s = '105';
        String[] numRev = s.split('');
        String[] act = new String[numRev.size() + 1];

        Integer idx = 0;
        for (Integer i = numRev.size() - 1; i >= 0; i--) {
            act[idx++] = numRev[i];
        }
        act[idx] = ''; // trailing blank

        String words = obj.convertInWords(numRev, act);
        System.assert(words.contains('Hundred'), 'Should include Hundred');
    } catch (Exception e) {
        System.assert(false, 'Unexpected error (105): ' + e.getMessage());
    }

    // ---- 1000 ----
    try {
        String s = '1000';
        String[] numRev = s.split('');
        String[] act = new String[numRev.size() + 1];

        Integer idx = 0;
        for (Integer i = numRev.size() - 1; i >= 0; i--) {
            act[idx++] = numRev[i];
        }
        act[idx] = '';

        String words = obj.convertInWords(numRev, act);
        System.assert(words.contains('Thousand'), 'Should include Thousand');
    } catch (Exception e) {
        System.assert(false, 'Unexpected error (1000): ' + e.getMessage());
    }

    // ---- 12000 (teen logic) ----
    try {
        String s = '12000';
        String[] numRev = s.split('');
        String[] act = new String[numRev.size() + 1];

        Integer idx = 0;
        for (Integer i = numRev.size() - 1; i >= 0; i--) {
            act[idx++] = numRev[i];
        }
        act[idx] = '';

        String words = obj.convertInWords(numRev, act);
        System.assert(words.contains('Thousand'), 'Should include Thousand');
        System.assert(words.contains('Twelve') || words.contains(' Eleven') || words.contains(' Thirteen'),
            'Should hit teen logic for 12xxx');
    } catch (Exception e) {
        System.assert(false, 'Unexpected error (12000): ' + e.getMessage());
    }

    // ---- 100000 (Lakhs) ----
    try {
        String s = '100000';
        String[] numRev = s.split('');
        String[] act = new String[numRev.size() + 1];

        Integer idx = 0;
        for (Integer i = numRev.size() - 1; i >= 0; i--) {
            act[idx++] = numRev[i];
        }
        act[idx] = '';

        String words = obj.convertInWords(numRev, act);
        System.assert(words.contains('Lakhs'), 'Should include Lakhs');
    } catch (Exception e) {
        System.assert(false, 'Unexpected error (100000): ' + e.getMessage());
    }

    // ---- 10000000 (Crore) ----
    try {
        String s = '10000000';
        String[] numRev = s.split('');
        String[] act = new String[numRev.size() + 1];

        Integer idx = 0;
        for (Integer i = numRev.size() - 1; i >= 0; i--) {
            act[idx++] = numRev[i];
        }
        act[idx] = '';

        String words = obj.convertInWords(numRev, act);
        System.assert(words.contains('Crore'), 'Should include Crore');
    } catch (Exception e) {
        System.assert(false, 'Unexpected error (10000000): ' + e.getMessage());
    }
}

    @IsTest
    static void testGetNumberTOWordConvertion_mainPaths() {
        NumberTOWordConvertionActual obj = new NumberTOWordConvertionActual();

        Test.startTest();

        // Normal integer
        String w1 = obj.getNumberTOWordConvertion(105);
        System.assertNotEquals('', w1, 'Should return words for 105');
        System.assert(w1.contains('Hundred'), 'Should include Hundred');

        // With paisa (should still return firstHalf; code mostly ignores secondHalf in return)
        String w2 = obj.getNumberTOWordConvertion(1234.56);
        System.assertNotEquals('', w2, 'Should return words for 1234.56');
        System.assert(w2.contains('Thousand') || w2.contains('Hundred'), 'Should include Thousand/Hundred');

        // Zero should return ''
        String w3 = obj.getNumberTOWordConvertion(0);
        System.assertEquals('', w3, 'Zero should return empty string');

        Test.stopTest();
    }
}