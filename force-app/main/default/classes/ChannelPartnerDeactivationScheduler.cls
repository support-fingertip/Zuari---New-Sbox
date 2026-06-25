/**
 * Daily scheduler for Batch_ChannelPartnerDeactivation.
 *
 * Schedule (one-time, anonymous Apex):
 *   System.schedule('CP Deactivation Daily', '0 0 2 * * ?',
 *                   new ChannelPartnerDeactivationScheduler());
 */
public without sharing class ChannelPartnerDeactivationScheduler implements Schedulable {

    @TestVisible private static final Integer DEFAULT_SCOPE = 200;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_ChannelPartnerDeactivation(), DEFAULT_SCOPE);
    }
}
