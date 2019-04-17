/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Tests functions related to ProductRequired records

History:
<Date			<Authors Name		<Brief Description of Change>
04/03/2018		Dave Mansell		Initial Creation (US-0004059)
------------------------------------------------------------*/

@isTest
private class ProductRequiredTriggerActions_Test {
	
	private static final Double TEST_UNIT_PRICE 	= 27;
	private static final Double TEST_QUANTITY	 	= 45;

	//Tests a PR that should be matched to an entitlement with a discount value
	private static testMethod void testInsertPR() {
		//Create test data
		TestUtility.setupConfigurationSettings();
		
		Account acc = TestUtility.newAccount('Test Account', null);
		insert acc;
		
		Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
		insert pb;
		
		Product2 prod = TestUtility.newProduct('Test Product');
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
		wo = [SELECT Id, Pricebook2Id FROM WorkOrder WHERE Id = :wo.Id];
		System.assertEquals(pb.Id, wo.Pricebook2Id);
		
		ProductRequired pr = new ProductRequired();
		pr.ParentRecordId = wo.Id;
		pr.Product2Id = prod.Id;
		pr.QuantityRequired = TEST_QUANTITY;
		
		//Start test
		Test.startTest();
		
		//Insert the PR
		insert pr;
		
		//Stop test
		Test.stopTest();
		
		//Read back PR and validate results
		pr = [
			SELECT Id
				  ,Entitlement__c
				  ,List_Price__c
				  ,Unit_Price__c
				  ,Total_Price__c
				  ,QuantityRequired
			  FROM ProductRequired
			 WHERE Id = :pr.Id
		];
		System.assertEquals(ent.Id, pr.Entitlement__c);
		System.assertEquals(TEST_UNIT_PRICE, pr.List_Price__c);
		System.assertEquals(TEST_UNIT_PRICE * ent.Discount__c / 100, pr.Unit_Price__c);
		System.assertEquals(pr.Unit_Price__c * TEST_QUANTITY, pr.Total_Price__c);
		
		//Read back WO and validate results
		wo = [
			SELECT Id
				  ,Estimate_Total__c
			  FROM WorkOrder
			 WHERE Id = :wo.Id
		];
		System.assertEquals(pr.Total_Price__c, wo.Estimate_Total__c);
		
		//Update PR
		pr.Unit_Price__c = 1;
		update pr;
		
		wo = [
			SELECT Id
				  ,Estimate_Total__c
			  FROM WorkOrder
			 WHERE Id = :wo.Id
		];
		System.assertEquals(TEST_QUANTITY, wo.Estimate_Total__c);
		
		//Delete PR
		delete pr;
		
		wo = [
			SELECT Id
				  ,Estimate_Total__c
			  FROM WorkOrder
			 WHERE Id = :wo.Id
		];
		System.assertEquals(0, wo.Estimate_Total__c);
	}

	//Tests a PR that should be matched to an entitlement with a max covered amount value
	private static testMethod void testInsertPR2() {
		//Create test data
		TestUtility.setupConfigurationSettings();
		
		Account acc = TestUtility.newAccount('Test Account', null);
		insert acc;
		
		Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
		insert pb;
		
		Product2 prod = TestUtility.newProduct('Test Product');
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
		
		ProductRequired pr = new ProductRequired();
		pr.ParentRecordId = wo.Id;
		pr.Product2Id = prod.Id;
		pr.QuantityRequired = TEST_QUANTITY;
		
		//Start test
		Test.startTest();
		
		//Insert the PR
		insert pr;
		
		//Stop test
		Test.stopTest();
		
		//Read back PR and validate results
		pr = [
			SELECT Id
				  ,Entitlement__c
				  ,List_Price__c
				  ,Unit_Price__c
				  ,Total_Price__c
			  FROM ProductRequired
			 WHERE Id = :pr.Id
		];
		System.assertEquals(ent.Id, pr.Entitlement__c);
		System.assertEquals(TEST_UNIT_PRICE, pr.List_Price__c);
		System.assertEquals(TEST_UNIT_PRICE - ent.Max_Covered_Amount__c, pr.Unit_Price__c);
		System.assertEquals(pr.Unit_Price__c * TEST_QUANTITY, pr.Total_Price__c);
	}

	//Tests a PR that should be matched to a luminary discount
	private static testMethod void testInsertPR3() {
		//Create test data
		TestUtility.setupConfigurationSettings();
		
		Account acc = TestUtility.newAccount('Test Account', null);
		insert acc;
		
		Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
		insert pb;
		
		Product2 prod = TestUtility.newProduct('Test Product');
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
		
		ProductRequired pr = new ProductRequired();
		pr.ParentRecordId = wo.Id;
		pr.Product2Id = prod.Id;
		pr.QuantityRequired = TEST_QUANTITY;
		
		//Start test
		Test.startTest();
		
		//Insert the PR
		insert pr;
		
		//Stop test
		Test.stopTest();
		
		//Read back PR and validate results
		pr = [
			SELECT Id
				  ,Unit_Price__c
			  FROM ProductRequired
			 WHERE Id = :pr.Id
		];
		System.assertEquals(TEST_UNIT_PRICE * (1 - price.Discount__c / 100), pr.Unit_Price__c);
	}
	
	//Test deletion based on Delete__c field
    private static testMethod void testCheckForDelete() {
        //Create data
        TestUtility.setupConfigurationSettings();
		
		Account acc = TestUtility.newAccount('Test Account', null);
		insert acc;
		
		Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
		insert pb;
		
		Product2 prod = TestUtility.newProduct('Test Product');
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
		
		ProductRequired pr = new ProductRequired();
		pr.ParentRecordId = wo.Id;
		pr.Product2Id = prod.Id;
		pr.QuantityRequired = TEST_QUANTITY;
		insert pr;
		
		//Start test
		Test.startTest();
		
		//Update the PR
		pr.Delete__c = true;
		update pr;
		
		//Stop test
		Test.stopTest();
        
        //Read back and validate results
        System.assertEquals(0, [SELECT Id FROM ProductRequired WHERE Id = :pr.Id].size());
    }

}