/**************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: Test Class for ProductViewController class
Controller Class: ProductViewController

History:
<Date>              <Author Name>        <Brief description of change >     <Copa.do US#>           
12-09-2018          Sunil Kumar Sharma   Initial Creation                   US-0005699 
12/02/2018          Sunil Kumar Sharma   Product Load performance issue    US-0006259 
                                         fixed
**************************************************************************************/
@isTest
public class ProductViewController_Test {
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
    
    /*Test method to test fucntionality of controller method -"getProducts()"*/
    @isTest static void testGetProductsReturnsSuccess(){
        List<Id> list_TestProductIds = new List<Id>();
        For(Product2 prodRec:[SELECT id,Community_Family_Name__c,Community_Product_Description__c FROM Product2]){
            list_TestProductIds.add(prodRec.Id);
        }
        Boolean showAllProducts = true ; 
        Test.startTest();
            List<ProductViewController.ProductFamilyHeader> lstOfProductFamily= ProductViewController.getProducts(showAllProducts);
            system.assertEquals(1, lstOfProductFamily.size(), 'Returned list of product family products is not matching with expected count.');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"getProductFamilyData()"*/
    @isTest static void testGetProductsWithNullList(){
        List<Id> list_TestProductIds = new List<Id>();
        For(Product2 prodRec:[SELECT id,Community_Family_Name__c,Community_Product_Description__c FROM Product2 WHERE name = 'Test']){
            list_TestProductIds.add(prodRec.Id);
        }
        
        Test.startTest();
            List<ProductViewController.ProductFamilyHeader> lstOfProductFamily = ProductViewController.getProductFamilyData();  
            system.assertEquals(1, lstOfProductFamily.size(), 'Returned list of product family products is not matching with expected count.');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"getSobjectRecordName()"*/
    @isTest static void testGetSobjectRecordNameReturnsSuccess(){
        List<Product2> list_TestProduct = new List<Product2>([SELECT id,Community_Family_Name__c,
                                                    Community_Product_Description__c 
                                                    FROM Product2 
                                                    WHERE Name='Test Product1']);
        Test.startTest();
            List<ProductViewController.sObjectVar> lstOfSobjects = ProductViewController.getSobjectRecordName('Product2',
                list_TestProduct[0].Id,'Community_Family_Name__c','Community_Product_Description__c','Community_Visible__c','Data_Category__c');
            system.assertEquals('Mammography', lstOfSobjects[0].value1,'Product service family name is not received as per expected.');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchConfigData()"*/
    @isTest static void testFetchConfigDataReturnsSuccess(){
        Test.startTest();
            Service_Community_Config__c configSetting = ProductViewController.fetchConfigData();
            system.assertEquals('test URL', configSetting.Documentation__c, 'Actual documentation link is not matched with expected link.');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchOrgURL()"*/
    @isTest static void testFetchOrgURLReturnsSuccess(){
        Test.startTest();
            String orgUrl = ProductViewController.fetchOrgURL();
            system.assertEquals(URL.getSalesforceBaseUrl().toExternalForm(), orgUrl, 'Actual org url is not matched with expected url.');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchOrgURL()"*/
    @isTest static void testGetProductDescriptionRecordReturnsSuccess(){
        Test.startTest();
            Id prodRec = ProductViewController.getProductDescriptionRecord('Test Product1','All Products');
            system.assertEquals(true, prodRec != null, 'Product is not fetched from query');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchOrgURL()"*/
    @isTest static void testGetProductDescriptionRecordReturnsElse(){
        Test.startTest();
            Id prodRec = ProductViewController.getProductDescriptionRecord('Test Product1','My Products');
            system.assertEquals(true, prodRec != null, 'Product is not fetched from query');
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"getMyProductFamilyData()"*/
    @isTest static void testGetMyProductFamilyDataReturnsSuccess(){    
          
        Test.startTest();
            List<ProductViewController.ProductFamilyHeader> lstOfProductFamily = ProductViewController.getMyProductFamilyData(); 
            system.assertEquals(1, lstOfProductFamily.size(), 'Returned list of product family products is not matching with expected count.');
        Test.stopTest();
    }
}