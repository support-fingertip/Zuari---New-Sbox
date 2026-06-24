public class NumberToWords {
    
    public static String numberToWords(Integer num) {
        if (num == 0) return 'Zero Only';
        return convert(num).trim() + ' Only';
    }
    
    private static String convert(Integer num) {
        List<String> ones = new List<String>{
            'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
            'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
            'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
        };
        
        List<String> tens = new List<String>{
            '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
        };
        
        String result = '';
        
        if (num >= 10000000) {
            result += convert(num / 10000000) + ' Crore ';
            num = Math.mod(num, 10000000);
        }
        
        if (num >= 100000) {
            result += convert(num / 100000) + ' Lakh ';
            num = Math.mod(num, 100000);
        }
        
        if (num >= 1000) {
            result += convert(num / 1000) + ' Thousand ';
            num = Math.mod(num, 1000);
        }
        
        if (num >= 100) {
            result += ones[num / 100] + ' Hundred ';
            num = Math.mod(num, 100);
        }
        
        if (num > 0) {
            if (!result.endsWith(' ') && result != '') {
                result += 'and ';
            }
            
            if (num < 20) {
                result += ones[num];
            } else {
                result += tens[num / 10];
                if (Math.mod(num, 10) > 0) {
                    result += ' ' + ones[Math.mod(num, 10)];
                }
            }
        }
        
        return result;
    }
}