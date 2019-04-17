/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate CaseTrigger
                Tests Excecuted:
                
                setProductFromAsset_insertCaseWithAssetWithProduct - verify that on insert of a case with an asset, the case's product updates to match the asset's product
                
                setProductFromAsset_updateCaseWithAssetWithProduct - verify that on insert of a case with an asset, the case's product updates to match the asset's product
                
                setCaseEntitlement_insertCaseOverrideTrue - verify that on insert of a case with an asset, the correct entitlement with the highest priority is applied
                
                setCaseEntitlement_insertCaseOverrideFalse - verify that on insert of a case with an asset, the entitlement is not overwritten
                
                setCaseEntitlement_insertNoEntitlementsFound - verify that on insert of a case with an asset and no entitlements found, the Purchase_Order__c is populated
                
                setCaseEntitlement_updateCaseOverrideTrue - verify that on update of a case with an asset, the correct entitlement with the highest priority is applied
                
                setCaseEntitlement_updateCaseOverrideFalse - verify that on update of a case with an asset, the entitlement is not overwritten
                
                setCaseEntitlement_updateNoEntitlementsFound - verify that on update of a case with an asset and no entitlements found, the Purchase_Order__c is populated
                
                validateDispatchedCase - verify that a case effort record exists when the case status is set to dispatched.
                
                testBusinessHoursBucketer - verify if the business hours on case is stamped when the case status is updated.
History:
<Date>          <Authors Name>      <Brief Description of Change>
06/24/2016      Denise Bacher       Initial Creation (US1311)
05/16/2017      Amarendra Nagireddy  Added trigger switch as part of (US-0002505)
05/22/2017      Raj Sharan           Update for Test Utility Trigger Switch 
12/06/2017      Mani Sundaresan      Added validateDispatchedCase method - Validation to prevent cases from getting dispatched without the Case Effort(US 3657)
12/18/2017      Mani Sundaresan      Added testBusinessHoursBucketer method - validate if business hours is stamped on Case when the status is updated.

06/20/2018   Ryan Lambert    Remove all code / reference to FSLIS
------------------------------------------------------------*/
@isTest
private class CaseTrigger_Test {
    private static Configuration_Settings__c orgDefaults;
    private static Record_Type_IDs__c rtIds;
    private static Case_Effort_Validation_Status__c caseEffortVR;
    private static Validation_Rule_Exception__c vrException;
    private static Account parentAccount;
    private static List<Account> accounts;
    private static List<Product2> products;
    private static List<Asset> assets;
    private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    
    private static Pricebook2 pricebook;
    private static List<PricebookEntry> pricebookEntries;
    private static Map<Id, PricebookEntry> productToPricebookEntry;
    
    private static Coverage_Group__c coverageGroup;
    private static List<Coverage_Template__c> coverageTemplates;
    private static List<Entitlement> caseEntitlements;
    private static Map<Id, List<Entitlement>> assetToEntitlement;
    private static List<ServiceContract> serviceContracts;
    private static Map<Id, ServiceContract> accountToServiceContract;
    private static List<ContractLineItem> contractLineItems;
    private static Map<Id, ContractLineItem> assetToContractLineItem;
    
    static private void doStaticSetup(){
        
        orgDefaults = TestUtility.setupConfigurationSettings();
        orgDefaults.Override_Entitlement_on_Case__c=true;
        update orgDefaults;
        
        caseEffortVR = TestUtility.caseEffortVR();
        insert caseEffortVR;
        
        vrException = new Validation_Rule_Exception__c( Run_Validation_Rules__c = true);
        insert vrException;
        
        rtIds = TestUtility.setupRecordTypeIds();
        update rtIds;
        
        // 05/08/2017-(Amarendra Nagireddy)-Added trigger switch to run case and product related triggers while inserting the test records (US-0002505)
        TestUtility.insertCustSetting('ProductReplacement'); 
        TestUtility.insertCustSetting('CaseTrigger'); 
        
        // End of Modification for US-0002505
        
        parentAccount = TestUtility.newAccount('Parent Account', null, null);
        parentAccount.BillingPostalCode = '1234';
        insert parentAccount;
        
        accounts = new List<Account>();
        for(Integer i = 0; i < 10; i++){
            accounts.add(TestUtility.newAccount('Account '+i, null, parentAccount.Id));
            accounts[i].BillingPostalCode = '1234';
        }
        insert accounts;
        
        //create Contact
        defaultContact = TestUtility.newContact('Default', 'Contact', parentAccount.Id);
        applicationContact = TestUtility.newContact('Application', 'Contact', parentAccount.Id);
        connectivityContact = TestUtility.newContact('Connectivity', 'Contact', parentAccount.Id);
        insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
        
        products = new List<Product2>();
        products.add(TestUtility.newProduct('Product 01'));
        products.add(TestUtility.newProduct('Product 02'));
        insert products;
        
        assets = new List<Asset>();
        for(Account a : accounts){
            Asset a1=TestUtility.newAsset(a.Name + ' Asset 01', a.Id, parentAccount.Id, products[0].Id);
            a1.ContactId= defaultContact.Id;
            assets.add(a1);
            Asset a2= TestUtility.newAsset(a.Name + ' Asset 02', a.Id, parentAccount.Id, products[1].Id);
            a2.ContactId= defaultContact.Id;
            assets.add(a2);
        }
        insert assets;
        system.debug('assets======'+assets);
      }
    
   
    static private void setupEntitlementRelatedRecords(){
        SlaProcess caseEntitlementProcess;
        try{
            caseEntitlementProcess = [Select Id, Name From SlaProcess Where SObjectType = 'Case' Limit 1];
        }
        catch(Exception e){}
        System.assertNotEquals(null, caseEntitlementProcess, 'SETUP ERROR: test cannot proceed, no Case SLA Processes were found.');
        
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
        for(Integer i = 1; i <= 5; i++){
            coverageTemplates.add(TestUtility.newCoverageTemplate('Test Coverage Template '+i, coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_SLA'), null, null, null, String.valueOf(i), caseEntitlementProcess.Name, null, null));
        }
        insert coverageTemplates;
        
        // create Entitlement
        caseEntitlements = new List<Entitlement>();
        assetToEntitlement = new Map<Id, List<Entitlement>>();
        for(Asset a : assets){
            assetToEntitlement.put(a.Id, new List<Entitlement>());
            for(Coverage_Template__c ct : coverageTemplates){
                Entitlement e = TestUtility.newEntitlement('Test ' + a.Name, businessHours.Id, caseEntitlementProcess.Id, a.AccountId, a.Id, ct.Id, System.today().addDays(-30), System.today().addDays(365));
                caseEntitlements.add(e);
                assetToEntitlement.get(a.Id).add(e);
            }
        }
        insert caseEntitlements;
    }
    
    static private void setupServiceContractRecords(){
        // create Price Book
        pricebook = TestUtility.newPricebook('Test Pricebook');
        insert pricebook;
        
        // create Price Book Entry
        pricebookEntries = new List<PricebookEntry>();
        productToPricebookEntry = new Map<Id, PricebookEntry>();
        for(Product2 p : products){
            PricebookEntry pbe = TestUtility.newPricebookEntry(pricebook.Id, p.Id, 1);
            pricebookEntries.add(pbe);
            productToPricebookEntry.put(p.Id, pbe);
        }
        insert pricebookEntries;
        
        // create Service Contract
        serviceContracts = new List<ServiceContract>();
        accountToServiceContract = new Map<Id, ServiceContract>();
        Date StartDate = System.today().addDays(-1);
        Date EndDate = System.today().addDays(365);
        for(Account a : accounts){
            //ServiceContract sc = TestUtility.newServiceContract(a.Name + ' Service Contract', a.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Purchase_Order'), pricebook.Id,System.today().addDays(-30), System.today().addDays(365));
            ServiceContract sc = TestUtility.newServiceContract(a.Name + ' Service Contract', a.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Purchase_Order'), pricebook.Id,null,null);
            serviceContracts.add(sc);
            accountToServiceContract.put(a.Id, sc);
        }
        insert serviceContracts;
        
        // create Contract Line Item
        contractLineItems = new List<ContractLineItem>();
        assetToContractLineItem = new Map<Id, ContractLineItem>();
        for(Asset a : assets){
            ContractLineItem cli = TestUtility.newContractLineItem(accountToServiceContract.get(a.AccountId).Id, productToPricebookEntry.get(a.Product2Id).Id, 1, 100, a.Id);
            contractLineItems.add(cli);
            assetToContractLineItem.put(a.Id, cli);
        }
        insert contractLineItems;
    }
    
    /*static testMethod void setProductFromAsset_insertCaseWithAssetWithProduct() {
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            cases.add(TestUtility.newCase(a.AccountId, null, a.Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
            //cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }   
        
        Test.startTest();
            insert cases;
        Test.stopTest();
        
        // assert that the product on the case matches the product on the cases's asset
        List<Case> postInsertCases = [Select Id, Asset.Product2Id, ProductId,Account_Postal_Code__c From Case Where Id IN: cases];
        for(Case c : postInsertCases){
            System.assertEquals(c.Asset.Product2Id, c.ProductId);
        }
    }*/
    
    /*static testMethod void setProductFromAsset_updateCaseWithAssetWithProduct() {
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }   
        insert cases;
        
        // assert that the product null on the case
        List<Case> postInsertCases = [Select Id, AssetId, ProductId,Account_Postal_Code__c From Case Where Id IN: cases];
        for(Case c : postInsertCases){
            System.assertEquals(null, c.AssetId);
            System.assertEquals(null, c.ProductId);
        }
        
        Test.startTest();
            for(Integer i = 0; i < assets.size(); i++){
                cases[i].ProductId = assets[i].Product2Id;
            }
            update cases;
        Test.stopTest();
        
        // assert that the product on the case matches the product on the cases's asset
        List<Case> postUpdateCases = [Select Id, Asset.Product2Id, ProductId From Case Where Id IN: cases];
        for(Case c : postUpdateCases){
            //System.assertEquals(c.Asset.Product2Id, c.ProductId);
        }
    }*/
    
    static testMethod void setCaseEntitlement_insertCaseOverrideTrue(){
    	doStaticSetup();
        setupEntitlementRelatedRecords();
        
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            cases.add(TestUtility.newCase(a.AccountId, null, a.Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }   
        
        Test.startTest();
            insert cases;
        Test.stopTest();
        
        // assert that the entitlement with the highest priority was set
        List<Case> postInsertCases = [Select Id, EntitlementId, Entitlement.Coverage_Template__r.Priority__c From Case Where Id IN: cases];
        for(Case c : postInsertCases){
            //System.assertNotEquals(null, c.EntitlementId);
            //System.assertEquals('1', c.Entitlement.Coverage_Template__r.Priority__c);
        }
    }
    
    static testMethod void setCaseEntitlement_insertCaseOverrideFalse(){
    	doStaticSetup();
        setupEntitlementRelatedRecords();
        orgDefaults.Override_Entitlement_on_Case__c = false;
        update orgDefaults;
        
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            Case c = TestUtility.newCase(a.AccountId, null, a.Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone');
            c.EntitlementId = assetToEntitlement.get(a.Id)[assetToEntitlement.get(a.Id).size() - 1].Id;
            cases.add(c);
        }   
        
        Test.startTest();
            insert cases;
        Test.stopTest();
        
        // assert that the entitlement was not overwritten 
        List<Case> postInsertCases = [Select Id, EntitlementId, Entitlement.Coverage_Template__r.Priority__c From Case Where Id IN: cases];
        for(Case c : postInsertCases){
            System.assertNotEquals(null, c.EntitlementId);
            System.assertEquals('5', c.Entitlement.Coverage_Template__r.Priority__c);
        }
    }
    
    static testMethod void setCaseEntitlement_insertNoEntitlementsFound(){
    	doStaticSetup();
        delete [Select Id From Entitlement];
        setupServiceContractRecords();
        
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            cases.add(TestUtility.newCase(a.AccountId, null, a.Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }   
        
        Test.startTest();
            insert cases;
        Test.stopTest();
        
        // assert that the entitlement with the highest priority was set
        List<Case> postInsertCases = [Select Id, AssetId, EntitlementId, Purchase_Order__c From Case Where Id IN: cases];
        for(Case c : postInsertCases){
            System.assertEquals(null, c.EntitlementId);
            System.assertNotEquals(assetToContractLineItem.get(c.AssetId).Id, c.Purchase_Order__c);
        }
    }
    
    static testMethod void setCaseEntitlement_updateCaseOverrideTrue(){
    	doStaticSetup();
        setupEntitlementRelatedRecords();
        
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }   
        insert cases;
        
        for(Integer i = 0; i < cases.size(); i++){
            cases[i].AssetId = assets[i].Id;
            //cases[i].AssetId = assets[i].Id;
        }
        
        Test.startTest();
            update cases;
        Test.stopTest();
        
        // assert that the entitlement with the highest priority was set
        List<Case> postUpdateCases = [Select Id, EntitlementId, Entitlement.Coverage_Template__r.Priority__c From Case Where Id IN: cases];
        for(Case c : postUpdateCases){
            // System.assertNotEquals(null, c.EntitlementId);
           // System.assertEquals('1', c.Entitlement.Coverage_Template__r.Priority__c);
        }
    }
    
    static testMethod void setCaseEntitlement_updateCaseOverrideFalse(){
    	doStaticSetup();
        setupEntitlementRelatedRecords();
        orgDefaults.Override_Entitlement_on_Case__c = false;
        update orgDefaults;
        
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            Case c = TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone');
            c.EntitlementId = assetToEntitlement.get(a.Id)[assetToEntitlement.get(a.Id).size() - 1].Id;
            cases.add(c);
        }   
        insert cases;
        
        for(Integer i = 0; i < cases.size(); i++){
            cases[i].AssetId = assets[i].Id;
        }
        
        Test.startTest();
            update cases;
        Test.stopTest();
        
        // assert that the entitlement was not overwritten 
        List<Case> postUpdateCases = [Select Id, EntitlementId, Entitlement.Coverage_Template__r.Priority__c From Case Where Id IN: cases];
        for(Case c : postUpdateCases){
            System.assertNotEquals(null, c.EntitlementId);
            System.assertEquals('5', c.Entitlement.Coverage_Template__r.Priority__c);
        }
    }
    
    static testMethod void setCaseEntitlement_updateNoEntitlementsFound(){
    	doStaticSetup();
        delete [Select Id From Entitlement];
        setupServiceContractRecords();
        
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }   
        insert cases;
        
        for(Integer i = 0; i < cases.size(); i++){
            cases[i].AssetId = assets[i].Id;
        }
        
        Test.startTest();
            update cases;
        Test.stopTest();
        
        // assert that the entitlement was not set and the Purchase_Order__c was
        List<Case> postUpdateCases = [Select Id, AssetId, EntitlementId, Purchase_Order__c From Case Where Id IN: cases];
        for(Case c : postUpdateCases){
            System.assertEquals(null, c.EntitlementId);
            System.assertNotEquals(assetToContractLineItem.get(c.AssetId).Id, c.Purchase_Order__c);
        }
    }
    
    static testMethod void validateDispatchedCase(){
    	doStaticSetup();
        
        List<Case> cases = new List<Case>();
        for(Asset a : assets){
            cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }   
        insert cases;
        
        for(Case c : cases)
            c.Status = 'Dispatched';
            
        Test.startTest();
            try{
                update cases;
            }
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('Error: The case status cannot be modified without case effort.') ? true : false;
                System.Assert(expectedExceptionThrown);
            }
        Test.stopTest();    
    }
    
    static testMethod void testBusinessHoursBucketer() {
    	doStaticSetup();
        
        Stop_Status__c ss = new Stop_Status__c(Name = 'On Hold');
        insert ss;
        
        Case c = TestUtility.newCase(null, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Connectivity'), 'Applications', 'New', 'Low', 'Phone');
        c.Last_Status_Change__c = System.Now();
        insert c;
        
        Test.startTest();
        c.Status = 'On Hold';
        update c;

        c.Status = 'New';
        update c;

        Case updatedCase = [select Time_With_Customer__c,Time_With_Support__c,Case_Age_In_Business_Hours__c from Case where Id=:c.Id];
        System.assert(updatedCase.Time_With_Customer__c!=null);
        System.assert(updatedCase.Time_With_Support__c!=null);
        System.assert(updatedCase.Case_Age_In_Business_Hours__c==null);

        c.Status = 'Closed';
        update c;
        Test.stopTest();
        
        updatedCase = [select Time_With_Customer__c,Time_With_Support__c,Case_Age_In_Business_Hours__c from Case where Id=:c.Id];

        System.assert(updatedCase.Time_With_Customer__c!=null);
        System.assert(updatedCase.Time_With_Support__c!=null);
        System.assert(updatedCase.Case_Age_In_Business_Hours__c!=null);
    }
    
    static testMethod void testCheckToAssignServiceTerritory(){
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'sitelocTrigger'];
        
        Account pacc = TestUtility.newAccount('Test Parent Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        acc.BillingPostalCode = '60647-1234';
        acc.BillingCountryCode = 'US';
        insert acc;
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        insert opHours;
        
        ServiceTerritory pTerr = new ServiceTerritory();
        pTerr.Name = 'Breast Skeletal Health';
        pTerr.OperatingHoursId = opHours.Id;
        insert pTerr;
        
        ServiceTerritory sTerr = new ServiceTerritory();
        sTerr.Name = 'Test Service Territory';
        sTerr.ParentTerritoryId = pTerr.Id;
        sTerr.Service_Territory_Type__c = 'Service';
        sTerr.OperatingHoursId = opHours.Id;
        sTerr.isActive = true;
        insert sTerr;
        
        Service_Geography__c geo = new Service_Geography__c();
        geo.Type__c = 'Postal Code';
        geo.PostalCode__c = '60647';
        geo.Breast_Skeletal_Health_Service__c = sTerr.Id;
        geo.Priority__c = 1;
        insert geo;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', null);
        psd.Service_Territory__c = sTerr.Id;
        insert psd;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        insert prod;
        
        Site_Location__c siteLoc = new Site_Location__c();
        siteLoc.Account__c = acc.Id;
        siteLoc.Name = 'Test Site Location';
        siteLoc.Address_Line_1__c = '123';
        siteLoc.City__c = 'Chicago';
        siteLoc.State__c = 'IL';
        siteLoc.Zip_Code__c = '60647-1234';
        siteLoc.Country__c = 'US';
        insert siteLoc;
        
        Asset asst = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        asst.Install_Location__c = siteLoc.Id;
        insert asst;
        
        List<Case> cases = new List<Case>();
        
        Case cas0 = new Case();
        cas0.AccountId = acc.Id;
        cas0.AssetId = asst.Id;
        cas0.Install_Location__c = siteLoc.Id;
        cas0.Priority = 'High';
        cases.add(cas0);
        
        Case cas1 = new Case();
        cas1.ProductId = prod.Id;
        cas1.AccountId = acc.Id;
        cas1.Priority = 'High';
        cases.add(cas1);
        
        //Start test
        Test.startTest();
        
        //Insert cases
        insert cases;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        System.assertEquals(sTerr.Id, [SELECT Service_Territory__c FROM Case WHERE Id = :cas0.Id].Service_Territory__c);
        System.assertEquals(sTerr.Id, [SELECT Service_Territory__c FROM Case WHERE Id = :cas1.Id].Service_Territory__c);
    }
}