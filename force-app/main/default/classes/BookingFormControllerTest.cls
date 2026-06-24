@IsTest
private class BookingFormControllerTest {

    @IsTest
    static void testConstructorWithNoImage() {
        // Create a Booking record (only writable, required fields)
        Booking__c b = new Booking__c();
        insert b;

        // Set the current page and pass the Id as URL parameter
        PageReference pageRef = new PageReference('/apex/DummyPage');
        pageRef.getParameters().put('id', b.Id);
        Test.setCurrentPage(pageRef);

        // Call controller
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(b);
        BookingFormController ctrl = new BookingFormController(sc);
        Test.stopTest();

        // Basic checks
        System.assertNotEquals(null, ctrl.booking, 'Booking should be loaded.');
        System.assertEquals(b.Id, ctrl.booking.Id, 'Booking Id should match.');
        // No ContentDocumentLink created in this test, so imageUrl should stay null
        System.assertEquals(null, ctrl.imageUrl, 'imageUrl should be null when no image exists.');
    }
}