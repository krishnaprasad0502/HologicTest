/**************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 8/13/2018 7:30 AM
    Description  : Fetch Menu Items from Custom Metadata and return to Lightning Component
    Test Class   : CommunityNavigationControllerTest    
    Coverage     : 100% 

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    8/13/2018       Nikhil Mutyam           Initial Creation                US-0005633
    10/25/2018      Nomita Walke            Updated FetchRecords()        US-0006062
    11/13/2014      Sunil Sharma            Added Webchat code methods    US-0006077
    11/20/2018      Sunil Sharma            Defect fix business hours and text update for Live Chat     US-0006172
	03/01/2019		Sunil Sharma			UI fix									US-0006454
	09/01/2018  	Vrushabh Katariya		Quicklinks for system detail Page		US-0006454 
	09/01/2018  	Sunil					Downloads & forums link fix				US-0006553 

**************************************************************************************/

public with sharing class CommunityNavigationController {
    
    /*
    * Method Name: getCurrentUser()
    * Input Param: No inputs required
    * Return: User 
    * Description: Fetch Current User Information.
    */
    @AuraEnabled
    public static User getCurrentUser(){
        User currentUser ;
        if(userInfo.getUserId() != null){
            currentUser= [SELECT id,FirstName,LastName,ProfileId,Profile.Name from User WHERE Id =: userInfo.getUserId()];
        }
        return currentUser ;
        
    }
    
    /*
    * Method Name: truncateString()
    * Input Param: String input required
    * Return: User 
    * Description: truncate the passed string.
    */
    @AuraEnabled
    public static String truncateString (String str) {
        String urlPathPrefix = '/hologicsupport';
        if (str != null && str.startsWith(urlPathPrefix)) {          
            return str.substring(urlPathPrefix.length());
        }else{
            return str;
        }
        
    }
    
    /*
    * Method Name: fetchConfigData()
    * Input Param: No inputs required
    * Return: Service_Community_Config__c 
    * Description: fetch Global Menu from Custom Setting
    */
    @AuraEnabled
    public static Service_Community_Config__c fetchConfigData(){
       Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
       return config;
    }
    
    /*
    * Method Name: isOfflineHours()
    * Input Param: No inputs required
    * Return: Boolean  
    * Description: Compute if the logged in user is using live chat between 8AM to 5PM.
    */
    @AuraEnabled
    public static Boolean isOfflineHours(){
        // Get the default business hours
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name='ServiceLiveChatSupport'];
        Datetime targetTime = System.now();
        String formattedTime = targetTime.format();
        Datetime currentLocalTime = DateTime.parse(formattedTime);
        // Find whether the time is within the default business hours
        Boolean isWithin= BusinessHours.isWithin(bh.id, currentLocalTime);
        
        return isWithin;
    }
    
    /*
    * Method Name: FetchRecords()
    * Input Param: Type(string)
    * Return: list<MenuItem> 
    * Description: Fetch records from custom meta data. It would return menu items
    */
    @AuraEnabled
    public static list<MenuItem> FetchRecords(string Type){
        list<MenuItem> MenuTypes = new list<MenuItem>();
        Service_Community_Config__c com_config = fetchConfigData();
        //Fetching the records from custom meta data
        for(Service_Community_Menu__mdt metadata : [SELECT Id, MasterLabel,Show_As_Hero_Menu__c,Is_Email__c, DeveloperName, Redirect_URL__c, 
                                                    Sort_Order__c,Is_Not_Hyperlink__c,IsCorporateSiteUrl__c, Type__c,Quick_Link_Menu_Name__c, Invoke_Component__c, Component_Name__c, Value2__c, Value1__c,Value3__c,
                                                    Subject__c
                                                    FROM Service_Community_Menu__mdt 
                                                    WHERE Type__c =: Type ORDER BY Sort_Order__c]){
            MenuItem sov = new MenuItem();
            sov.MenuItem_Title = metadata.Quick_Link_Menu_Name__c;
            sov.MenuItem_Id = metadata.Id;
            sov.MenuItem_Type = metadata.Type__c;
            /* Updated by Nomita - 25 Oct
            Generate the url by concatenating Site URL + Menu url so that the menu urls are constant across
            all environments and remain relative/partial. Site URL will contain the specific domain url for the 
            respective org.*/                                                
            //sov.MenuItem_Url = metadata.Redirect_URL__c;
            if(metadata.Redirect_URL__c != null && ! metadata.IsCorporateSiteUrl__c){
                sov.MenuItem_Url = com_config.SiteURL__c+metadata.Redirect_URL__c;
            }else if(metadata.IsCorporateSiteUrl__c){
                sov.MenuItem_Url = metadata.Redirect_URL__c;
            }
            
            sov.MenuItem_displayComponent = metadata.Invoke_Component__c;   
            sov.MenuItem_ComponentName = metadata.Component_Name__c;
            sov.MenuItem_Value1 = metadata.Value1__c;
            sov.MenuItem_Value2 = metadata.Value2__c; 
            sov.MenuItem_Value3 = metadata.Value3__c; 
            sov.MenuItem_Subject = metadata.Subject__c;                                             
            sov.MenuItem_IsHeroMenu = metadata.Show_As_Hero_Menu__c; 
            sov.MenuItem_IsEmailType = metadata.Is_Email__c ;  
            sov.MenuItem_IsNotHyperLink = metadata.Is_Not_Hyperlink__c ;
            MenuTypes.add(sov);
        }
        return MenuTypes;
    }
    
    /*
    * Method Name: returnChatButtonId()
    * Input Param: Skill Type
    * Return: String 
    * Description: Return chat button id based on the skill selected by the customer.
    */
    @AuraEnabled
    public static string returnChatButtonId(String skillType){
        system.debug('Skill Type is'+ skillType);
        List<ServiceLiveChatButtonCodes__mdt> chatButtonMetadata = new List<ServiceLiveChatButtonCodes__mdt>([SELECT Id,Chat_Button_Id__c FROM ServiceLiveChatButtonCodes__mdt WHERE Type__c =: skillType LIMIT 1]);
        if(chatButtonMetadata.size() > 0){
            system.debug('Chat button code are'+ chatButtonMetadata[0].Chat_Button_Id__c);
            return chatButtonMetadata[0].Chat_Button_Id__c ;
        }   else{
            return null ;
        }    
        
    }
    
    /*
    * Method Name: generateTechSupportSkillOptions()
    * Input Param: 
    * Return: List of object. 
    * Description: Return tech support skill options with chat button id mapped to them. 
    */
    @AuraEnabled
    public static List<WebChatController.WebChatOptions> generateTechSupportSkillOptions(){
        List<WebChatController.WebChatOptions> techSupportSkillsList = new List<WebChatController.WebChatOptions>() ;    
        for(ServiceLiveChatButtonCodes__mdt metaValue : [SELECT Id,MasterLabel,Chat_Button_Id__c FROM ServiceLiveChatButtonCodes__mdt WHERE Type__c = 'Technical Support Sub-Skills' ORDER BY Sort_Order__c ASC]){
            WebChatController.WebChatOptions skillData = new WebChatController.WebChatOptions(metaValue.MasterLabel,metaValue.Chat_Button_Id__c);
            techSupportSkillsList.add(skillData);
        }
        return techSupportSkillsList ; 
    }
    
    /*
    * Method Name: getForumId()
    * Input Param: Asset Record Id
    * Return: Id
    * Description: Return Id of asset related forum based on the community family name. 
    */
    @AuraEnabled
    public static String getForumId(String assetId){
        Asset currentAssetRec ;
        if(assetId != null && assetId != '' && assetId.startsWith('02i')){
            currentAssetRec = [SELECT id,Product2.Community_Family_Name__c FROM Asset WHERE Id=:assetId LIMIT 1];
            
            Network communityName ;
            if(Test.isRunningTest()){
                communityName = [SELECT id, name FROM Network WHERE Name = 'Hologic Support Portal'];
            }else{ 
                communityName = [SELECT id, name FROM Network WHERE Id =:Network.getNetworkId()];
            }
            ConnectApi.TopicPage topicRef ;
            if(currentAssetRec.Product2.Community_Family_Name__c =='Breast Biopsy'){
            	topicRef = ConnectApi.Topics.getTopics(communityName.Id,'Biopsy',false);     
            }else{
                topicRef = ConnectApi.Topics.getTopics(communityName.Id,currentAssetRec.Product2.Community_Family_Name__c,false);  
            }
            List<ConnectApi.Topic> topicDetail ;
            if(topicRef != null){
               topicDetail = topicRef.topics;
                if(topicDetail.size() > 0){
                	return topicDetail[0].Id;    
                }else{
                    return null ;
                }
                
            }else{
                return null ;
            }
            
        }
        return null ;
        
    }
    
    /*
    * Method Name: getDataCategory()
    * Input Param: Asset Record Id
    * Return: string. 
    * Description: Return string of data category associated with related Product of Asset. 
    * Quicklinks for system detail Page	US-0006454 
    */
    @AuraEnabled
    public static String  getDataCategory(Id AssetId){
        string category;
        category = [SELECT Id,Name,product2.Data_Category__c from Asset where Id =: AssetId].product2.Data_Category__c;
        if(String.isBlank(category)){
            return Null;
        }
        return category ; 
    }
    
    
    //Wrapper Class
    public class WebChatOptions{
        @AuraEnabled public string skillLabel;
        @AuraEnabled public string chatButtonId;
        
        public WebChatOptions(String skillName, String chatButtonCode){
            skillLabel = skillName ;
            chatButtonId = chatButtonCode ;
        }
    } 
    //Helper class
    public class MenuItem{
        @AuraEnabled public string MenuItem_Title;
        @AuraEnabled public string MenuItem_Id;
        @AuraEnabled public string MenuItem_Type;
        @AuraEnabled public string MenuItem_Url;
        @AuraEnabled public boolean MenuItem_displayComponent;
        @AuraEnabled public string MenuItem_ComponentName;
        @AuraEnabled public string MenuItem_Value1;
        @AuraEnabled public string MenuItem_Value2;
        @AuraEnabled public string MenuItem_Value3;
        @AuraEnabled public string MenuItem_Subject;
        @AuraEnabled public Boolean MenuItem_IsHeroMenu;
        @AuraEnabled public Boolean MenuItem_IsEmailType;
        @AuraEnabled public Boolean MenuItem_IsNotHyperLink;
    }
    
}