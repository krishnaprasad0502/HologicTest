@isTest
private class ContractLineItemStatusBatch_Test {

	private static testMethod void testContractLineItemStatusBatchScheduler() {
		//Create test data
        TestUtility.setupConfigurationSettings();
        
        //Deactivate trigger which duplicates the functionality we're trying to test
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'ContractLineItemTrigger'];
        
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
        asst.Contract_Line_Processing_Completed__c = true;
        insert asst;
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = servCon.Id;
        cli.PricebookEntryId = pbe.Id;
        cli.Quantity = 27;
        cli.UnitPrice = 27;
        cli.StartDate = Date.today();
        cli.EndDate = Date.today().addYears(1);
        cli.AssetId = asst.Id;
        insert cli;
        
        asst.SBQQSC__CurrentContractLineItem__c = cli.id;
        update asst;
        
        //Start test
        Test.startTest();
        
        //Call scheduler
        System.schedule('arbitraryNameAndDate', '0 0 0 31 3 ? 2027', new ContractLineItemStatusBatchScheduler());
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        asst = [SELECT Id, SBQQSC__CurrentContractLineItem__c, Contract_Line_Processing_Completed__c FROM Asset WHERE Id = :asst.Id];
        //System.assertEquals(cli.Id, asst.SBQQSC__CurrentContractLineItem__c);
        System.assertEquals(true, asst.Contract_Line_Processing_Completed__c);
	}

}