/*------------------------------------------------------------
Author:       Raviraj Reddy
Description:  Test Class for AccountChildrenActivities

History:
<Date>       <Authors Name>    <Brief Description of Change>
03/21/2018   Raviraj Reddy      Initial Creation (US3819)             
------------------------------------------------------------*/

@isTest
public class AccountChildrenActivities_Test {
    static testmethod void testPage(){
    
        
        Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;

        List<User> lstTestUsers = new List<User>{new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester1@hologic.com'),
            
            new User(alias = 'test1234', email='test1234@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester2@hologic.com'),
            
           new User(alias = 'test123', email='test12345@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing15', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester3@hologic.com')
            
        };
        
        
        insert lstTestUsers;
        
        System.runAs(lstTestUsers[0]){
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
        
        Contact contact = new Contact( FirstName = 'Test', LastName = 'User', AccountId = objSoldToAcc.Id, Phone ='+2032544455');
        insert contact;
        
        List<Asset> assetsToInsert = new List<Asset>{
             new Asset(Name='test1',accountID=objSoldToAcc.id,SerialNumber= 'SCLP871519'),
             new Asset(Name='test2',accountID=objSoldToAcc.id,SerialNumber= 'SCLP871520')
        };
        
        insert assetsToInsert ;
        
        List<Asset_Team__c> assetTeamToInsert = new List<Asset_Team__c>{
            new Asset_Team__c(Asset__c = assetsToInsert[0].Id, User__c=lstTestUsers[0].Id, Relationship__c='AMPS Representative'),
            new Asset_Team__c(Asset__c = assetsToInsert[1].Id, User__c=lstTestUsers[1].Id, Relationship__c='AMPS Representative')
        };
        
        insert assetTeamToInsert;
        
        
        List<Task> lstTaskToInsert = new List<Task>{
            new Task(Subject = 'Call' , Status = 'Completed', WhatId = assetsToInsert[0].Id,whoiD=contact.Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 2' , status = 'Completed' , whoiD=contact.Id,WhatId = assetsToInsert [0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId() ),
            new Task(Subject = 'Test Subject - 3' ,status = 'Completed',whoiD=contact.Id, WhatId = assetsToInsert [0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 4' , status = 'Completed',whoiD=contact.Id, WhatId = assetsToInsert [0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 5' , status = 'Completed' , WhatId = assetsToInsert [0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 6' , status = 'Completed' , WhatId = assetsToInsert [1].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 7' , status = 'Completed' , WhatId = assetsToInsert [1].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 8' , status = 'Completed' , WhatId = assetsToInsert [1].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 9' , status = 'Completed' , WhatId = assetsToInsert [1].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 10' ,status = 'Completed' , WhatId = assetsToInsert [1].Id ,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId())
        };
        
        insert lstTaskToInsert;
        lstTaskToInsert[0].Description = 'Test';
        update lstTaskToInsert[0];
        

        
        AccountChildrenActivities aca = new AccountChildrenActivities (new ApexPages.StandardController(objSoldToAcc));  

        aca.strLaserSelect = ''+assetsToInsert[0].ID;
        aca.updatePage();
        aca.strLaserSelect = 'None';
        aca.updatePage();
        List<SelectOption> options = aca.lstLaserOwnedSelect;
        string test21 = aca.mapIdToAMPSUser;
        String test33 = aca.mapIdToEmails;
        
        
       } 
    }
    static testmethod void testPage1(){
    
        
        Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;

        List<User> lstTestUsers = new List<User>{new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester1@hologic.com'),
            
            new User(alias = 'test1234', email='test1234@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing1', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester2@hologic.com'),
            
           new User(alias = 'test123', email='test12345@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing15', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester3@hologic.com')
            
        };
        
        
        insert lstTestUsers;
        
        System.runAs(lstTestUsers[0]){
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
        
        Contact contact = new Contact( FirstName = 'Test', LastName = 'User', AccountId = objSoldToAcc.Id, Phone ='+2032544455');
        insert contact;
         List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true,Description='test product',Family='Sculpsure'));
        }
       
        System.assertNotEquals(prodList,null,'success');
        insert prodList;
        List<Asset> assetsToInsert = new List<Asset>{
             new Asset(Name='test1',accountID=objSoldToAcc.id,SerialNumber= '871519',Product2Id=prodList[0].id),
             new Asset(Name='test2',accountID=objSoldToAcc.id,SerialNumber= '871520',Product2Id=prodList[0].id)
        };
        
        insert assetsToInsert ;
        
        List<Asset_Team__c> assetTeamToInsert = new List<Asset_Team__c>{
            new Asset_Team__c(Asset__c = assetsToInsert[0].Id, User__c=lstTestUsers[0].Id, Relationship__c='AMPS Representative'),
             new Asset_Team__c(Asset__c = assetsToInsert[0].Id, User__c=lstTestUsers[1].Id, Relationship__c='AMPS Representative'),
           
                new Asset_Team__c(Asset__c = assetsToInsert[1].Id, User__c=lstTestUsers[1].Id, Relationship__c='AMPS Representative')
        };
        
        insert assetTeamToInsert;
        
        
        List<Task> lstTaskToInsert = new List<Task>{
            new Task(Subject = 'Call' , Status = 'Completed', WhatId = assetsToInsert[0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 2' , status = 'Completed' , WhatId = assetsToInsert [0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId() ),
            new Task(Subject = 'Test Subject - 3' ,status = 'Completed', WhatId = assetsToInsert [0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 4' , status = 'Completed', WhatId = assetsToInsert [0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 5' , status = 'Completed' , WhatId = assetsToInsert [0].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 6' , status = 'Completed' , WhatId = assetsToInsert [1].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 7' , status = 'Completed' , WhatId = assetsToInsert [1].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 8' , status = 'Completed' , WhatId = assetsToInsert [1].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 9' , status = 'Completed' , WhatId = assetsToInsert [1].Id,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId()),
            new Task(Subject = 'Test Subject - 10' ,status = 'Completed' , WhatId = assetsToInsert [1].Id ,recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId())
        };
        
        insert lstTaskToInsert;
        lstTaskToInsert[0].Description = 'Test';
        update lstTaskToInsert[0];
        
             
        List<Event> lstEventToInsert = new List<Event>{
            new Event(Subject = 'Call' ,WhatId = assetsToInsert[0].Id,DurationInMinutes=10,ActivityDateTime=system.today(),whoiD=contact.Id)
            /*new Event(Subject = 'Test Subject - 2' , WhatId = assetsToInsert [0].Id,DurationInMinutes=10,ActivityDateTime=system.today()),
            new Event(Subject = 'Test Subject - 3' , WhatId = assetsToInsert [0].Id,DurationInMinutes=10),
            new Event(Subject = 'Test Subject - 4' , WhatId = assetsToInsert [0].Id,DurationInMinutes=10),
            new Event(Subject = 'Test Subject - 5' , WhatId = assetsToInsert [0].Id,DurationInMinutes=10),
            new Event(Subject = 'Test Subject - 6' ,  WhatId = assetsToInsert [1].Id,DurationInMinutes=10),
            new Event(Subject = 'Test Subject - 7' , WhatId = assetsToInsert [1].Id,DurationInMinutes=10),
            new Event(Subject = 'Test Subject - 8' ,  WhatId = assetsToInsert [1].Id,DurationInMinutes=10),
            new Event(Subject = 'Test Subject - 9' , WhatId = assetsToInsert [1].Id,DurationInMinutes=10),
            new Event(Subject = 'Test Subject - 10' , WhatId = assetsToInsert [1].Id,DurationInMinutes=10)*/
        };
        
        insert lstEventToInsert;
        lstEventToInsert[0].Description = 'Test';
        update lstEventToInsert[0];
        

        
        AccountChildrenActivities aca = new AccountChildrenActivities (new ApexPages.StandardController(objSoldToAcc));  

        aca.strLaserSelect = ''+assetsToInsert[0].ID;
        aca.updatePage();
        aca.strLaserSelect = 'None';
        aca.updatePage();
        List<SelectOption> options = aca.lstLaserOwnedSelect;
        string test21 = aca.mapIdToAMPSUser;
        String test33 = aca.mapIdToEmails;
        
        
       } 
    }
	
}