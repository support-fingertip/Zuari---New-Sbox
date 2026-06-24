@isTest
private class CoApplicantControllerTest {
    
    @isTest
    static void testCoApplicantControllerLoadsCoApplicants() {
        Booking__c booking = new Booking__c(
            Email__c = 'testbooking@example.com',
            Stage__c = 'Agreement',
            PAN_Number__c = 'ABCDE1234F' 
        );
        
        insert booking;
        
        // Step 2: Create related Co-Applicant record
        Co_Applicant__c coApp = new Co_Applicant__c(
            Name = 'Test CoApplicant',
            Booking__c = booking.Id,
            PAN_Number__c = 'ABCDE1234F'
        );
        insert coApp;
        
        // Step 3: Create StandardController and pass booking
        ApexPages.StandardController sc = new ApexPages.StandardController(booking);
        
        // Step 4: Instantiate your controller
        Test.startTest();
        CoApplicantController controller = new CoApplicantController(sc);
        Test.stopTest();
        
        // Step 5: Assert coApplicants list is correctly loaded
        System.assertNotEquals(null, controller.coApplicants, 'coApplicants list should not be null');
        System.assertEquals(1, controller.coApplicants.size(), 'Should have 1 co-applicant loaded');
        System.assertEquals('Test CoApplicant', controller.coApplicants[0].Name, 'Co-applicant name should match');
    }
}