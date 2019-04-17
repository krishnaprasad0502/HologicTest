/**************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: This test class is written to cover the controller CustomSearchController class.
Controller Class: CustomSearchController

History:
<Date>              <Author Name>       <Brief description of change >      <Copa.do US#>
13/09/2018        Sunil Kumar Sharma    Initial creation                    US-0005633
****************************************************************************************/
@isTest
public class CustomSearchController_Test {
    @testSetup static void setupTestData() {
        TestUtility.setupConfigurationSettings();
        //Create test Account record
        Account acc = TestUtility.newAccount('Test Account','112');
        database.insert(acc); 
        
        //Create test Product records
        List<Product2> list_TestProducts = new List<Product2>();
        
        Product2 testProduct1 = new Product2(Name='Test Product1',
                                             Community_Family_Name__c='Mammography_Systems',
                                             Community_Product_Description__c='Test Product1',
                                             Community_Visible__c =true);
        Product2 testProduct2 = new Product2(Name='Test Product2',
                                             Community_Family_Name__c='Mammography_Systems',
                                             Community_Product_Description__c='Test Product2',
                                             Community_Visible__c =true);
        product2 testProduct3 = new Product2(Name='Test Product3',
                                             Community_Family_Name__c='Mammography_Systems',
                                             Community_Product_Description__c='Test Product3',
                                             Community_Visible__c =true);
        
        list_TestProducts.add(testProduct1);
        list_TestProducts.add(testProduct2);
        list_TestProducts.add(testProduct3);
        
        database.insert(list_TestProducts); 
        
        //Create Asset test data
        List<Asset> list_TestAssets = new List<Asset>();
        
        Asset testAssetRec1 = new Asset(Name ='Test Asset',Accountid =acc.Id,Product2Id= testProduct1.Id);
        Asset testAssetRec2 = new Asset(Name ='Test Asset',Accountid =acc.Id,Product2Id= testProduct1.Id);
        list_TestAssets.add(testAssetRec1);
        list_TestAssets.add(testAssetRec2);
        database.insert(list_TestAssets); 
        
    }
    
    /*Test method to test fucntionality of controller method -"searchForIds()"*/
    @isTest static void testSearchForIdsReturnsSuccess(){
        Test.startTest();
            List<String> listOfObjectIds = CustomSearchController.searchForIds('112');
            system.assertEquals(0, listOfObjectIds.size(), 'Returned list of object Ids do not match with expected value.');
        Test.stopTest();
    }
}