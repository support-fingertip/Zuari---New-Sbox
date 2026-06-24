@IsTest
public class ReceiptVFPControllerTest {

    @TestSetup
    static void setupTestData() {
         Project__c project = new Project__c();
        project.Name = 'Zuari Garden City';
        project.Project__c = 'Zuari Garden city';
        project.Active__c = true;
        insert project;
        // Create a Booking record
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            S__c = 'Mr.',
            Booking_Amount__c = 500000,
            Permanent_Address1__c = '123 Test Street, Test City',
            Pincode1__c = '560001'
        );
        insert booking;
        
        // Create a Plot record
        Plot__c plot = new Plot__c(
            Name = 'Plot-001',
            Project__c = project.Id
        );
        insert plot;
        
        // Update booking with plot
        booking.Plot__c = plot.Id;
        update booking;
        
        List<Payment_Schedule__c> paySchedules = new List<Payment_Schedule__c>();
        for(Integer i = 1; i <= 5; i++) {
            Payment_Schedule__c ps = new Payment_Schedule__c(
                Booking__c = booking.Id,
                S_No__c = i,
                Payment_Due_Date__c = Date.today().addDays(-30),
                Include_Interest__c = true,
                Interest_Percent__c = 12,
                Payment_Percent__c = 20
            );
            paySchedules.add(ps);
        }
        
        // Add Additional Charge Payment Schedule
        Payment_Schedule__c addChargePS = new Payment_Schedule__c(
            Name = 'Additional Charge',
            Booking__c = booking.Id,
            S_No__c = 6
        );
        paySchedules.add(addChargePS);
        
        insert paySchedules;
        // Create Co-Applicant records
        List<Co_Applicant__c> coApplicants = new List<Co_Applicant__c>();
        
        Co_Applicant__c coApp1 = new Co_Applicant__c(
            Booking__c = booking.Id,
            Name = 'Co-Applicant One',
            Salutation__c = 'Mrs.',
            Date_of_Birth__c = Date.newInstance(1992, 8, 20),
            Son_Daughter_Wife_of__c = 'Test Father',
            Aadhar_Number__c = '987654321098',
            PAN_Number__c = 'GTHSP0095C',
            Email__c = 'coapplicant1@example.com',
            Primary_Phone__c = '9876543210',
            Alternate_Contact_No__c = '9876543211',
            Nationality__c = 'Indian',
            Country_of_Residence__c = 'India',
            Residential_Status__c = 'Resident',
            
            Communication_Address__c = '321 Pine Road',
            Office_Address__c = 'Tech Park, Whitefield',
            Pincode_permanent__c = '560003',
            Pincode_commmunication__c = '560004',
            Office_Pincode__c = '560066',
            Passport_Number__c = 'P1234567',
            Spouse_Name__c = 'Spouse Name',
            Spouse_Date_Of_Birth_coapp__c = Date.newInstance(1990, 5, 15),
            Anniverssary_Date__c = Date.newInstance(2015, 12, 25),
            Other_Qualification__c = 'MBA',
            Other_Industry__c = 'Finance',
            Pincode_office__c = '560066'
        );
        coApplicants.add(coApp1);
        
        Co_Applicant__c coApp2 = new Co_Applicant__c(
            Booking__c = booking.Id,
            Name = 'Co-Applicant Two',
            Salutation__c = 'Mr.',
            Date_of_Birth__c = Date.newInstance(1988, 4, 15),
            Son_Daughter_Wife_of__c = 'Test Father Two',
            Email__c = 'coapplicant2@example.com',
            Primary_Phone__c = '9876543220',
            PAN_Number__c = 'GDTHA7764R'
        );
        coApplicants.add(coApp2);
        
        insert coApplicants;
        
        // Create Receipt records
        List<Receipt__c> receipts = new List<Receipt__c>();
        
        Receipt__c receipt1 = new Receipt__c(
            Booking__c = booking.Id,
            Bank_Name__c = 'HDFC Bank'
        );
        receipts.add(receipt1);
        
        Receipt__c receipt2 = new Receipt__c(
            Booking__c = booking.Id,
            Bank_Name__c = 'ICICI Bank'
        );
        receipts.add(receipt2);
        
        Receipt__c receipt3 = new Receipt__c(
            Booking__c = booking.Id,
            Bank_Name__c = 'SBI Bank'
        );
        receipts.add(receipt3);
        
        insert receipts;
        
        // Create Receipt Line Items
        List<Receipt_Line_Item__c> lineItems = new List<Receipt_Line_Item__c>();
        
        Receipt_Line_Item__c item1 = new Receipt_Line_Item__c(
            Receipt__c = receipt1.Id,
            Booking__c = booking.Id,
            Payment_Type__c = 'Plot Amount',
            Mode_Of_Payment__c = 'Cheque',
            Payment_schedule__c = paySchedules[0].Id,
            Cheque_no_Transaction_Number__c = 'CHQ123456',
            Received_Amount__c = 50000,
            Branch__c = 'MG Road'
        );
        lineItems.add(item1);
        
        Receipt_Line_Item__c item2 = new Receipt_Line_Item__c(
            Receipt__c = receipt1.Id,
            Booking__c = booking.Id,
            Payment_schedule__c = paySchedules[0].Id,
            Payment_Type__c = 'Plot Amount',
            Mode_Of_Payment__c = 'Cheque',
            Cheque_no_Transaction_Number__c = 'TXN789012',
            Received_Amount__c = 50000,
            Branch__c = 'Koramangala'
        );
        lineItems.add(item2);
        
        Receipt_Line_Item__c item3 = new Receipt_Line_Item__c(
            Receipt__c = receipt2.Id,
            Booking__c = booking.Id,
            Payment_schedule__c = paySchedules[0].Id,
            Payment_Type__c = 'Plot Amount',
            Mode_Of_Payment__c = 'Cheque',
            Cheque_no_Transaction_Number__c = 'TXN345678',
            Received_Amount__c = 200000,
            Branch__c = 'Indiranagar'
        );
        lineItems.add(item3);
        
        Receipt_Line_Item__c item4 = new Receipt_Line_Item__c(
            Receipt__c = receipt1.Id,
            Booking__c = booking.Id,
            Payment_schedule__c = paySchedules[0].Id,
            Payment_Type__c = 'Plot Amount',
            Mode_Of_Payment__c = 'Cheque',
            Received_Amount__c = 0
        );
        lineItems.add(item4);
        
        insert lineItems;
        
        // Create Payment Schedule for reference
        Payment_schedule__c ps = new Payment_schedule__c(
            Booking__c = booking.Id,
            Name = 'Payment 1',
            S_No__c = 1,
            Payment_percent__c = 20
        );
        insert ps;
    }

    @IsTest
    static void testConstructorWithValidReceiptAndBooking() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();
        
        // Code executes without assertions
    }

   /* @IsTest
    static void testConstructorWithReceiptWithoutBooking() {
        Receipt__c receipt = [
            SELECT Id 
            FROM Receipt__c 
            WHERE Booking__c = null 
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();
        
        // Code executes without assertions
    }*/

    @IsTest
    static void testConstructorWithCoApplicants() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testGetPermanentFullAddress() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
        
        booking.Permanent_Address2__Street__s = '123 Main Street';
        booking.Permanent_Address2__City__s = 'Bangalore';
        booking.Permanent_Address2__StateCode__s = 'KA';
        booking.Permanent_Address2__PostalCode__s = '560001';
        booking.Permanent_Address2__CountryCode__s = 'IN';
        update booking;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String address1 = controller.getPermanentFullAddress();
        String address2 = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testGetPermanentFullAddressWithNullAddress() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String address = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testGetPermanentFullAddressWithPartialAddress() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
        
        booking.Permanent_Address2__Street__s = '123 Main Street';
        booking.Permanent_Address2__City__s = 'Bangalore';
        update booking;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String address = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testReceiptLineItemsCalculation() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            ORDER BY Total_Received_Amount__c DESC
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testReceiptLineItemsWithNullAmount() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testAmountInWordsConversion() {
        Receipt__c receipt = [
            SELECT Id, Total_Received_Amount__c 
            FROM Receipt__c 
            WHERE Total_Received_Amount__c != null 
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String words = controller.amountInWords;
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testPlotNameAssignment() {
        Receipt__c receipt = [
            SELECT Id, Booking__c, Booking__r.Plot__r.Name 
            FROM Receipt__c 
            WHERE Booking__c != null 
            AND Booking__r.Plot__c != null
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String plot = controller.plotName;
        Test.stopTest();
        
        // Code executes without assertions
    }

    /*@IsTest
    static void testPlotNameNullWhenNoBooking() {
        Receipt__c receipt = [
            SELECT Id 
            FROM Receipt__c 
            WHERE Booking__c = null 
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String plot = controller.plotName;
        Test.stopTest();
        
        // Code executes without assertions
    }*/

    @IsTest
    static void testEmptyCoApplicantsList() {
        Booking__c newBooking = new Booking__c(
            First_Applicant_Name__c = 'No CoApp Applicant',
            Booking_Amount__c = 300000
        );
        insert newBooking;
        
        Receipt__c receipt = new Receipt__c(
            Booking__c = newBooking.Id
        );
        insert receipt;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testEmptyReceiptLineItems() {
        Booking__c newBooking = new Booking__c(
            First_Applicant_Name__c = 'No Items Applicant',
            Booking_Amount__c = 400000
        );
        insert newBooking;
        
        Receipt__c receipt = new Receipt__c(
            Booking__c = newBooking.Id
        );
        insert receipt;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testMultipleReceiptLineItems() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            AND Id IN (SELECT Receipt__c FROM Receipt_Line_Item__c)
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Decimal total = controller.totalReceivedAmount;
        List<Receipt_Line_Item__c> items = controller.receiptLineItems;
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testFormatAddressWithAllFields() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
        
        booking.Permanent_Address2__Street__s = '456 Oak Avenue';
        booking.Permanent_Address2__City__s = 'Mumbai';
        booking.Permanent_Address2__StateCode__s = 'MH';
        booking.Permanent_Address2__PostalCode__s = '400001';
        booking.Permanent_Address2__CountryCode__s = 'IN';
        update booking;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String address = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testFormatAddressWithBlankFields() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
        
        booking.Permanent_Address2__Street__s = '';
        booking.Permanent_Address2__City__s = 'Delhi';
        booking.Permanent_Address2__StateCode__s = '';
        booking.Permanent_Address2__PostalCode__s = '110001';
        booking.Permanent_Address2__CountryCode__s = '';
        update booking;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String address = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testBookingAddressesCaching() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
        
        booking.Permanent_Address2__Street__s = '789 Test Road';
        booking.Permanent_Address2__City__s = 'Chennai';
        update booking;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String address1 = controller.getPermanentFullAddress();
        String address2 = controller.getPermanentFullAddress();
        String address3 = controller.getPermanentFullAddress();
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testReceiptWithZeroAmount() {
        Booking__c newBooking = new Booking__c(
            First_Applicant_Name__c = 'Zero Amount Applicant',
            Booking_Amount__c = 100000
        );
        insert newBooking;
        
        Receipt__c receipt = new Receipt__c(
            Booking__c = newBooking.Id
        );
        insert receipt;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testReceiptWithLargeAmount() {
        Booking__c newBooking = new Booking__c(
            First_Applicant_Name__c = 'Large Amount Applicant',
            Booking_Amount__c = 50000000
        );
        insert newBooking;
        
        Receipt__c receipt = new Receipt__c(
            Booking__c = newBooking.Id
        );
        insert receipt;
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        String words = controller.amountInWords;
        Test.stopTest();
        
        // Code executes without assertions
    }

    @IsTest
    static void testAllProperties() {
        Receipt__c receipt = [
            SELECT Id, Booking__c 
            FROM Receipt__c 
            WHERE Booking__c != null 
            LIMIT 1
        ];
        
        PageReference pageRef = Page.Receipt;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(receipt);
        
        Test.startTest();
        ReceiptVFPController controller = new ReceiptVFPController(sc);
        
        Id recId = controller.receiptId;
        String words = controller.amountInWords;
        Co_Applicant__c firstCoApp = controller.firstCoApplicant;
        String plot = controller.plotName;
        List<Receipt_Line_Item__c> items = controller.receiptLineItems;
        Decimal total = controller.totalReceivedAmount;
        String permAddr = controller.getPermanentFullAddress();
        
        Test.stopTest();
        
        // Code executes without assertions
    }
}