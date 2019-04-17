/*------------------------------------------------------------
Author:      Denise Bacher
Company:    Salesforce.com
Description:  Test class to validate AccountAssetHierarchy, AssetHierarchy pages and AssetHierarchy_ControllerX
        Tests Excecuted:
        
        viewHierarchyFromSiteAccount - test view of asset hierarchy from the siteAccount
        
        viewHierarchyFromCustomerAccount - test view of asset hierarchy from the customerAccount
        
        viewHierarchyFromSystemAsset - test view of asset hierarchy from the system asset 
        
        viewHierarchyFromComponentAsset - test view of asset hierarchy from the component asset
        
        errorHandlingNewAccount - verify running controller with a new (no id) account causes no issues
          and verify that calling the corresponding populate function correctly handels errors
        
        errorHandlingNewAsset - verify running controller with a new (no id) asset causes no issues
          and verify that calling the corresponding populate function correctly handels errors

History:
<Date>      <Authors Name>    <Brief Description of Change>
04/11/2016    Denise Bacher    Initial Creation
04/28/2016    Denise Bacher    Update to test from site and customer accounts (US762)
05/10/2016    Denise Bacher    Update to test popover update (US958)
09/02/2016    Denise Bacher    Updated to group by Asset.Produc2.Division__c (REQ168)
------------------------------------------------------------*/
@isTest
private class AssetHierarchy_ControllerX_Test {
  private final static List<String> divisionValues = new List<String>{'BREAST HEALTH', 'SKELETAL HEALTH', null};
  private final static Id assetNonHologicRecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'Non_Hologic');
  private final static Id assetSystemRecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
  private final static Id assetComponentRecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'Component');
  
  private static Configuration_Settings__c orgDefaults;
  private static Account customerAccount;
  private static Account siteAccount;
  private static Account siteAccount2;
  private static User otherUser;
  private static List<Asset> nonHologicAsset;
  private static List<Asset> systemAsset;
  private static List<Asset> componentAsset;
  
  static{
    orgDefaults = TestUtility.setupConfigurationSettings();
    TestUtility.insertCustSetting('sitelocTrigger');
    customerAccount = TestUtility.newAccount('Customer Account Test', null);
    insert customerAccount;
    
    siteAccount = TestUtility.newAccount('Site Account Test', null, customerAccount.Id);
    siteAccount.RecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
    siteAccount2 = TestUtility.newAccount('Site Account Test2', null, customerAccount.Id);
    siteAccount2.RecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
    insert new List<Account>{siteAccount, siteAccount2};
    
    List<Product2> products = new List<Product2>();
    for(String divisionVal : divisionValues){
      Product2 p = TestUtility.newProduct(String.isNotBlank(divisionVal) ? divisionVal : 'Unknown');
      p.Division__c = divisionVal;
      
      products.add(p);
    }
    insert products;
    
    Site_Location__c installLoc = TestUtility.newSiteLocation('Test Install Location',siteAccount.Id,'Test Address');
    insert installLoc;
    
    nonHologicAsset = new List<Asset>();
    systemAsset = new List<Asset>();
    componentAsset = new List<Asset>();
    
    for(Integer i = 0; i < 20; i++){
    
      Asset nonHol1 = TestUtility.newAsset(siteAccount.Id, customerAccount.Id, null, assetNonHologicRecordTypeId, 'Non-Hologic '+i, '', 'XXXX'+i);
      nonHol1.Install_Location__c = installLoc.Id;
      Asset nonHol2 = TestUtility.newAsset(siteAccount2.Id, customerAccount.Id, null, assetNonHologicRecordTypeId, 'Non-Hologic '+i, '', 'XXXX'+i);
      nonHol2.Install_Location__c = installLoc.Id;
      nonHologicAsset.add(nonHol1);
      nonHologicAsset.add(nonHol2);
      
      for(Product2 p : products){
        Asset sys1 = TestUtility.newAsset(siteAccount.Id, customerAccount.Id, null, assetSystemRecordTypeId, p.Division__c+' '+i, null, 'XXXX'+i);
        sys1.Product2Id = p.Id;
        sys1.Install_Location__c = installLoc.Id;
        
        Asset sys2 = TestUtility.newAsset(siteAccount2.Id, customerAccount.Id, null, assetSystemRecordTypeId, p.Division__c+' '+i, null, 'XXXX'+i);
        sys2.Product2Id = p.Id;
        sys2.Install_Location__c = installLoc.Id;
        
        systemAsset.add(sys1);
        systemAsset.add(sys2);
      }
    }
    List<Asset> temp = new List<Asset>();
    temp.addAll(nonHologicAsset);
    temp.addAll(systemAsset);
    insert temp;
    
    for(Asset a : systemAsset){
      
      Asset comp1 = TestUtility.newAsset(a.AccountId, a.Customer_Account__c, a.Id, assetComponentRecordTypeId, 'ComponentA', '', a.SerialNumber + '-A');
      comp1.Install_Location__c = installLoc.Id;
      Asset comp2 = TestUtility.newAsset(a.AccountId, a.Customer_Account__c, a.Id, assetComponentRecordTypeId, 'ComponentB', '', a.SerialNumber + '-B');
      comp2.Install_Location__c = installLoc.Id;
      componentAsset.add(comp1);
      componentAsset.add(comp2);
    }
    insert componentAsset;
    
    otherUser = TestUtility.newUser(UserInfo.getProfileId(), 'other');
    insert otherUser;
  }
  
  static testMethod void viewHierarchyFromSiteAccount() {
    PageReference pageRef = Page.AccountAssetHierarchy;
    Test.setCurrentPage(pageRef);
    
    Test.startTest();
      System.runAs(otherUser) {
        AssetHierarchy_ControllerX ctrl = new AssetHierarchy_ControllerX(new ApexPages.StandardController(siteAccount));
        System.assert(divisionValues.size() > 0);
        System.assertNotEquals(null, ctrl.accountObj);
        System.assertEquals(null, ctrl.assetObj);
        
        // verify asset hierarchy isn't null
        System.assertNotEquals(null, ctrl.jsonAssetHierarchy);
        System.assertEquals(divisionValues.size() + 1, ctrl.assetHierarchy.size());
        
        // verify the data for the popover is not null
        System.assertNotEquals(null, ctrl.popoverFields);
        System.assert(ctrl.assets.size() > 0);
        
        // verify division groups
        Integer i;
        for(i = 0; i < divisionValues.size(); i++){
          ObjectNode o = ctrl.assetHierarchy[i];
          
          // verify group node name
          System.assertEquals(String.isNotBlank(divisionValues[i]) ? divisionValues[i] : 'UNKNOWN', o.nodeName); 
          
          // verify has the correct number of children and grandchildren
          //System.assertEquals(20, o.nodeChildren.size());
          System.assertEquals(2, o.nodeChildren[0].nodeChildren.size());
          
          // if the node name matches the user's division, it should be expanded, other nodes will default collapsed 
          if(ctrl.assetHierarchy[i].nodeName == otherUser.Hologic_Division__c){
            System.assert(ctrl.assetHierarchy[i].defaultCollapsed == false);
          }
          else{
            System.assert(ctrl.assetHierarchy[i].defaultCollapsed == true);
          }
        }
        
        // verify the non-hologic group
        System.assertEquals(GlobalUtility.getRecordTypeName('Asset', assetNonHologicRecordTypeId).toUpperCase(), ctrl.assetHierarchy[i].nodeName);
        System.assert(ctrl.assetHierarchy[i].defaultCollapsed == true);
        //System.assertEquals(40, ctrl.assetHierarchy[i].nodeChildren.size()); // 20 children
        System.assertEquals(0, ctrl.assetHierarchy[ctrl.assetHierarchy.size() - 1].nodeChildren[0].nodeChildren.size()); // children have no children
      }
     GlobalUtility.getAllObjectRecordTypeByName('Account');
      GlobalUtility.getAllObjectRecordTypeById('Account');
     GlobalUtility.runOnce();
     GlobalUtility.getRecordTypeDeveloperName('Account',GlobalUtility.getRecordTypeId('Account', 'Site'));
     GlobalUtility.sleep(100);
    Test.stopTest();
  }
  
  /*static testMethod void viewHierarchyFromCustomerAccount() {
    PageReference pageRef = Page.AccountAssetHierarchy;
    Test.setCurrentPage(pageRef);
    
    Test.startTest();
      System.runAs(otherUser) {
        AssetHierarchy_ControllerX ctrl = new AssetHierarchy_ControllerX(new ApexPages.StandardController(customerAccount));
        System.assert(divisionValues.size() > 0);
        System.assertNotEquals(null, ctrl.accountObj);
        System.assertEquals(null, ctrl.assetObj);
        
        // verify asset hierarchy isn't null
        System.assertNotEquals(null, ctrl.jsonAssetHierarchy);
        System.assertEquals(divisionValues.size() + 1, ctrl.assetHierarchy.size());
        
        // verify the data for the popover is not null
        System.assertNotEquals(null, ctrl.popoverFields);
        System.assert(ctrl.assets.size() > 0);
        
        // verify division groups
        Integer i;
        for(i = 0; i < divisionValues.size(); i++){
          ObjectNode o = ctrl.assetHierarchy[i];
          
          // verify group node name
          System.assertEquals(String.isNotBlank(divisionValues[i]) ? divisionValues[i] : 'UNKNOWN', o.nodeName);
          
          // verify has the correct number of children and grandchildren
          System.assertEquals(40, o.nodeChildren.size());
          System.assertEquals(2, o.nodeChildren[0].nodeChildren.size());
          
          // if the node name matches the user's division, it should be expanded, other nodes will default collapsed 
          if(ctrl.assetHierarchy[i].nodeName == otherUser.Hologic_Division__c){
            System.assert(ctrl.assetHierarchy[i].defaultCollapsed == false);
          }
          else{
            System.assert(ctrl.assetHierarchy[i].defaultCollapsed == true);
          }
        }
        
        // verify the non-hologic group
        System.assertEquals(GlobalUtility.getRecordTypeName('Asset', assetNonHologicRecordTypeId).toUpperCase(), ctrl.assetHierarchy[i].nodeName);
        System.assert(ctrl.assetHierarchy[i].defaultCollapsed == true);
        System.assertEquals(40, ctrl.assetHierarchy[i].nodeChildren.size()); // 40 children
        System.assertEquals(0, ctrl.assetHierarchy[ctrl.assetHierarchy.size() - 1].nodeChildren[0].nodeChildren.size()); // children have no children
      }
    Test.stopTest();
  }*/
  
  static testMethod void viewHierarchyFromSystemAsset() {
    PageReference pageRef = Page.AccountAssetHierarchy;
    Test.setCurrentPage(pageRef);
    
    Test.startTest();
      System.runAs(otherUser) {
        AssetHierarchy_ControllerX ctrl = new AssetHierarchy_ControllerX(new ApexPages.StandardController(systemAsset[0]));
        System.assertNotEquals(null, ctrl.assetObj);
        System.assertEquals(null, ctrl.accountObj);
        
        // verify asset hierarchy isn't null
        System.assertNotEquals(null, ctrl.jsonAssetHierarchy);
        System.assertEquals(1, ctrl.assetHierarchy.size());
        
        // verify the data for the popover is not null
        System.assertNotEquals(null, ctrl.popoverFields);
        System.assert(ctrl.assets.size() > 0);
        
        ObjectNode o = ctrl.assetHierarchy[0];
          
        // verify has the correct number of children
        System.assertEquals(2, o.nodeChildren.size());
        
        // verify not collapsed
        System.assert(o.defaultCollapsed == false);
      }
    Test.stopTest();
  }
  
  static testMethod void viewHierarchyFromComponentAsset() {
    PageReference pageRef = Page.AccountAssetHierarchy;
    Test.setCurrentPage(pageRef);
    
    Test.startTest();
      System.runAs(otherUser) {
        AssetHierarchy_ControllerX ctrl = new AssetHierarchy_ControllerX(new ApexPages.StandardController(componentAsset[0]));
        System.assertNotEquals(null, ctrl.assetObj);
        System.assertEquals(null, ctrl.accountObj);
        
        // verify asset hierarchy isn't null
        System.assertNotEquals(null, ctrl.jsonAssetHierarchy);
        System.assertEquals(1, ctrl.assetHierarchy.size());
        
        // verify the data for the popover is not null
        System.assertNotEquals(null, ctrl.popoverFields);
        System.assert(ctrl.assets.size() > 0);
        
        ObjectNode o = ctrl.assetHierarchy[0];
          
        // verify has the correct number of children
        System.assertEquals(2, o.nodeChildren.size());
        
        // verify not collapsed
        System.assert(o.defaultCollapsed == false);
      }
    Test.stopTest();
  }
  
  static testMethod void errorHandlingNewAccount(){
    PageReference pageRef = Page.AccountAssetHierarchy;
    Test.setCurrentPage(pageRef);
    
    Test.startTest();
      System.runAs(otherUser) {
        AssetHierarchy_ControllerX ctrl = new AssetHierarchy_ControllerX(new ApexPages.StandardController(new Account()));
        System.assertEquals(null, ctrl.assetObj);
        System.assertEquals(null, ctrl.accountObj);
        
        // hierarchy does not populate
        System.assertEquals('[]', ctrl.jsonAssetHierarchy);
        System.assertEquals(0, ctrl.assetHierarchy.size());
        
        // verify the data for the popover
        System.assertNotEquals(null, ctrl.popoverFields);
        System.assertEquals(0, ctrl.assets.size());
        
        // run populate anyway to ensure errors are handled
        List<ObjectNode> assetHierarchy = ctrl.populateAccountAssetHierarchy();
        System.assert(ApexPages.hasMessages(), 'No messages');
        System.assertEquals(1, ApexPages.getMessages().size());
        
        // groups will not get populated
        System.assertNotEquals(null, Json.serialize(assetHierarchy));
        System.assertEquals(0, assetHierarchy.size());
      }
    Test.stopTest();
  }
  
  static testMethod void errorHandlingNewAsset(){
    PageReference pageRef = Page.AccountAssetHierarchy;
    Test.setCurrentPage(pageRef);
    
    Test.startTest();
      System.runAs(otherUser) {
        AssetHierarchy_ControllerX ctrl = new AssetHierarchy_ControllerX(new ApexPages.StandardController(new Asset()));
        System.assertEquals(null, ctrl.assetObj);
        System.assertEquals(null, ctrl.accountObj);
        
        // hierarchy does not populate
        System.assertEquals('[]', ctrl.jsonAssetHierarchy);
        System.assertEquals(0, ctrl.assetHierarchy.size());
        
        // verify the data for the popover
        System.assertNotEquals(null, ctrl.popoverFields);
        System.assertEquals(0, ctrl.assets.size());
        
        // run populate anyway to ensure errors are handled
        List<ObjectNode> assetHierarchy = ctrl.populateAssetHierarchy();
        System.assert(ApexPages.hasMessages(), 'No messages');
        System.assertEquals(1, ApexPages.getMessages().size());
        System.assertEquals('[]', Json.serialize(assetHierarchy));
        System.assertEquals(0, assetHierarchy.size());
      }
    Test.stopTest();
  }
}