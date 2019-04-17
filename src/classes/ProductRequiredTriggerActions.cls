/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Functions related to ProductRequired records

History:
<Date			<Authors Name		<Brief Description of Change>
04/03/2018		Dave Mansell		Initial Creation (US-0004059)
------------------------------------------------------------*/

public class ProductRequiredTriggerActions {

	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Sets PBEId on incoming records
	Inputs:         	List of records
	Returns:        	N/A
	Test Class(es):		ProductRequiredTriggerActions_Test.testInsertPR,
						ProductRequiredTriggerActions_Test.testInsertPR2
	------------------------------------------------------------*/
	public static void setPriceBookEntryAndListPrice(List<ProductRequired> prs){
		Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>();
		Set<Id> pricebookIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		
		//Collect values from incoming PRs
		for(ProductRequired pr : prs) {
			wosById.put(pr.ParentRecordId, null);
			productIds.add(pr.Product2Id);
		}
		
		//Map parent work order records by Id
		for(WorkOrder wo : [
			SELECT Id
				  ,Pricebook2Id
				  ,CurrencyISOCode
			  FROM WorkOrder
			 WHERE Id IN :wosById.keySet()
			   AND Pricebook2Id != null
		]){
			wosById.put(wo.Id, wo);
			pricebookIds.add(wo.Pricebook2Id);
		}
		
		//Map pbes by key: Pricebook2Id | Product2Id
		Map<String, PricebookEntry> pbesByKey = new Map<String, PricebookEntry>();
		for(PricebookEntry pbe : [
			SELECT Id
				  ,Product2Id
				  ,Pricebook2Id
				  ,UnitPrice
			  FROM PricebookEntry
			 WHERE Pricebook2Id IN :pricebookIds
			   AND Product2Id IN :productIds
		]){
			String key = pbe.Pricebook2Id + '|' + pbe.Product2Id;
			pbesByKey.put(key, pbe);
		}
		
		//Loop through incoming PRs
		for(Integer i = 0; i < prs.size(); i++){
			ProductRequired pr = prs[i];
			
			//Find the correct PBE for each
			WorkOrder wo = wosById.get(pr.ParentRecordId);
			PricebookEntry pbe;
			if(wo != null){
				String key = wo.Pricebook2Id + '|' + pr.Product2Id;
				pbe = pbesByKey.get(key);
				pr.CurrencyISOCode = wo.CurrencyISOCode;
			}
			if(pbe != null){
				pr.List_Price__c = pbe.UnitPrice;
			}
		}
	}
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Calls helper function to create entitlements
	Inputs:         	List of records
	Returns:        	N/A
	Test Class(es):		ProductRequiredTriggerActions_Test.testInsertPR,
						ProductRequiredTriggerActions_Test.testInsertPR2
	------------------------------------------------------------*/
	public static void linkEntitlementsAndSetUnitPricing(List<ProductRequired> prs){
		//Call helper function to create entitlements
		EntitlementLinkingHelper.linkEntitlementsForRecords(prs, EntitlementLinkingHelper.TYPE_PRODUCT_REQUIRED, null, null);
	}
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Checks to see if parent work orders need updating
	Inputs:         	List of records, Map of old records
	Returns:        	N/A
	Test Class(es):		ProductRequiredTriggerActions_Test.testInsertPR,
						ProductRequiredTriggerActions_Test.testInsertPR2
	------------------------------------------------------------*/
	public static void checkToUpdateParentWorkOrders(List<ProductRequired> prs, Map<Id, ProductRequired> oldMap){
		List<ProductRequired> validPRs = new List<ProductRequired>();
		for(ProductRequired pr : prs){
			ProductRequired old = oldMap.get(pr.Id);
			if(pr.Total_Price__c != old.Total_Price__c){
				validPRs.add(pr);
			}
		}
		
		if(validPRs.size() > 0){
			updateParentWorkOrders(validPRs);
		}
	}
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Updates parent Work Order records
	Inputs:         	List of records
	Returns:        	N/A
	Test Class(es):		ProductRequiredTriggerActions_Test.testInsertPR,
						ProductRequiredTriggerActions_Test.testInsertPR2
	------------------------------------------------------------*/
	public static void updateParentWorkOrders(List<ProductRequired> prs){
		Set<Id> woIds = new Set<Id>();
		for(ProductRequired pr : prs){
			woIds.add(pr.ParentRecordId);
		}
		
		List<WorkOrder> wos = [
			SELECT Id
				  ,(SELECT Total_Price__c
				      FROM ProductsRequired
				   )
			  FROM WorkOrder
			 WHERE Id IN :woIds
		];
		
		for(WorkOrder wo : wos){
			Double total = 0;
			for(ProductRequired pr : wo.ProductsRequired){
				total += pr.Total_Price__c;
			}
			wo.Estimate_Total__c = total;
		}
		
		update wos;
	}
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Checks for Delete checkbox value
	Inputs:         	List of new records
	Returns:        	N/A
	Test Class(es):		ProductRequiredTriggerActions_Test.testCheckForDelete
	------------------------------------------------------------*/
	public static void checkForDelete(List<ProductRequired> prs){
		Set<Id> prIds = new Set<Id>();
		for(ProductRequired pr : [
			SELECT Id
			  FROM ProductRequired
			 WHERE Id IN :prs
			   AND Delete__c = true
		]){
			prIds.add(pr.Id);
		}
		if(prIds.size() > 0){
			deletePRs(prIds);
		}
	}
	
	@future
	private static void deletePRs(Set<Id> prIds){
		delete [SELECT Id FROM ProductRequired WHERE Id IN :prIds];
	}

}