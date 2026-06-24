public with sharing class MilestoneCompletionVFPController {
    public Master_Payment_Schedule__c milestoneRec { get; set; }
    public String projectName { get; set; }
    public String masterScheduleName { get; set; }
    public Date completedDate { get; set; }
    public String projectHeadName { get; set; }

    public MilestoneCompletionVFPController(ApexPages.StandardController stdController) {
        Id milestoneId = stdController.getId();
        milestoneRec = [
            SELECT Id, Name, Completed_Date__c,
                   Project__c, Project__r.Name,
                   Project__r.Project_Head__c, Project__r.Project_Head__r.Name
            FROM Master_Payment_Schedule__c
            WHERE Id = :milestoneId
            LIMIT 1
        ];
        if (milestoneRec != null) {
            masterScheduleName = milestoneRec.Name;
            completedDate = milestoneRec.Completed_Date__c;
            projectName = milestoneRec.Project__r.Name;
            projectHeadName = milestoneRec.Project__r.Project_Head__r.Name;
        }
    }

    @AuraEnabled
    public static Map<String, Object> getMilestoneDetails(Id milestoneId) {
        Master_Payment_Schedule__c milestone = [
            SELECT Id, Name, Completed_Date__c
            FROM Master_Payment_Schedule__c
            WHERE Id = :milestoneId
            LIMIT 1
        ];

        Map<String, Object> result = new Map<String, Object>();
        result.put('completedDate', milestone.Completed_Date__c);
        return result;
    }
}