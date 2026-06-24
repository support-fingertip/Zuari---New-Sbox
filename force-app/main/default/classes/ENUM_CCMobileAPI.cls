@RestResource(urlMapping='/CCENUMAPI/*')
global without sharing class ENUM_CCMobileAPI {
    
       @HttpGet
    global static void getPicklistValues() {
        // Create the response object
        EnumAPIResponse response = new EnumAPIResponse();
        response.status = true;
        response.message = 'Enum status data';
        response.data = new EnumData();
        
       
        // Fetch Priority picklist values
        response.data.projectMilestone = getPicklistValues('Project__c', 'Project_Status__c');
        response.data.supportTicketPriorityStatus = getPicklistValues('Customer_Query__c', 'Priority__c');
        response.data.supportTicketStatus = getPicklistValues('Customer_Query__c', 'Query_Status__c');
        response.data.milstoneStatus = getPicklistValues('Payment_schedule__c', 'status__c');
        response.data.paymentStatus = getPicklistValues('Receipt__c', 'Approval_status__c');
        response.data.demandPaymentStatus = getPicklistValues('Demand_Raised__c', 'Demand_Status__c');
        response.data.referralStatus = getPicklistValues('Referral__c', 'Status__c');
        response.data.queryType = getPicklistValues('Customer_Query__c', 'Query_Type__c');
        response.data.querySubType = getPicklistValues('Customer_Query__c', 'Query_Sub_Type__c');
        response.data.notificationType = getPicklistValues('Customer_Portal_Notification__c', 'Notification_Type__c');
        response.data.feedbackRating = getPicklistValues('Customer_Query__c', 'Feedback_Rating__c');
        
        // Set links from custom labels

        //response.data.termsAndConditionLink = System.Label.TermsAndConditionLink;
        
        // Send the response
        sendResponse(response);
    }
    
    // Helper: get picklist values
    private static List<PicklistValue> getPicklistValues(String objectName, String fieldName) {
        List<PicklistValue> picklistValues = new List<PicklistValue>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) return picklistValues;
        
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            PicklistValue picklistValue = new PicklistValue();
            picklistValue.id = entry.getValue();  // API Name
            picklistValue.name = entry.getLabel(); // Label
            picklistValue.statusColor = getStatusColor(entry.getValue());
            picklistValues.add(picklistValue);
        }
        return picklistValues;
    }
    
    // Helper method to send response
    private static void sendResponse(EnumAPIResponse response) {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
    }
    
    // Response wrapper
    public class EnumAPIResponse {
        public Boolean status;
        public String message;
        public EnumData data;
    }
    
    // Data wrapper
    public class EnumData {
        public List<PicklistValue> projectMilestone;
        public List<PicklistValue> supportTicketPriorityStatus;
        public List<PicklistValue> supportTicketStatus;
        public List<PicklistValue> paymentStatus;
        public List<PicklistValue> demandPaymentStatus;
        public List<PicklistValue> referralStatus;
        public List<PicklistValue> queryType;
        public List<PicklistValue> querySubType;
        public List<PicklistValue> notificationType;
        public List<PicklistValue> feedbackRating;
 public List<PicklistValue> milstoneStatus;
        //public String termsAndConditionLink;


    }
    
    // Basic picklist wrapper
    public virtual class PicklistValue {
        public String id;
        public String name;
        public String statusColor;
    }
    
    // Support Type wrapper (with nested concernList)
    public class SupportTypeValue extends PicklistValue {
        public List<PicklistValue> concernList;
    }
    
    private static String getStatusColor(String statusValue) {

    Map<String, String> statusColorMap = new Map<String, String>{

        // ---------- New / Highlight ----------
        'New'                    => '0xFFFFD54F',
        'Allocated'              => '0xFFFFD54F',
        'Offer'                  => '0xFFFFD54F',
        'New Launch'             => '0xFFFFD54F',
        'Demand Raised'             => '0xFFFFD54F',

        // ---------- Active / In Progress ----------
        'Open'                   => '0xFF155DFC',
        'In Progress'            => '0xFF155DFC',
        'Scheduled'              => '0xFF155DFC',
        'Rescheduled'            => '0xFF155DFC',
        'Verified by GRE'        => '0xFF155DFC',
        'Site Visit Schedule'    => '0xFF155DFC',
        'Pre Sales Follow Up'    => '0xFF155DFC',
        'Demand Reversed'    => '0xFF155DFC',

        // ---------- Pending / Follow-up ----------
        'Pending'                => '0xFFA65F00',
        'Medium'                 => '0xFFA65F00',
        'Not Completed'          => '0xFFA65F00',
        'RNR'                    => '0xFFA65F00',

        // ---------- Success / Completed ----------
        'Completed'              => '0xFF008236',
        'Approved'               => '0xFF008236',
        'Booked'                 => '0xFF81C784',

        // ---------- Negative / Closed / Rejected ----------
        'Rejected'               => '0xFFC10007',
        'Request for Rejection'  => '0xFFC10007',
        'Unqualified'            => '0xFFC10007',
        'Missed'                 => '0xFFC10007',
        'Escalated'              => '0xFFC10007',
        'Cancelled'              => '0xFFC10007',
        'Close'                  => '0xFFC10007',
        'High'                   => '0xFFC10007',
        'Closed Lost'                   => '0xFFC10007',
        'Demand Cancelled'                   => '0xFFC10007',

        // ---------- Priority ----------
        'Low'                    => '0xFF64B5F6'
    };

    return statusColorMap.containsKey(statusValue)
        ? statusColorMap.get(statusValue)
        : '0xFF9E9E9E'; // Default grey
}
}