public class SimplePasswordGenerator {
    
    public static String generatePassword() {
        String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        String lower = 'abcdefghijklmnopqrstuvwxyz';
        String digits = '0123456789';
        String special = '!@#$%^&*()_+-=';

        String pwd = '';
        pwd += randomChar(upper);
        pwd += randomChar(lower);
        pwd += randomChar(special);
        pwd += randomChar(digits);

        // Fill remaining with random mix
        String all = upper + lower + digits + special;
        for (Integer i = 0; i < 4; i++) {
            pwd += randomChar(all);
        }

        // Shuffle password
        String shuffled = shuffleString(pwd);
        return shuffled;
    }

    private static String randomChar(String chars) {
        Integer idx = getRandomNumber(chars.length());
        return chars.substring(idx, idx + 1);
    }

    private static String shuffleString(String input) {
        List<String> chars = new List<String>();
        for (Integer i = 0; i < input.length(); i++) {
            chars.add(input.substring(i, i + 1));
        }
        for (Integer i = chars.size() - 1; i > 0; i--) {
            Integer j = getRandomNumber(i + 1);
            String temp = chars[i];
            chars[i] = chars[j];
            chars[j] = temp;
        }
        return String.join(chars, '');
    }
   
    private static Integer getRandomNumber(Integer maxValue) {
        Long seed = DateTime.now().getTime();
        
        return Math.mod(Math.abs(seed.intValue()), maxValue);
    }
}