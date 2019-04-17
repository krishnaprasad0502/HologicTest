/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Test class to validate ContractLineItemParent_Invocable
				Tests Excecuted:
				
				setParentContractLineId_singleQuote - verifies the invocable method sets the parent contract line on contract lines created from a single quote
				
				setParentContractLineId_amendQuote - verifies the invocable method sets the parent contract line on contract lines created from an amendment quote

History:
<Date>			<Authors Name>		<Brief Description of Change>08/04/2016		Denise Bacher		Initial Creation (US164)
------------------------------------------------------------*/
@isTest
private class ContractLineItemParent_Invocable_Test {
	private static List<Product2> productSystems = new List<Product2>();
	private static List<Product2> productServices = new List<Product2>();
	private static List<Product2> productAddOns = new List<Product2>();
	
	private static Pricebook2 pricebook;
	private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
	private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id, PricebookEntry>>();
	
	private static Account customerAccount;
	private static List<Asset> assets = new List<Asset>();
	
	static{
		TestUtility.setupConfigurationSettings();
		
		// create products
		for(Integer i = 0; i < 5; i++){
			productSystems.add(TestUtility.newProduct('System '+i));
		}
		
		for(Integer i = 0; i < 5; i++){
			productServices.add(TestUtility.newProduct('Service '+i));
		}
		
		for(Integer i = 0; i < 2; i++){
			productAddOns.add(TestUtility.newProduct('Add-On '+i));
		}
		
		List<Product2> allProducts = new List<Product2>();
		allProducts.addAll(productSystems);
		allProducts.addAll(productServices);
		allProducts.addAll(productAddOns);
		insert allProducts;
		
		// create price book
		pricebook = TestUtility.newPricebook('Test Pricebook1');
		insert pricebook;
		pricebookToProductToPricebookEntry.put(pricebook.Id, new Map<Id, PricebookEntry>());
		
		// create Price Book entry
		for(Product2 p : allProducts){
			PricebookEntry pbe1 = TestUtility.newPricebookEntry(pricebook.Id, p.Id, 100);
			pricebookEntries.add(pbe1);
			pricebookToProductToPricebookEntry.get(pricebook.Id).put(p.Id, pbe1);
		}
		insert pricebookEntries;
		
		// create account
		customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
		insert customerAccount;
		
		// create asset
		for(Product2 p : productSystems){
			Asset asset = TestUtility.newAsset(p.Name + ' Asset ' + p.Name, customerAccount.Id, customerAccount.Id, p.Id);
			assets.add(asset);
		}
		insert assets;
	}
	
	static testMethod void setParentContractLineId_singleQuote() {
		// create Quotes
		SBQQ__Quote__c quotePrimary = TestUtility.newQuote(customerAccount.Id, null);
		quotePrimary.SBQQ__PriceBookId__c = pricebook.Id;
		
		insert quotePrimary;
		
		// create service quote lines
		List<SBQQ__QuoteLine__c> serviceQuoteLines = new List<SBQQ__QuoteLine__c>();
		for(Product2 p : productServices){
			SBQQ__QuoteLine__c quoteLine1 = TestUtility.newQuoteLine(quotePrimary.Id, p.Id, 10, 1);
			quoteLine1.Covered_Asset__c = assets[0].Id;
			serviceQuoteLines.add(quoteLine1);
		}
		insert serviceQuoteLines;
		
		// create add on quote lines
		List<SBQQ__QuoteLine__c> addOnQuoteLines = new List<SBQQ__QuoteLine__c>();
		for(SBQQ__QuoteLine__c ql : serviceQuoteLines){
			for(Product2 addOn : productAddOns){
				SBQQ__QuoteLine__c addOnLine = TestUtility.newQuoteLine(ql.SBQQ__Quote__c, addOn.Id, 10, 1);
				addOnLine.SBQQ__RequiredBy__c = ql.Id;
				addOnLine.Covered_Asset__c = ql.Covered_Asset__c;
				addOnQuoteLines.add(addOnLine);
			}
		}
		insert addOnQuoteLines;
		
		// create service contract
		ServiceContract serviceContract = TestUtility.newServiceContract('Primary Service Contract', customerAccount.Id
			, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract'), pricebook.Id
			, System.today().addDays(-1), System.today().addDays(365));
		insert serviceContract;
		
		// create service contract lines
		List<ContractLineItem> serviceContractLines = new List<ContractLineItem>();
		for(SBQQ__QuoteLine__c ql : serviceQuoteLines){
			ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(ql.SBQQ__Product__c).Id, 1, 1, ql.Covered_Asset__c);
			cli.SBQQSC__QuoteLine__c = ql.Id;
			cli.SBQQSC__Account__c = serviceContract.AccountId;
			cli.StartDate = serviceContract.StartDate;
			cli.EndDate = serviceContract.EndDate;
			serviceContractLines.add(cli);
		}
		insert serviceContractLines;
		
		Map<Id, Id> quoteLineToContractLine = new Map<Id, Id>();
		for(ContractLineItem cli : serviceContractLines){
			quoteLineToContractLine.put(cli.SBQQSC__QuoteLine__c, cli.Id);
		}
		
		// create add on contract lines
		List<ContractLineItem> addOnContractLines = new List<ContractLineItem>();
		for(SBQQ__QuoteLine__c ql : addOnQuoteLines){
			ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(ql.SBQQ__Product__c).Id, 1, 1, ql.Covered_Asset__c);
			cli.SBQQSC__QuoteLine__c = ql.Id;
			cli.SBQQSC__Account__c = serviceContract.AccountId;
			cli.StartDate = serviceContract.StartDate;
			cli.EndDate = serviceContract.EndDate;
			addOnContractLines.add(cli);
		}
		
		Test.startTest();
			ContractLineItemParent_Invocable.setParentContractLineItem(serviceContractLines);
			ContractLineItemParent_Invocable.setParentContractLineItem(addOnContractLines);
		Test.stopTest();
		
		List<ContractLineItem> insertedAddOns = [Select Id, ParentContractLineItemId, SBQQSC__QuoteLine__c, SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c
			From ContractLineItem
			Where Id IN: addOnContractLines];
			
		for(ContractLineItem cli : insertedAddOns){
			System.assertNotEquals(null, cli.ParentContractLineItemId);
			System.assertEquals(quoteLineToContractLine.get(cli.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c), cli.ParentContractLineItemId);
		}
	}
	
	static testMethod void setParentContractLineId_amendQuote() {
		SBQQ__Quote__c quotePrimary = TestUtility.newQuote(customerAccount.Id, null);
		quotePrimary.SBQQ__PriceBookId__c = pricebook.Id;
		
		SBQQ__Quote__c quoteAmend = TestUtility.newQuote(customerAccount.Id, null);
		quoteAmend.SBQQ__PriceBookId__c = pricebook.Id;
		
		insert new List<SBQQ__Quote__c> {quotePrimary, quoteAmend};
		
		// create service quote lines
		List<SBQQ__QuoteLine__c> primaryServiceQuoteLines = new List<SBQQ__QuoteLine__c>();
		List<SBQQ__QuoteLine__c> amendServiceQuoteLines = new List<SBQQ__QuoteLine__c>();
		for(Product2 p : productServices){
			SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quotePrimary.Id, p.Id, 10, 1);
			quoteLine.Covered_Asset__c = assets[1].Id;
			primaryServiceQuoteLines.add(quoteLine);
			
			SBQQ__QuoteLine__c quoteLineClone = TestUtility.newQuoteLine(quoteAmend.Id, p.Id, 0, 1);
			quoteLineClone.Covered_Asset__c = assets[1].Id;
			amendServiceQuoteLines.add(quoteLineClone);
		}
		
		List<SBQQ__QuoteLine__c> allServiceQuoteLines = new List<SBQQ__QuoteLine__c>();
		allServiceQuoteLines.addAll(primaryServiceQuoteLines);
		allServiceQuoteLines.addAll(amendServiceQuoteLines);
		insert allServiceQuoteLines;
		
		// create service contract
		ServiceContract serviceContract = TestUtility.newServiceContract('Service Contract - Quote Amend', customerAccount.Id
			, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract'), pricebook.Id
			, System.today().addDays(-1), System.today().addDays(365));
		insert serviceContract;
		
		// create service contract lines
		List<ContractLineItem> primaryServiceContractLines = new List<ContractLineItem>();
		for(SBQQ__QuoteLine__c ql : primaryServiceQuoteLines){
			ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(ql.SBQQ__Product__c).Id, 1, 1, ql.Covered_Asset__c);
			cli.SBQQSC__QuoteLine__c = ql.Id;
			cli.SBQQSC__Account__c = serviceContract.AccountId;
			cli.StartDate = serviceContract.StartDate;
			cli.EndDate = serviceContract.EndDate;
			primaryServiceContractLines.add(cli);
		}
		insert primaryServiceContractLines;
		
		// update the ammendment quote lines
		for(Integer i = 0; i < amendServiceQuoteLines.size(); i++){
			amendServiceQuoteLines[i].SBQQSC__UpgradedContractLine__c = primaryServiceContractLines[i].Id;
		}
		update amendServiceQuoteLines;
		
		// create add on quote lines
		List<SBQQ__QuoteLine__c> amendAddOnQuoteLines = new List<SBQQ__QuoteLine__c>();
		for(SBQQ__QuoteLine__c ql : amendServiceQuoteLines){
			for(Product2 addOn : productAddOns){
				SBQQ__QuoteLine__c addOnLine = TestUtility.newQuoteLine(ql.SBQQ__Quote__c, addOn.Id, 10, 1);
				addOnLine.SBQQ__RequiredBy__c = ql.Id;
				addOnLine.Covered_Asset__c = ql.Covered_Asset__c;
				amendAddOnQuoteLines.add(addOnLine);
			}
		}
		insert amendAddOnQuoteLines;
		
		// create add on contract lines
		List<ContractLineItem> amendAddOnContractLines = new List<ContractLineItem>();
		for(SBQQ__QuoteLine__c ql : amendAddOnQuoteLines){
			ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(ql.SBQQ__Product__c).Id, 1, 1, ql.Covered_Asset__c);
			cli.SBQQSC__QuoteLine__c = ql.Id;
			cli.SBQQSC__Account__c = serviceContract.AccountId;
			cli.StartDate = serviceContract.StartDate;
			cli.EndDate = serviceContract.EndDate;
			amendAddOnContractLines.add(cli);
		}
		
		Test.startTest();
			ContractLineItemParent_Invocable.setParentContractLineItem(primaryServiceContractLines);
			ContractLineItemParent_Invocable.setParentContractLineItem(amendAddOnContractLines);
		Test.stopTest();
		
		List<ContractLineItem> insertedAddOns = [Select Id, ParentContractLineItemId, SBQQSC__QuoteLine__c, SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c, SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__c
			From ContractLineItem
			Where Id IN: amendAddOnContractLines];
			
		for(ContractLineItem cli : insertedAddOns){
			System.assertNotEquals(null, cli.ParentContractLineItemId);
			System.assertEquals(cli.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__c, cli.ParentContractLineItemId);
		}
	}
}