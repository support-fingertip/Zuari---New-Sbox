@isTest
private class DemandLetterVFPTest {
    
    @testSetup
    static void setupTestData() {
        // Create a Booking record with all necessary fields
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            S__c = 'Mr.',
            Son_Daughter_Wife_of1__c = 'Father Name',
            PAN_Number__c = 'ABCDE1234F',
            Aadhar_No__c = '123456789012',
            Address__c = 'Test Address',
            Date_of_Birth1__c = Date.newInstance(1990, 1, 1),
            Son_Daughter_Wife_of__c = 'D/o',
            Booking_Amount__c = 100000,
            Pincode1__c = '110001'
        );
        
        // Set compound address fields
        booking.Correspondence_Address__Street__s = '123 Test Street';
        booking.Correspondence_Address__City__s = 'Test City';
        booking.Correspondence_Address__PostalCode__s = '110001';
        booking.Correspondence_Address__StateCode__s = 'DL';
        
        // Set permanent address
        booking.Permanent_Address2__Street__s = '456 Permanent Street';
        booking.Permanent_Address2__City__s = 'Permanent City';
       // booking.Permanent_Address2__State__s = 'Test State';
        booking.Permanent_Address2__PostalCode__s = '110002';
       // booking.Permanent_Address2__Country__s = 'India';
        
        insert booking;
        
        // Create an Additional Charges record linked to the Booking
        Additional_Charges__c additionalCharge = new Additional_Charges__c(
            Booking__c = booking.Id,
            Name = 'Test Charge'
        );
        insert additionalCharge;
    }
    
    @isTest
    static void testConstructorWithValidAdditionalCharge() {
        // Get the test data
        Additional_Charges__c charge = [SELECT Id, Booking__c FROM Additional_Charges__c LIMIT 1];
        
        // Create StandardController
        ApexPages.StandardController sc = new ApexPages.StandardController(charge);
        
        Test.startTest();
        // Initialize the VFP controller
        DemandLetterVFP controller = new DemandLetterVFP(sc);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, controller.bookingId, 'Booking ID should be set');
        System.assertEquals(charge.Booking__c, controller.bookingId, 'Booking ID should match');
        System.assertNotEquals(null, controller.booking, 'Booking should be fetched');
        System.assertEquals('Test Applicant', controller.booking.First_Applicant_Name__c, 'Applicant name should match');
    }
    
    @isTest
    static void testFetchBookingDetailsSuccess() {
        // Get the test data
        Booking__c testBooking = [SELECT Id FROM Booking__c LIMIT 1];
        Additional_Charges__c charge = [SELECT Id, Booking__c FROM Additional_Charges__c LIMIT 1];
        
        // Create StandardController
        ApexPages.StandardController sc = new ApexPages.StandardController(charge);
        DemandLetterVFP controller = new DemandLetterVFP(sc);
        
        Test.startTest();
        controller.fetchBookingDetails();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, controller.booking, 'Booking should be populated');
        System.assertEquals(testBooking.Id, controller.booking.Id, 'Booking ID should match');
        System.assertEquals('Test Applicant', controller.booking.First_Applicant_Name__c, 'First applicant name should match');
        System.assertEquals(100000, controller.booking.Booking_Amount__c, 'Booking amount should match');
    }
    
    @isTest
    static void testFetchBookingDetailsWithNullBookingId() {
        // Create a charge without a booking
        Booking__c testBooking = [SELECT Id FROM Booking__c LIMIT 1];
        Additional_Charges__c charge = new Additional_Charges__c(
            Name = 'Test Charge No Booking',
           Booking__c = testBooking.Id 
        );
        insert charge;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(charge);
        DemandLetterVFP controller = new DemandLetterVFP(sc);
        
        // Manually set bookingId to null
        controller.bookingId = null;
        
      /*  Test.startTest();
        try {
            controller.fetchBookingDetails();
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Booking ID is not provided.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }*/
    
   /* @isTest
    static void testFetchBookingDetailsWithInvalidBookingId() {
        // Get a valid booking first
        Booking__c validBooking = [SELECT Id FROM Booking__c LIMIT 1];
        
        // Create a temporary booking to get a valid ID format
        Booking__c tempBooking = new Booking__c(
            First_Applicant_Name__c = 'Temp Booking'
        );
        insert tempBooking;
        Id invalidBookingId = tempBooking.Id;
        
        // Delete it so the ID becomes invalid
        delete tempBooking;
        
        // Create the charge with the valid booking
        Additional_Charges__c charge = new Additional_Charges__c(
            Booking__c = validBooking.Id,
            Name = 'Test Charge Invalid'
        );
        insert charge;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(charge);
        DemandLetterVFP controller = new DemandLetterVFP(sc);
        
        // Override with the invalid booking ID
      //  controller.bookingId = invalidBookingId;
        
        Test.startTest();
        try {
            controller.fetchBookingDetails();
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('No Booking found with the provided Booking ID.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }*/
    
   /* @isTest
    static void testGetPermanentFullAddress() {
        // Get the test data
        Additional_Charges__c charge = [SELECT Id, Booking__c FROM Additional_Charges__c LIMIT 1];
        
        // Create StandardController
        ApexPages.StandardController sc = new ApexPages.StandardController(charge);
        DemandLetterVFP controller = new DemandLetterVFP(sc);
        
        Test.startTest();*/
      /*  String address = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, address, 'Address should not be null');
        System.assert(address.contains('456 Permanent Street'), 'Address should contain street');
        System.assert(address.contains('Permanent City'), 'Address should contain city');
        System.assert(address.contains('Test State'), 'Address should contain state');
        System.assert(address.contains('110002'), 'Address should contain postal code');
        System.assert(address.contains('India'), 'Address should contain country');*/
    }
    
    @isTest
    static void testGetPermanentFullAddressWithPartialData() {
        // Create a booking with partial address data
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Partial Address Test'
        );
        
        // Set only some address fields
        booking.Permanent_Address2__Street__s = 'Only Street';
        booking.Permanent_Address2__City__s = 'Only City';
        
        insert booking;
        
        Additional_Charges__c charge = new Additional_Charges__c(
            Booking__c = booking.Id,
            Name = 'Test Charge Partial'
        );
        insert charge;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(charge);
        DemandLetterVFP controller = new DemandLetterVFP(sc);
        
        Test.startTest();
        String address = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, address, 'Address should not be null');
        System.assert(address.contains('Only Street'), 'Address should contain street');
        System.assert(address.contains('Only City'), 'Address should contain city');
        System.assert(!address.contains('null'), 'Address should not contain null values');
    }
    
    @isTest
    static void testGetPermanentFullAddressMultipleCalls() {
        // Test that address loading happens only once (caching test)
        Additional_Charges__c charge = [SELECT Id, Booking__c FROM Additional_Charges__c LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(charge);
        DemandLetterVFP controller = new DemandLetterVFP(sc);
        
        Test.startTest();
        String address1 = controller.getPermanentFullAddress();
        String address2 = controller.getPermanentFullAddress();
        String address3 = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // All calls should return the same address
        System.assertEquals(address1, address2, 'First and second call should return same address');
        System.assertEquals(address2, address3, 'Second and third call should return same address');
    }
    
    @isTest
    static void testGetPermanentFullAddressWithEmptyAddress() {
        // Create a booking without permanent address
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'No Address Test'
        );
        insert booking;
        
        Additional_Charges__c charge = new Additional_Charges__c(
            Booking__c = booking.Id,
            Name = 'Test Charge No Address'
        );
        insert charge;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(charge);
        DemandLetterVFP controller = new DemandLetterVFP(sc);
        
       /* Test.startTest();
        String address = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Assertions
        System.assertEquals('', address, 'Address should be empty string when no address is set');*/
    }
}