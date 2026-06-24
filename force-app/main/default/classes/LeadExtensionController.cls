/**
 * @description Backs the leadExtensionRequest LWC. RM submits an extension
 *              request that routes to the lead owner's manager (TL); the TL
 *              approves or rejects. On approve, Extension_Days__c is
 *              incremented and the Expiry_Date__c formula recomputes.
 */
public with sharing class LeadExtensionController {

    public class LeadExtensionException extends Exception {}

    /**
     * Snapshot the LWC renders on load. The same component shows either the
     * request form (RM, no pending request) or the approval form (TL,
     * pending request awaiting them).
     */
    public class RequestState {
        @AuraEnabled public Id      recordId;
        @AuraEnabled public Date    expiryDate;
        @AuraEnabled public Decimal expiryDays;
        @AuraEnabled public Decimal extensionDays;
        @AuraEnabled public String  status;
        @AuraEnabled public Decimal requestedDays;
        @AuraEnabled public Id      requestedById;
        @AuraEnabled public String  requestedByName;
        @AuraEnabled public Id      approverId;
        @AuraEnabled public String  approverName;
        @AuraEnabled public DateTime requestedAt;
        @AuraEnabled public DateTime decidedAt;
        @AuraEnabled public String  decisionNotes;
        @AuraEnabled public Boolean canRequest;
        @AuraEnabled public Boolean canDecide;
        @AuraEnabled public String  message;
    }

    @AuraEnabled(cacheable=false)
    public static RequestState getRequestState(Id recordId) {
        if (recordId == null) {
            throw new LeadExtensionException('Record id is required.');
        }
        Related_Source__c rs = loadRecord(recordId);
        return toState(rs, UserInfo.getUserId());
    }

    @AuraEnabled
    public static RequestState submitRequest(Id recordId, Decimal days, String reason) {
        if (recordId == null) {
            throw new LeadExtensionException('Record id is required.');
        }
        if (days == null || days <= 0) {
            throw new LeadExtensionException('Requested days must be greater than zero.');
        }

        Related_Source__c rs = loadRecord(recordId);

        if (rs.Extension_Status__c == 'Pending') {
            throw new LeadExtensionException('An extension request is already pending for this lead.');
        }

        Id currentUserId = UserInfo.getUserId();
        Id approverId    = resolveApprover(currentUserId, rs.OwnerId);
        if (approverId == null) {
            throw new LeadExtensionException(
                'No Team Leader (User.ManagerId) is configured for the requester. Set the Manager field on the User record.');
        }

        rs.Extension_Status__c          = 'Pending';
        rs.Extension_Requested_Days__c  = days;
        rs.Extension_Requested_By__c    = currentUserId;
        rs.Extension_Approver__c        = approverId;
        rs.Extension_Requested_At__c    = System.now();
        rs.Extension_Decision_Notes__c  = String.isBlank(reason) ? null : reason;
        rs.Extension_Decided_At__c      = null;
        update rs;

        notifyApprover(rs, approverId, days, reason);

        return toState(loadRecord(recordId), currentUserId);
    }

    @AuraEnabled
    public static RequestState approveRequest(Id recordId, String notes) {
        return decide(recordId, true, notes);
    }

    @AuraEnabled
    public static RequestState rejectRequest(Id recordId, String notes) {
        return decide(recordId, false, notes);
    }

    private static RequestState decide(Id recordId, Boolean approve, String notes) {
        if (recordId == null) {
            throw new LeadExtensionException('Record id is required.');
        }
        Related_Source__c rs = loadRecord(recordId);

        if (rs.Extension_Status__c != 'Pending') {
            throw new LeadExtensionException('There is no pending extension request to decide.');
        }
        Id currentUserId = UserInfo.getUserId();
        if (rs.Extension_Approver__c != currentUserId) {
            throw new LeadExtensionException('Only the designated Team Leader can decide this request.');
        }

        Decimal requestedDays = rs.Extension_Requested_Days__c == null ? 0 : rs.Extension_Requested_Days__c;
        Decimal currentExt    = rs.Extension_Days__c == null ? 0 : rs.Extension_Days__c;

        if (approve) {
            rs.Extension_Days__c   = currentExt + requestedDays;
            rs.Extension_Status__c = 'Approved';
            rs.Expiry_Days__c = rs.Expiry_Days__c + rs.Extension_Days__c;
        } else {
            rs.Extension_Status__c = 'Rejected';
            rs.Extension_Days__c = 0;
        }
        rs.Extension_Decided_At__c     = System.now();
        rs.Extension_Decision_Notes__c = String.isBlank(notes) ? rs.Extension_Decision_Notes__c : notes;
        update rs;

        notifyRequester(rs, approve, requestedDays, notes);

        return toState(loadRecord(recordId), currentUserId);
    }

    // ------------------------------------------------------------
    //  Helpers
    // ------------------------------------------------------------

    private static Related_Source__c loadRecord(Id recordId) {
        List<Related_Source__c> recs = [
            SELECT Id, Name, OwnerId, Owner.Name, Owner.Email,
                   Expiry_Date__c, Expiry_Days__c, Extension_Days__c,
                   Extension_Status__c, Extension_Requested_Days__c,
                   Extension_Requested_By__c, Extension_Requested_By__r.Name,
                   Extension_Requested_By__r.Email,
                   Extension_Approver__c, Extension_Approver__r.Name,
                   Extension_Approver__r.Email,
                   Extension_Requested_At__c, Extension_Decided_At__c,
                   Extension_Decision_Notes__c
            FROM   Related_Source__c
            WHERE  Id = :recordId
            LIMIT  1
        ];
        if (recs.isEmpty()) {
            throw new LeadExtensionException('Related Source not found.');
        }
        return recs[0];
    }

    private static Id resolveApprover(Id requesterId, Id ownerId) {
        Set<Id> userIds = new Set<Id>{ requesterId };
        if (ownerId != null) userIds.add(ownerId);

        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, ManagerId FROM User WHERE Id IN :userIds
        ]);
        User requester = userMap.get(requesterId);
        if (requester != null && requester.ManagerId != null) {
            return requester.ManagerId;
        }
        if (ownerId != null) {
            User owner = userMap.get(ownerId);
            if (owner != null && owner.ManagerId != null) {
                return owner.ManagerId;
            }
        }
        return null;
    }

    private static RequestState toState(Related_Source__c rs, Id currentUserId) {
        RequestState s = new RequestState();
        s.recordId        = rs.Id;
        s.expiryDate      = rs.Expiry_Date__c;
        s.expiryDays      = rs.Expiry_Days__c;
        s.extensionDays   = rs.Extension_Days__c;
        s.status          = rs.Extension_Status__c;
        s.requestedDays   = rs.Extension_Requested_Days__c;
        s.requestedById   = rs.Extension_Requested_By__c;
        s.requestedByName = rs.Extension_Requested_By__r != null ? rs.Extension_Requested_By__r.Name : null;
        s.approverId      = rs.Extension_Approver__c;
        s.approverName    = rs.Extension_Approver__r    != null ? rs.Extension_Approver__r.Name    : null;
        s.requestedAt     = rs.Extension_Requested_At__c;
        s.decidedAt       = rs.Extension_Decided_At__c;
        s.decisionNotes   = rs.Extension_Decision_Notes__c;
        s.canRequest      = (rs.Extension_Status__c != 'Pending');
        s.canDecide       = (rs.Extension_Status__c == 'Pending' && rs.Extension_Approver__c == currentUserId);
        return s;
    }

    private static void notifyApprover(Related_Source__c rs, Id approverId, Decimal days, String reason) {
        String title = 'Lead Extension Request: ' + rs.Name;
        String body  = UserInfo.getName() + ' requested ' + days + ' extra day(s) on ' + rs.Name +
                       (String.isBlank(reason) ? '.' : ' — ' + reason);
        sendCustomNotification('Lead_Extension_Approval', title, body, rs.Id, new Set<Id>{ approverId });

        if (Test.isRunningTest()) return;
        User approver = [SELECT Email FROM User WHERE Id = :approverId LIMIT 1];
        if (String.isBlank(approver.Email)) return;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ approver.Email });
        mail.setSaveAsActivity(false);
        mail.setSubject('[Lead Extension] Approval needed for ' + rs.Name);
        mail.setPlainTextBody(
            'Hello,\n\n' +
            UserInfo.getName() + ' has requested ' + days + ' day(s) of extension on Related Source ' + rs.Name + '.\n' +
            (String.isBlank(reason) ? '' : 'Reason: ' + reason + '\n') +
            '\nPlease open the record to approve or reject:\n' +
            URL.getOrgDomainUrl().toExternalForm() + '/' + rs.Id + '\n\n' +
            '-- Lead Extension'
        );
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail }, false);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Approver email failed: ' + ex.getMessage());
        }
    }

    private static void notifyRequester(Related_Source__c rs, Boolean approve, Decimal days, String notes) {
        if (rs.Extension_Requested_By__c == null) return;

        String verdict = approve ? 'APPROVED' : 'REJECTED';
        String title   = 'Lead Extension ' + verdict + ': ' + rs.Name;
        String body    = UserInfo.getName() + ' ' + verdict.toLowerCase() + ' your ' + days +
                         '-day extension request on ' + rs.Name + '.';
        sendCustomNotification('Lead_Extension_Approval', title, body, rs.Id,
                               new Set<Id>{ rs.Extension_Requested_By__c });

        if (Test.isRunningTest()) return;
        String requesterEmail = rs.Extension_Requested_By__r != null ? rs.Extension_Requested_By__r.Email : null;
        if (String.isBlank(requesterEmail)) return;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ requesterEmail });
        mail.setSaveAsActivity(false);
        mail.setSubject('[Lead Extension] ' + verdict + ' - ' + rs.Name);
        mail.setPlainTextBody(
            'Hello,\n\n' +
            'Your ' + days + '-day extension request on Related Source ' + rs.Name +
            ' was ' + verdict.toLowerCase() + ' by ' + UserInfo.getName() + '.\n' +
            (String.isBlank(notes) ? '' : 'Notes: ' + notes + '\n') +
            (approve ? 'New expiry date: ' + rs.Expiry_Date__c + '\n' : '') +
            '\n' + URL.getOrgDomainUrl().toExternalForm() + '/' + rs.Id + '\n\n' +
            '-- Lead Extension'
        );
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail }, false);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Requester email failed: ' + ex.getMessage());
        }
    }

    private static void sendCustomNotification(String typeName, String title, String body, Id targetId, Set<Id> recipientIds) {
        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType WHERE DeveloperName = :typeName LIMIT 1
        ];
        if (types.isEmpty()) return;
        Messaging.CustomNotification n = new Messaging.CustomNotification();
        n.setNotificationTypeId(types[0].Id);
        n.setSenderId(UserInfo.getUserId());
        n.setTitle(title);
        n.setBody(body);
        n.setTargetId(targetId);
        // Messaging.CustomNotification.send() expects Set<String> of recipient ids.
        Set<String> recipientStrings = new Set<String>();
        for (Id rid : recipientIds) {
            if (rid != null) recipientStrings.add(String.valueOf(rid));
        }
        if (recipientStrings.isEmpty()) return;
        try {
            n.send(recipientStrings);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'CustomNotification send failed: ' + ex.getMessage());
        }
    }
}