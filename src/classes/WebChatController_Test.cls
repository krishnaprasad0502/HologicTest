/**************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 11/05/2018 
    Description  : Test class for WebChatController Class
    Test Class   : WebChatController_Test    
    Coverage     : 

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    11/05/2018       Sunil Kumar Sharma     Initial Creation                US-0006077
**************************************************************************************/
@isTest
public class WebChatController_Test {
    @testSetup static void setupTestData() {
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount) ;
        
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Accountid= testAccount.id;
        cont.Phone= '+1-9009191923';
        database.insert(cont);
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login User - Customer']; 
        
        User u = new User(Alias = 'hotest', Email='currentuser@test.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='currentuser@test.com', ContactId=cont.Id);
        database.insert(u);       
    }
    
    static testMethod void testFetchConfigData() {
        User userRec = [Select id from User where Email ='currentuser@test.com' LIMIT 1] ;
        system.runAs(userRec){
            WebChatController webChatRef = new WebChatController();
            webChatRef.fetchConfigDataSetting();
            WebChatController.fetchConfigData();
            WebChatController.generateTechSupportSkillOptions();
            
        }
    }
    
    static testMethod void testReturnChatButtonId() {
        User userRec = [Select id from User where Email ='currentuser@test.com' LIMIT 1] ;
        system.runAs(userRec){
            WebChatController.returnChatButtonId('Parts Inquiries');            
        }
    }
    
}