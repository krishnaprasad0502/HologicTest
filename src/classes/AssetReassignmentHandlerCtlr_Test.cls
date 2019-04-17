/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Raviraj Reddy
Description:  Test class for AssetReassignmentHandlerCtrl class

History:
<Date>      <Authors Name>    <Brief Description of Change>
03/23/2018   Raviraj Reddy    Initial Creation (US3819)
------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class AssetReassignmentHandlerCtlr_Test{
      public static User user1;
      public static void insertData(){
          List<AMPS_Marketing_Activity_Flow__c> parentFlowList =  new List<AMPS_Marketing_Activity_Flow__c>();
            parentFlowList.add(new AMPS_Marketing_Activity_Flow__c(Initiating_Task_Type__c='New AMPS Marketing',name ='Flow 1',AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13));
            insert parentFlowList;                                                              
                
            
            Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;
    
        
            user1 = new User(alias = 'test123', email='test123@hologic.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
            timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
            
            insert user1;
            System.runAs(user1){
            ID prospectRecTypeId =  [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1].id;
            ID siteRecTypeId = [SELECT Id FROM RecordType WHERE DeveloperName ='Site' Limit 1].id;
            
            Product2 prod = TestUtility.newProduct('Test Product');
            prod.Division__c = 'Med Aesthetics';
            prod.ProductCode = 'Prod1';
            insert prod;
            
            Account objSoldToAcc = TestUtility.newAccount('Test Account - 00001', '', '', null, prospectRecTypeId );
            objSoldToAcc.ShippingStateCode = 'AK';
            objSoldToAcc.ShippingCountryCode = 'US'; 
            objSoldToAcc.ShippingPostalCode = '10010'; 
            objSoldToAcc.ShippingCity = 'citay'; 
            objSoldToAcc.CurrencyIsoCode = 'USD';
            objSoldToAcc.CDQ_Status__c = 'New';
            objSoldToAcc.ShippingStreet = 'SHIPTest1 \n SHIPTest2 \n SHIPTest3 \n SHIPTest4';
            insert objSoldToAcc;
            
            
           
            List<Asset> AssetList=new List<Asset>();
                AssetList.add(new Asset(
                    name='test',
                    AccountID=objSoldToAcc.id,
                    Product2ID = prod.id
                    ));
                insert AssetList;
                
                Asset_Team__c asT = new Asset_Team__c();
                asT.Relationship__c = 'AMPS Representative';
                asT.User__c = user1.id;
                asT.Asset__c = AssetList[0].id;
                insert asT;
           
               List<Task> taskList = new List<Task>();
            
            Task obj= new task();
            obj.Subject = 'Flow 1';
            obj.status = 'Open';
            obj.whatID = AssetList[0].id;
            obj.ownerid= user1.id;
            obj.recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
            
                
            insert obj;
                
    
            }
      }

      static testMethod void method1(){
                 
        insertData();
        
        AssetReassignmentHandlerCtlr ctrl = new AssetReassignmentHandlerCtlr();
        ctrl.team1.User__c = user1.id;
        ctrl.team1.RelationShip__c = 'AMPS Representative';
        ctrl.team2.User__c = Userinfo.getUserID();
        ctrl.getAssetRecords();
        ctrl.Assign(); 
        
        AssetReassignmentHandlerCtlr ctrl2 = new AssetReassignmentHandlerCtlr();
        //ctrl2.team1.User__c = user1.id;
        ctrl2.team1.RelationShip__c = 'AMPS Representative';
        
        ctrl2.getAssetRecords();
        ctrl2.team2.User__c = Userinfo.getUserID();
        ctrl2.laserList[0].selected = true;
        ctrl2.Assign();
        
        ctrl2.getAssetRecords();
        ctrl2.team2.User__c = Userinfo.getUserID();
        ctrl2.laserList[0].selected = true;  
        ctrl2.team1.User__c = user1.id;
        ctrl2.Assign(); 
                         
        
     } 
     
     static testMethod void method2(){
       insertData();         
       AssetReassignmentHandlerCtlr ctrl = new AssetReassignmentHandlerCtlr();
        ctrl.team1.User__c = user1.id;
        ctrl.team1.RelationShip__c = 'AMPS Representative';
        //ctrl.team2.User__c = Userinfo.getUserID();
        ctrl.getAssetRecords();
        ctrl.Assign(); 
      } 
      
      
      static testMethod void method3(){
       insertData();        
       AssetReassignmentHandlerCtlr ctrl = new AssetReassignmentHandlerCtlr();
        ctrl.team1.User__c = user1.id;
        ctrl.team1.RelationShip__c = 'AMPS Representative';
        ctrl.team2.User__c = user1.id;
        ctrl.getAssetRecords();
        ctrl.Assign(); 
      }   

}