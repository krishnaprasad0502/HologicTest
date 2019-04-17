/**************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: Test Class for ObjectRelatedListController class
Controller Class: ObjectRelatedListController

History:
<Date>              <Author Name>        <Brief description of change >     <Copa.do US#>           
12-10-2018          Sunil Kumar Sharma   Initial Creation                   US-0006257 
**************************************************************************************/
@isTest
public class ObjectRelatedListController_Test {
	@testSetup static void setupTestData() {
        TestUtility.setupConfigurationSettings();
        //Create test Account record
        Account acc = TestUtility.newAccount('Test Account',null);
        database.insert(acc);
        
        //Create test Product records
        List<Product2> list_TestProducts = new List<Product2>();
        
        Product2 testProduct1 = new Product2(Name='Test Product1',isActive=true,
                                             Community_Family_Name__c='Mammography',
                                             Community_Product_Description__c='Test Product1',
                                             Community_Visible__c =true, Division__c = 'BREAST HEALTH');
        Product2 testProduct2 = new Product2(Name='Test Product2',isActive=true,
                                             Community_Family_Name__c='Mammography',
                                             Community_Product_Description__c='Test Product2',
                                             Community_Visible__c =true, Division__c = 'BREAST HEALTH');
        product2 testProduct3 = new Product2(Name='Test Product3',isActive=true,
                                             Community_Family_Name__c='Workstations',
                                             Community_Product_Description__c='Test Product3',
                                             Community_Visible__c =true, Division__c = 'BREAST HEALTH');
        
        list_TestProducts.add(testProduct1);
        list_TestProducts.add(testProduct2);
        list_TestProducts.add(testProduct3);
        
        database.insert(list_TestProducts) ;
        
        //Create Asset test data
        List<Asset> list_TestAssets = new List<Asset>();
        
        Asset testAssetRec1 = new Asset(Name ='Test Asset',Status='Installed',Accountid =acc.Id,Product2Id= testProduct1.Id);
        Asset testAssetRec2 = new Asset(Name ='Test Asset',Status='Installed',Accountid =acc.Id,Product2Id= testProduct1.Id);
        list_TestAssets.add(testAssetRec1);
        list_TestAssets.add(testAssetRec2);
        database.insert(list_TestAssets);
        
        //Create custom setting data for test class
        Service_Community_Config__c configSetting = new Service_Community_Config__c(Documentation__c ='test URL',
            Privacy_Policy__c='test Url');
        database.insert(configSetting); 
        
    }
    
    /*Test method to test fucntionality of controller method -"fetchConfigData()"*/
    @isTest static void testFetchConfigDataReturnsSuccess(){
        Test.startTest();
            Service_Community_Config__c configSetting = ObjectRelatedListController.fetchConfigData();
            system.assertEquals('test URL', configSetting.Documentation__c, 'Actual documentation link is not matched with expected link.');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchOrgURL()"*/
    @isTest static void testFetchAssetsListReturnsSuccess(){
        Test.startTest();
            List<Asset> assetList = ObjectRelatedListController.fetchAssetsList('Test Product1');
            system.assertEquals(true, assetList.size() > 0, 'Product is not fetched from query');
        Test.stopTest();
    }
}