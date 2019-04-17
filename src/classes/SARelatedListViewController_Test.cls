/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: Test Class for SARelatedListViewController class
Controller Class: SARelatedListViewController

History:
<Date>              <Author Name>         <Brief description of change>         <Copa.do US#>
1/09/2018           Vrushabh Katariya       Initial creation                    US-0006454
1/19/2018           Vrushabh Katariya       PM schedule on Home page and 
                                            My System detail Page               US-0006553
****************************************************************************/
@isTest
public class SARelatedListViewController_Test {
    
    @testsetup
    static void testSetup(){
        
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('TestAccount', 'TestAccount1');
        database.insert(testAccount) ;
        
        Contact cont = new Contact();
        cont.FirstName='testContact';
        cont.LastName='ContactLastName';
        cont.Accountid= testAccount.id;
        cont.Phone= '+1-9009191923';
        database.insert(cont);
        
        Profile p = [SELECT Id FROM Profile WHERE Name=: Label.Community_Profile_Name]; 
        User u = new User(Alias = 'testUser', Email='currentuser@test.com', 
                          EmailEncodingKey='UTF-8', FirstName='FirstName',LastName='LastName', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='currentuser@test.com', ContactId=cont.Id);
        database.insert(u);
    }
    
    /*Test method to test fetchServiceAppointment method*/
    @isTest
    static void testfetchServiceAppointment(){
        Test.startTest();
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 1');
        database.insert(TestC);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id);
        database.insert(newAsset);
        SARelatedListViewController.fetchServiceAppointment('ServiceAppointment','Community_SAListView',newAsset.Id, 'YES');
        
        system.assertequals('Test Asset',newAsset.Name); 
        
        Test.stopTest();
    }
    
    /*Test method to test fetchServiceAppointment method*/
    @isTest
    static void testfetchServiceAppointment1(){
        Test.startTest();
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 1');
        database.insert(TestC);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id);
        database.insert(newAsset);
        SARelatedListViewController.fetchServiceAppointment('ServiceAppointment','Community_SAListView',newAsset.Id, 'NO');
        
        system.assertequals('Test Asset',newAsset.Name); 
        
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchConfigData()"*/
    @isTest static void testFetchConfigDataReturnsSuccess(){
        Test.startTest();
            Account newAcc = new Account(Name = 'TestAccount');
            database.insert(newAcc);
            Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 1');
            database.insert(TestC);
            Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id);
            database.insert(newAsset);
            Service_Community_Config__c configSetting = SARelatedListViewController.fetchConfigData();
            system.assertequals('Test Asset',newAsset.Name); 
        Test.stopTest();
    }
}