/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: Test Class for UserProfileDetailController class
Controller Class: UserProfileDetailController

History:
<Date>              <Author Name>        <Brief description of change>      <Copa.do US#>
03/01/2018          Vrushabh Kataria     Initial creation                   US-0006454

****************************************************************************/
@isTest
public class UserProfileDetailController_Test {
    
    @testsetup
    static void testSetup(){
        
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('TestAccount', 'TestAccount1');
        database.insert(testAccount) ;
        
        Contact cont = new Contact();
        cont.FirstName='testContact';
        cont.LastName='ContactLastName';
        cont.Accountid= testAccount.id;
        database.insert(cont);
        
        Profile p = [SELECT Id FROM Profile WHERE Name=:Label.Community_Profile_Name]; 
        User u = new User(Alias = 'testUser', Email='currentuser@test.com', 
                          EmailEncodingKey='UTF-8', FirstName='FirstName',LastName='LastName', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='currentuser@test.com', ContactId=cont.Id);
        database.insert(u);
    }
    
    /*Test method to test fucntionality of controller method -"fetchUser()"*/
    @isTest
    static void testFetchUser(){
        
        Test.startTest();
        User u = UserProfileDetailController.fetchUser();
        system.assertEquals(u.Id,UserInfo.getUserID());
        UserProfileDetailController.fetchConfigData();
        Test.stopTest();
    }
    
    
    /*Test method to test fucntionality of controller method -"UpdateUser()"*/
    @isTest
    static void testUpdateUser(){
        
        Test.startTest();
        User u = UserProfileDetailController.UpdateUser(UserInfo.getUserID(),'0123456789','12345','01234567498');
        system.assertEquals(u.Phone,'0123456789');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"SubmitNewCase()"*/
    @isTest
    static void testSubmitNewCase(){
        
        Test.startTest();
        case c = UserProfileDetailController.SubmitNewCase();
        system.assertEquals(c.Status,'New');
        Test.stopTest();
    }
}