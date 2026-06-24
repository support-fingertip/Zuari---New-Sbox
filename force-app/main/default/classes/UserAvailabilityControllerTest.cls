@isTest
public class UserAvailabilityControllerTest {
	 public static testMethod void userstatustest(){
        //test.startTest();
         UserAvailabilityController.getAllUsers('System Administrator');
         UserAvailabilityController.getMyUsers();
         User u = [SELECT Id,Name,Availability__c,is_working__c FROM User WHERE Id=:userinfo.getuserid()];
         UserAvailabilityController.updateUser('test',u);
          UserAvailabilityController.updateUser2(u);
         //test.stoptest();
     }
}