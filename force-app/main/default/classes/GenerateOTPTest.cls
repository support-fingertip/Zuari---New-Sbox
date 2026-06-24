@isTest
public class GenerateOTPTest {

    @isTest
    static void testGenerateUniqueOTP() {
        // Call the method.
        String otp = GenerateOTP.generateUniqueOTP();
        
        // System debug for visibility in test logs..
        System.debug('Generated OTP: ' + otp);
        
        // Assert that the OTP is not null...
        System.assertNotEquals(null, otp, 'OTP should not be null');
        
        // Assert that the OTP length is 6....
        System.assertEquals(6, otp.length(), 'OTP should be 6 digits long');
        
        
    }
}