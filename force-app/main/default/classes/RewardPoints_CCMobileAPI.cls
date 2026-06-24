/**
 * @description REST API to fetch reward points summary and reward list for Contact Center mobile app.
 * Validates customer using userId, fetches reward records, groups by reward type,
 * and returns reward criteria content from custom label.
 *
 * Request:
 * {
 *   "userId": "CPC001"
 * }
 *
 * @author Praveen Kumar
 * @version 1.0
 * @since 2026-02-25
 */
@RestResource(urlMapping='/CCRewardPointsAPI/*')
global without sharing class RewardPoints_CCMobileAPI {

    @HttpPost
    global static void getRewardPoints() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody != null ? req.requestBody.toString() : '';

        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'RewardPoints_CCMobileAPI';
        log.Request__c = requestBody;

        try {
            RewardPointsRequest requestData = (RewardPointsRequest) JSON.deserialize(requestBody, RewardPointsRequest.class);
            String userId = requestData != null ? requestData.userId : null;

            if (String.isBlank(userId)) {
                ErrorResponseUitilityClass.sendErrorResponse('Please provide userId', 'RewardPoints_CCMobileAPI', requestBody);
                return;
            }

            List<Customer_Master__c> customerList = [
                SELECT Id, Name
                FROM Customer_Master__c
                WHERE (Id = :userId OR Name = :userId)
                AND Active__c = true
                LIMIT 1
            ];

            if (customerList.isEmpty()) {
                ErrorResponseUitilityClass.sendErrorResponse('Customer Not Found', 'RewardPoints_CCMobileAPI', requestBody);
                return;
            }

            Id customerId = customerList[0].Id;

            List<Reward__c> rewardRecords = [
                SELECT Id, Reward_Type__c, Reward_Amount__c, Reward_Criteria__c
                FROM Reward__c
                WHERE Customer_Master__c = :customerId
                ORDER BY CreatedDate DESC
            ];

            Set<Id> rewardCriteriaIds = new Set<Id>();
            for (Reward__c rewardRec : rewardRecords) {
                if (rewardRec.Reward_Criteria__c != null) {
                    rewardCriteriaIds.add(rewardRec.Reward_Criteria__c);
                }
            }

            Map<Id, String> rewardCriteriaToSiteName = getRewardCriteriaSiteMap(rewardCriteriaIds);

            RewardPointsData data = new RewardPointsData();
            data.totalRewardBalance = 0;
            data.totalReferralEarnings = 0;
            data.rewardCriteria = '<ul>' +
                '<li>Qualified leads require a Lead Rating of 8 or above</li>' +
                '<li>Rewards points are created automatically upon successful conversion</li>' +
                '<li>Project-level rewards are set by Admin and may vary</li>' +
                '<li>All Rewards can be redeemed through GYFTR partners.</li>' +
                '</ul>';
            data.rewards = new List<RewardTypeGroup>();

            Map<String, RewardTypeGroup> groupedData = new Map<String, RewardTypeGroup>();
            List<String> orderedGroupNames = new List<String>();
            Decimal totalreward = 0;
            Decimal salesearning =0;
            for (Reward__c rewardRec : rewardRecords) {
                Decimal rewardAmount = rewardRec.Reward_Amount__c != null ? rewardRec.Reward_Amount__c : 0;
                String rewardType = rewardRec.Reward_Type__c != null ? rewardRec.Reward_Type__c : '';
                totalreward += rewardAmount;

                if (rewardType != null && rewardType.trim().toLowerCase() == 'booking') {
                    data.totalReferralEarnings += rewardAmount;
                    salesearning += rewardAmount;
                }
                String nameOfReward;
                String rewardTypeKey = rewardType != null ? rewardType.trim().toLowerCase() : '';
                if (rewardTypeKey == 'site visit' || rewardTypeKey == 'site vist' || rewardTypeKey == 'site visit reward') {
                    nameOfReward = 'Site Visit Reward';
                } else if (rewardTypeKey == 'booking') {
                    nameOfReward = 'Sales Rewards';
                } else {
                    nameOfReward = String.isBlank(rewardType) ? 'Other Rewards' : rewardType + ' Rewards';
                }

                if (!groupedData.containsKey(nameOfReward)) {
                    RewardTypeGroup newGroup = new RewardTypeGroup();
                    newGroup.nameOfReward = nameOfReward;
                    newGroup.rewardsData = new List<RewardLineItem>();
                    groupedData.put(nameOfReward, newGroup);
                    orderedGroupNames.add(nameOfReward);
                }

                String siteName = '';
                if (rewardRec.Reward_Criteria__c != null) {
                    Id rcId = rewardRec.Reward_Criteria__c;
                    siteName = rewardCriteriaToSiteName.containsKey(rcId) ? rewardCriteriaToSiteName.get(rcId) : '';
                }

                RewardLineItem lineItem = new RewardLineItem();
                lineItem.siteName = siteName;
                lineItem.rewardAmount = rewardAmount;
                groupedData.get(nameOfReward).rewardsData.add(lineItem);
            }

            data.totalRewardBalance = totalreward-salesearning;

            for (String groupName : orderedGroupNames) {
                data.rewards.add(groupedData.get(groupName));
            }

            RewardPointsResponse responseData = new RewardPointsResponse();
            responseData.status = true;
            responseData.message = 'Reward points data';
            responseData.data = data;

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));

            log.Response__c = 'Reward points data fetched: ' + rewardRecords.size();
            log.Status__c = 'SUCCESS';
            insert log;
        } catch (Exception e) {
            ErrorResponseUitilityClass.sendErrorResponse(e.getStackTraceString() + ' - ' + e.getMessage(), 'RewardPoints_CCMobileAPI', requestBody);
        }
    }

    private static Map<Id, String> getRewardCriteriaSiteMap(Set<Id> rewardCriteriaIds) {
        Map<Id, String> rewardCriteriaToSiteName = new Map<Id, String>();
        if (rewardCriteriaIds == null || rewardCriteriaIds.isEmpty()) {
            return rewardCriteriaToSiteName;
        }

        List<Reward_Criteria__c> rcRecords = [
            SELECT Id, Project__c, Project__r.Name
            FROM Reward_Criteria__c
            WHERE Id IN :rewardCriteriaIds
        ];

        for (Reward_Criteria__c rcRec : rcRecords) {
            rewardCriteriaToSiteName.put(
                rcRec.Id,
                (rcRec.Project__r != null && rcRec.Project__r.Name != null) ? rcRec.Project__r.Name : ''
            );
        }

        return rewardCriteriaToSiteName;
    }

    public class RewardPointsRequest {
        public String userId;
    }

    public class RewardLineItem {
        public String siteName;
        public Decimal rewardAmount;
    }

    public class RewardTypeGroup {
        public String nameOfReward;
        public List<RewardLineItem> rewardsData;
    }

    public class RewardPointsData {
        public Decimal totalRewardBalance;
        public Decimal totalReferralEarnings;
        public String rewardCriteria;
        public List<RewardTypeGroup> rewards;
    }

    public class RewardPointsResponse {
        public Boolean status;
        public String message;
        public RewardPointsData data;
    }
}