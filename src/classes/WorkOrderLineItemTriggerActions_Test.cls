/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Tests functions related to WorkOrderLineItem records

History:
<Date			<Authors Name		<Brief Description of Change>
03/20/2018		Dave Mansell		Initial Creation (US-0004035)
------------------------------------------------------------*/

@isTest
private class WorkOrderLineItemTriggerActions_Test {
    
    private static final Double TEST_UNIT_PRICE 	= 27;
    private static final Double TEST_QUANTITY	 	= 45;
    private static final String TEST_TYPE 			= 'LABOR-WKDAY';
    
    //Tests any custom validation rules for WOLIs
    private static testMethod void testCustomValidations() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        User use = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        use.Division = 'Breast & Skeletal Health';
        update use;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, asst.Id, null);
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, asst.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        insert woli;
        System.assertNotEquals(null, woli.Id);
        
        //Start test
        Test.startTest();
        
        //Attempt to update the WOLI and ensure it errors on the validation
        Boolean errorOccured = false;
        try {
            woli.Override_Amount__c = 27;
            woli.Override_Explanation__c = null;
            woli.Price_Override_Reason__c = null;
            update woli;
        } catch (Exception e){
            errorOccured = true;
        }
        //System.assertEquals(true, errorOccured);
        
        //Stop test
        Test.stopTest();
    }
    /*private static testMethod void testUpdateUnitPriceToZero() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        User use = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        use.Division = 'Diagnostics';
        update use;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
                
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
         PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        insert pricebook;
        List<PricebookEntry> priceentires=new List<PricebookEntry>();
        
        for(Integer i=0; i<=5; i++){
            priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prod.id, UnitPrice= 9000.00, IsActive = true));
        }

        insert priceentires;
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        MaintenancePlan mp=new MaintenancePlan(AccountId=acc.id,Frequency=10,FrequencyType='Months',GenerationTimeframe=3,GenerationTimeframeType='Months',NextSuggestedMaintenanceDate=system.today()+30,StartDate=system.today());  
        insert mp;
        RecordType rt=[SELECT Id, SobjectType FROM RecordType WHERE Name='PM' AND SobjectType ='WorkOrder' LIMIT 1];
        WorkOrder wo;
        system.runAs(use)
        {
            wo = TestUtility.newWorkOrder(acc.Id, null, asst.Id, null);
            wo.RecordTypeId=rt.id;
            wo.SuggestedMaintenanceDate=system.today();
            wo.MaintenancePlanId=mp.id;
            insert wo;   
        }
        
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, asst.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Product2Id=priceentires[0].id;
        test.startTest();
        try{
          insert woli;  
        }
        
        catch(Exception e)
        {
            system.debug('Exception:'+e);
        }
        test.stopTest();
        System.assertNotEquals(null, woli.Id);
        
       
    }*/
    //Tests a WOLI that should be matched to an entitlement with a discount value
    private static testMethod void testInsertWOLI1() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'BONE');
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        prod.Service_Category__c = 'T3';
        prod.Labor_Travel_Type__c = TEST_TYPE;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        Coverage_Group_Product__c cgp = TestUtility.newCoverageGroupProduct(cg.Id, prod.Id);
        insert cgp;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, cg.Id, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), Date.Today(), null, 50, null);
        insert ent;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, childAsset.Id, null);
        wo.Pricebook2Id = pb.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, childAsset.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Labor_Travel_Type__c = TEST_TYPE;
        woli.Labor_Qty__c = TEST_QUANTITY;
        
        //Start test
        Test.startTest();
        
        //Insert the WOLI
        insert woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        woli = [
            SELECT Id
            ,Quantity
            ,ListPrice
            ,PricebookEntryId
            ,Product2Id
            ,Entitlement__c
            ,UnitPrice
            FROM WorkOrderLineItem
            WHERE Id = :woli.Id
        ];
        System.assertEquals(TEST_QUANTITY, woli.Quantity);
        System.assertEquals(pbe.Id, woli.PricebookEntryId);
        System.assertEquals(prod.Id, woli.Product2Id);
        System.assertEquals(TEST_UNIT_PRICE, woli.ListPrice);
        System.assertEquals(ent.Id, woli.Entitlement__c);
        System.assertEquals(TEST_UNIT_PRICE * ent.Discount__c / 100, woli.UnitPrice);
    }
    
    //Tests a WOLI that should be matched to an entitlement with a max covered amount value
    private static testMethod void testInsertWOLI2() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'MOLECULAR');
        psd.Source_Division__c = 'MOLECULAR';
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        prod.Labor_Travel_Type__c = TEST_TYPE;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        Coverage_Group_Product__c cgp = TestUtility.newCoverageGroupProduct(cg.Id, prod.Id);
        insert cgp;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, cg.Id, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), Date.Today(), null, 0, 10);
        insert ent;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, childAsset.Id, null);
        wo.Pricebook2Id = pb.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, childAsset.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Labor_Travel_Type__c = TEST_TYPE;
        woli.Labor_Qty__c = TEST_QUANTITY;
        
        //Start test
        Test.startTest();
        
        //Insert the WOLI
        insert woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        woli = [
            SELECT Id
            ,Quantity
            ,ListPrice
            ,PricebookEntryId
            ,Product2Id
            ,Entitlement__c
            ,UnitPrice
            FROM WorkOrderLineItem
            WHERE Id = :woli.Id
        ];
        System.assertEquals(1, woli.Quantity);
        System.assertEquals(pbe.Id, woli.PricebookEntryId);
        System.assertEquals(prod.Id, woli.Product2Id);
        System.assertEquals(TEST_UNIT_PRICE, woli.ListPrice);
        System.assertEquals(ent.Id, woli.Entitlement__c);
        System.assertEquals(TEST_UNIT_PRICE - ent.Max_Covered_Amount__c, woli.UnitPrice);
    }
    
    //Tests a WOLI that should be matched to an luminary discount
    private static testMethod void testInsertWOLI3() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'BONE');
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        prod.Service_Category__c = 'T3';
        prod.Labor_Travel_Type__c = TEST_TYPE;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        Coverage_Group_Product__c cgp = TestUtility.newCoverageGroupProduct(cg.Id, prod.Id);
        insert cgp;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, cg.Id, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), Date.Today(), null, 50, null);
        insert ent;
        
        Contract cont = new Contract();
        cont.AccountId = acc.Id;
        cont.Contract_End_Date__c = Date.today().addDays(10);
        cont.Status = 'Draft';
        cont.Marketing_Program__c = 'MEDA-Luminary Discounts';
        insert cont;
        
        Agreed_Price__c price = new Agreed_Price__c();
        price.Discount__c = ent.Discount__c + 10;
        price.Contract__c = cont.Id;
        insert price;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, childAsset.Id, null);
        wo.Pricebook2Id = pb.Id;
        wo.Luminary_Discount_Agreed_Price__c = price.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, childAsset.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Labor_Travel_Type__c = TEST_TYPE;
        woli.Labor_Qty__c = TEST_QUANTITY;
        woli.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Part_Billing');
        
        //Start test
        Test.startTest();
        
        //Insert the WOLI
        insert woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        woli = [
            SELECT Id
            ,UnitPrice
            FROM WorkOrderLineItem
            WHERE Id = :woli.Id
        ];
        System.assertEquals(TEST_UNIT_PRICE * (1 - price.Discount__c / 100), woli.UnitPrice);
    }
    
    //Tests a WOLI with the billable event record type
    private static testMethod void testInsertWOLI4() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'MOLECULAR');
        psd.Source_Division__c = 'MOLECULAR';
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        prod.Service_Category__c = 'T3';
        prod.Labor_Travel_Type__c = 'Training';
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        Coverage_Group_Product__c cgp = TestUtility.newCoverageGroupProduct(cg.Id, prod.Id);
        insert cgp;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, cg.Id, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), Date.Today(), null, 10, null);
        insert ent;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, childAsset.Id, null);
        wo.Pricebook2Id = pb.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, childAsset.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Billable_Event'), null);
        woli.Labor_Travel_Type__c = 'Training';
        woli.Labor_Qty__c = TEST_QUANTITY;
        woli.UnitPrice = 1234;
        
        //Start test
        Test.startTest();
        
        //Insert the WOLI
        insert woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        woli = [
            SELECT Id
            ,Quantity
            ,ListPrice
            ,PricebookEntryId
            ,Product2Id
            ,Entitlement__c
            FROM WorkOrderLineItem
            WHERE Id = :woli.Id
        ];
        System.assertEquals(TEST_QUANTITY, woli.Quantity);
        System.assertEquals(pbe.Id, woli.PricebookEntryId);
        System.assertEquals(prod.Id, woli.Product2Id);
        System.assertEquals(TEST_UNIT_PRICE, woli.ListPrice);
        System.assertEquals(ent.Id, woli.Entitlement__c);
    }
    
    //Tests a WOLI that is Diagnostic Depot Repair
    private static testMethod void testInsertWOLI5() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'BONE');
        psd.Division__c = 'Diagnostics';
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Diagnostic Depot Repair Product');
        prod.Product_Source_Division__c = psd.Id;
        insert prod;
        
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getInstance();
        orgDefaults.Depot_Repair_Labor_Product_Diag__c = prod.Id;
        insert orgDefaults;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        Coverage_Group_Product__c cgp = TestUtility.newCoverageGroupProduct(cg.Id, prod.Id);
        insert cgp;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, cg.Id, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), Date.Today(), null, 50, null);
        insert ent;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, childAsset.Id, null);
        wo.Pricebook2Id = pb.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, childAsset.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Labor_Travel_Type__c = 'Depot Repair';
        woli.Labor_Qty__c = TEST_QUANTITY;
        
        //Start test
        Test.startTest();
        
        //Insert the WOLI
        insert woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        woli = [
            SELECT Id
            ,PricebookEntryId
            FROM WorkOrderLineItem
            WHERE Id = :woli.Id
        ];
        System.assertEquals(pbe.Id, woli.PricebookEntryId);
    }
    
    //Tests a WOLI that should be matched to an entitlement but have unit price zeroed out
    private static testMethod void testInsertWOLI6() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'BONE');
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        prod.Service_Category__c = 'T3';
        prod.Labor_Travel_Type__c = TEST_TYPE;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        Coverage_Group_Product__c cgp = TestUtility.newCoverageGroupProduct(cg.Id, prod.Id);
        insert cgp;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, cg.Id, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), Date.Today(), null, 50, null);
        insert ent;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, childAsset.Id, null);
        wo.Pricebook2Id = pb.Id;
        wo.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Applications');
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, childAsset.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Labor_Travel_Type__c = TEST_TYPE;
        woli.Labor_Qty__c = TEST_QUANTITY;
        
        //Start test
        Test.startTest();
        
        //Insert the WOLI
        insert woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        woli = [
            SELECT Id
            ,UnitPrice
            FROM WorkOrderLineItem
            WHERE Id = :woli.Id
        ];
        System.assertEquals(0, woli.UnitPrice);
    }
    
    //Tests a WOLI where WO has Product__c value
    private static testMethod void testInsertWOLI7() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'BONE');
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        prod.Service_Category__c = 'T3';
        prod.Labor_Travel_Type__c = TEST_TYPE;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        Coverage_Group_Product__c cgp = TestUtility.newCoverageGroupProduct(cg.Id, prod.Id);
        insert cgp;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, cg.Id, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), Date.Today(), null, 50, null);
        insert ent;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.Product__c = prod.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, null, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Labor_Travel_Type__c = TEST_TYPE;
        woli.Labor_Qty__c = TEST_QUANTITY;
        
        //Start test
        Test.startTest();
        
        //Insert the WOLI
        insert woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        woli = [
            SELECT Id
            ,Quantity
            ,ListPrice
            ,PricebookEntryId
            ,Product2Id
            ,Entitlement__c
            ,UnitPrice
            FROM WorkOrderLineItem
            WHERE Id = :woli.Id
        ];
        System.assertEquals(TEST_QUANTITY, woli.Quantity);
        System.assertEquals(pbe.Id, woli.PricebookEntryId);
        System.assertEquals(prod.Id, woli.Product2Id);
    }
    
    //Tests updating a WOLI
    private static testMethod void testUpdateWOLI() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'MOLECULAR');
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        prod.Service_Category__c = 'T3';
        prod.Labor_Travel_Type__c = TEST_TYPE;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        Coverage_Group_Product__c cgp = TestUtility.newCoverageGroupProduct(cg.Id, prod.Id);
        insert cgp;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, cg.Id, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount'), Date.Today(), null, 50, null);
        insert ent;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null, null);
        wo.Pricebook2Id = pb.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, null, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Quantity = null;
        woli.Labor_Travel_Type__c = TEST_TYPE;
        woli.Labor_Qty__c = TEST_QUANTITY;
        insert woli;
        
        //Start test
        Test.startTest();
        
        //Update the WO and WOLI
        wo.AssetId = childAsset.Id;
        update wo;
        
        woli.UnitPrice = null;
        woli.AssetId = childAsset.Id;
        update woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        woli = [
            SELECT Id
            ,Quantity
            ,ListPrice
            ,PricebookEntryId
            ,Product2Id
            ,Entitlement__c
            ,UnitPrice
            FROM WorkOrderLineItem
            WHERE Id = :woli.Id
        ];
        System.assertEquals(1, woli.Quantity);
        System.assertEquals(pbe.Id, woli.PricebookEntryId);
        System.assertEquals(prod.Id, woli.Product2Id);
        System.assertEquals(TEST_UNIT_PRICE, woli.ListPrice);
        System.assertEquals(ent.Id, woli.Entitlement__c);
        System.assertEquals(0, woli.UnitPrice);
    }
    
    //Tests deleting a cancelled WOLI
    private static testMethod void testCheckForCancelledStatus() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'MOLECULAR');
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null, null);
        wo.Pricebook2Id = pb.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, null, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
        woli.Quantity = null;
        woli.Labor_Travel_Type__c = TEST_TYPE;
        woli.Labor_Qty__c = TEST_QUANTITY;
        insert woli;
        
        //Start test
        Test.startTest();
        
        //Update the WOLI
        woli.Status = 'Cancelled';
        update woli;
        
        //Stop test
        Test.stopTest();
        
        //Read back WOLI and validate results
        System.assertEquals(0, [SELECT Id FROM WorkOrderLineItem WHERE Id = :woli.Id].size());
    }
    
}