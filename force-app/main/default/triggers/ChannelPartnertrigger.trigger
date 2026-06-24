/**
 * @lastModified  2026-05-25 — wired ChannelPartnerTriggerHandler.onAfterUpdate for CP email notifications (one-shot bundle deploy)
 */
trigger ChannelPartnertrigger on Channel_Partner__c (after insert, after update) {

    if (Trigger.isAfter && Trigger.isInsert) {
        ChannelPartnerTriggerHandler.onAfterInsert(Trigger.new);
        ChannelPartnerSharingHelper.shareWithSourcingRM(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        ChannelPartnerTriggerHandler.onApprovalSetPasswordAndNotify(Trigger.new, Trigger.oldMap);
        ChannelPartnerTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        ChannelPartnerSharingHelper.reshareOnSourcingRMChange(Trigger.new, Trigger.oldMap);
    }
}