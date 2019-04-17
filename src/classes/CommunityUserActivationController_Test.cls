/**************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: Test Class for CommunityUserActivationController class
Controller Class: CommunityUserActivationController

History:
<Date>              <Author Name>        <Brief description of change >     <Copa.do US#>           
12-09-2018          Sunil Kumar Sharma   Initial Creation                   US-0006553 
**************************************************************************************/
@isTest
public class CommunityUserActivationController_Test {
    @testSetup static void setupTestData() {
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount) ;
        
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Accountid= testAccount.id;
        cont.Email = 'test@gmail.com';
        cont.Phone= '+1-9009191923';
        database.insert(cont);
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login User - Customer']; 
        
        User u = new User(Alias = 'hotest', Email='currentuser@test.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='currentuser@test.com', ContactId=cont.Id);
        database.insert(u);  
    }
    @isTest static void testEnableCommunityUser(){
        List<Contact> contactId = new List<Contact>([SELECT Id FROM Contact WHERE FirstName = 'Test']);
        CommunityUserActivationController.enableCommunityUser(contactId[0].Id) ;
    }
    @isTest static void testEnableCommunityUser1(){
        List<Contact> contactId = new List<Contact>([SELECT Id FROM Contact WHERE FirstName = 'Test']);
        contactId[0].Email = '' ;
        update contactId ;
        CommunityUserActivationController.enableCommunityUser(contactId[0].Id) ;
    }
    @isTest static void testdisableCommunityUserSuccess(){
        List<Contact> contactId = new List<Contact>([SELECT Id FROM Contact WHERE FirstName = 'Test']);
        CommunityUserActivationController.disableCommunityUser(contactId[0].Id) ;
    }
    @isTest static void testdisableCommunityUserFailure(){
        List<Contact> contactId = new List<Contact>([SELECT Id FROM Contact WHERE FirstName = 'Test1']);
        CommunityUserActivationController.disableCommunityUser(null) ;
    }
    @isTest static void testCheckCommunityUserSuccess(){
        List<Contact> contactId = new List<Contact>([SELECT Id FROM Contact WHERE FirstName = 'Test']);
        CommunityUserActivationController.checkCommunityUser(contactId[0].Id) ;
    }
    @isTest static void testCheckCommunityUserFailure(){
        List<Contact> contactId = new List<Contact>([SELECT Id FROM Contact WHERE FirstName = 'Test']);
        CommunityUserActivationController.checkCommunityUser( null) ;
    }
}