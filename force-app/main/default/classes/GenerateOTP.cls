public without sharing class GenerateOTP {
    public static String generateUniqueOTP(){
        String randomIntegerString = string.valueOf(Math.abs(Crypto.getRandomInteger()));
        String otp = randomIntegerString.substring(0,6);
        system.debug(otp);
        return otp; 
    }
}