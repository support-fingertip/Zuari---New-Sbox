/****************************************************************
* Class Name   : ENUM_MobileAPI
* Company      : Fingertipplus
* Created Date : 22-12-2025
*
* @description :
* This Apex REST API exposes the endpoint `/ENUMAPI/*` and is designed
* to provide all required picklist (enum) values to mobile and
* external applications in a single call.
*
* The API is primarily used to populate dropdowns, filters, and
* status indicators across the application.
*
* Functional Overview:
* - Exposes a GET endpoint to fetch picklist metadata.
* - Dynamically retrieves picklist values using Schema Describe.
* - Returns both API values and user-friendly labels.
* - Optionally enriches status values with UI color codes.
*
* Picklist Data Provided:
* - Lead Status
* - Lead Source
* - Rejected Reason
* - Site Visit Status
* - Follow-up Status
* - Project Status
* - Unit Type
* - Facing
* - Support Ticket Status
* - Support Ticket Priority
* - Issue Type
* - Announcement Status
* - Announcement Type
* - Notification Type
* - Call Type
* - Call Status
* - Invoice Status
* - Payment Status
*
* Additional Configuration Data:
* - TDS Percentage
* - GST Percentage
*
* Response Structure:
* - Returns a unified JSON response containing:
*     • Status
*     • Message
*     • Enum data grouped by functional area
*
* Key Features:
* - Centralized enum/picklist API for mobile apps
* - Schema-driven (no hardcoded picklist values)
* - Supports UI color mapping for status fields
* - Reduces multiple API calls from frontend
* - Easy to extend with new picklists
*
* Author       : Praveen Kumar
*
* Change Log:
* --------------------------------------------------------------------------
* Ver | Author         | Date       | Description
* --------------------------------------------------------------------------
* 1.0 | Praveen Kumar  | 27-12-2025 | Initial implementation
* --------------------------------------------------------------------------
**************************************************************/

@RestResource(urlMapping='/ENUMAPI/*')
global without sharing class ENUM_MobileAPI {
    
    @HttpGet
    global static void getPicklistValues() {
        // Create the response object
        EnumAPIResponse response = new EnumAPIResponse();
        response.status = true;
        response.message = 'Enum status data';
        response.data = new EnumData();
        
        // Build supportType with nested concernList (using dependency map)
        // response.data.supportType = new List<SupportTypeValue>();
        //  Map<String, List<String>> dependencyMap = ENUMRequestHelper.getSupportRequestDependentMap();
        
        // Get Support Type picklist values
        /*  List<PicklistValue> supportTypes = getPicklistValues('Support_Request__c', 'Support_Type__c');
for (PicklistValue st : supportTypes) {
SupportTypeValue stv = new SupportTypeValue();
stv.id = st.id;
stv.name = st.name;
stv.concernList = new List<PicklistValue>();

if (dependencyMap.containsKey(st.id)) {
for (String dep : dependencyMap.get(st.id)) {
PicklistValue pv = new PicklistValue();
pv.id = dep;
pv.name = dep;
stv.concernList.add(pv);
}
}
response.data.supportType.add(stv);
}
*/ 
        // Fetch Priority picklist values
        response.data.leadStatus = getPicklistValues('Related_Source__c', 'Lead_status1__c');
        response.data.leadSource = getPicklistValues('Lead', 'Lead_source__c');
        response.data.rejectedReasonStatus = getPicklistValues('Related_Source__c', 'Reason_For_Rejection__c');
        response.data.siteVisitStatus = getPicklistValues('Site_Visit__c', 'Status__c');
        response.data.followUpStatus = getPicklistValues('Follow_up__c', 'Status__c');
        response.data.projectStatus = getPicklistValues('Project__c', 'Project_Status__c');
        response.data.unitType = getPicklistValues('Project__c', 'Unit_Type__c');
        response.data.supportTicketStatus = getPicklistValues('Support_Ticket__c', 'Ticket_Status__c');
        response.data.supportTicketPriorityStatus = getPicklistValues('Support_Ticket__c', 'Priority_Status__c');
        response.data.issueType = getPicklistValues('Support_Ticket__c', 'Type__c');
        response.data.announcementStatus = getPicklistValues('Announcement__c', 'Announcement_Status__c');
        response.data.notificationType = getPicklistValues('Notification__c', 'Notification_Type__c');
        response.data.callType = getPicklistValues('Call_Detail__c', 'Call_Type_ENUM__c');//Updated on 10-03-2026
        response.data.callStatus = getPicklistValues('Call_Detail__c', 'Status__c');
        response.data.facingStatus = getPicklistValues('Project__c', 'Facing__c');
        response.data.invoiceStatus = getPicklistValues('Invoice__c', 'Invoice_Status__c');
        response.data.announcementType = getPicklistValues('Announcement__c', 'Announcement_Type__c');
        response.data.paymentStatus = getPicklistValues('Payment_Line_Item__c', 'Payament_Status__c');
        
        // Set links from custom labels
        response.data.TDSPercentage = '5.3';
        response.data.GSTPercentage = '12.5';
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
        public List<PicklistValue> leadStatus;
        public List<PicklistValue> leadSource;
        public List<PicklistValue> siteVisitStatus;
        public List<PicklistValue> followUpStatus;
        public List<PicklistValue> projectStatus;
        public List<PicklistValue> unitType;
        public List<PicklistValue> supportTicketStatus;
        public List<PicklistValue> supportTicketPriorityStatus;
        public List<PicklistValue> issueType;
        public List<PicklistValue> announcementStatus;
        public List<PicklistValue> notificationType;
        public List<PicklistValue> callType;
        public List<PicklistValue> callStatus;
        public List<PicklistValue> facingStatus;
        public List<PicklistValue> invoiceStatus;
        public List<PicklistValue> announcementType;
        public List<PicklistValue> paymentStatus;
        public List<PicklistValue> rejectedReasonStatus;
        public String TDSPercentage;
        public String GSTPercentage;
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
        'New'                    => '#FFD54F',
        'Allocated'              => '#FFD54F',
        'Offer'                  => '#FFD54F',
        'New Launch'             => '#FFD54F',

        // ---------- Active / In Progress ----------
        'Open'                   => '0xFF155DFC',
        'In Progress'            => '0xFF155DFC',
        'Scheduled'              => '0xFF155DFC',
        'Rescheduled'            => '0xFF155DFC',
        'Verified by GRE'        => '0xFF155DFC',
        'Site Visit Schedule'    => '0xFF155DFC',
        'Pre Sales Follow Up'    => '0xFF155DFC',

        // ---------- Pending / Follow-up ----------
        'Pending'                => '0xFFA65F00',
        'Medium'                 => '0xFFA65F00',
        'Not Completed'          => '0xFFA65F00',
        'RNR'                    => '0xFFA65F00',

        // ---------- Success / Completed ----------
        'Completed'              => '0xFF008236',
        'Approved'               => '0xFF008236',
        'Booked'                 => '#81C784',

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

        // ---------- Priority ----------
        'Low'                    => '#64B5F6'
    };

    return statusColorMap.containsKey(statusValue)
        ? statusColorMap.get(statusValue)
        : '#9E9E9E'; // Default grey
}
}