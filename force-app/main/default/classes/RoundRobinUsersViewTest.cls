@isTest
public class RoundRobinUsersViewTest {

    @isTest
    Public static void testRoundRobinMethods() {
        Round_Robin__c testRoundRobin = new Round_Robin__c();
        insert testRoundRobin;
        
        List<Round_Robin_Member__c> testMembers = new List<Round_Robin_Member__c>();
        for(Integer i = 0; i < 2; i++) {
            testMembers.add(new Round_Robin_Member__c(
                Round_Robin__c = testRoundRobin.Id,
                Active__c = true
            ));
        }
        insert testMembers;
        
        List<Round_Robin_Member__c> result1 = RoundRobinUsersView.fetchRoundRobinMembers(testRoundRobin.Id);
        
        for(Round_Robin_Member__c member : result1) {
            System.assertEquals(true, member.Active__c, 'Round Robin Member should be active');
        }
        
        Round_Robin_Member__c testMember = testMembers[0];
        List<Round_Robin_Member__c> updatedMembers;
        
        updatedMembers = RoundRobinUsersView.toggleMemberStatus(testMember.Id, testRoundRobin.Id);
        Round_Robin_Member__c updatedMember = updatedMembers[0];
        
        updatedMembers = RoundRobinUsersView.toggleMemberStatus(testMember.Id, testRoundRobin.Id);
        updatedMember = updatedMembers[0];
    }
}