@IsTest
public class NumberToWordsTest {
    
    @IsTest
    static void testZero() {
        String result = NumberToWords.numberToWords(0);
        System.assertEquals('Zero Only', result, 'Zero should return "Zero Only".');
    }
    
    @IsTest
    static void testSimpleNumber() {
        String result = NumberToWords.numberToWords(5);
        System.assertEquals('Five Only', result, '5 should return "Five Only".');
    }
    
    @IsTest
    static void testTwoDigitNumber() {
        String result = NumberToWords.numberToWords(42);
        System.assertEquals('Forty Two Only', result, '42 should return "Forty Two Only".');
    }
  /*  
    @IsTest
    static void testThreeDigitNumber() {
        String result = NumberToWords.numberToWords(315);
        System.assertEquals('Three Hundred and Fifteen Only', result,
                            '315 should return "Three Hundred and Fifteen Only".');
    }
   
    @IsTest
    static void testThousandNumber() {
        String result = NumberToWords.numberToWords(1234);
        System.assertEquals('One Thousand Two Hundred and Thirty Four Only', result,
                            '1234 should return correct thousand format.');
    }
    */
    @IsTest
    static void testLakhNumber() {
        String result = NumberToWords.numberToWords(5123456);
        System.assertNotEquals(null, result, 'Result should not be null for lakh values.');
        System.assert(result.contains('Lakh'), 'Should contain "Lakh" for values in lakh range.');
    }
    
    @IsTest
    static void testCroreNumber() {
        String result = NumberToWords.numberToWords(123456789);
        System.assertNotEquals(null, result, 'Result should not be null for crore values.');
        System.assert(result.contains('Crore'), 'Should contain "Crore" for values in crore range.');
    }
}