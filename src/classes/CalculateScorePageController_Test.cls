/*-----------------------------------------------------------------------------------------------------------------------------------
Author:       Raviraj Reddy
Description:  Test Class for Controller class 'CalculateScorePageController' 


History:
<Date>       <Authors Name>    <Brief Description of Change>
03/21/2018    Raviraj Reddy     Initial Creation (US3808)         
------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class CalculateScorePageController_Test {
    private static testMethod void method1() {
         Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;


        User user1 = new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
        
        insert user1;
        System.runAs(user1){
        ID prospectRecTypeId =  [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1].id;
        ID siteRecTypeId = [SELECT Id FROM RecordType WHERE DeveloperName ='Site' Limit 1].id;
        
    
        Account objSoldToAcc = TestUtility.newAccount('Test Account - 00001', '', '', null, prospectRecTypeId );
        objSoldToAcc.ShippingStateCode = 'AK';
        objSoldToAcc.ShippingCountryCode = 'US'; 
        objSoldToAcc.ShippingPostalCode = '10010'; 
        objSoldToAcc.ShippingCity = 'citay'; 
        objSoldToAcc.CurrencyIsoCode = 'USD';
        objSoldToAcc.CDQ_Status__c = 'New';
        objSoldToAcc.ShippingStreet = 'SHIPTest1 \n SHIPTest2 \n SHIPTest3 \n SHIPTest4';
        insert objSoldToAcc;
        
        Account objShipToAcc = TestUtility.newAccount('Test Account - 00002', '', '', null, siteRecTypeId );
        objShipToAcc.ParentId=objSoldToAcc.Id;
        objShipToAcc.ShippingStateCode = 'AK';
        objShipToAcc.ShippingCountryCode = 'US'; 
        objShipToAcc.ShippingPostalCode = '10010'; 
        objShipToAcc.ShippingCity = 'citay';
        objShipToAcc.CurrencyIsoCode = 'USD';
        objShipToAcc.CDQ_Status__c = 'New'; 
        objShipToAcc.ShippingStreet = 'test1';
        insert objShipToAcc;
        
        Contact contact = new Contact( FirstName = 'Test', LastName = 'User', AccountId = objSoldToAcc.Id);
        insert contact;
        
        AMPS_Marketing_Activity_Flow__c flow2 = new AMPS_Marketing_Activity_Flow__c();
        flow2.Name = 'QUARTERLY ACTIVITY - 02';
        flow2.AMPS_Track__c = 'GREEN';
        flow2.Initiating_Task_Type__c = 'GREEN';
        insert flow2;
        
        AMPS_Marketing_Activity_Flow__c flow = new AMPS_Marketing_Activity_Flow__c ();
        flow.Name = 'QUARTERLY ACTIVITY - 01';
        flow.AMPS_Track__c = 'GREEN';
        flow.Initiating_Task_Type__c = 'GREEN';
        flow.Next_Task__c = flow2.id;
        insert flow;
        List<Asset> AssetList=new List<Asset>();
        AssetList.add(new Asset(
            name='test',
            AccountID=objSoldToAcc.id
            ));
        insert AssetList;
        PageReference myVfPage = Page.CalculateScorePage;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('ParentID',AssetList[0].Id);
        CalculateScorePageController con = new CalculateScorePageController(new ApexPages.StandardController(AssetList[0]));
        
        con.revenueGrowth='Green';
        con.sculpsureBrand= 'Green'; 
        con.staffAndProviders= 'Green'; 
        con.cashPayBusiness= 'Green'; 
        con.finalCode= 'Green'; 
        
        con.SaveTask();
        
      }  
  }

  private static testMethod void method2() {
       Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;


        User user1 = new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
        
        insert user1;
        System.runAs(user1){
        ID prospectRecTypeId =  [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1].id;
        ID siteRecTypeId = [SELECT Id FROM RecordType WHERE DeveloperName ='Site' Limit 1].id;
        
    
        Account objSoldToAcc = TestUtility.newAccount('Test Account - 00001', '', '', null, prospectRecTypeId );
        objSoldToAcc.ShippingStateCode = 'AK';
        objSoldToAcc.ShippingCountryCode = 'US'; 
        objSoldToAcc.ShippingPostalCode = '10010'; 
        objSoldToAcc.ShippingCity = 'citay'; 
        objSoldToAcc.CurrencyIsoCode = 'USD';
        objSoldToAcc.CDQ_Status__c = 'New';
        objSoldToAcc.ShippingStreet = 'SHIPTest1 \n SHIPTest2 \n SHIPTest3 \n SHIPTest4';
        insert objSoldToAcc;
        
        Account objShipToAcc = TestUtility.newAccount('Test Account - 00002', '', '', null, siteRecTypeId );
        objShipToAcc.ParentId=objSoldToAcc.Id;
        objShipToAcc.ShippingStateCode = 'AK';
        objShipToAcc.ShippingCountryCode = 'US'; 
        objShipToAcc.ShippingPostalCode = '10010'; 
        objShipToAcc.ShippingCity = 'citay';
        objShipToAcc.CurrencyIsoCode = 'USD';
        objShipToAcc.CDQ_Status__c = 'New'; 
        objShipToAcc.ShippingStreet = 'test1';
        insert objShipToAcc;
        
        Contact contact = new Contact( FirstName = 'Test', LastName = 'User', AccountId = objSoldToAcc.Id);
        insert contact;
        
        List<Asset> AssetList = new List<Asset>();
        AssetList.add(new Asset(
            name='test',
            AccountID=objSoldToAcc.id
            ));
        insert AssetList;
        
        
        PageReference myVfPage = Page.CalculateScorePage;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('ParentID',AssetList[0].Id);
        CalculateScorePageController con = new CalculateScorePageController(new ApexPages.StandardController(AssetList[0]));
        
        con.revenueGrowth='';
        con.sculpsureBrand= ''; 
        con.staffAndProviders= ''; 
        con.cashPayBusiness= ''; 
        con.finalCode= '';   
        
        con.SaveTask();
        
        
      }  
  }
}