public without sharing class LoggedInDeviceTriggerHandler {

    private static Boolean isExecuting = false;

    /**
     * Push Logged_in_Device__c.Last_Logged_In__c up to the parent
     * Channel_Partner__c.Last_Logged_Time__c whenever a device record is
     * inserted or its Last_Logged_In__c value changes.
     *
     * Semantics (per product decision):
     *   - Always overwrite -- do NOT compare against the parent's current
     *     Last_Logged_Time__c.
     *   - Within a single DML batch, when multiple devices for the same CP
     *     fire together, take the max Last_Logged_In__c so the latest event
     *     wins deterministically.
     *   - Skip records with a null Channel_Partner__c lookup.
     *   - Skip records where Last_Logged_In__c is null (clearing the field
     *     is not a login event, so we do not propagate null up).
     *   - On update, skip records whose Last_Logged_In__c was not changed.
     */
    public static void propagateLastLoggedTimeToParent(
        List<Logged_in_Device__c> newList,
        Map<Id, Logged_in_Device__c> oldMap
    ) {
        if (isExecuting || newList == null || newList.isEmpty()) {
            return;
        }

        isExecuting = true;
        try {
            Map<Id, DateTime> latestPerCp = new Map<Id, DateTime>();

            for (Logged_in_Device__c d : newList) {
                if (d.Channel_Partner__c == null || d.Last_Logged_In__c == null) {
                    continue;
                }
                if (oldMap != null) {
                    Logged_in_Device__c prev = oldMap.get(d.Id);
                    if (prev != null && prev.Last_Logged_In__c == d.Last_Logged_In__c) {
                        continue;
                    }
                }

                DateTime running = latestPerCp.get(d.Channel_Partner__c);
                if (running == null || d.Last_Logged_In__c > running) {
                    latestPerCp.put(d.Channel_Partner__c, d.Last_Logged_In__c);
                }
            }

            if (latestPerCp.isEmpty()) {
                return;
            }

            List<Channel_Partner__c> updates = new List<Channel_Partner__c>();
            for (Id cpId : latestPerCp.keySet()) {
                updates.add(new Channel_Partner__c(
                    Id = cpId,
                    Last_Logged_Time__c = latestPerCp.get(cpId)
                ));
            }
            update updates;
        } finally {
            isExecuting = false;
        }
    }
}