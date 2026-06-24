/**
 * @description REST API endpoint for Contact Center mobile application to retrieve booked units.
 * Validates the customer using userId and retrieves all associated Booking__c records with related unit details.
 *
 * Request:
 * {
 *   "userId": "CPC0023",
 *   "pageSize": 0
 * }
 *
 * Response (Success):
 * {
 *   "status": true,
 *   "message": "My Booked Units List",
 *   "data": [
 *     {
 *       "unitId": "UT01",
 *       "unitName": "Green Meadows",
 *       "unitLocation": "Whitefield, Bangalore",
 *       "unitNumber": "Tower A • A-504",
 *       "unitType": "3 BHK",
 *       "unitStatus": "Nearing Completion"
 *     }
 *   ]
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-18
 */
@RestResource(urlMapping='/CCMyBookedUnitsAPI/*')
global without sharing class MyBookedUnit_CCMobileAPI {

    /**
     * @description Handles POST requests to retrieve booked units for a customer.
     * Validates userId, queries associated Booking__c records with related Unit and Project information,
     * and returns formatted list of booked units.
     * All requests and responses are logged to Apex_Log__c for audit trail.
     */
    @HttpPost
    global static void getMyBookedUnits() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'MyBookedUnit_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            BookedUnitsWrapper requestData = (BookedUnitsWrapper) JSON.deserialize(requestBody, BookedUnitsWrapper.class);

            String userId = requestData.userId;
            Integer pageSize = requestData.pageSize;

            // Validate that required fields are not empty
            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'MyBookedUnit_CCMobileAPI', requestBody);
                return;
            }

            // Query customer by userId (Name or Id)
            List<Customer_Master__c> cmList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = True
                LIMIT 1
            ];

            if (cmList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'MyBookedUnit_CCMobileAPI', requestBody);
                return;
            }

            Customer_Master__c customer = cmList[0];

            // Calculate offset based on pageSize (pageSize * 15 records per page)
            System.debug(customer);

Integer noforecord = 15;
Integer offset = noforecord * pageSize;

List<Booking__c> bookingList = [
    SELECT Id, Name,
           Plot__c, Plot__r.Name, Plot__r.BHK_Type__c,Plot__r.Plot_Type__c ,Unit_No__c,
           Plot__r.Project__c, Plot__r.Project__r.Name,
           Plot__r.Project__r.Project_Address__c,
           Plot__r.Project__r.Project_Status__c,
           Plot__r.Project__r.Project_Id__c
    FROM Booking__c
    WHERE Customer_Master__c = :customer.Id
    ORDER BY CreatedDate DESC
    LIMIT :noforecord OFFSET :offset
];

            System.debug(bookingList.Size());
            // If no bookings found, return error response
            if (bookingList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('No booked units found for customer ' + customer.Id, 'MyBookedUnit_CCMobileAPI', requestBody);
                return;
            }

            // Build response data array
            List<BookingResponse> bookingResponseList = new List<BookingResponse>();

            for (Booking__c booking : bookingList) {
                BookingResponse bookingResponse = new BookingResponse();
                bookingResponse.bookingId = booking.Name != null ? booking.Name : '';
                bookingResponse.projectId = booking.Plot__r.Project__r.Project_Id__c != null ? booking.Plot__r.Project__r.Project_Id__c : '';
                bookingResponse.unitName = booking.Plot__r.Project__r.Name != null ? booking.Plot__r.Project__r.Name : '';
                bookingResponse.unitLocation = booking.Plot__r.Project__r.Project_Address__c != null ? booking.Plot__r.Project__r.Project_Address__c : '';
                bookingResponse.unitNumber = booking.Unit_No__c != null ? booking.Unit_No__c : '';
                bookingResponse.unitType = booking.Plot__r.BHK_Type__c != null ? booking.Plot__r.BHK_Type__c : booking.Plot__r.Plot_Type__c != null ? booking.Plot__r.Plot_Type__c : '';
                bookingResponse.unitStatus = booking.Plot__r.Project__r.Project_Status__c != null ? booking.Plot__r.Project__r.Project_Status__c : '';
                bookingResponseList.add(bookingResponse);
            }

            // Build response data object with totalBooking count and bookings array
            MyBookedUnitsResponseData responseData = new MyBookedUnitsResponseData();
            responseData.totalBooking = bookingList.size();
            responseData.bookings = bookingResponseList;

            // Build successful response
            MyBookedUnitsResponse response = new MyBookedUnitsResponse();
            response.status = true;
            response.message = 'My Booked Units List';
            response.data = responseData;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));

            log.Response__c = 'Retrieved ' + bookingList.size() + ' booked units for ' + customer.Id;
            log.Status__c = 'SUCCESS';
            insert log;

        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'MyBookedUnit_CCMobileAPI', requestBody);
        }
    }

    /**
     * @description Wrapper class for deserializing booked units request JSON.
     */
    public class BookedUnitsWrapper {
        public String userId;    // Customer identifier (Id or Name)
        public Integer pageSize; // Number of records to retrieve (0 for all)
    }

    /**
     * @description Wrapper class for individual booking item in response.
     */
    public class BookingResponse {
        public String bookingId; 
        public String projectId;     // Booking record Id
        public String unitName;       // Project name
        public String unitLocation;   // Project location
        public String unitNumber;     // Unit/Plot number
        public String unitType;       // Unit/Plot type (BHK)
        public String unitStatus;     // Booking status
    }

    /**
     * @description Wrapper class for response data container.
     */
    public class MyBookedUnitsResponseData {
        public Integer totalBooking;         // Total number of bookings
        public List<BookingResponse> bookings; // Array of booking items
    }

    /**
     * @description Wrapper class for complete API response.
     */
    public class MyBookedUnitsResponse {
        public Boolean status;                 // Response status
        public String message;                 // Response message
        public MyBookedUnitsResponseData data; // Response data container
    }

}