/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Tests functions related to ProductConsumed records

History:
<Date           <Authors Name       <Brief Description of Change>
03/20/201       Dave Mansell        Initial Creation (US-0004035)
------------------------------------------------------------*/

@isTest
private class ProductConsumedTriggerActions_Test {
    
    private static final Double TEST_UNIT_PRICE     = 27;

    //Tests any custom validation rules for PCs
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
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = 1;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pcon = new ProductConsumed();
        pcon.ProductItemId = prit.Id;
        pcon.WorkOrderId = wo.Id;
        pcon.Return_Asset__c = asst.Id;
        pcon.QuantityConsumed = 1;
        insert pcon;
        
        //Start test
        Test.startTest();
        
        //Attempt to update the PC and ensure it errors on the validation
        Boolean errorOccured = false;
        try {
            pcon.Override_Amount__c = 27;
            pcon.Override_Explanation__c = null;
            pcon.Price_Override_Reason__c = null;
            update pcon;
            
        } catch (Exception e){
            errorOccured = true;
        }
        System.assertEquals(true, errorOccured);
        
        //Stop test
        Test.stopTest();
    }
    
    private static testMethod void testCheckForUnitPriceChange() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, asst.Id, null);
        insert wo;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = 15;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pcon = new ProductConsumed();
        pcon.ProductItemId = prit.Id;
        pcon.WorkOrderId = wo.Id;
        pcon.Return_Asset__c = asst.Id;
        pcon.QuantityConsumed = 12;
        insert pcon;
        
        //Start test
        Test.startTest();
        
        //Update the pc
        pcon.UnitPrice = TEST_UNIT_PRICE;
        update pcon;
        
        //Stop test
        Test.stopTest();
        
        //Read back ProductConsumed and validate results
        pcon = [
            SELECT Id
                  ,UnitPrice
                  ,QuantityConsumed
                  ,Override_Amount__c
              FROM ProductConsumed
             WHERE Id = :pcon.Id
        ];
        System.assertEquals(pcon.UnitPrice * pcon.QuantityConsumed, pcon.Override_Amount__c);
    }
    
    private static testMethod void testUpdateReturnFields() {
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        asst.SerialNumber = '1234567';
        insert asst;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, asst.Id, null);
        insert wo;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = 1;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pcon = new ProductConsumed();
        pcon.ProductItemId = prit.Id;
        pcon.WorkOrderId = wo.Id;
        pcon.Return_Asset__c = asst.Id;
        pcon.QuantityConsumed = 1;
        
        //Start test
        Test.startTest();
        
        //Insert ProductConsumed record
        insert pcon;
        
        //Stop test
        Test.stopTest();
        
        //Read back ProductConsumed and validate results
        pcon = [
            SELECT Id
                  ,Return_Product__c
                  ,Return_Serial_Number__c
              FROM ProductConsumed
             WHERE Id = :pcon.Id
        ];
        System.assertEquals(prod.Id,            pcon.Return_Product__c);
        System.assertEquals(asst.SerialNumber,  pcon.Return_Serial_Number__c);
    }
    
    private static testMethod void testLinkEntitlements() {
        //Create data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
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
        insert wo;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = 1;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pcon = new ProductConsumed();
        pcon.ProductItemId = prit.Id;
        pcon.WorkOrderId = wo.Id;
        pcon.QuantityConsumed = 1;
        pcon.UnitPrice = TEST_UNIT_PRICE;
        
        //Start test
        Test.startTest();
        
        //Insert ProductConsumed record
        insert pcon;
        
        //Stop test
        Test.stopTest();
        
        //Read back ProductConsumed and validate results
        pcon = [
            SELECT Id
                  ,Entitlement__c
                  ,Product2Id
                  ,UnitPrice
              FROM ProductConsumed
             WHERE Id = :pcon.Id
        ];
        System.assertEquals(prod.Id, pcon.Product2Id);
        System.assertEquals(ent.Id, pcon.Entitlement__c);
        System.assertEquals(TEST_UNIT_PRICE * ent.Discount__c / 100, pcon.UnitPrice);
    }
    
    private static testMethod void testLinkEntitlements2() {
        //Create data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
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
		wo.Luminary_Discount_Agreed_Price__c = price.Id;
        insert wo;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = 1;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pcon = new ProductConsumed();
        pcon.ProductItemId = prit.Id;
        pcon.WorkOrderId = wo.Id;
        pcon.QuantityConsumed = 1;
        pcon.UnitPrice = TEST_UNIT_PRICE;
        
        //Start test
        Test.startTest();
        
        //Insert ProductConsumed record
        insert pcon;
        
        //Stop test
        Test.stopTest();
        
        //Read back ProductConsumed and validate results
        pcon = [
            SELECT Id
                  ,UnitPrice
              FROM ProductConsumed
             WHERE Id = :pcon.Id
        ];
        System.assertEquals(TEST_UNIT_PRICE * (1 - price.Discount__c / 100), pcon.UnitPrice);
    }

    private static testMethod void testUpdateAssetFields() {
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        asst.Oracle_System_Id__c = 'Test ID';
        insert asst;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, asst.Id, null);
        wo.Status = 'Completed';
        wo.FE_Resolution__c = 'Test';
        wo.StartDate = Date.today();
        wo.EndDate = Date.today().addDays(1);
        insert wo;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = 1;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pcon = new ProductConsumed();
        pcon.ProductItemId = prit.Id;
        pcon.WorkOrderId = wo.Id;
        pcon.Return_Asset__c = asst.Id;
        pcon.QuantityConsumed = 1;
        
        //Start test
        Test.startTest();
        
        //Insert ProductConsumed record
        insert pcon;
        
        //Stop test
        Test.stopTest();
        
        //Read back Asset and validate results
        asst = [
            SELECT Id
                  ,Oracle_System_Id__c
              FROM Asset
             WHERE Id = :asst.Id
        ];
        System.assertEquals(null, asst.Oracle_System_Id__c);
    }

    private static testMethod void testCheckForDelete() {
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        asst.Oracle_System_Id__c = 'Test ID';
        insert asst;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, asst.Id, null);
        insert wo;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = 1;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pcon = new ProductConsumed();
        pcon.ProductItemId = prit.Id;
        pcon.WorkOrderId = wo.Id;
        pcon.Return_Asset__c = asst.Id;
        pcon.QuantityConsumed = 1;
        insert pcon;
        
        //Start test
        Test.startTest();
        
        //Update ProductConsumed record
        pcon.Delete__c = true;
        update pcon;
        
        //Stop test
        Test.stopTest();
        
        //Read back Asset and validate results
        System.assertEquals(0, [SELECT Id FROM ProductConsumed WHERE Id = :pcon.Id].size());
    }

}