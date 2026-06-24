public class NotificationController {
 public static void sendCustomNotification(Set<String> recepientIds, String title, String body, Id recId, String notificationName){
        CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
        Notification.setNotificationTypeId(closedWonNotification.id); 
        Notification.setSenderId(Userinfo.getUserId()); 
        Notification.setBody(body); 
        Notification.setTitle(title); 
        Notification.setTargetId(recId);
        try{
            Notification.send(recepientIds);
        }catch(exception e){
            
        }
        
    }
}