/*------------------------------------------------------------
Author:      Denise Bacher
Company:    Salesforce.com
Description:  Test class to validate ContractLineItemTrigger
        Tests Excecuted:
        
        terminateEntitlementAndPMPlans_update - verify that on update of a ContractLineItem termination date, the related Entitlements and PM Plans are updated
        
        createEntitlements_insert - verify that on insert of a ContractLineItem, the appropriate Entitlements are created
        
        setServiceContractApprovalStatus_insert - verify that on insert of a ContractLineItem, ServiceContract.ApprovalStatus is updated
        
        setServiceType_insert - verify that on insert of a ContractLineItme, the service type is set
History:
<Date>      <Authors Name>    <Brief Description of Change>
07/25/2016    Denise Bacher    Initial Creation (US54)
07/29/2016    Denise Bacher    Add tests for createEntitlements (US164)
08/08/2016    Denise Bacher    Add tests for setServiceContractApprovalStatus (US1444)
10/28/2016    Denise Bacher    Add tests for setServiceType (US-0001108)
------------------------------------------------------------*/
@isTest
private class ContractLineItemTrigger_Test {
  private static Account customerAccount;
  private static List<Product2> products = new List<Product2>();
  private static List<Asset> assets = new List<Asset>();
  private static Pricebook2 pricebook = new Pricebook2();
  private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
  private static List<ServiceContract> serviceContracts = new List<ServiceContract>();
  
  private static Map<Id, Asset> productToAsset = new Map<Id, Asset>();
  private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id, PricebookEntry>>();
  
  static{
    TestUtility.setupConfigurationSettings();
    
    customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
    insert customerAccount;
    
    // create products
    for(Integer i = 0; i < 50; i++){
      products.add(TestUtility.newProduct('Product '+i));
    }
    insert products;
    
    // create asset
    for(Product2 p : products){
      Asset asset = TestUtility.newAsset(customerAccount.Name + ' Asset ' + p.Name, customerAccount.Id, customerAccount.Id, p.Id);
      assets.add(asset);
      productToAsset.put(p.Id, asset);
    }
    insert assets;
    
    // create Price Book
    pricebook = TestUtility.newPricebook('Test Pricebook1');
    insert pricebook;
    pricebookToProductToPricebookEntry.put(pricebook.Id, new Map<Id, PricebookEntry>());
    
    // create Price Book entry
    for(Product2 p : products){
      PricebookEntry pbe1 = TestUtility.newPricebookEntry(pricebook.Id, p.Id, 500);
      pricebookEntries.add(pbe1);
      pricebookToProductToPricebookEntry.get(pricebook.Id).put(p.Id, pbe1);
    }
    insert pricebookEntries;
    
    // create service contracts
    ServiceContract purchaseOrder = TestUtility.newServiceContract(customerAccount.Name + ' Purchase Order', customerAccount.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Purchase_Order'), pricebook.Id, System.today().addDays(-1), System.today().addMonths(12));
    purchaseOrder.ApprovalStatus = 'Activated';
    serviceContracts.add(purchaseOrder);
    
    ServiceContract contractOrder = TestUtility.newServiceContract(customerAccount.Name + ' Service Contract', customerAccount.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract'), pricebook.Id, System.today().addDays(-1), System.today().addMonths(12)); 
    contractOrder.ApprovalStatus = 'Activated';
    serviceContracts.add(contractOrder);
    insert serviceContracts;
  }
  
  private static Coverage_Group__c coverageGroup;
  private static List<Coverage_Template__c> coverageTemplates;
  
  private static void setupCoverageGroupAndTemplates(){
    SlaProcess caseEntitlementProcess;
    try{
      caseEntitlementProcess = [Select Id, Name From SlaProcess Where SObjectType = 'Case' Limit 1];
    }
    catch(Exception e){}
    System.assertNotEquals(null, caseEntitlementProcess, 'SETUP ERROR: test cannot proceed, no Case SLA Processes were found.');
    
    SlaProcess workOrderEntitlementProcess;
    try{
      workOrderEntitlementProcess = [Select Id, Name From SlaProcess Where SObjectType = 'WorkOrder' Limit 1];
    }
    catch(Exception e){}
    System.assertNotEquals(null, workOrderEntitlementProcess, 'SETUP ERROR: test cannot proceed, no WorkOrder SLA Processes were found.');
    
    // create Business Hours
    BusinessHours businessHours;
    try{
      businessHours = [Select Id, Name From BusinessHours Limit 1];
    }
    catch(Exception e){}
    System.assertNotEquals(null, businessHours, 'SETUP ERROR: test cannot proceed, no Business Hours were found.');
    
    // create Coverage Group
    coverageGroup = TestUtility.newCoverageGroup('Test Coverage Group');
    insert coverageGroup;
    
    // create Coverage Template
    coverageTemplates = new List<Coverage_Template__c>();
    for(Integer i = 0; i < products.size(); i++){
      Product2 p = products[i];
      coverageTemplates.add(TestUtility.newCoverageTemplate(p.Name + ' SLA', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_SLA'), p.Id, null, null, String.valueOf(Math.mod(i, 5) + 1), caseEntitlementProcess.Name, workOrderEntitlementProcess.Name, i+'-'+p.Id));
      coverageTemplates.add(TestUtility.newCoverageTemplate(p.Name + ' PM', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_PM'), p.Id, null, null, String.valueOf(Math.mod(i, 5) + 1), null, null, null));
      coverageTemplates.add(TestUtility.newCoverageTemplate(p.Name + ' Discount', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_Discount'), p.Id, 10, null, String.valueOf(Math.mod(i, 5) + 1), null, null, null));
      coverageTemplates.add(TestUtility.newCoverageTemplate(p.Name + ' Other', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_Other'), p.Id, null, null, String.valueOf(Math.mod(i, 5) + 1), null, null, null));
    }
    insert coverageTemplates;
  }
  
  private static testMethod void testCheckToUpdateParentAssets() {
        //Create test data
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 27);
        insert pbe;
        
        ServiceContract servCon = new ServiceContract();
        servCon.Name = 'Test Service Contract';
        servCon.AccountId = acc.Id;
        servCon.Pricebook2Id = pb.Id;
        insert servCon;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = servCon.Id;
        cli.PricebookEntryId = pbe.Id;
        cli.Quantity = 27;
        cli.UnitPrice = 27;
        cli.StartDate = Date.today().addMonths(-6);
        cli.EndDate = Date.today().addYears(1);
        cli.AssetId = asst.Id;
        
        //Start test
        Test.startTest();
        
        //Insert ContractLineItem
        insert cli;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        asst = [SELECT Id, SBQQSC__CurrentContractLineItem__c FROM Asset WHERE Id = :asst.Id];
        System.assertEquals(cli.Id, asst.SBQQSC__CurrentContractLineItem__c);
        
        //Test update
        cli.StartDate = Date.today().addMonths(1);
        update cli;
        asst = [SELECT Id, SBQQSC__CurrentContractLineItem__c FROM Asset WHERE Id = :asst.Id];
        System.assertEquals(null, asst.SBQQSC__CurrentContractLineItem__c);
    }
  
    /*private static testMethod void testCreateRenewalOpportunity(){
        //Create data
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product_Source_Division__c psd = new Product_Source_Division__c();
        psd.Source_Division__c = 'MEDICAL AESTHETICS';
        insert psd;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 1);
        insert pbe;
        
        ServiceContract servCon = new ServiceContract();
        servCon.Name = 'Test Service Contract';
        servCon.AccountId = acc.Id;
        servCon.Pricebook2Id = pb.Id;
        insert servCon;
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = servCon.Id;
        cli.PricebookEntryId = pbe.Id;
        cli.Quantity = 2;
        cli.UnitPrice = 3;
        cli.Service_Type__c = 'Warranty';
        
        //Start test
        Test.startTest();
        
        //Insert ContractLineItem
        insert cli;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        servCon = [
            SELECT Id
                  ,SBQQSC__PreserveBundleStructureUponRenewals__c
                  ,SBQQSC__RenewalForecast__c
                  ,SBQQSC__RenewalOpportunityRecordTypeId__c
              FROM ServiceContract
             WHERE Id = :servCon.Id
        ];
        System.assertEquals(false,      servCon.SBQQSC__PreserveBundleStructureUponRenewals__c);
        //System.assertEquals(true,     servCon.SBQQSC__RenewalForecast__c);
        System.assertEquals(GlobalUtility.getRecordTypeId('Opportunity', 'Medical_Aesthetics_Svc_Contract_Opportunity'), servCon.SBQQSC__RenewalOpportunityRecordTypeId__c);
    }*/
  
  static testMethod void terminateEntitlementAndPMPlans_update(){
    List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
    for(ServiceContract sc : serviceContracts){
      for(PricebookEntry pbe : pricebookEntries){
        ContractLineItem cli = TestUtility.newContractLineItem(sc.Id, pbe.Id, 1, 1, productToAsset.get(pbe.Product2Id).Id);
        cli.SBQQSC__Account__c = sc.AccountId;
        cli.StartDate = sc.StartDate;
        cli.EndDate = sc.EndDate;
        contractLineItems.add(cli);
      }
    }
    insert contractLineItems;
    
    List<Entitlement> entitlements = new List<Entitlement>();
    List<Entitlement> pmEntitlements = new List<Entitlement>();
    for(ContractLineItem cli : contractLineItems){
      Entitlement discountEntitlement = TestUtility.newEntitlement('Discount', null, null, cli.SBQQSC__Account__c, cli.AssetId, null, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), cli.StartDate, cli.EndDate, 10, 0);
      discountEntitlement.ContractLineItemId = cli.Id;
      entitlements.add(discountEntitlement);
      
      Entitlement otherEntitlement = TestUtility.newEntitlement('Other', null, null, cli.SBQQSC__Account__c, cli.AssetId, null, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Other'), cli.StartDate, cli.EndDate, 0, 0);
      otherEntitlement.ContractLineItemId = cli.Id;
      entitlements.add(otherEntitlement);
      
      Entitlement slaEntitlement = TestUtility.newEntitlement('SLA', null, null, cli.SBQQSC__Account__c, cli.AssetId, null, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_SLA'), cli.StartDate, cli.EndDate, 0, 0);
      slaEntitlement.ContractLineItemId = cli.Id;
      entitlements.add(slaEntitlement);
      
      Entitlement pmEntitlement = TestUtility.newEntitlement('PM', null, null, cli.SBQQSC__Account__c, cli.AssetId, null, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_PM'), cli.StartDate, cli.EndDate, 0, 0);
      pmEntitlement.ContractLineItemId = cli.Id;
      entitlements.add(pmEntitlement);
      pmEntitlements.add(pmEntitlement);
    }
    insert entitlements;
    
    Test.startTest();
      for(ContractLineItem cli : contractLineItems){
        cli.EndDate = System.today();
        cli.SBQQSC__TerminatedDate__c = System.today();
      }
      update contractLineItems;
    Test.stopTest();
    
    List<Entitlement> postEntitlements = [Select Id, Terminated_Date__c, Original_End_Date__c, EndDate From Entitlement];
    System.assertEquals(400, postEntitlements.size());
    for(Entitlement e : postEntitlements){
      System.assertEquals(System.today().addMonths(12), e.Original_End_Date__c);
      System.assertEquals(System.today(), e.Terminated_Date__c);
      System.assertEquals(System.today(), e.EndDate);
    }
  }
  
  static testMethod void createEntitlements_insert(){
    setupCoverageGroupAndTemplates();
    
    List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
    for(ServiceContract sc : serviceContracts){
      for(PricebookEntry pbe : pricebookEntries){
        ContractLineItem cli = TestUtility.newContractLineItem(sc.Id, pbe.Id, 1, 1, productToAsset.get(pbe.Product2Id).Id);
        cli.SBQQSC__Account__c = sc.AccountId;
        cli.StartDate = sc.StartDate;
        cli.EndDate = sc.EndDate;
        contractLineItems.add(cli);
      }
    }
    
    Test.startTest();
      insert contractLineItems;
    Test.stopTest();
    
    List<ContractLineItem> postInsertCLI = [Select Id, StartDate, EndDate, ServiceContractId, AssetId, Asset.Name, Asset.AccountId, Asset.SerialNumber
      , (Select Id, Name, AssetId, Type, ServiceContractId, ContractLineItemId, RecordTypeId, StartDate, EndDate, SlaProcessId, Discount__c, Max_Covered_Amount__c
        , Coverage_Group__c, Coverage_Template__c, Coverage_Template__r.Name
        From Entitlements)
      From ContractLineItem];
    
    System.assertEquals(100, postInsertCLI.size());
    for(ContractLineItem cli : postInsertCLI){
      for(Entitlement e : cli.Entitlements){
        System.assertEquals(e.Coverage_Template__r.Name + ' for SN: ' + cli.Asset.SerialNumber, e.Name);
        System.assertEquals(cli.StartDate, e.StartDate);
        System.assertEquals(cli.EndDate, e.EndDate);
        System.assertEquals(cli.ServiceContractId, e.ServiceContractId);
        System.assertEquals(cli.Id, e.ContractLineItemId);
        System.assertNotEquals(null, e.Coverage_Group__c);
        System.assertNotEquals(null, e.Coverage_Template__c);
        
        if(e.RecordTypeId == GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_SLA')){
          System.assertNotEquals(null, e.SlaProcessId);
        }
        else if(e.RecordTypeId == GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount')){
          System.assertEquals(10, e.Discount__c);
          System.assertEquals(null, e.Max_Covered_Amount__c);
        }
      }
    }
  }
  
  static testMethod void setServiceContractApprovalStatus_insert(){
    List<ContractLineItem> contractLineItemsTrue = new List<ContractLineItem>();
    List<ContractLineItem> contractLineItemsFalse = new List<ContractLineItem>();
    for(PricebookEntry pbe : pricebookEntries){
      ContractLineItem cliTrue = TestUtility.newContractLineItem(serviceContracts[0].Id, pbe.Id, 1, 1, productToAsset.get(pbe.Product2Id).Id);
      cliTrue.SBQQSC__Account__c = serviceContracts[0].AccountId;
      cliTrue.StartDate = serviceContracts[0].StartDate;
      cliTrue.EndDate = serviceContracts[0].EndDate;
      cliTrue.Asset_Created__c = true;
      contractLineItemsTrue.add(cliTrue);
      
      ContractLineItem cliFalse = TestUtility.newContractLineItem(serviceContracts[1].Id, pbe.Id, 1, 1, productToAsset.get(pbe.Product2Id).Id);
      cliFalse.SBQQSC__Account__c = serviceContracts[1].AccountId;
      cliFalse.StartDate = serviceContracts[1].StartDate;
      cliFalse.EndDate = serviceContracts[1].EndDate;
      cliFalse.Asset_Created__c = false;
      contractLineItemsFalse.add(cliFalse);
    }
    
    List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
    contractLineItems.addAll(contractLineItemsTrue);
    contractLineItems.addAll(contractLineItemsFalse);
    
    Test.startTest();
      insert contractLineItems;
    Test.stopTest();
    
    List<ContractLineItem> postInsertCLITrue = [Select Id, Asset_Created__c, ServiceContractId, ServiceContract.ApprovalStatus
      From ContractLineItem
      Where Id IN: contractLineItemsTrue];
    for(ContractLineItem cli : postInsertCLITrue){
      System.assertEquals(true, cli.Asset_Created__c);
      System.assertEquals('Activated', cli.ServiceContract.ApprovalStatus);
    }
      
    List<ContractLineItem> postInsertCLIFalse = [Select Id, Asset_Created__c, ServiceContractId, ServiceContract.ApprovalStatus
      From ContractLineItem
      Where Id IN: contractLineItemsFalse];
    for(ContractLineItem cli : postInsertCLIFalse){
      System.assertEquals(false, cli.Asset_Created__c);
    }
  }
  
  static testMethod void setServiceType_insert(){
    // update with service types
    for(Product2 p : products){
      p.Service_Type__c = 'Service Contract';
    }
    update products;
    
    List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
    for(PricebookEntry pbe : pricebookEntries){
      ContractLineItem cliTrue = TestUtility.newContractLineItem(serviceContracts[0].Id, pbe.Id, 1, 1, productToAsset.get(pbe.Product2Id).Id);
      contractLineItems.add(cliTrue);
    }
    
    Test.startTest();
      insert contractLineItems;
    Test.stopTest();
    
    List<ContractLineItem> postContractLineItems = [Select Id, Service_Type__c From ContractLineItem];
    for(ContractLineItem cli : postContractLineItems){
      System.assertEquals('Service Contract', cli.Service_Type__c);
    }
  }
  
}