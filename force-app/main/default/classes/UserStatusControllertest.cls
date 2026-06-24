@isTest
public class UserStatusControllertest {
    public static testMethod void userstatustest(){
        //test.startTest();
        UserStatusController.getUserRec();
        User u = [SELECT Id,Name,ManagerId,Availability__c FROM User where Profile.Name='Sales'limit 1];
        
        UserStatusController.updateUser(u,'test');
        u.Availability__c=false;
        update u;
        UserStatusController.updateUser(u,'test');
        //test.stoptest();
    }
}