/**************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 11/05/2018 
    Description  : Fetch custom setting data and metadata for showing the skill options for live chat. 
    Test Class   : WebChatController_Test    
    Coverage     : 

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    11/05/2018       Sunil Kumar Sharma     Initial Creation                US-0006077
**************************************************************************************/
public without sharing class WebChatController{

    public String chatButtonId {get;set;}  //selected chat button id based on selected skill.
    public User currentUser {get;set;}     //Variable to store the current user information.
    public Contact currentUserContact {get;set;}   //Variable to store the current customer contact information.
    public Service_Community_Config__c customSettingData ;
    public String submitCaseUrl {get;set;}
    //Constructor
    public WebChatController(){
		chatButtonId = ApexPages.currentPage().getParameters().get('buttonCode') ;
        currentUser = [SELECT Id,ContactId FROM User WHERE Id =: Userinfo.getUserId() LIMIT 1];
        system.debug('User info is'+ currentUser.ContactId);
        if(currentUser.ContactId != null){
        	currentUserContact = [SELECT Id,AccountId,Customer_Account__c,Account.ParentId,Email,phone,firstName,lastName FROM contact where Id=: currentUser.ContactId];
        	system.debug('contact info is'+ currentUserContact);
        }
        customSettingData = Service_Community_Config__c.getOrgDefaults();
        submitCaseUrl = customSettingData.SiteURL__c+customSettingData.My_Service_Requests__c;	
    }
    
    public void fetchConfigDataSetting(){
        customSettingData = Service_Community_Config__c.getOrgDefaults();
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
    
    //Wrapper Class
    public class WebChatOptions{
        @AuraEnabled public string skillLabel;
        @AuraEnabled public string chatButtonId;
        
        public WebChatOptions(String skillName, String chatButtonCode){
            skillLabel = skillName ;
            chatButtonId = chatButtonCode ;
        }
    }    
}