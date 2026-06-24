@isTest
public class NumberTOWordConvertionTest {
    
    @isTest
    static void testGetNumberTOWordConvertion_PositiveNumber() {
        Decimal num = 234456778; // rupees, no paise

        NumberTOWordConvertion nc = new NumberTOWordConvertion();
        
        Test.startTest();
        String result = nc.getNumberTOWordConvertion(num);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Rupees'), 'Result should contain the word Rupees');
    }
  /*  
    @isTest
    static void testGetNumberTOWordConvertion_Zero() {
        Decimal num = 0;

        NumberTOWordConvertion nc = new NumberTOWordConvertion();
        
        Test.startTest();
        String result = nc.getNumberTOWordConvertion(num);
        Test.stopTest();
        
        System.assertEquals('Zero Only Rupees Only', result,
            'Zero amount should return Zero Only Rupees Only');
    }
    */
    @isTest
    static void testGetNumberTOWordConvertion_WithPaise() {
        Decimal num = 123.45; // 123 rupees and 45 paise

        NumberTOWordConvertion nc = new NumberTOWordConvertion();
        
        Test.startTest();
        String result = nc.getNumberTOWordConvertion(num);
        Test.stopTest();
        
        System.assert(result.contains('Paise'),
            'Result should contain Paise when there is a paise part');
        System.assert(result.contains('Rupees'),
            'Result should contain Rupees');
    }
}