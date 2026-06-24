public  without Sharing class pushRSToSalesController {
    
    // Returns the active users allowed to receive a Related Source push,
    // chosen from one of two Custom Labels (CP vs Direct Marketing) based
    // on the record's Source_Type__c. Usernames are stored as a
    // comma-separated list in the Custom Label values.
    @AuraEnabled
    public static List<User> getSalesUsersForRS(String recordId) {
        Related_Source__c rs = [
            SELECT Id, Source_Type__c
            FROM Related_Source__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        Boolean isCP = rs.Source_Type__c == 'Channel partner';
        String rawList = isCP ? System.Label.PushToSales_CP_Users
            : System.Label.PushToSales_DM_Users;
        
        Set<String> usernames = new Set<String>();
        if (String.isNotBlank(rawList)) {
            for (String u : rawList.split(',')) {
                String trimmed = u.trim();
                if (String.isNotBlank(trimmed)) {
                    usernames.add(trimmed);
                }
            }
        }
        
        if (usernames.isEmpty()) {
            return new List<User>();
        }
        
        return [
            SELECT Id, Name, Username
            FROM User
            WHERE IsActive = true AND Username IN :usernames
            ORDER BY Name
        ];
    }
    
    @AuraEnabled
    public static String moveRSToSales(String recordId, String newOwnerId, String addNote) {
        Related_Source__c rs = [
            SELECT Id, OwnerId, RecordTypeId, Lead_status1__c, Lead_Transfer_Note__c,
            Transfered_By__c, Transfered_On__c, Lead_Transfered__c, IsPushed__c,STM2__c,Channel_Partner1__c
            FROM Related_Source__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        Id salesRTId = Schema.SObjectType.Related_Source__c.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId();
        if(rs.Channel_Partner1__c != null){
            rs.STM2__c =newOwnerId;
        }else{
            
        rs.OwnerId               = newOwnerId;
        }
        rs.RecordTypeId          = salesRTId;
        if(rs.Lead_status1__c =='Pre-Sales Interested'){
            
            rs.Lead_status1__c       = 'Sales Follow up';
            
        }       if(rs.Lead_status1__c =='Pre-Sales Site Visit Schedule'){
            
            rs.Lead_status1__c       = 'Site Visit Schedule';
        }
        rs.Lead_Transfer_Note__c = addNote;
        rs.Transfered_By__c      = UserInfo.getUserId();
        rs.Transfered_On__c      = System.now();
        rs.Lead_Transfered__c    = true;
        rs.IsPushed__c           = true;
        
        update rs;
        sendLeadTransferEmail(rs.Id, newOwnerId, addNote);
        return rs.Id;
    }
    private static void sendLeadTransferEmail(Id relatedSourceId, Id ownerId, String note) {

    User newOwner = [
        SELECT Id, Name, Email
        FROM User
        WHERE Id = :ownerId
        LIMIT 1
    ];

    Related_Source__c rs = [
        SELECT Id, Name, Lead_status1__c
        FROM Related_Source__c
        WHERE Id = :relatedSourceId
        LIMIT 1
    ];
String recordUrl = URL.getOrgDomainUrl().toExternalForm()
    + '/lightning/r/Related_Source__c/' + rs.Id + '/view';
      //  List<OrgWideEmailAddress> owea = [ SELECT Id FROM OrgWideEmailAddress WHERE Address ='pattusudaru@gmail.com' LIMIT 1  ];
        
       List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE '%communication@crm.zuariproperties.com%' LIMIT 1];
   
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    mail.setToAddresses(new List<String>{ newOwner.Email });
  if (!owea.IsEmpty()) mail.setOrgWideEmailAddressId(owea[0].id);
          
    mail.setSubject('New Lead Assigned - ' + rs.Name);

    String body =
        'Hi ' + newOwner.Name + ',<br/><br/>' +
        'A lead has been transferred to you.<br/><br/>' +
        '<b>Lead Name:</b> ' + rs.Name + '<br/>' +
        '<b>Status:</b> ' + rs.Lead_status1__c + '<br/>' +
        '<b>Transfer Note:</b> ' + note + '<br/><br/>' +
        'Please review and take necessary action.<br/><br/>' +
        'Regards,<br/>' +
        UserInfo.getName();
body += '<br/><b>Record:</b> <a href="' + recordUrl + '">Open Lead</a>';
    mail.setHtmlBody(body);

    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
}
}