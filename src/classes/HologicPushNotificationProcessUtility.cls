/**
* @author Salesforce.com
* @date 2016
*
* @description Apex class used in the Process Builder to send a push notification to the specified user
*/
global with sharing class HologicPushNotificationProcessUtility {
    
    /*******************************************************************************************************
    * @description Sends a push notification with the specified url, message, and user ID
    */
    @InvocableMethod(label='Send push notification' description='Sends a push notification with the specified url, message, and user ID') 
    public static Void SendPushNotification(List<Info> infos) {
        
        for (Info i : infos) {
            HologicPushNotificationUtility thisNotification = new HologicPushNotificationUtility();
            thisNotification.sendNotification(i.messageUrl, i.userID, i.messageText);    
        }
    }
    
    /**
    * @author Salesforce.com
    * @date 2016
    *
    * @description Inner class used as a wrapper that contains variables passed in from the Process Builder
    */
    public class Info {
        
        @InvocableVariable(label='URL' required='false')
        public String messageUrl;
        
        @InvocableVariable(label='Message' required='true')
        public String messageText;
        
        @InvocableVariable(label='User ID' required='true')
        public String userID;
        
    }
}