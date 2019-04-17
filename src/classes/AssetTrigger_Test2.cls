@isTest
private class AssetTrigger_Test2{


      static testMethod void test_ampsFlows(){
                 
                    
                                                                               
            /*                                                                   
            List<AMPS_Marketing_Activity_Flow__c> parentFlowList =  new List<AMPS_Marketing_Activity_Flow__c>();
            parentFlowList.add(new AMPS_Marketing_Activity_Flow__c(Initiating_Task_Type__c='New AMPS Marketing',name ='Flow 1',AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13));
            
            insert parentFlowList;                                                              
            
            
            
            
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
        
        
       
        List<Asset> AssetList=new List<Asset>();
            AssetList.add(new Asset(
                name='test',
                AccountID=objSoldToAcc.id
                ));
            insert AssetList;
            
            Asset_Team__c asT = new Asset_Team__c();
            asT.Relationship__c = 'AMPS Representative';
            asT.User__c = user1.id;
            asT.Asset__c = AssetList[0].id;
            insert asT;
       
           AssetList[0].AMPS_Track__c = 'New AMPS Marketing';
           update AssetList;
            

        }
       */
     }   

}