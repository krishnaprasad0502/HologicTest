/**************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 8/23/2018 5:10 AM
    Description  : Test Class for CommunityNavigationController    

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    8/23/2018       Nikhil Mutyam           Initial Creation                US-0005633
     11/13/2014       Sunil Sharma           Added Webchat code methods      US-0006077
    11/13/2014        Nomita Walke        Update test method                US-0006062
    09/01/2018      Vrushabh Katariya       Quicklinks for system detail Page       US-0006454
    10/01/2019        Nomita Walke            Updated Profile with custom label US-0006524
**************************************************************************************/

@isTest
public class CommunityNavigationController_Test {
    @testSetup static void setupTestData() {
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount) ;
            
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Phone= '+1-9009191923';
        cont.Accountid= testAccount.id;
        database.insert(cont);
            
        Profile p = [SELECT Id FROM Profile WHERE Name=: Label.Community_Profile_Name]; 
            
        User u = new User(Alias = 'hotest', Email='currentuser@test.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='currentuser@test.com', ContactId=cont.Id);
        database.insert(u);       
    }
    /*Test Method created to unit test methods of CommunityNavigationController*/
    public static testMethod void testfetchRecords(){
        Context_Test.customMetadata = 
        (List<Service_Community_Menu__mdt>) JSON.deserialize( '[{"Type__c ":"Product Information","Sort_Order__c ":"1"}]', list<Service_Community_Menu__mdt>.class );
        
        test.startTest();
            CommunityNavigationController.getCurrentUser();
            CommunityNavigationController.FetchRecords('Product Information');
            CommunityNavigationController.fetchConfigData();
            String str = CommunityNavigationController.truncateString('/hologicsupport/s/home');
            String str1 = CommunityNavigationController.truncateString('/s/home');
        test.stopTest();
    }
    
    static testMethod void testFetchConfigData() {
        User userRec = [Select id from User where Email ='currentuser@test.com' LIMIT 1] ;
        system.runAs(userRec){
            CommunityNavigationController webChatRef = new CommunityNavigationController();
            CommunityNavigationController.fetchConfigData();
            CommunityNavigationController.generateTechSupportSkillOptions();
            CommunityNavigationController.isOfflineHours();
            CommunityNavigationController.WebChatOptions refObj = new CommunityNavigationController.WebChatOptions('testSkill','12345');
        }
    }
    
    static testMethod void testReturnChatButtonId() {
        User userRec = [Select id from User where Email ='currentuser@test.com' LIMIT 1] ;
        system.runAs(userRec){
            CommunityNavigationController.returnChatButtonId('Parts Inquiries');            
        }
    }
    
    //  Quicklinks for system detail Page   US-0006454 
    //  This method helps to test covrage of method 'getDataCategory' from class 'CommunityNavigationController'
    static testMethod void testgetDataCategory() {
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Product2 prod = new Product2(Name = 'TestProd',Data_Category__c='Dimension__c');
        database.insert(prod);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id,product2Id=prod.Id);
        database.insert(newAsset);
        string cat = CommunityNavigationController.getDataCategory(newAsset.Id);       
            system.assertequals('Dimension__c',cat); 
    }
}