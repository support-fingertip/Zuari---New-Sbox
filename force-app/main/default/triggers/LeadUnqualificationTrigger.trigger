/**
 * Trigger Name  : LeadUnqualificationTrigger
 * Object        : Lead_Unqualification__c
 * Description   : Calls handler to map unqualification details
 *                 to Related_Source__c records
 * Author        : Sandeep
 * Created Date  : 21-Jan-2026
 */
trigger LeadUnqualificationTrigger on Lead_Unqualification__c (
    after insert,
    after update
) {

    // AFTER INSERT
    if (Trigger.isAfter && Trigger.isInsert) {
        LeadUnqualificationHandler.mapToRelatedSource(Trigger.new);
    }

    // AFTER UPDATE
    if (Trigger.isAfter && Trigger.isUpdate) {
        LeadUnqualificationHandler.mapToRelatedSource(Trigger.new);
    }
}