/**
* @author Salesforce.com
* @date 2016
*
* @description Utility class that sends out a push notification to the specified user
*/
public with sharing class HologicPushNotificationUtility {
    Boolean payloadIsPopulated = false; 
    
    public void sendNotification(String url, String userID, String message) {
    	Map<String, String> userData = new Map<String, String>();
    	if (!String.isBlank(url)) {
    		userData.put('url', url);	
    	}
    	
        Messaging.PushNotification msg = new Messaging.PushNotification();
        Map<String, Object> payload = Messaging.PushNotificationPayload.apple(message, '', null, userData);
        msg.setPayload(payload);
        Set<String> users = new Set<String>{userID};
            
        if(payload != null){
            payloadIsPopulated = true;
        }
        
        FSO__Settings__c settings = FSO__Settings__c.getOrgDefaults();
        
        if(!Test.isRunningTest()){
            if (settings != null && !String.isBlank(settings.FSO__Connected_App_API_Name__c)) {
                msg.send(settings.FSO__Connected_App_API_Name__c, users);
            } else {
                msg.send('Field_Service', users);
            }
        }
        
        
    }
}