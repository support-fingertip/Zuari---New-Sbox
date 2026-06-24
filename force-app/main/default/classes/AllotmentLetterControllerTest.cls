@isTest
private class AllotmentLetterControllerTest {

    private static Booking__c createTestData(Boolean includeAllData) {
        Quote__c qc = new Quote__c(
            Quote_status__c = 'Converted',
            Block__c = ' ',
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100
        );
        insert qc;

        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Zuari Garden City',
            Active__c = true
        );
        insert pjt;

        Plot__c ut = new Plot__c(
            Name = 'Test plot',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        Master_payment_schedule__c mps = new Master_payment_schedule__c(
            Project__c = pjt.Id,
            Name = 'test',
            Payment_Percent__c = 20,
            Status__c = 'Completed'
        );
        insert mps;

        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            Project1__c = pjt.Id,
            Email__c = 'test@gmail.com',
            First_Applicant_Name__c = 'John Doe',
            Mobile__c = '9999999999',
            Booking_Date__c = Date.today()
        );
        insert book;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Payment_percent__c = 100,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c = true,
            Quote__c = qc.Id,
            Booking__c = book.Id,
            S_No__c = 1
        );
        insert ps;

        if (includeAllData) {
            Co_Applicant__c testCoApplicant = new Co_Applicant__c(
                Name = 'Test Co-Applicant',
                Email__c = 'coapplicant@example.com',
                Booking__c = book.Id,
                PAN_Number__c = 'ABCDE1234F',
                Passport_Number__c = 'A1234567',
                Date_of_Birth__c = System.today() - 7300,
                Nationality__c = 'NRI',
                Occupation__c = 'Employee',
                Son_Daughter_Wife_of__c = 'Test Parent',
                Salutation__c = 'Mrs.',
                Primary_Phone__c = '8888888888'
            );
            insert testCoApplicant;
        }

        return book;
    }

    @isTest
    static void testControllerWithAllData() {
        Booking__c book = createTestData(true);

        Test.setCurrentPage(new ApexPages.PageReference('/apex/fakePage'));
        ApexPages.currentPage().getParameters().put('Id', book.Id);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(book);
        AllotmentLetterController controller = new AllotmentLetterController(stdController);

        // Access all properties to cover getters
        Booking__c b = controller.booking;
        String pName = controller.projectName;
        String logo = controller.projectLogoUrl;
        String uLabel = controller.unitLabel;
        String gtWords = controller.grandTotalInWords;
        String trWords = controller.totalReceivedInWords;
        String paWords = controller.pendingAmountInWords;
        Co_Applicant__c coApp = controller.firstCoApplicant;
        List<Payment_Schedule__c> schedules = controller.paymentSchedules;

        Test.stopTest();
    }

    @isTest
    static void testControllerWithoutCoApplicant() {
        Booking__c book = createTestData(false);

        Test.setCurrentPage(new ApexPages.PageReference('/apex/fakePage'));
        ApexPages.currentPage().getParameters().put('Id', book.Id);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(book);
        AllotmentLetterController controller = new AllotmentLetterController(stdController);

        Co_Applicant__c coApp = controller.firstCoApplicant;
        List<Payment_Schedule__c> schedules = controller.paymentSchedules;

        Test.stopTest();
    }

    @isTest
    static void testControllerWithBlankId() {
        Booking__c book = createTestData(false);

        Test.setCurrentPage(new ApexPages.PageReference('/apex/fakePage'));
        // Do NOT set Id parameter — covers the blank Id error path

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(book);
        AllotmentLetterController controller = new AllotmentLetterController(stdController);
        Test.stopTest();
    }

    @isTest
    static void testGetPermanentFullAddressWithAllFields() {
        Booking__c book = createTestData(false);

        // Set full address fields
        book.Permanent_Address2__Street__s = '123 Main Street';
        book.Permanent_Address2__City__s = 'Bangalore';
        book.Permanent_Address2__StateCode__s = 'KA';
        book.Permanent_Address2__PostalCode__s = '560001';
        book.Permanent_Address2__CountryCode__s = 'IN';
        update book;

        Test.setCurrentPage(new ApexPages.PageReference('/apex/fakePage'));
        ApexPages.currentPage().getParameters().put('Id', book.Id);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(book);
        AllotmentLetterController controller = new AllotmentLetterController(stdController);

        // First call — triggers loadAddresses
        String address1 = controller.getPermanentFullAddress();
        // Second call — covers caching (addressesLoaded = true)
        String address2 = controller.getPermanentFullAddress();

        Test.stopTest();
    }

    @isTest
    static void testGetPermanentFullAddressWithNullAddress() {
        Booking__c book = createTestData(false);

        Test.setCurrentPage(new ApexPages.PageReference('/apex/fakePage'));
        ApexPages.currentPage().getParameters().put('Id', book.Id);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(book);
        AllotmentLetterController controller = new AllotmentLetterController(stdController);

        String address = controller.getPermanentFullAddress();

        Test.stopTest();
    }

    @isTest
    static void testGetPermanentFullAddressWithPartialFields() {
        Booking__c book = createTestData(false);

        book.Permanent_Address2__Street__s = '456 Oak Avenue';
        book.Permanent_Address2__City__s = 'Mumbai';
        // Leave state, postalCode, country blank
        update book;

        Test.setCurrentPage(new ApexPages.PageReference('/apex/fakePage'));
        ApexPages.currentPage().getParameters().put('Id', book.Id);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(book);
        AllotmentLetterController controller = new AllotmentLetterController(stdController);

        String address = controller.getPermanentFullAddress();

        Test.stopTest();
    }

    @isTest
    static void testGetUnitLabelFromType() {
        // Apartment / Flat / Residential → 'Flat'
        System.assertEquals('Flat', AllotmentLetterController.getUnitLabelFromType('Apartment'));
        System.assertEquals('Flat', AllotmentLetterController.getUnitLabelFromType('flat'));
        System.assertEquals('Flat', AllotmentLetterController.getUnitLabelFromType('Residential'));

        // Plot / Plotted Development → 'Plot'
        System.assertEquals('Plot', AllotmentLetterController.getUnitLabelFromType('Plot'));
        System.assertEquals('Plot', AllotmentLetterController.getUnitLabelFromType('Plotted Development'));

        // Villa / Independent House → 'Villa'
        System.assertEquals('Villa', AllotmentLetterController.getUnitLabelFromType('Villa'));
        System.assertEquals('Villa', AllotmentLetterController.getUnitLabelFromType('Independent House'));

        // Commercial → 'Office'
        System.assertEquals('Office', AllotmentLetterController.getUnitLabelFromType('Commercial'));

        // Shop → 'Shop'
        System.assertEquals('Shop', AllotmentLetterController.getUnitLabelFromType('Shop'));

        // Null / Blank → 'Unit'
        System.assertEquals('Unit', AllotmentLetterController.getUnitLabelFromType(null));
        System.assertEquals('Unit', AllotmentLetterController.getUnitLabelFromType(''));

        // Unknown value → capitalized fallback
        System.assertEquals('Warehouse', AllotmentLetterController.getUnitLabelFromType('Warehouse'));
    }
}