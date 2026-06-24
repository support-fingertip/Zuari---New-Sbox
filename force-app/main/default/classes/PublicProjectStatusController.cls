/**
 * Controller backing the public Project Status site page.
 * Exposes read-only data for the Project -> Block -> Payment Plan -> Master Payment Schedule hierarchy.
 * Declared `without sharing` so the Site guest user can read the records regardless of sharing rules.
 */
public without sharing class PublicProjectStatusController {

    @AuraEnabled(cacheable=true)
    public static Project__c getProject(Id projectId) {
        if (projectId == null) return null;
        List<Project__c> projects = [
            SELECT Id, Name, Project__c
            FROM Project__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        return projects.isEmpty() ? null : projects[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<Block__c> getBlocks(Id projectId) {
        if (projectId == null) return new List<Block__c>();
        return [
            SELECT Id, Name
            FROM Block__c
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Payment_Plan__c> getPaymentPlans(Id blockId) {
        if (blockId == null) return new List<Payment_Plan__c>();
        return [
            SELECT Id, Name
            FROM Payment_Plan__c
            WHERE Block__c = :blockId AND Active__c = true
            ORDER BY Name ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<MpsWrapper> getMasterPaymentSchedule(Id paymentPlanId) {
        List<MpsWrapper> result = new List<MpsWrapper>();
        if (paymentPlanId == null) return result;

        List<Master_Payment_Schedule__c> mpsList = [
            SELECT Id, Name, Status__c, Payment_Percent__c, S_No__c
            FROM Master_Payment_Schedule__c
            WHERE Payment_Plan__c = :paymentPlanId
            ORDER BY S_No__c ASC
        ];

        Map<Id, String> imageUrlByMpsId = new Map<Id, String>();
        if (!mpsList.isEmpty()) {
            Set<Id> mpsIds = (new Map<Id, Master_Payment_Schedule__c>(mpsList)).keySet();
            for (ContentDocumentLink link : [
                SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :mpsIds
            ]) {
                if (!imageUrlByMpsId.containsKey(link.LinkedEntityId)) {
                    imageUrlByMpsId.put(
                        link.LinkedEntityId,
                        '/sfc/servlet.shepherd/version/download/' + link.ContentDocument.LatestPublishedVersionId
                    );
                }
            }
        }

        for (Master_Payment_Schedule__c mps : mpsList) {
            result.add(new MpsWrapper(mps, imageUrlByMpsId.get(mps.Id)));
        }
        return result;
    }

    public class MpsWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal percent;
        @AuraEnabled public String imageUrl;

        public MpsWrapper(Master_Payment_Schedule__c mps, String imageUrl) {
            this.id = mps.Id;
            this.name = mps.Name;
            this.status = mps.Status__c;
            this.percent = mps.Payment_Percent__c;
            this.imageUrl = imageUrl;
        }
    }
}